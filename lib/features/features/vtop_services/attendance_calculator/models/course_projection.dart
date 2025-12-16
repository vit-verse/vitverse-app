import 'day_status.dart';
import 'course_schedule.dart';
import 'attendance_day.dart';

/// Model representing attendance projection for a course
class CourseProjection {
  // Course details
  final int courseId;
  final String courseCode;
  final String courseTitle;

  // Current attendance
  final int currentAttended;
  final int currentTotal;
  final double currentPercentage;

  // Classes in selected date range
  final int totalClassesInRange;
  final int presentInRange;
  final int absentInRange;
  final int holidayInRange;

  // Projected attendance (current + range)
  final int projectedAttended;
  final int projectedTotal;
  final double projectedPercentage;

  // Buffer calculation
  final int bufferClasses;
  final bool meetsTarget;

  // Course schedule
  final CourseSchedule schedule;

  // Date-wise attendance in range (with full AttendanceDay info including followsScheduleOf)
  final Map<DateTime, AttendanceDay> dateWiseAttendance;

  // Day-wise class count (Monday=1, Tuesday=2, etc.)
  final Map<int, int> dayWiseClassCount;

  const CourseProjection({
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.currentAttended,
    required this.currentTotal,
    required this.currentPercentage,
    required this.totalClassesInRange,
    required this.presentInRange,
    required this.absentInRange,
    required this.holidayInRange,
    required this.projectedAttended,
    required this.projectedTotal,
    required this.projectedPercentage,
    required this.bufferClasses,
    required this.meetsTarget,
    required this.schedule,
    required this.dateWiseAttendance,
    this.dayWiseClassCount = const {},
  });

  /// Factory constructor to create projection from course data and attendance days
  factory CourseProjection.calculate({
    required int courseId,
    required String courseCode,
    required String courseTitle,
    required int currentAttended,
    required int currentTotal,
    required List<AttendanceDay> attendanceDays,
    required double targetPercentage,
    required CourseSchedule schedule,
  }) {
    // Calculate current percentage
    final currentPercentage =
        currentTotal > 0 ? (currentAttended / currentTotal) * 100 : 0.0;

    // Count classes in range - based on actual slots per day
    int totalInRange = 0;
    int presentInRange = 0;
    int absentInRange = 0;
    int holidayInRange = 0;

    final Map<DateTime, AttendanceDay> courseSpecificDates = {};
    final Map<int, int> dayWiseCount = {}; // Track total days per weekday

    for (final attendanceDay in attendanceDays) {
      final date = attendanceDay.date;
      final status = attendanceDay.status;

      // Determine effective weekday (considering makeup days)
      int effectiveWeekday = date.weekday;
      if (attendanceDay.followsScheduleOf != null) {
        effectiveWeekday = attendanceDay.followsScheduleOf!;
      }

      // Check if this course has class on this effective weekday
      bool hasClass = schedule.hasClassOnDay(effectiveWeekday);

      // Only count this day if the course has class
      if (hasClass) {
        courseSpecificDates[date] = attendanceDay; // Store full AttendanceDay

        // Get number of classes (slots) for this weekday
        final slotsForDay = schedule.getSlotsForDay(effectiveWeekday);
        final classesPerDay = slotsForDay.isNotEmpty ? slotsForDay.length : 1;

        switch (status) {
          case DayStatus.present:
            totalInRange += classesPerDay;
            presentInRange += classesPerDay;
            // Count number of days (not classes) for day-wise breakdown
            dayWiseCount[effectiveWeekday] =
                (dayWiseCount[effectiveWeekday] ?? 0) + 1;
            break;
          case DayStatus.absent:
            totalInRange += classesPerDay;
            absentInRange += classesPerDay;
            // Count number of days (not classes) for day-wise breakdown
            dayWiseCount[effectiveWeekday] =
                (dayWiseCount[effectiveWeekday] ?? 0) + 1;
            break;
          case DayStatus.holiday:
            holidayInRange++;
            break;
        }
      }
    }

    // Calculate projected attendance
    final projectedAttended = currentAttended + presentInRange;
    final projectedTotal = currentTotal + totalInRange;
    final projectedPercentage =
        projectedTotal > 0 ? (projectedAttended / projectedTotal) * 100 : 0.0;

    // Calculate buffer classes
    final bufferClasses = _calculateBuffer(
      currentAttended: projectedAttended,
      currentTotal: projectedTotal,
      targetPercentage: targetPercentage,
    );

    final meetsTarget = projectedPercentage >= targetPercentage;

    return CourseProjection(
      courseId: courseId,
      courseCode: courseCode,
      courseTitle: courseTitle,
      currentAttended: currentAttended,
      currentTotal: currentTotal,
      currentPercentage: currentPercentage,
      totalClassesInRange: totalInRange,
      presentInRange: presentInRange,
      absentInRange: absentInRange,
      holidayInRange: holidayInRange,
      projectedAttended: projectedAttended,
      projectedTotal: projectedTotal,
      projectedPercentage: projectedPercentage,
      bufferClasses: bufferClasses,
      meetsTarget: meetsTarget,
      schedule: schedule,
      dateWiseAttendance: courseSpecificDates,
      dayWiseClassCount: dayWiseCount,
    );
  }

