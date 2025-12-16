import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database.dart';
import '../utils/logger.dart';

/// Notification service for VIT Connect app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Timer? _schedulingDebounceTimer;
  Timer? _dailyCheckTimer;
  bool _isCurrentlyScheduling = false;
  DateTime? _lastSchedulingTime;
  DateTime? _lastAutoCheckTime;
  void Function()? _onCancelSyncRequested;

  // Cached preferences
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
      description: 'Notifications for ongoing and upcoming classes',
      importance: Importance.high,
      ledColor: Color(0xFF4CAF50),
    ),
    'exam': _ChannelConfig(
      id: 'vit_connect_exam_reminders',
      name: 'Exam Reminders',
      description: 'Notifications for upcoming exams',
      importance: Importance.max,
      ledColor: Color(0xFFFF9800),
    ),
    'laundry': _ChannelConfig(
      id: 'vit_connect_laundry_reminders',
      name: 'Laundry Reminders',
      description: 'Notifications for laundry schedule reminders',
      importance: Importance.high,
      ledColor: Color(0xFF2196F3),
    ),
  };

  // Notification ID ranges
  static const _notificationIds = {
    'login': 1001,
    'classStarted': 2001, // 2001-3000
    'classReminder': 3000, // 3000-4000
    'examStarted': 4000, // 4000-5000
    'examReminder': 5000, // 5000-6000
    'laundry': 6000, // 6000-6999
    'test': 9999,
    // VIT Verse general notification channel is in fcm dir
  };

  // Preference keys
  static const _prefKeys = {
    'classEnabled': 'class_notifications_enabled',
    'examEnabled': 'exam_notifications_enabled',
    'classMinutes': 'class_reminder_minutes',
    'examMinutes': 'exam_reminder_minutes',
  };

  /// Initialize the notification service
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
      _isInitialized = true;
      _startDailyAutoCheck();
    } catch (e, stack) {
      Logger.e('NotificationService', 'Initialization failed', e, stack);
      rethrow;
    }
  }

  /// Start daily auto-check for notifications
  void _startDailyAutoCheck() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      _performAutoCheck();
    });
    // Run initial check after 1 minute
    Future.delayed(const Duration(minutes: 1), () {
      _performAutoCheck();
    });
  }

  /// Perform automatic check and reschedule if needed
  Future<void> _performAutoCheck() async {
    try {
      // Prevent too frequent checks
      if (_lastAutoCheckTime != null) {
        final timeSince = DateTime.now().difference(_lastAutoCheckTime!);
        if (timeSince.inHours < 4) return;
      }

      _lastAutoCheckTime = DateTime.now();
      final settings = await getSettings();

      if (!settings.classEnabled && !settings.examEnabled) return;

      final pending = await _notifications.pendingNotificationRequests();

      // Check if class notifications are missing
      final hasClassReminder = pending.any(
        (n) =>
            n.id >= _notificationIds['classReminder']! &&
            n.id < _notificationIds['classReminder']! + 1000,
      );
      final hasClassStarted = pending.any(
        (n) =>
            n.id >= _notificationIds['classStarted']! &&
            n.id < _notificationIds['classStarted']! + 1000,
      );

      // If notifications are missing, reschedule
      if (settings.classEnabled && (!hasClassReminder || !hasClassStarted)) {
        Logger.i(
          'NotificationService',
          'Auto-check: Missing class notifications, rescheduling...',
        );
        await scheduleClassNotifications();
      }

      // Check exam notifications
      if (settings.examEnabled) {
        final hasExamNotif = pending.any(
          (n) =>
              n.id >= _notificationIds['examStarted']! &&
              n.id < _notificationIds['examReminder']! + 1000,
        );
        if (!hasExamNotif) {
          Logger.i(
            'NotificationService',
            'Auto-check: Missing exam notifications, rescheduling...',
          );
          await scheduleExamNotifications();
        }
      }
    } catch (e) {
      Logger.e('NotificationService', 'Auto-check failed', e);
    }
  }

  /// Create notification channels
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

  /// Handle notification responses
  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'cancel_sync') {
      _onCancelSyncRequested?.call();
    } else if (response.payload?.startsWith('class_notification:') == true) {
      _handleClassAlarmFired(response.payload!);
    }
  }

  /// Handle class alarm fired - reschedule next notifications
  void _handleClassAlarmFired(String payload) {
    try {
      Logger.i('NotificationService', 'Class alarm fired, rescheduling...');
      // Reschedule notifications to get the next class
      forceScheduleImmediately();
    } catch (e) {
      Logger.e('NotificationService', 'Failed to handle alarm fired', e);
    }
  }

  // ============================================================================
  // PUBLIC API - SCHEDULING
  // ============================================================================

  /// Schedule class notifications (next class reminder + class starting)
  Future<void> scheduleClassNotifications() async {
    if (!_isInitialized) await initialize();
    if (!await _ensurePermissions()) return;

    final settings = await getSettings();
    if (!settings.classEnabled) return;

    final startTime = DateTime.now();
    await _cancelAll();

    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;

      // Get all timetable, courses, and slots data
      final timetableData = await database.query('timetable');
      final coursesData = await database.query('courses');
      final slotsData = await database.query('slots');

      if (timetableData.isEmpty) {
        Logger.w('NotificationService', 'No timetable data found');
        return;
      }

      // Create lookup maps (same as home_logic)
      final courseMap = <int, Map<String, dynamic>>{};
      for (var course in coursesData) {
        if (course['id'] != null) {
          courseMap[course['id'] as int] = course;
        }
      }

      final slotMap = <int, Map<String, dynamic>>{};
      for (var slot in slotsData) {
        if (slot['id'] != null) {
          slotMap[slot['id'] as int] = slot;
        }
      }

      // Find next class from today's schedule
      final now = DateTime.now();
      final currentTimeMinutes = now.hour * 60 + now.minute;

      // Try today first
      ClassNotificationData? nextClass = _findNextClassForDay(
        now.weekday - 1,
        currentTimeMinutes,
        timetableData,
        courseMap,
        slotMap,
      );

      // If no class today, try tomorrow
      if (nextClass == null) {
        final tomorrow = now.add(const Duration(days: 1));
        nextClass = _findNextClassForDay(
          tomorrow.weekday - 1,
          0, // Start from beginning of day
          timetableData,
          courseMap,
          slotMap,
        );
      }

      // If still no class, try the rest of the week
      if (nextClass == null) {
        for (int daysAhead = 2; daysAhead < 7; daysAhead++) {
          final futureDay = now.add(Duration(days: daysAhead));
          nextClass = _findNextClassForDay(
            futureDay.weekday - 1,
            0,
            timetableData,
            courseMap,
            slotMap,
          );
          if (nextClass != null) break;
        }
      }

      int scheduledCount = 0;

      if (nextClass != null) {
        // Schedule reminder notification (30 minutes before)
        final reminderTime = nextClass.time.subtract(
          Duration(minutes: settings.classReminderMinutes),
        );

        if (reminderTime.isAfter(now)) {
          await _scheduleClassAlarm(
            nextOccurrence: reminderTime,
            courseCode: nextClass.courseCode,
            courseTitle: nextClass.courseTitle,
            venue: nextClass.venue,
            slotId: nextClass.slotId,
            reminderMinutes: settings.classReminderMinutes,
            isReminder: true,
            startTime: nextClass.startTime,
            endTime: nextClass.endTime,
          );
          scheduledCount++;
        }

        // Schedule "class starting now" notification
        if (nextClass.time.isAfter(now)) {
          await _scheduleClassAlarm(
            nextOccurrence: nextClass.time,
            courseCode: nextClass.courseCode,
            courseTitle: nextClass.courseTitle,
            venue: nextClass.venue,
            slotId: nextClass.slotId,
            reminderMinutes: 0,
            isReminder: false,
            startTime: nextClass.startTime,
            endTime: nextClass.endTime,
          );
          scheduledCount++;
        }
      }

      final duration = DateTime.now().difference(startTime);
      Logger.i(
        'NotificationService',
        'Scheduled $scheduledCount class alarms in ${duration.inMilliseconds}ms',
      );
    } catch (e, stack) {
      Logger.e(
        'NotificationService',
        'Failed to schedule class notifications',
        e,
        stack,
      );
    }
  }

  /// Find next class for a specific day (like home_logic approach)
  ClassNotificationData? _findNextClassForDay(
    int dayIndex,
    int currentTimeMinutes,
    List<Map<String, dynamic>> timetableData,
    Map<int, Map<String, dynamic>> courseMap,
    Map<int, Map<String, dynamic>> slotMap,
  ) {
    // Convert dayIndex to database day format (0=Monday → 'monday')
    final dayColumn =
        [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ][dayIndex];

    final now = DateTime.now();
    final targetDate = now.add(Duration(days: dayIndex - (now.weekday - 1)));

    // Get classes for this day
    for (var timetableEntry in timetableData) {
      final slotId = timetableEntry[dayColumn];
      if (slotId == null) continue;

      final startTime = timetableEntry['start_time']?.toString();
      final endTime = timetableEntry['end_time']?.toString();
      if (startTime == null || endTime == null) continue;

      // Parse start time
      final timeParts = startTime.split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final startMinutes = hour * 60 + minute;

      // Skip if this class has already started or passed
      if (startMinutes <= currentTimeMinutes) continue;

      // Get course details
      final slot = slotMap[slotId];
      final courseId = slot?['course_id'] as int?;
      final course = courseId != null ? courseMap[courseId] : null;

      if (course == null) continue;

      // Create class notification data
      return ClassNotificationData(
        courseCode: course['code']?.toString() ?? 'Unknown',
        courseTitle: course['title']?.toString() ?? 'Unknown',
        venue: course['venue']?.toString() ?? 'TBA',
        slotId: slotId is int ? slotId : int.tryParse(slotId.toString()) ?? 0,
        time: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        ),
        startTime: startTime,
        endTime: endTime,
      );
    }

    return null;
  }

  /// Schedule exam notifications (finds next exam only)
  Future<void> scheduleExamNotifications() async {
    if (!_isInitialized) await initialize();
    if (!await _ensurePermissions()) return;

    final settings = await getSettings();
    if (!settings.examEnabled) return;

    await _cancelAll();

    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;

      // Optimized JOIN query
      final results = await database.rawQuery('''
        SELECT 
          e.*,
          c.code as course_code,
          c.title as course_title
        FROM exams e
        LEFT JOIN courses c ON c.id = e.course_id
        ORDER BY e.start_time ASC
      ''');

      final now = DateTime.now();
      ExamNotificationData? nextExam;

      // Find next upcoming exam
      for (var row in results) {
        final examDateTime = _parseExamDateTime(row);
        if (examDateTime == null || examDateTime.isBefore(now)) continue;

        nextExam = ExamNotificationData(
          id: row['id'] as int? ?? 0,
          courseCode:
              row['course_code']?.toString() ??
              row['course_code']?.toString() ??
              'Unknown',
          courseTitle: row['course_title']?.toString() ?? '',
          examTitle:
              row['title']?.toString() ??
              row['exam_type']?.toString() ??
              'Exam',
          venue:
              row['venue']?.toString() ?? row['location']?.toString() ?? 'TBA',
          slot: row['slot']?.toString() ?? row['time_slot']?.toString(),
          dateTime: examDateTime,
        );
        break; // Only need the next exam
      }

      int scheduledCount = 0;

      if (nextExam != null) {
        // Schedule exam started notification (0 minutes)
        await _scheduleExamNotification(
          notificationId: _notificationIds['examStarted']! + nextExam.id,
          title: '🎓 Exam Started',
          exam: nextExam,
          scheduledTime: nextExam.dateTime,
          reminderMinutes: 0,
        );
        scheduledCount++;

        // Schedule exam reminder notification
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
          scheduledCount++;
        }
      }

      Logger.i(
        'NotificationService',
        'Scheduled $scheduledCount exam notifications',
      );
    } catch (e) {
      Logger.e(
        'NotificationService',
        'Failed to schedule exam notifications',
        e,
      );
    }
  }

  /// Schedule laundry notifications
  Future<void> scheduleLaundryNotifications({
    int? roomNumber,
    DateTime? laundryDate,
  }) async {
    if (!_isInitialized) await initialize();
    if (!await _ensurePermissions()) return;
    if (roomNumber == null || laundryDate == null) return;

    await _cancelAll();

    final now = DateTime.now();
    if (laundryDate.isBefore(now)) return;

    int scheduledCount = 0;

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
        scheduledCount++;
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
              'Today is your laundry (Room $roomNumber). Don\'t forget to prepare your clothes!',
          scheduledTime: sameDayTime,
        );
        scheduledCount++;
      }

      Logger.i(
        'NotificationService',
        'Scheduled $scheduledCount laundry notifications',
      );
    } catch (e) {
      Logger.e(
        'NotificationService',
        'Failed to schedule laundry notifications',
        e,
      );
    }
  }

  /// Debounced scheduling (waits 2 seconds before executing)
  void scheduleNotificationsDeferred() {
    _schedulingDebounceTimer?.cancel();

    // Throttle: prevent scheduling if done recently
    if (_lastSchedulingTime != null) {
      final timeSince = DateTime.now().difference(_lastSchedulingTime!);
      if (timeSince.inSeconds < 30) return;
    }

    if (_isCurrentlyScheduling) return;

    _schedulingDebounceTimer = Timer(const Duration(seconds: 2), () {
      _executeSchedulingInBackground();
    });
  }

  /// Force immediate scheduling (bypasses debouncing)
  Future<void> forceScheduleImmediately() async {
    _schedulingDebounceTimer?.cancel();
    await _executeSchedulingInBackground();
  }

  /// Execute scheduling in background
  Future<void> _executeSchedulingInBackground() async {
    if (_isCurrentlyScheduling) return;

    _isCurrentlyScheduling = true;
    _lastSchedulingTime = DateTime.now();

    try {
      final startTime = DateTime.now();
      await Future.wait([
        scheduleClassNotifications(),
        scheduleExamNotifications(),
      ]);
      final duration = DateTime.now().difference(startTime);
      Logger.i(
        'NotificationService',
        'Background scheduling complete in ${duration.inMilliseconds}ms',
      );
    } catch (e, stack) {
      Logger.e('NotificationService', 'Background scheduling failed', e, stack);
    } finally {
      _isCurrentlyScheduling = false;
    }
  }

  // ============================================================================
  // PUBLIC API - PROGRESS & COMPLETION NOTIFICATIONS
  // ============================================================================

  /// Show login progress notification
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

  /// Show completion notification
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
          (success
              ? 'Notifications are working perfectly! 🎉'
              : 'Please try again'),
      NotificationDetails(android: androidDetails),
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _notifications.cancel(_notificationIds['test']!);
    });
  }

  /// Dismiss notification
  Future<void> dismissNotification() async {
    if (!_isInitialized) return;
    await _notifications.cancel(_notificationIds['login']!);
  }

  // ============================================================================
  // PUBLIC API - SETTINGS
  // ============================================================================

  /// Get current notification settings
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

  /// Update notification settings
  Future<void> setClassNotificationsEnabled(bool enabled) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeys['classEnabled']!, enabled);
    if (enabled) {
      await forceScheduleImmediately();
    } else {
      await _cancelAll();
    }
  }

  Future<void> setExamNotificationsEnabled(bool enabled) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeys['examEnabled']!, enabled);
    if (enabled) {
      await forceScheduleImmediately();
    } else {
      await _cancelAll();
    }
  }

  Future<void> setClassReminderMinutes(int minutes) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeys['classMinutes']!, minutes);
    await forceScheduleImmediately();
  }

  Future<void> setExamReminderMinutes(int minutes) async {
    _cachedSettings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeys['examMinutes']!, minutes);
    await forceScheduleImmediately();
  }

  Future<bool> getClassNotificationsEnabled() async =>
      (await getSettings()).classEnabled;
  Future<bool> getExamNotificationsEnabled() async =>
      (await getSettings()).examEnabled;
  Future<int> getClassReminderMinutes() async =>
      (await getSettings()).classReminderMinutes;
  Future<int> getExamReminderMinutes() async =>
      (await getSettings()).examReminderMinutes;

  Future<void> forceRescheduleAllNotifications() async =>
      await forceScheduleImmediately();

  // ============================================================================
  // PUBLIC API - UTILITIES
  // ============================================================================

  /// Set callback for cancel sync action
  void setOnCancelSyncCallback(void Function()? callback) {
    _onCancelSyncRequested = callback;
  }

  /// Cancel all notifications (used during logout)
  void cancelAllNotifications() {
    _cachedSettings = null;
    _schedulingDebounceTimer?.cancel();
    _schedulingDebounceTimer = null;
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
    _isCurrentlyScheduling = false;
    _lastSchedulingTime = null;
    _lastAutoCheckTime = null;

    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _cancelAll();
      } catch (e) {
        Logger.e('NotificationService', 'Background cancellation failed', e);
      }
    });
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();

    try {
      final pending = await _notifications.pendingNotificationRequests();
      final synthetic = <PendingNotificationRequest>[...pending];

      // Add synthetic exam notifications
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final exams = await database.query('exams');
      final now = DateTime.now();

      ExamNotificationData? nextExam;
      for (var exam in exams) {
        final examDateTime = _parseExamDateTime(exam);
        if (examDateTime != null && examDateTime.isAfter(now)) {
          if (nextExam == null || examDateTime.isBefore(nextExam.dateTime)) {
            nextExam = ExamNotificationData(
              id: exam['id'] as int? ?? 0,
              courseCode: exam['course_code']?.toString() ?? 'Unknown',
              courseTitle: '',
              examTitle: exam['title']?.toString() ?? 'Exam',
              venue: '',
              slot: null,
              dateTime: examDateTime,
            );
          }
        }
      }

      if (nextExam != null) {
        final examStartedId = _notificationIds['examStarted']! + nextExam.id;
        final examReminderId = _notificationIds['examReminder']! + nextExam.id;

        if (!pending.any((n) => n.id == examStartedId)) {
          synthetic.add(
            PendingNotificationRequest(
              examStartedId,
              '🎓 Exam Started',
              '${nextExam.courseCode} - ${nextExam.examTitle}',
              null,
            ),
          );
        }

        if (!pending.any((n) => n.id == examReminderId)) {
          synthetic.add(
            PendingNotificationRequest(
              examReminderId,
              '🎓 Exam Reminder',
              '${nextExam.courseCode} - ${nextExam.examTitle}',
              null,
            ),
          );
        }
      }

      Logger.i(
        'NotificationService',
        'Found ${synthetic.length} pending notifications',
      );
      return synthetic;
    } catch (e) {
      Logger.e('NotificationService', 'Failed to get pending notifications', e);
      return [];
    }
  }

  /// Check and request permissions
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

  /// Ensure permissions are granted
  Future<bool> _ensurePermissions() async {
    return await canScheduleExactAlarms() ||
        await requestExactAlarmPermission();
  }

  /// Cancel all notifications efficiently
  Future<void> _cancelAll() async {
    try {
      final android =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await (android?.cancelAll() ?? _notifications.cancelAll());
    } catch (e) {
      Logger.e('NotificationService', 'Error cancelling notifications', e);
    }
  }

  /// Build notification details
  AndroidNotificationDetails _buildNotificationDetails({
    required String channelKey,
    required String title,
    required String body,
    bool ongoing = false,
  }) {
    final channel = _channels[channelKey]!;
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority:
          channel.importance == Importance.max ? Priority.max : Priority.high,
      playSound: channel.enableSound,
      enableVibration: channel.enableVibration,
      ongoing: ongoing,
      autoCancel: !ongoing,
      enableLights: channel.ledColor != null,
      ledColor: channel.ledColor,
      ledOnMs: channel.ledColor != null ? 1000 : null,
      ledOffMs: channel.ledColor != null ? 500 : null,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );
  }

  /// Schedule class alarm
  Future<void> _scheduleClassAlarm({
    required DateTime nextOccurrence,
    required String courseCode,
    required String courseTitle,
    required String venue,
    required int slotId,
    required int reminderMinutes,
    required bool isReminder,
    required String startTime,
    required String endTime,
  }) async {
    final notificationTime = nextOccurrence.subtract(
      Duration(minutes: reminderMinutes),
    );
    if (notificationTime.isBefore(DateTime.now())) return;

    final notificationId =
        (reminderMinutes == 0
            ? _notificationIds['classStarted']!
            : _notificationIds['classReminder']!) +
        (slotId % 1000);
    final timeRange =
        startTime.isNotEmpty && endTime.isNotEmpty
            ? '\n${_formatTo12Hour(startTime)} - ${_formatTo12Hour(endTime)}'
            : '';
    final title = isReminder ? '📚 Upcoming Class' : '📚 Class Starting Now';
    final timeInfo =
        isReminder ? 'Starts in $reminderMinutes minutes' : 'Starting now';
    final body =
        '$courseCode - $courseTitle\nVenue: $venue$timeRange\n$timeInfo';

    final androidDetails = _buildNotificationDetails(
      channelKey: 'class',
      title: title,
      body: body,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'class_notification:$courseCode',
    );
  }

  /// Schedule exam notification
  Future<void> _scheduleExamNotification({
    required int notificationId,
    required String title,
    required ExamNotificationData exam,
    required DateTime scheduledTime,
    required int reminderMinutes,
  }) async {
    final slotInfo =
        exam.slot != null && exam.slot!.isNotEmpty
            ? '\nSlot: ${exam.slot}'
            : '';
    final displayCourse =
        exam.courseTitle.isNotEmpty
            ? '${exam.courseCode} (${exam.courseTitle})'
            : exam.courseCode;
    final timeInfo =
        reminderMinutes > 0
            ? '\nStarts in $reminderMinutes minutes'
            : '\nExam is starting now';
    final body =
        '$displayCourse - ${exam.examTitle}\nVenue: ${exam.venue}$slotInfo$timeInfo';

    final androidDetails = _buildNotificationDetails(
      channelKey: 'exam',
      title: title,
      body: body,
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

    Logger.d(
      'NotificationService',
      'Scheduled exam notification: $title at ${scheduledTime.toString()}',
    );
  }

  /// Schedule laundry notification
  Future<void> _scheduleLaundryNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = _buildNotificationDetails(
      channelKey: 'laundry',
      title: title,
      body: body,
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

  /// Parse exam date time from various formats
  DateTime? _parseExamDateTime(Map<String, dynamic> exam) {
    final dateTimeStr =
        exam['date_time']?.toString() ??
        exam['start_time']?.toString() ??
        exam['exam_date']?.toString();
    if (dateTimeStr == null) return null;

    // Try ISO string
    DateTime? examDateTime = DateTime.tryParse(dateTimeStr);

    // Try milliseconds
    if (examDateTime == null) {
      final timestamp = int.tryParse(dateTimeStr);
      if (timestamp != null) {
        examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }

    return examDateTime;
  }

  /// Format time to 12-hour format
  String _formatTo12Hour(String time24) {
    if (time24.isEmpty) return '';

    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;

      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Notification settings
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

/// Channel configuration
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

/// Class notification data
class ClassNotificationData {
  final String courseCode;
  final String courseTitle;
  final String venue;
  final int slotId;
  final DateTime time;
  final String startTime;
  final String endTime;

  ClassNotificationData({
    required this.courseCode,
    required this.courseTitle,
    required this.venue,
    required this.slotId,
    required this.time,
    required this.startTime,
    required this.endTime,
  });
}

/// Exam notification data
class ExamNotificationData {
  final int id;
  final String courseCode;
  final String courseTitle;
  final String examTitle;
  final String venue;
  final String? slot;
  final DateTime dateTime;

  ExamNotificationData({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.examTitle,
    required this.venue,
    required this.slot,
    required this.dateTime,
  });
}
