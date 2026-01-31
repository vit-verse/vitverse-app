import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database.dart';
import '../utils/logger.dart';
import 'class_notification_scheduler.dart';
import 'notification_worker.dart';

/// Notification service for VIT Connect app
/// Architecture: AlarmManager for precision, WorkManager for recovery
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _tag = 'NotificationService';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  ClassNotificationScheduler? _classScheduler;

  bool _isInitialized = false;
  void Function()? _onCancelSyncRequested;
  NotificationSettings? _cachedSettings;

  // Notification channels
  static const _channels = {
    'login': _ChannelConfig(
      id: 'vit_connect_login_progress',
      name: 'Login Progress',
      description: 'Shows progress during VIT Connect sign in',
      importance: Importance.low,
      enableSound: false,
      enableVibration: false,
    ),
    'class': _ChannelConfig(
      id: 'vit_connect_class_reminders',
      name: 'Class Reminders',
      description: 'Notifications for class reminders',
      importance: Importance.high,
      ledColor: Color(0xFF4CAF50),
    ),
    'exam': _ChannelConfig(
      id: 'vit_connect_exam_reminders',
      name: 'Exam Reminders',
      description: 'Notifications for exam reminders',
      importance: Importance.max,
      ledColor: Color(0xFFFF9800),
    ),
    'laundry': _ChannelConfig(
      id: 'vit_connect_laundry_reminders',
      name: 'Laundry Reminders',
      description: 'Notifications for laundry reminders',
      importance: Importance.high,
      ledColor: Color(0xFF2196F3),
    ),
  };

  // Notification ID ranges
  // Class: 3000-3999 (reminder), 4000-4999 (start) - managed by ClassNotificationScheduler
  // Exam: 5000-5999 (reminder), 5000+ (start)
  // Laundry: 6000-6999
  static const _notificationIds = {
    'login': 1001,
    'examStarted': 5000,
    'examReminder': 5500,
    'laundry': 6000,
    'test': 9999,
  };

  // Preference keys
  static const _prefKeys = {
    'classEnabled': 'class_notifications_enabled',
    'examEnabled': 'exam_notifications_enabled',
    'classMinutes': 'class_reminder_minutes',
    'examMinutes': 'exam_reminder_minutes',
  };

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      await _createNotificationChannels();

      // Initialize class scheduler (only if not already initialized)
      _classScheduler ??= ClassNotificationScheduler(_notifications);

      // Initialize WorkManager for background recovery
      await NotificationWorker.initialize();
      await NotificationWorker.registerDailyTask();

      _isInitialized = true;
      Logger.i(_tag, 'NotificationService initialized');
    } catch (e, stack) {
      Logger.e(_tag, 'Initialization failed', e, stack);
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return;

    for (var config in _channels.values) {
      await android.createNotificationChannel(config.toAndroidChannel());
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'cancel_sync') {
      _onCancelSyncRequested?.call();
    } else if (response.payload?.startsWith('class_') == true) {
      // Reschedule after notification fires to get next class
      scheduleTodayClassNotifications();
    }
  }

  // ============================================================================
  // CLASS NOTIFICATIONS (Core - uses AlarmManager)
  // ============================================================================

  /// Schedule today's class notifications (with duplicate guard)
  /// Returns early if already scheduled today (Fix 3: prevent duplicate calls)
  Future<ScheduleResult> scheduleTodayClassNotifications({
    bool skipGuard = false,
  }) async {
    if (!_isInitialized) await initialize();

    final settings = await getSettings();
    if (!settings.classEnabled) {
      return ScheduleResult(
        success: true,
        scheduledCount: 0,
        message: 'Class notifications disabled',
      );
    }

    // Fix 3: Prevent duplicate scheduling (unless explicitly skipping guard)
    if (!skipGuard && await _classScheduler!.isScheduledToday()) {
      Logger.d(_tag, 'Already scheduled today - skipping');
      return ScheduleResult(
        success: true,
        scheduledCount: 0,
        message: 'Already scheduled',
      );
    }

    return _classScheduler!.scheduleTodayClasses();
  }

  /// Force reschedule (clears old, schedules fresh) - skips duplicate guard
  Future<ScheduleResult> forceRescheduleClassNotifications() async {
    if (!_isInitialized) await initialize();
    await _classScheduler!.clearAllClassNotifications();
    return scheduleTodayClassNotifications(skipGuard: true);
  }

  /// Get real pending class notifications (no fake data)
  Future<List<PendingNotificationRequest>>
  getPendingClassNotifications() async {
    if (!_isInitialized) await initialize();
    return _classScheduler!.getPendingClassNotifications();
  }

  // ============================================================================
  // EXAM NOTIFICATIONS
  // ============================================================================

  Future<void> scheduleExamNotifications() async {
    if (!_isInitialized) await initialize();

    final settings = await getSettings();
    if (!settings.examEnabled) return;

    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;

      final results = await database.rawQuery('''
        SELECT e.*, c.code as course_code, c.title as course_title
        FROM exams e
        LEFT JOIN courses c ON c.id = e.course_id
        ORDER BY e.start_time ASC
      ''');

      final now = DateTime.now();
      ExamData? nextExam;

      for (var row in results) {
        final examDateTime = _parseExamDateTime(row);
        if (examDateTime == null || examDateTime.isBefore(now)) continue;

        nextExam = ExamData(
          id: row['id'] as int? ?? 0,
          courseCode: row['course_code']?.toString() ?? 'Unknown',
          courseTitle: row['course_title']?.toString() ?? '',
          examTitle: row['title']?.toString() ?? 'Exam',
          venue: row['venue']?.toString() ?? 'TBA',
          slot: row['slot']?.toString(),
          dateTime: examDateTime,
        );
        break;
      }

      if (nextExam != null) {
        // Schedule exam start notification
        await _scheduleExamNotification(
          notificationId: _notificationIds['examStarted']! + nextExam.id,
          title: '🎓 Exam Started',
          exam: nextExam,
          scheduledTime: nextExam.dateTime,
          reminderMinutes: 0,
        );

        // Schedule reminder
        final reminderTime = nextExam.dateTime.subtract(
          Duration(minutes: settings.examReminderMinutes),
        );
        if (reminderTime.isAfter(now)) {
          await _scheduleExamNotification(
            notificationId: _notificationIds['examReminder']! + nextExam.id,
            title: '🎓 Exam Reminder',
            exam: nextExam,
            scheduledTime: reminderTime,
            reminderMinutes: settings.examReminderMinutes,
          );
        }
      }

      Logger.i(_tag, 'Exam notifications scheduled');
    } catch (e) {
      Logger.e(_tag, 'Failed to schedule exam notifications', e);
    }
  }

  Future<void> _scheduleExamNotification({
    required int notificationId,
    required String title,
    required ExamData exam,
    required DateTime scheduledTime,
    required int reminderMinutes,
  }) async {
    final slotInfo = exam.slot != null ? '\n🎫 Slot: ${exam.slot}' : '';
    final timeInfo =
        reminderMinutes > 0
            ? '\n⏰ Starts in $reminderMinutes minutes'
            : '\n⏰ Exam is starting now';
    final body =
        '${exam.courseCode} • ${exam.examTitle}\n📍 ${exam.venue}$slotInfo$timeInfo';

    final androidDetails = AndroidNotificationDetails(
      _channels['exam']!.id,
      _channels['exam']!.name,
      channelDescription: _channels['exam']!.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================================
  // LAUNDRY NOTIFICATIONS
  // ============================================================================

  Future<void> scheduleLaundryNotifications({
    int? roomNumber,
    DateTime? laundryDate,
  }) async {
    if (!_isInitialized) await initialize();
    if (roomNumber == null || laundryDate == null) return;

    final now = DateTime.now();
    if (laundryDate.isBefore(now)) return;

    try {
      // Day before reminder (8 PM)
      final dayBeforeTime = DateTime(
        laundryDate.year,
        laundryDate.month,
        laundryDate.day - 1,
        20,
        0,
      );

      if (dayBeforeTime.isAfter(now)) {
        await _scheduleLaundryNotification(
          notificationId: _notificationIds['laundry']! + 1,
          title: '🧺 Laundry Reminder',
          body: 'Your laundry is scheduled for tomorrow (Room $roomNumber)',
          scheduledTime: dayBeforeTime,
        );
      }

      // Same day reminder (8 AM)
      final sameDayTime = DateTime(
        laundryDate.year,
        laundryDate.month,
        laundryDate.day,
        8,
        0,
      );

      if (sameDayTime.isAfter(now)) {
        await _scheduleLaundryNotification(
          notificationId: _notificationIds['laundry']! + 2,
          title: '🧺 Laundry Day!',
          body:
              'Today is your laundry (Room $roomNumber). Prepare your clothes!',
          scheduledTime: sameDayTime,
        );
      }

      Logger.i(_tag, 'Laundry notifications scheduled');
    } catch (e) {
      Logger.e(_tag, 'Failed to schedule laundry notifications', e);
    }
  }

  Future<void> _scheduleLaundryNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channels['laundry']!.id,
      _channels['laundry']!.name,
      channelDescription: _channels['laundry']!.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================================
  // PROGRESS & COMPLETION NOTIFICATIONS
  // ============================================================================

  Future<void> showProgressNotification({
    required int currentStep,
    required int totalSteps,
    required String stepLabel,
    bool showCancelAction = true,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channels['login']!.id,
      _channels['login']!.name,
      channelDescription: _channels['login']!.description,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: totalSteps,
      progress: currentStep,
      playSound: false,
      enableVibration: false,
      actions:
          showCancelAction
              ? [
                const AndroidNotificationAction(
                  'cancel_sync',
                  'Cancel',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ]
              : null,
      styleInformation: BigTextStyleInformation(
        stepLabel,
        contentTitle: 'VIT Verse - Signing In',
      ),
    );

    await _notifications.show(
      _notificationIds['login']!,
      'VIT Verse - Signing In',
      stepLabel,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showCompletionNotification({
    required bool success,
    String? message,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.cancel(_notificationIds['login']!);

    final androidDetails = AndroidNotificationDetails(
      _channels['class']!.id,
      _channels['class']!.name,
      channelDescription: _channels['class']!.description,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
    );

    await _notifications.show(
      _notificationIds['test']!,
      success ? 'VIT Verse' : 'Sign In Failed',
      message ??
          (success ? 'Notifications are working! 🎉' : 'Please try again'),
      NotificationDetails(android: androidDetails),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _notifications.cancel(_notificationIds['test']!);
    });
  }

  Future<void> dismissNotification() async {
    if (!_isInitialized) return;
    await _notifications.cancel(_notificationIds['login']!);
  }

  // ============================================================================
  // SETTINGS
  // ============================================================================

  Future<NotificationSettings> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();
    _cachedSettings = NotificationSettings(
      classEnabled: prefs.getBool(_prefKeys['classEnabled']!) ?? true,
      examEnabled: prefs.getBool(_prefKeys['examEnabled']!) ?? true,
      classReminderMinutes: prefs.getInt(_prefKeys['classMinutes']!) ?? 30,
      examReminderMinutes: prefs.getInt(_prefKeys['examMinutes']!) ?? 60,
    );
    return _cachedSettings!;
  }

  Future<void> setClassNotificationsEnabled(bool enabled) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeys['classEnabled']!, enabled);
    if (enabled) {
      await scheduleTodayClassNotifications();
    } else {
      await _classScheduler?.clearAllClassNotifications();
    }
  }

  Future<void> setExamNotificationsEnabled(bool enabled) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeys['examEnabled']!, enabled);
    if (enabled) {
      await scheduleExamNotifications();
    } else {
      await _cancelExamNotifications();
    }
  }

  Future<void> setClassReminderMinutes(int minutes) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeys['classMinutes']!, minutes);
    await forceRescheduleClassNotifications();
  }

  Future<void> setExamReminderMinutes(int minutes) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeys['examMinutes']!, minutes);
    await scheduleExamNotifications();
  }

  Future<bool> getClassNotificationsEnabled() async =>
      (await getSettings()).classEnabled;
  Future<bool> getExamNotificationsEnabled() async =>
      (await getSettings()).examEnabled;
  Future<int> getClassReminderMinutes() async =>
      (await getSettings()).classReminderMinutes;
  Future<int> getExamReminderMinutes() async =>
      (await getSettings()).examReminderMinutes;

  // ============================================================================
  // UTILITIES
  // ============================================================================

  void setOnCancelSyncCallback(void Function()? callback) {
    _onCancelSyncRequested = callback;
  }

  /// Clear all and reschedule fresh (on sync)
  /// Always force reschedule - don't skip based on "already scheduled" marker
  Future<void> rescheduleOnSync() async {
    Logger.i(_tag, 'Rescheduling on sync...');
    await cancelAllNotifications();
    await Future.delayed(const Duration(milliseconds: 100));
    // Use force reschedule to bypass the "already scheduled today" guard
    await forceRescheduleClassNotifications();
    await scheduleExamNotifications();
    Logger.i(_tag, 'Sync reschedule complete');
  }

  /// Cancel all notifications (on logout)
  Future<void> cancelAllNotifications() async {
    _cachedSettings = null;

    try {
      await _notifications.cancelAll();
      await NotificationWorker.cancelAll();
      Logger.i(_tag, 'All notifications cancelled');
    } catch (e) {
      Logger.e(_tag, 'Cancellation failed', e);
    }
  }

  /// Legacy method for backwards compatibility
  void scheduleNotificationsDeferred() {
    Future.delayed(const Duration(seconds: 2), () {
      scheduleTodayClassNotifications();
    });
  }

  Future<void> forceScheduleImmediately() async {
    await forceRescheduleClassNotifications();
    await scheduleExamNotifications();
  }

  /// Get all pending notifications (real data only)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return _notifications.pendingNotificationRequests();
  }

  /// Check exact alarm permission
  Future<bool> canScheduleExactAlarms() async {
    if (!_isInitialized) await initialize();
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!_isInitialized) await initialize();
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return true;

    final alreadyGranted = await android.canScheduleExactNotifications();
    if (alreadyGranted == true) return true;

    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return true;

    final granted = await android.requestNotificationsPermission();
    if (granted == true) {
      await requestExactAlarmPermission();
    }
    return granted ?? false;
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<void> _cancelExamNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    for (final n in pending) {
      if (n.id >= _notificationIds['examStarted']! &&
          n.id < _notificationIds['laundry']!) {
        await _notifications.cancel(n.id);
      }
    }
  }

  DateTime? _parseExamDateTime(Map<String, dynamic> exam) {
    final dateTimeStr =
        exam['date_time']?.toString() ??
        exam['start_time']?.toString() ??
        exam['exam_date']?.toString();
    if (dateTimeStr == null) return null;

    DateTime? examDateTime = DateTime.tryParse(dateTimeStr);

    if (examDateTime == null) {
      final timestamp = int.tryParse(dateTimeStr);
      if (timestamp != null) {
        examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }

    return examDateTime;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

class NotificationSettings {
  final bool classEnabled;
  final bool examEnabled;
  final int classReminderMinutes;
  final int examReminderMinutes;

  const NotificationSettings({
    required this.classEnabled,
    required this.examEnabled,
    required this.classReminderMinutes,
    required this.examReminderMinutes,
  });
}

class _ChannelConfig {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  final bool enableSound;
  final bool enableVibration;
  final Color? ledColor;

  const _ChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    this.enableSound = true,
    this.enableVibration = true,
    this.ledColor,
  });

  AndroidNotificationChannel toAndroidChannel() {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
      enableVibration: enableVibration,
      playSound: enableSound,
      showBadge: true,
      enableLights: ledColor != null,
      ledColor: ledColor,
    );
  }
}

class ExamData {
  final int id;
  final String courseCode;
  final String courseTitle;
  final String examTitle;
  final String venue;
  final String? slot;
  final DateTime dateTime;

  ExamData({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.examTitle,
    required this.venue,
    required this.slot,
    required this.dateTime,
  });
}
