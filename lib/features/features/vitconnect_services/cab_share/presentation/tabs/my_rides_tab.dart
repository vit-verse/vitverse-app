import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/widgets/themed_lottie_widget.dart';
import '../../../../../../core/database/entities/student_profile.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../logic/cab_ride_provider.dart';
import '../../models/cab_ride.dart';

/// My Rides tab - shows user's posted rides
class MyRidesTab extends StatefulWidget {
  const MyRidesTab({super.key});

  @override
  State<MyRidesTab> createState() => _MyRidesTabState();
}

class _MyRidesTabState extends State<MyRidesTab> {
  StudentProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson != null && profileJson.isNotEmpty) {
        final profile = StudentProfile.fromJson(jsonDecode(profileJson));
        setState(() {
          _profile = profile;
          _isLoading = false;
        });

        // Load user's rides
        if (mounted) {
          final provider = Provider.of<CabRideProvider>(context, listen: false);
          await provider.loadMyRides(profile.registerNumber);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Logger.e('MyRidesTab', 'Error loading profile', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final provider = Provider.of<CabRideProvider>(context);

    if (_isLoading || provider.isLoadingMyRides) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.text.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile not found',
              style: TextStyle(
                fontSize: 16,
                color: theme.text.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.myRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemedLottieWidget(
              assetPath: 'assets/lottie/cabshare.lottie',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'No rides posted yet',
              style: TextStyle(
                fontSize: 16,
                color: theme.text.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to post a new ride',
              style: TextStyle(
                fontSize: 14,
                color: theme.text.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: provider.myRides.length,
      itemBuilder: (context, index) {
        final ride = provider.myRides[index];
        return _buildMyRideCard(context, ride, theme, provider);
      },
    );
  }

  Widget _buildMyRideCard(
    BuildContext context,
    CabRide ride,
    dynamic theme,
    CabRideProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trip_origin,
                            size: 16,
                            color: theme.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.fromLocation,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 7,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Container(
                          width: 2,
                          height: 16,
                          color: theme.border,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: theme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.toLocation,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  onPressed: () => _confirmDelete(context, ride, provider),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(theme, Icons.calendar_today, ride.formattedDate),
                _buildInfoChip(theme, Icons.access_time, ride.travelTime),
                _buildInfoChip(theme, Icons.directions_car, ride.cabType),
                _buildInfoChip(
                  theme,
                  Icons.event_seat,
                  '${ride.seatsAvailable} seats',
                ),
              ],
            ),

            if (ride.description != null && ride.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ride.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.text.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],

            // Status indicator
            if (ride.isPastRide) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: theme.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Past ride',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(dynamic theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.text.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: theme.text.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CabRide ride,
    CabRideProvider provider,
  ) {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Delete Ride?', style: TextStyle(color: theme.text)),
            content: Text(
              'Are you sure you want to delete this ride?',
              style: TextStyle(color: theme.text.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.text)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await provider.deleteRide(
                    ride.id,
                    _profile!.registerNumber,
                  );
                  if (context.mounted) {
                    if (success) {
                      SnackbarUtils.success(
                        context,
                        'Ride deleted successfully',
                      );
                    } else {
                      SnackbarUtils.error(context, 'Failed to delete ride');
                    }
                  }
                },
                child: Text('Delete', style: TextStyle(color: theme.error)),
              ),
            ],
          ),
    );
  }
}
