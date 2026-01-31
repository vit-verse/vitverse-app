import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database.dart';
import '../utils/logger.dart';
import '../../features/profile/widget_customization/data/calendar_home_service.dart';

/// Industry-standard class notification scheduler using AlarmManager
/// Architecture: AlarmManager for exact notifications, WorkManager for recovery only
class ClassNotificationScheduler {
  static const String _tag = 'ClassScheduler';

  // Notification ID ranges (non-overlapping)
  static const int classReminderBase = 3000; // 3000-3999
  static const int classStartBase = 4000; // 4000-4999

  // Preference keys
  static const String _keyEnabled = 'class_notifications_enabled';
  static const String _keyReminderMinutes = 'class_reminder_minutes';
  static const String _keyLastScheduledDate = 'last_scheduled_date';

  final FlutterLocalNotificationsPlugin _notifications;

  ClassNotificationScheduler(this._notifications);

  // ============================================================================
  // SCHEDULING
  // ============================================================================

  /// Schedule ALL classes for today only (production pattern).
  /// Called on: app open, timetable change, midnight refresh.
  Future<ScheduleResult> scheduleTodayClasses() async {
    final stopwatch = Stopwatch()..start();

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? true;

      if (!enabled) {
        Logger.d(_tag, 'Class notifications disabled');
        return ScheduleResult(
          success: true,
          scheduledCount: 0,
          message: 'Disabled',
        );
      }

      // Check exact alarm permission
      final android =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final canSchedule =
          await android?.canScheduleExactNotifications() ?? true;

      if (!canSchedule) {
        Logger.e(_tag, 'Exact alarm permission not granted');
        return ScheduleResult(
          success: false,
          scheduledCount: 0,
          message: 'Permission denied',
        );
      }

      // Clear old class notifications first
      await clearAllClassNotifications();

      // Fetch today's classes from database
      final classes = await _fetchTodayClasses();

      if (classes.isEmpty) {
        Logger.d(_tag, 'No classes today');
        await _markScheduled();
        return ScheduleResult(
          success: true,
          scheduledCount: 0,
          message: 'No classes',
        );
      }

      // Get reminder minutes setting
      final reminderMinutes = prefs.getInt(_keyReminderMinutes) ?? 30;
      final now = DateTime.now();
      int scheduledCount = 0;

      for (final classData in classes) {
        // Schedule reminder (30 min before by default)
        final reminderTime = classData.startDateTime.subtract(
          Duration(minutes: reminderMinutes),
        );

        if (reminderTime.isAfter(now)) {
          await _scheduleNotification(
            id: classReminderBase + classData.slotId,
            title: '📚 Class in $reminderMinutes min',
            body: _buildNotificationBody(classData),
            scheduledTime: reminderTime,
            payload: 'class_reminder:${classData.courseCode}',
          );
          scheduledCount++;
        }

        // Schedule class start notification
        if (classData.startDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: classStartBase + classData.slotId,
            title: '📚 Class Starting Now',
            body: _buildNotificationBody(classData),
            scheduledTime: classData.startDateTime,
            payload: 'class_start:${classData.courseCode}',
          );
          scheduledCount++;
        }
      }

      await _markScheduled();
      stopwatch.stop();

      Logger.i(
        _tag,
        'Scheduled $scheduledCount notifications in ${stopwatch.elapsedMilliseconds}ms',
      );

