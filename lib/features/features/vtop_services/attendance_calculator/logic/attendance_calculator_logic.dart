import '../models/attendance_day.dart';
import '../models/date_range.dart';
import '../models/day_status.dart';

/// Core logic for attendance calculator
class AttendanceCalculatorLogic {
  /// Generate list of AttendanceDay objects for a date range
  static List<AttendanceDay> generateDaysForRange(DateRange dateRange) {
    if (!dateRange.isValid) return [];

    final days = <AttendanceDay>[];
    final today = DateTime.now();
    DateTime current = dateRange.startDate;

    while (!current.isAfter(dateRange.endDate)) {
      days.add(AttendanceDay.fromDate(current, today: today));
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Generate map of date to DayStatus for easier lookups
  static Map<DateTime, DayStatus> generateStatusMap(List<AttendanceDay> days) {
    final map = <DateTime, DayStatus>{};
    for (final day in days) {
      // Normalize date to remove time component
      final normalizedDate = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
      );
      map[normalizedDate] = day.status;
    }
    return map;
  }

  /// Toggle day status (cycles through absent -> present -> holiday -> absent)
  static DayStatus toggleDayStatus(DayStatus currentStatus) {
    return currentStatus.next;
  }

  /// Update a specific day's status in the list
  static List<AttendanceDay> updateDayStatus(
    List<AttendanceDay> days,
    DateTime targetDate,
    DayStatus newStatus,
  ) {
    return days.map((day) {
      final normalizedDayDate = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
      );
      final normalizedTargetDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      if (normalizedDayDate.isAtSameMomentAs(normalizedTargetDate)) {
        return day.copyWith(status: newStatus);
      }
      return day;
    }).toList();
  }

  /// Count total days by status
  static Map<DayStatus, int> countDaysByStatus(List<AttendanceDay> days) {
    final counts = {
      DayStatus.absent: 0,
      DayStatus.present: 0,
      DayStatus.holiday: 0,
    };

    for (final day in days) {
      counts[day.status] = (counts[day.status] ?? 0) + 1;
    }

    return counts;
  }

  /// Get total class days (excluding holidays)
  static int getTotalClassDays(List<AttendanceDay> days) {
    return days.where((day) => day.status != DayStatus.holiday).length;
  }

  /// Get present days count
  static int getPresentDays(List<AttendanceDay> days) {
    return days.where((day) => day.status == DayStatus.present).length;
  }

  /// Get absent days count
  static int getAbsentDays(List<AttendanceDay> days) {
    return days.where((day) => day.status == DayStatus.absent).length;
  }

  /// Get holiday days count
  static int getHolidayDays(List<AttendanceDay> days) {
    return days.where((day) => day.status == DayStatus.holiday).length;
  }

  /// Calculate percentage for given attended/total
  static double calculatePercentage(int attended, int total) {
    if (total == 0) return 0.0;
    return (attended / total) * 100;
  }

  /// Group days by month for display
  static Map<String, List<AttendanceDay>> groupDaysByMonth(
    List<AttendanceDay> days,
  ) {
    final grouped = <String, List<AttendanceDay>>{};

    for (final day in days) {
      final monthKey = '${day.monthName} ${day.date.year}';
      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(day);
    }

    return grouped;
  }

  /// Get weeks for calendar display
  /// Returns list of weeks, where each week is a list of 7 days (Mon-Sun)
  /// Padding days are null
  static List<List<AttendanceDay?>> getCalendarWeeks(List<AttendanceDay> days) {
    if (days.isEmpty) return [];

    final weeks = <List<AttendanceDay?>>[];
    List<AttendanceDay?> currentWeek = List.filled(7, null);

    for (final day in days) {
      // Monday = 1, Sunday = 7 in DateTime.weekday
      // We want: Mon = 0, Tue = 1, ..., Sun = 6
      final weekdayIndex = day.date.weekday - 1;

      currentWeek[weekdayIndex] = day;

      // If it's Sunday (last day of week), start new week
      if (weekdayIndex == 6) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
      }
    }

    // Add remaining days if any
    if (currentWeek.any((day) => day != null)) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  /// Normalize DateTime to date only (removes time component)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get default target percentage
  static const double defaultTargetPercentage = 75.0;

  /// Get minimum target percentage
  static const double minTargetPercentage = 50.0;

  /// Get maximum target percentage
  static const double maxTargetPercentage = 100.0;
}
