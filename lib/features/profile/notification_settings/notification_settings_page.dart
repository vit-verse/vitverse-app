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
        if (mounted) {
          SnackbarUtils.success(context, 'Notification permissions granted');
        }
        final canSchedule = await _notificationService.canScheduleExactAlarms();
        if (!canSchedule) {
          await _notificationService.requestExactAlarmPermission();
        }
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      Logger.e('NotificationSettings', 'Failed to request permissions: $e');
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to request permissions');
      }
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

  void _showExactAlarmPermissionDialog() {
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
              Icon(Icons.alarm_off, color: themeProvider.currentTheme.error),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Exact Alarm Permission Required',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To schedule notifications at exact times, this app needs permission to set exact alarms.',
                style: TextStyle(color: themeProvider.currentTheme.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Steps to enable:',
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Tap "Open Settings" below\n'
                '2. Find "Alarms & reminders" permission\n'
                '3. Enable "Allow setting alarms and reminders"',
                style: TextStyle(color: themeProvider.currentTheme.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.currentTheme.muted),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final granted =
                    await _notificationService.requestExactAlarmPermission();
                if (!granted && mounted) {
                  await openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open Settings'),
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
              'If any of the above notification channels (Lost & Found, Cab Share, Events) are not subscribed or turned on, please turn them off and turn them back on to reinitialize the subscription.',
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
          // Header with day indicators
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
              Text(
                '${_scheduledNotifications.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day indicator row
          _buildDayIndicators(themeProvider),
          const SizedBox(height: 16),

          // Action buttons
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
                      final canSchedule =
                          await _notificationService.canScheduleExactAlarms();

                      if (!canSchedule) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          _showExactAlarmPermissionDialog();
                        }
                        return;
                      }

                      await _notificationService.forceScheduleImmediately();

                      await Future.delayed(const Duration(milliseconds: 500));
                      await _loadScheduledNotifications();

                      if (mounted) {
                        if (_scheduledNotifications.isEmpty) {
                          SnackbarUtils.warning(
                            context,
                            'No classes to schedule. Check your timetable.',
                          );
                        } else {
                          SnackbarUtils.success(
                            context,
                            'Scheduled ${_scheduledNotifications.length} notifications',
                          );
                        }
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

          // Notification list
          if (_isLoading)
            _buildLoadingState(themeProvider)
          else if (_scheduledNotifications.isEmpty)
            _buildEmptyState(themeProvider)
          else
            _buildNotificationList(themeProvider),
        ],
      ),
    );
  }

  Widget _buildDayIndicators(ThemeProvider themeProvider) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday; // 1=Monday, 7=Sunday

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isToday = (index + 1) == today;
        final hasNotifications = isToday && _scheduledNotifications.isNotEmpty;

        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isToday
                        ? themeProvider.currentTheme.primary
                        : themeProvider.currentTheme.background,
                border: Border.all(
                  color:
                      isToday
                          ? themeProvider.currentTheme.primary
                          : themeProvider.currentTheme.muted.withValues(
                            alpha: 0.3,
                          ),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isToday
                            ? Colors.white
                            : themeProvider.currentTheme.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (hasNotifications)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeProvider.currentTheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_scheduledNotifications.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.currentTheme.primary,
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingState(ThemeProvider themeProvider) {
    return Padding(
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
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No scheduled notifications',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.currentTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Force Reschedule" to schedule class reminders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeProvider.currentTheme.muted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(ThemeProvider themeProvider) {
    // Group notifications by type
    final classReminders =
        _scheduledNotifications
            .where((n) => n.id >= 3000 && n.id < 4000)
            .toList();
    final classStarts =
        _scheduledNotifications
            .where((n) => n.id >= 4000 && n.id < 5000)
            .toList();
    final exams =
        _scheduledNotifications
            .where((n) => n.id >= 5000 && n.id < 6000)
            .toList();
    final laundry =
        _scheduledNotifications
            .where((n) => n.id >= 6000 && n.id < 7000)
            .toList();
    final others =
        _scheduledNotifications
            .where((n) => n.id < 3000 || n.id >= 7000)
            .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
        minHeight: 100,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (classReminders.isNotEmpty || classStarts.isNotEmpty) ...[
              _buildSectionTitle(
                'Today\'s Classes',
                Icons.school,
                Colors.blue,
                classReminders.length + classStarts.length,
                themeProvider,
              ),
              const SizedBox(height: 8),
              ...classReminders.map(
                (n) => _buildNotificationTile(n, themeProvider),
              ),
              ...classStarts.map(
                (n) => _buildNotificationTile(n, themeProvider),
              ),
              const SizedBox(height: 16),
            ],
            if (exams.isNotEmpty) ...[
              _buildSectionTitle(
                'Exam Reminders',
                Icons.assignment,
                Colors.orange,
                exams.length,
                themeProvider,
              ),
              const SizedBox(height: 8),
              ...exams.map((n) => _buildNotificationTile(n, themeProvider)),
              const SizedBox(height: 16),
            ],
            if (laundry.isNotEmpty) ...[
              _buildSectionTitle(
                'Laundry',
                Icons.local_laundry_service,
                Colors.purple,
                laundry.length,
                themeProvider,
              ),
              const SizedBox(height: 8),
              ...laundry.map((n) => _buildNotificationTile(n, themeProvider)),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              _buildSectionTitle(
                'Other',
                Icons.notifications,
                Colors.grey,
                others.length,
                themeProvider,
              ),
              const SizedBox(height: 8),
              ...others.map((n) => _buildNotificationTile(n, themeProvider)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    int count,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.currentTheme.text,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(
    PendingNotificationRequest notification,
    ThemeProvider themeProvider,
  ) {
    final typeInfo = _getNotificationTypeInfo(notification.id);
    final timeDisplay = _getScheduledTimeDisplay(notification);

    // Extract course code from title or body
    final title = notification.title ?? '';
    final body = notification.body ?? '';

    // Get first line of body (course info)
    final bodyLines = body.split('\n');
    final courseInfo = bodyLines.isNotEmpty ? bodyLines[0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: typeInfo.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(typeInfo.icon, size: 18, color: typeInfo.color),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Course info
                if (courseInfo.isNotEmpty)
                  Text(
                    courseInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: themeProvider.currentTheme.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // Fire time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: typeInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: typeInfo.color,
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

  // ignore: unused_element
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
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get notification type info based on ID ranges
  /// ID Ranges:
  /// - 3000-3999: Class reminders (30 min before)
  /// - 4000-4999: Class start notifications
  /// - 5000-5999: Exam reminders
  /// - 6000-6999: Laundry notifications
  ({Color color, String label, IconData icon}) _getNotificationTypeInfo(
    int id,
  ) {
    if (id >= 3000 && id < 4000) {
      return (color: Colors.blue, label: 'CLASS REMINDER', icon: Icons.alarm);
    }
    if (id >= 4000 && id < 5000) {
      return (
        color: Colors.green,
        label: 'CLASS START',
        icon: Icons.play_circle,
      );
    }
    if (id >= 5000 && id < 6000) {
      return (color: Colors.orange, label: 'EXAM', icon: Icons.assignment);
    }
    if (id >= 6000 && id < 7000) {
      return (
        color: Colors.purple,
        label: 'LAUNDRY',
        icon: Icons.local_laundry_service,
      );
    }
    return (color: Colors.grey, label: 'OTHER', icon: Icons.notifications);
  }

  /// Parse scheduled time from notification payload or estimate from ID
  String _getScheduledTimeDisplay(PendingNotificationRequest notification) {
    // Extract time from body if available (format: "🕒 HH:MM AM/PM")
    final body = notification.body ?? '';
    final timeMatch = RegExp(
      r'🕒\s*(\d{1,2}:\d{2}\s*(?:AM|PM)?)',
    ).firstMatch(body);
    if (timeMatch != null) {
      final classTime = timeMatch.group(1) ?? '';
      // For reminder (3000-3999), it fires 30 min before class time
      // For start (4000-4999), it fires at class time
      if (notification.id >= 3000 && notification.id < 4000) {
        return '30 min before $classTime';
      } else if (notification.id >= 4000 && notification.id < 5000) {
        return 'At $classTime';
      }
      return classTime;
    }
    return 'Scheduled';
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
        if (mounted) {
          SnackbarUtils.success(context, 'Subscribed to Lost & Found updates');
        }
      } else {
        await FCMService.unsubscribeLostFoundTopic();
        if (mounted) {
          SnackbarUtils.success(
            context,
            'Unsubscribed from Lost & Found updates',
          );
        }
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
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update notification settings');
      }
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
        if (mounted) {
          SnackbarUtils.success(context, 'Subscribed to Cab Share updates');
        }
      } else {
        await FCMService.unsubscribeFromTopic('cab_share_updates');
        if (mounted) {
          SnackbarUtils.success(context, 'Unsubscribed from Cab Share updates');
        }
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
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update notification settings');
      }
    }
  }

  Future<void> _toggleEventsNotifications(bool value) async {
    try {
      if (value) {
        await FCMService.subscribeEventsTopic();
        if (mounted) {
          SnackbarUtils.success(context, 'Subscribed to Events updates');
        }
      } else {
        await FCMService.unsubscribeEventsTopic();
        if (mounted) {
          SnackbarUtils.success(context, 'Unsubscribed from Events updates');
        }
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
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update notification settings');
      }
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
