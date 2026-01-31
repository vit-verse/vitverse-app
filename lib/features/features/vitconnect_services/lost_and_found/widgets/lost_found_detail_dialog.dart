import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/widgets/themed_lottie_widget.dart';
import '../../../../../core/config/app_config.dart';
import '../models/lost_found_item.dart';

/// Detail dialog for Lost & Found item
class LostFoundDetailDialog extends StatelessWidget {
  final LostFoundItem item;

  const LostFoundDetailDialog({super.key, required this.item});

  static void show(BuildContext context, LostFoundItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LostFoundDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                // Type badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          item.isLost
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isLost
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                          size: 16,
                          color:
                              item.isLost
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.type.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color:
                                item.isLost
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Item name
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Date
                Text(
                  'Posted ${_formatDate(item.createdAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Image
                if (item.imagePath != null && item.imagePath!.isNotEmpty)
                  _buildImage(theme),

                // Place
                _buildInfoSection(
                  theme,
                  icon: Icons.location_on_outlined,
                  label: 'Place',
                  value: item.place,
                ),

                // Description
                if (item.description != null && item.description!.isNotEmpty)
                  _buildInfoSection(
                    theme,
                    icon: Icons.description_outlined,
                    label: 'Description',
                    value: item.description!,
                  ),

                // Contact info
                const SizedBox(height: 20),
                Text(
                  'Contact Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Contact name
                _buildContactInfo(
                  theme,
                  icon: Icons.person_outline,
                  label: item.contactName,
                ),

                // Contact number with call/WhatsApp buttons
                _buildContactNumberRow(theme, item.contactNumber),

                // Posted by
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.8),
                            ),
                            children: [
                              const TextSpan(text: 'Posted by '),
                              TextSpan(
                                text: item.postedByName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' (${item.postedByRegno})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl:
              '${AppConfig.supabaseUrl}/storage/v1/object/public/lost-found-images/${item.imagePath}',
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                height: 200,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: const Center(
                  child: ThemedLottieWidget(
                    assetPath: 'assets/lottie/lostFound.lottie',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                height: 200,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: const Center(
                  child: ThemedLottieWidget(
                    assetPath: 'assets/lottie/lostFound.lottie',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    ThemeData theme, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildContactNumberRow(ThemeData theme, String phoneNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Left half - Phone icon and number
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(phoneNumber, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          // Right half - Call and WhatsApp buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call button
              InkWell(
                onTap: () => _makePhoneCall(phoneNumber),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/icons/call.png',
                    width: 24,
                    height: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // WhatsApp button
              InkWell(
                onTap: () => _openWhatsApp(phoneNumber),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/icons/whatsapp.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Add +91 prefix if not already present
    String formattedNumber = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedNumber = '+91$phoneNumber';
    }

    // Remove any spaces, dashes, or other formatting
    formattedNumber = formattedNumber.replaceAll(RegExp(r'[^+0-9]'), '');

    final uri = Uri.parse('https://wa.me/$formattedNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