  /// Calculate buffer classes (+ve = can miss, -ve = need to attend)
  static int _calculateBuffer({
    required int currentAttended,
    required int currentTotal,
    required double targetPercentage,
  }) {
    if (currentTotal == 0) return 0;

    final targetFraction = targetPercentage / 100;
    final currentPercentage = currentAttended / currentTotal;

    if (currentPercentage >= targetFraction) {
      // Can miss classes - calculate how many
      int canMiss = 0;
      int tempAttended = currentAttended;
      int tempTotal = currentTotal;

      while (true) {
        tempTotal++;
        final newPercentage = tempAttended / tempTotal;
        if (newPercentage < targetFraction) break;
        canMiss++;
      }

      return canMiss;
    } else {
      // Need to attend classes - calculate how many
      int needToAttend = 0;
      int tempAttended = currentAttended;
      int tempTotal = currentTotal;

      while (true) {
        tempAttended++;
        tempTotal++;
        needToAttend++;
        final newPercentage = tempAttended / tempTotal;
        if (newPercentage >= targetFraction) break;

        // Prevent infinite loop
        if (needToAttend > 1000) break;
      }

      return -needToAttend;
    }
  }

  /// Get buffer display text
  String get bufferText {
    if (bufferClasses == 0) {
      return 'At target';
    } else if (bufferClasses > 0) {
      return '+$bufferClasses ${bufferClasses == 1 ? 'class' : 'classes'}';
    } else {
      return '${bufferClasses} ${bufferClasses == -1 ? 'class' : 'classes'}';
    }
  }

  /// Get status level (safe, warning, danger)
  AttendanceStatus get status {
    if (projectedPercentage >= 85) {
      return AttendanceStatus.safe;
    } else if (projectedPercentage >= 75) {
      return AttendanceStatus.warning;
    } else {
      return AttendanceStatus.danger;
    }
  }

  /// Get current attendance display string
  String get currentAttendanceText {
    return '$currentAttended / $currentTotal';
  }

  /// Get projected attendance display string
  String get projectedAttendanceText {
    return '$projectedAttended / $projectedTotal';
  }

  @override
  String toString() {
    return 'CourseProjection{$courseCode: '
        'current: ${currentPercentage.toStringAsFixed(1)}%, '
        'projected: ${projectedPercentage.toStringAsFixed(1)}%, '
        'buffer: $bufferText}';
  }
}

/// Enum for attendance status levels
enum AttendanceStatus {
  safe,
  warning,
  danger;

  String get displayName {
    switch (this) {
      case AttendanceStatus.safe:
        return 'Safe';
      case AttendanceStatus.warning:
        return 'Warning';
      case AttendanceStatus.danger:
        return 'Danger';
    }
  }
}
