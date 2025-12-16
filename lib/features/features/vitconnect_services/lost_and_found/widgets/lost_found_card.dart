import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/lost_found_item.dart';

/// Lost & Found item card widget
class LostFoundCard extends StatelessWidget {
  final LostFoundItem item;

  const LostFoundCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildIcon(theme),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Place
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.text.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.place,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.text.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Posted by
                    Text(
                      'Posted by ${item.postedByName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.text.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Image thumbnail if available
              if (item.imagePath != null) _buildThumbnail(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(theme) {
    final isLost = item.isLost;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isLost ? Colors.red : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isLost ? Icons.help_outline : Icons.check_circle_outline,
        color: isLost ? Colors.red : Colors.green,
        size: 24,
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: item.imagePath!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 24, color: Colors.grey),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image,
                size: 24,
                color: Colors.grey,
              ),
            ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Type badge
                        _buildTypeBadge(theme),
                        const SizedBox(height: 16),

                        // Item name
                        Text(
                          item.itemName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image if available
                        if (item.imagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.imagePath!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Place
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Place',
                          value: item.place,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.description,
                            label: 'Description',
                            value: item.description!,
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Posted by
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Posted By',
                          value: '${item.postedByName} (${item.postedByRegno})',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        // Contact
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Contact Name',
                          value: item.contactName,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Contact Number',
                          value: item.contactNumber,
                          theme: theme,
                        ),
                        const SizedBox(height: 24),

                        // Call button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _makeCall(item.contactNumber),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildTypeBadge(theme) {
    final isLost = item.isLost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isLost ? Colors.red : Colors.green).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isLost ? Colors.red : Colors.green).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isLost ? '❓ Lost' : '✅ Found',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isLost ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.text.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, color: theme.text)),
            ],
          ),
        ),
      ],
    );
  }

  void _makeCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        Logger.d('LostFoundCard', 'Launched call to: $phoneNumber');
      }
    } catch (e) {
      Logger.e('LostFoundCard', 'Error launching call', e);
    }
  }
}
