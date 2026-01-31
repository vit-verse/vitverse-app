import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'class_notification_scheduler.dart';
import '../utils/logger.dart';

/// WorkManager callback - runs in isolate, must be top-level
/// Uses LIGHTWEIGHT rebuild method (no SharedPreferences in isolate)
@pragma('vm:entry-point')
void notificationWorkerCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Initialize timezone for notifications
      tz.initializeTimeZones();

      // Initialize notifications plugin
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Use lightweight rebuild (no prefs, assumes enabled)
      final scheduler = ClassNotificationScheduler(notifications);
      await scheduler.rebuildTodayAlarmsSilently();

      Logger.i('NotificationWorker', 'Background rebuild complete');

      return true;
    } catch (e) {
      Logger.e('NotificationWorker', 'Background task failed', e);
      return false;
    }
  });
}

/// WorkManager safety net for notification recovery
/// Runs ONLY at midnight to rebuild today's alarms
class NotificationWorker {
  static const String _tag = 'NotificationWorker';
  static const String _taskName = 'dailyNotificationReschedule';

  static bool _isInitialized = false;

  /// Initialize WorkManager (call once in main.dart)
  /// NEVER call from UI - only from app startup
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        notificationWorkerCallback,
        isInDebugMode: false, // Set to true for debugging
      );
      _isInitialized = true;
      Logger.i(_tag, 'WorkManager initialized');
    } catch (e) {
      Logger.e(_tag, 'Failed to initialize WorkManager', e);
    }
  }

  /// Register daily midnight task (safety net)
  /// This ensures notifications are rescheduled even if app is killed
  static Future<void> registerDailyTask() async {
    if (!_isInitialized) {
      Logger.w(_tag, 'WorkManager not initialized');
      return;
    }

    try {
      // Cancel existing task first
      await Workmanager().cancelByUniqueName(_taskName);

      // Calculate delay until next midnight
      final now = DateTime.now();
      final midnight = DateTime(
        now.year,
        now.month,
        now.day + 1,
        0,
        5,
      ); // 12:05 AM
      final delay = midnight.difference(now);

      // Register periodic task (runs daily)
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(hours: 24),
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      Logger.i(
        _tag,
        'Daily task registered (next run in ${delay.inHours}h ${delay.inMinutes % 60}m)',
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to register daily task', e);
    }
  }

  /// Cancel all background tasks (on logout)
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      Logger.i(_tag, 'All background tasks cancelled');
    } catch (e) {
      Logger.e(_tag, 'Failed to cancel tasks', e);
    }
  }

  /// Run one-off task immediately (for testing/sync)
  static Future<void> runOnce() async {
    if (!_isInitialized) {
      Logger.w(_tag, 'WorkManager not initialized');
      return;
    }

    try {
      await Workmanager().registerOneOffTask(
        'immediate_reschedule',
        _taskName,
        constraints: Constraints(networkType: NetworkType.not_required),
      );
      Logger.i(_tag, 'One-off task registered');
    } catch (e) {
      Logger.e(_tag, 'Failed to run one-off task', e);
    }
  }
}
