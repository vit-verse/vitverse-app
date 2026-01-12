import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../firebase/analytics/analytics_service.dart';
import '../../../firebase/messaging/fcm_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _notificationService = NotificationService();
  bool _isLoading = true;
  bool _permissionsGranted = false;
  List<PendingNotificationRequest> _scheduledNotifications = [];
  bool _showScheduledNotifications = false;
  bool _lostFoundNotifications = true; // Default enabled
  bool _cabShareNotifications = true; // Default enabled
  bool _eventsNotifications = true; // Default enabled

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'NotificationSettings',
      screenClass: 'NotificationSettingsPage',
    );
    _checkPermissions();
    _loadScheduledNotifications();
    _loadLostFoundNotificationSetting();
    _loadCabShareNotificationSetting();
    _loadEventsNotificationSetting();
  }

  Future<void> _loadLostFoundNotificationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('lost_found_notifications') ?? true;
      setState(() => _lostFoundNotifications = saved);
    } catch (e) {
      Logger.e('NotificationSettings', 'Error loading Lost&Found setting', e);
    }
  }

  Future<void> _loadCabShareNotificationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('cab_share_notifications') ?? true;
      setState(() => _cabShareNotifications = saved);
    } catch (e) {
      Logger.e('NotificationSettings', 'Error loading CabShare setting', e);
    }
  }

  Future<void> _loadEventsNotificationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('events_notifications') ?? true;
      setState(() => _eventsNotifications = saved);
    } catch (e) {
      Logger.e('NotificationSettings', 'Error loading Events setting', e);
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final notificationStatus = await Permission.notification.status;
      setState(() {
        _permissionsGranted = notificationStatus.isGranted;
        _isLoading = false;
      });
    } catch (e) {
      Logger.e('NotificationSettings', 'Failed to check permissions', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final result = await _notificationService.requestPermissions();

      setState(() {
        _permissionsGranted = result;
      });

      if (result) {
        SnackbarUtils.success(context, 'Notification permissions granted');
        final canSchedule = await _notificationService.canScheduleExactAlarms();
        if (!canSchedule) {
          await _notificationService.requestExactAlarmPermission();
        }
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      Logger.e('NotificationSettings', 'Failed to request permissions: $e');
      SnackbarUtils.error(context, 'Failed to request permissions');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.currentTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: themeProvider.currentTheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Permission Required',
                style: TextStyle(color: themeProvider.currentTheme.text),
              ),
            ],
          ),
          content: Text(
            'Notification permissions are required to send you class and exam reminders. Please enable notifications in your device settings.',
            style: TextStyle(color: themeProvider.currentTheme.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.currentTheme.muted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadScheduledNotifications() async {
    try {
      final notifications =
          await _notificationService.getPendingNotifications();
      setState(() {
        _scheduledNotifications = notifications;
      });
      Logger.i(
        'NotificationSettings',
        'Loaded ${notifications.length} scheduled notifications',
      );
    } catch (e) {
      Logger.e(
        'NotificationSettings',
        'Failed to load scheduled notifications: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: false,
        backgroundColor: themeProvider.currentTheme.background,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(ThemeConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_permissionsGranted) ...[
                      _buildPermissionBanner(themeProvider),
                      const SizedBox(height: ThemeConstants.spacingLg),
                    ],

                    _buildSectionHeader('System Settings', themeProvider),
                    const SizedBox(height: ThemeConstants.spacingSm),

                    _buildSystemNotificationSettingsCard(themeProvider),
                    const SizedBox(height: ThemeConstants.spacingLg),

                    _buildSectionHeader('Feature Notifications', themeProvider),
                    const SizedBox(height: ThemeConstants.spacingSm),

                    _buildLostFoundNotificationCard(themeProvider),
                    const SizedBox(height: ThemeConstants.spacingMd),

                    _buildCabShareNotificationCard(themeProvider),
                    const SizedBox(height: ThemeConstants.spacingMd),

                    _buildEventsNotificationCard(themeProvider),
                    const SizedBox(height: ThemeConstants.spacingMd),

                    _buildScheduledNotificationsDropdown(themeProvider),
                    const SizedBox(height: ThemeConstants.spacingLg),

                    _buildInfoCard(themeProvider),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ThemeConstants.spacingSm,
        bottom: ThemeConstants.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: themeProvider.currentTheme.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: themeProvider.currentTheme.primary,
            size: 20,
          ),
          const SizedBox(width: ThemeConstants.spacingSm),
          Expanded(
            child: Text(
              'If any of the above notification channels (Lost & Found, Cab Share) are not subscribed or turned on, please turn them off and turn them back on to reinitialize the subscription.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeProvider.currentTheme.text.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledNotificationsDropdown(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scheduled Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await _loadScheduledNotifications();
                    setState(() => _isLoading = false);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await _notificationService.forceScheduleImmediately();
                      await _loadScheduledNotifications();
                      if (mounted) {
                        SnackbarUtils.success(
                          context,
                          'Notifications rescheduled successfully',
                        );
                      }
                    } catch (e) {
                      Logger.e(
                        'NotificationSettings',
                        'Force reschedule failed',
                        e,
                      );
                      if (mounted) {
                        SnackbarUtils.error(
                          context,
                          'Failed to reschedule notifications',
                        );
                      }
                    }
                    setState(() => _isLoading = false);
                  },
                  icon: const Icon(Icons.schedule_send, size: 18),
                  label: const Text('Force Reschedule'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeProvider.currentTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading notifications...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeProvider.currentTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_scheduledNotifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Center(
                child: Text(
                  'No scheduled notifications',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeProvider.currentTheme.muted,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                minHeight: 100,
              ),
              child: Builder(
                builder: (context) {
                  // Filter to show only class notifications (reminder + starting)
                  final classNotifications =
                      _scheduledNotifications
                          .where((n) => (n.id >= 2001 && n.id < 4000))
                          .toList();

                  if (classNotifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No class notifications scheduled',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: themeProvider.currentTheme.muted,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: classNotifications.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = classNotifications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeProvider.currentTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getNotificationTypeInfo(
                              notification.id,
                            ).color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getNotificationTypeInfo(
                                      notification.id,
                                    ).color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ID: ${notification.id}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _getNotificationTypeInfo(
                                            notification.id,
                                          ).color,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _getNotificationTypeInfo(
                                          notification.id,
                                        ).color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getNotificationTypeInfo(
                                      notification.id,
                                    ).label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.title ?? 'No title',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: themeProvider.currentTheme.text,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body ?? 'No body',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: themeProvider.currentTheme.muted,
                                fontSize: 11,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildNotificationScheduleInfo(
                              notification,
                              themeProvider,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
        // ],
      ),
    );
  }

  Widget _buildNotificationScheduleInfo(
    PendingNotificationRequest notification,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: themeProvider.currentTheme.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Notification ID: ${notification.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeProvider.currentTheme.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else if (notificationDate.isBefore(today.add(const Duration(days: 7)))) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dateStr = days[dateTime.weekday - 1];
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }

    final timeStr = _formatTime(dateTime);
    return '$dateStr at $timeStr';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }

  ({Color color, String label}) _getNotificationTypeInfo(int id) {
    if (id >= 2001 && id < 3000) return (color: Colors.green, label: 'CLASS');
    if (id >= 3000 && id < 4000) return (color: Colors.blue, label: 'REMINDER');
    if (id >= 4000 && id < 5000) return (color: Colors.red, label: 'EXAM');
    if (id >= 5000 && id < 6000)
      return (color: Colors.orange, label: 'EXAM-REM');
    if (id >= 6000 && id < 7000)
      return (color: Colors.purple, label: 'LAUNDRY');
    if (id >= 7000 && id < 8000)
      return (color: Colors.indigo, label: 'PERSONAL');
    if (id >= 9999) return (color: Colors.pink, label: 'TEST');
    return (color: Colors.grey, label: 'OTHER');
  }

  Widget _buildSystemNotificationSettingsCard(ThemeProvider themeProvider) {
    return InkWell(
      onTap: () async {
        // Open app-specific notification settings in system
        await openAppSettings();
      },
      borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          border: Border.all(
            color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_applications_outlined,
                color: themeProvider.currentTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: ThemeConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Notification Settings',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: themeProvider.currentTheme.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage all notification channels & categories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeProvider.currentTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 20,
              color: themeProvider.currentTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostFoundNotificationCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.deepPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: ThemeConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost & Found Updates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get notified when items are reported',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.currentTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _lostFoundNotifications,
            onChanged: _toggleLostFoundNotifications,
            activeColor: themeProvider.currentTheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLostFoundNotifications(bool value) async {
    try {
      if (value) {
        await FCMService.subscribeLostFoundTopic();
        SnackbarUtils.success(context, 'Subscribed to Lost & Found updates');
      } else {
        await FCMService.unsubscribeLostFoundTopic();
        SnackbarUtils.success(
          context,
          'Unsubscribed from Lost & Found updates',
        );
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lost_found_notifications', value);

      setState(() => _lostFoundNotifications = value);
    } catch (e) {
      Logger.e(
        'NotificationSettings',
        'Error toggling Lost & Found notifications',
        e,
      );
      SnackbarUtils.error(context, 'Failed to update notification settings');
    }
  }

  Widget _buildCabShareNotificationCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_taxi_outlined,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: ThemeConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cab Share Updates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get notified when new rides are posted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.currentTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _cabShareNotifications,
            onChanged: _toggleCabShareNotifications,
            activeColor: themeProvider.currentTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsNotificationCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_outlined,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: ThemeConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events Updates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get notified when new events are posted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeProvider.currentTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _eventsNotifications,
            onChanged: _toggleEventsNotifications,
            activeColor: themeProvider.currentTheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCabShareNotifications(bool value) async {
    try {
      if (value) {
        await FCMService.subscribeToTopic('cab_share_updates');
        SnackbarUtils.success(context, 'Subscribed to Cab Share updates');
      } else {
        await FCMService.unsubscribeFromTopic('cab_share_updates');
        SnackbarUtils.success(context, 'Unsubscribed from Cab Share updates');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cab_share_notifications', value);

      setState(() => _cabShareNotifications = value);
    } catch (e) {
      Logger.e(
        'NotificationSettings',
        'Error toggling Cab Share notifications',
        e,
      );
      SnackbarUtils.error(context, 'Failed to update notification settings');
    }
  }

  Future<void> _toggleEventsNotifications(bool value) async {
    try {
      if (value) {
        await FCMService.subscribeEventsTopic();
        SnackbarUtils.success(context, 'Subscribed to Events updates');
      } else {
        await FCMService.unsubscribeEventsTopic();
        SnackbarUtils.success(context, 'Unsubscribed from Events updates');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('events_notifications', value);

      setState(() => _eventsNotifications = value);
    } catch (e) {
      Logger.e(
        'NotificationSettings',
        'Error toggling Events notifications',
        e,
      );
      SnackbarUtils.error(context, 'Failed to update notification settings');
    }
  }

  Widget _buildPermissionBanner(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: themeProvider.currentTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: themeProvider.currentTheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notification Permission Required',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enable notifications to receive class reminders, exam alerts, and laundry notifications.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeProvider.currentTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.currentTheme.error,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
