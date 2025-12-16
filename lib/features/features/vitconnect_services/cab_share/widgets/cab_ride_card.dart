import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/cab_ride.dart';

class CabRideCard extends StatelessWidget {
  final CabRide ride;

  const CabRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FROM
            _locationRow(
              icon: Icons.trip_origin,
              iconColor: theme.success,
              text: ride.fromLocation,
              theme: theme,
            ),

            const SizedBox(height: 3),

            /// TO
            _locationRow(
              icon: Icons.location_on,
              iconColor: theme.error,
              text: ride.toLocation,
              theme: theme,
            ),

            const Spacer(),

            /// DATE + TIME (same line, small)
            Row(
              children: [
                Icon(Icons.calendar_today, size: 10, color: theme.muted),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    ride.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.schedule, size: 10, color: theme.muted),
                const SizedBox(width: 3),
                Text(
                  ride.travelTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            /// CAB TYPE (compact pill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ride.cabType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),

            const SizedBox(height: 4),

            /// POSTED BY (own line, small)
            Text(
              'By ${ride.postedByName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.text.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show ride details bottom sheet (matching Lost & Found style)
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
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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

                        // Cab type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_taxi,
                                size: 16,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ride.cabType,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Route title
                        Text(
                          '${ride.fromLocation} → ${ride.toLocation}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // From location
                        _buildInfoRow(
                          icon: Icons.trip_origin,
                          label: 'From',
                          value: ride.fromLocation,
                          theme: theme,
                          iconColor: theme.success,
                        ),
                        const SizedBox(height: 12),

                        // To location
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'To',
                          value: ride.toLocation,
                          theme: theme,
                          iconColor: theme.error,
                        ),
                        const SizedBox(height: 12),

                        // Date
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: ride.formattedDate,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        // Time
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: ride.travelTime,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        // Seats available
                        _buildInfoRow(
                          icon: Icons.event_seat,
                          label: 'Seats Available',
                          value: '${ride.seatsAvailable}',
                          theme: theme,
                        ),

                        // Description if available
                        if (ride.description != null &&
                            ride.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.description,
                            label: 'Description',
                            value: ride.description!,
                            theme: theme,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Posted by
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Posted By',
                          value: '${ride.postedByName} (${ride.postedByRegno})',
                          theme: theme,
                        ),
                        const SizedBox(height: 24),

                        // Contact buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makeCall(ride.contactNumber),
                                icon: const Icon(Icons.phone, size: 20),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _openWhatsApp(ride.contactNumber),
                                icon: Image.asset(
                                  'assets/icons/whatsapp.png',
                                  width: 20,
                                  height: 20,
                                ),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required theme,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? theme.primary),
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

  /// Make phone call
  void _makeCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      Logger.e('CabRideCard', 'Error making call', e);
    }
  }

  /// Open WhatsApp
  void _openWhatsApp(String phoneNumber) async {
    try {
      // Remove any non-digit characters and add +91 if not present
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanNumber.startsWith('+91') && !cleanNumber.startsWith('91')) {
        cleanNumber = '+91$cleanNumber';
      } else if (cleanNumber.startsWith('91') && !cleanNumber.startsWith('+')) {
        cleanNumber = '+$cleanNumber';
      }
      final uri = Uri.parse('https://wa.me/$cleanNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.e('CabRideCard', 'Error opening WhatsApp', e);
    }
  }

  /// Compact location row (overflow-safe)
  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
        ),
      ],
    );
  }
}