      return ScheduleResult(
        success: true,
        scheduledCount: scheduledCount,
        message: 'Scheduled ${classes.length} classes',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      Logger.e(_tag, 'Failed to schedule', e, stack);
      return ScheduleResult(
        success: false,
        scheduledCount: 0,
        message: 'Error: $e',
      );
    }
  }

  /// LIGHTWEIGHT rebuild for WorkManager (Fix 1 & 2)
  /// - No SharedPreferences (worker assumes enabled)
  /// - No permission check (if we're running, we have permission)
  /// - Minimal logging
  Future<void> rebuildTodayAlarmsSilently() async {
    try {
      // Just clear and reschedule - assume enabled if worker runs
      await clearAllClassNotifications();

      final classes = await _fetchTodayClasses();
      if (classes.isEmpty) return;

      const defaultReminderMinutes = 30;
      final now = DateTime.now();

      for (final classData in classes) {
        final reminderTime = classData.startDateTime.subtract(
          const Duration(minutes: defaultReminderMinutes),
        );

        if (reminderTime.isAfter(now)) {
          await _scheduleNotification(
            id: classReminderBase + classData.slotId,
            title: '📚 Class in $defaultReminderMinutes min',
            body: _buildNotificationBody(classData),
            scheduledTime: reminderTime,
            payload: 'class_reminder:${classData.courseCode}',
          );
        }

        if (classData.startDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: classStartBase + classData.slotId,
            title: '📚 Class Starting Now',
            body: _buildNotificationBody(classData),
            scheduledTime: classData.startDateTime,
            payload: 'class_start:${classData.courseCode}',
          );
        }
      }

      Logger.d(_tag, 'Silent rebuild: ${classes.length} classes');
    } catch (e) {
      Logger.e(_tag, 'Silent rebuild failed', e);
    }
  }

  // ============================================================================
  // DATA FETCHING
  // ============================================================================

  /// Fetches today's classes from SQLite with Saturday handling.
  Future<List<ClassData>> _fetchTodayClasses() async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    final now = DateTime.now();

    // Get raw data
    final timetableData = await database.query('timetable');
    final coursesData = await database.query('courses');
    final slotsData = await database.query('slots');

    if (timetableData.isEmpty) return [];

    // Build lookup maps
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

    // Determine effective day (handle Saturday mapping)
    int effectiveDayIndex = now.weekday - 1; // 0=Mon, 6=Sun

    // Saturday special handling
    if (now.weekday == 6) {
      final calendarService = CalendarHomeService.instance;
      if (calendarService.isEnabled) {
        final mappedDay = calendarService.getDayOrderForDate(now);
        if (mappedDay != null) {
          effectiveDayIndex = mappedDay;
          Logger.d(_tag, 'Saturday mapped to day index $mappedDay');
        }
      }
    }

    // Check if today is a holiday
    final calendarService = CalendarHomeService.instance;
    if (calendarService.isEnabled && calendarService.isHolidayDate(now)) {
      Logger.d(_tag, 'Today is a holiday');
      return [];
    }

    // Get day column
    final dayColumn =
        [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ][effectiveDayIndex];

    final classes = <ClassData>[];
    final currentMinutes = now.hour * 60 + now.minute;

    for (var entry in timetableData) {
      final slotId = entry[dayColumn];
      if (slotId == null) continue;

      final startTime = entry['start_time']?.toString();
      final endTime = entry['end_time']?.toString();
      if (startTime == null || endTime == null) continue;

      // Parse times
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length != 2 || endParts.length != 2) continue;

      final startHour = int.tryParse(startParts[0]);
      final startMinute = int.tryParse(startParts[1]);
      final endHour = int.tryParse(endParts[0]);
      final endMinute = int.tryParse(endParts[1]);

      if (startHour == null ||
          startMinute == null ||
          endHour == null ||
          endMinute == null) {
        continue;
      }

      final endMinutes = endHour * 60 + endMinute;

      // Skip classes that have already ended
      if (endMinutes <= currentMinutes) continue;

      // Get course details
      final slot = slotMap[slotId];
      final courseId = slot?['course_id'] as int?;
      final course = courseId != null ? courseMap[courseId] : null;

      if (course == null) continue;

      final slotIdInt =
          slotId is int ? slotId : int.tryParse(slotId.toString()) ?? 0;

      classes.add(
        ClassData(
          slotId: slotIdInt,
          courseCode: course['code']?.toString() ?? 'Unknown',
          courseTitle: course['title']?.toString() ?? 'Unknown',
          venue: course['venue']?.toString() ?? 'TBA',
          startTime: startTime,
          endTime: endTime,
          startDateTime: DateTime(
            now.year,
            now.month,
            now.day,
            startHour,
            startMinute,
          ),
        ),
      );
    }

    // Sort by start time
    classes.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    Logger.d(_tag, 'Found ${classes.length} classes for today');
    return classes;
  }

  /// Build professional notification body
  String _buildNotificationBody(ClassData classData) {
    final timeFormatted =
        '${_formatTime(classData.startTime)} – ${_formatTime(classData.endTime)}';
    return '${classData.courseCode} • ${classData.courseTitle}\n'
        '🕒 $timeFormatted\n'
        '📍 ${classData.venue}';
  }

  // ============================================================================
  // NOTIFICATION MANAGEMENT
  // ============================================================================

  /// Schedules single notification via AlarmManager.
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'vit_connect_class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for class reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    Logger.d(
      _tag,
      'Scheduled #$id at ${scheduledTime.toString().substring(11, 16)}',
    );
  }

  /// Check if notification ID is a class notification (future-safe)
  static bool isClassNotification(int id) =>
      (id >= classReminderBase && id < classReminderBase + 1000) ||
      (id >= classStartBase && id < classStartBase + 1000);

  /// Clear all class notifications (fast, by ID range)
  Future<void> clearAllClassNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    int cancelled = 0;

    for (final n in pending) {
      if (isClassNotification(n.id)) {
        await _notifications.cancel(n.id);
        cancelled++;
      }
    }

    if (cancelled > 0) {
      Logger.d(_tag, 'Cancelled $cancelled old notifications');
    }
  }

  /// Get real pending class notifications (no synthetic data)
  Future<List<PendingNotificationRequest>>
  getPendingClassNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.where((n) => isClassNotification(n.id)).toList();
  }

  /// Check if already scheduled today
  Future<bool> isScheduledToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastScheduledDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastDate == today;
  }

  /// Mark as scheduled for today
  Future<void> _markScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_keyLastScheduledDate, today);
  }

  /// Format time to 12-hour format
  String _formatTime(String time24) {
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

// ==============================================================================
// DATA CLASSES
// ==============================================================================

/// Class data model.
class ClassData {
  final int slotId;
  final String courseCode;
  final String courseTitle;
  final String venue;
  final String startTime;
  final String endTime;
  final DateTime startDateTime;

  ClassData({
    required this.slotId,
    required this.courseCode,
    required this.courseTitle,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.startDateTime,
  });
}

/// Schedule result model
class ScheduleResult {
  final bool success;
  final int scheduledCount;
  final String message;
  final int? durationMs;

  ScheduleResult({
    required this.success,
    required this.scheduledCount,
    required this.message,
    this.durationMs,
  });
}
