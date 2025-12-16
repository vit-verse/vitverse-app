import 'day_status.dart';

/// Model representing a single day in the attendance calculator
class AttendanceDay {
  final DateTime date;
  final DayStatus status;
  final bool isWeekend;
  final bool isToday;

  /// Optional: Which day's schedule this day follows (for makeup days)
  /// 1=Sunday, 2=Monday, 3=Tuesday, ..., 7=Saturday
  /// Used when Saturday follows a weekday schedule
  final int? followsScheduleOf;

  /// Whether this is a CAT exam day (CAT-1 or CAT-2)
  /// VTOP Academic calendar does  not show FATTHEORY and FATLAB are instructional days
  final bool isCatDay;

  /// CAT number (1 or 2) if this is a CAT day
  final int? catNumber;

  /// Whether this CAT day is included in attendance calculation
  /// If true, treats as normal working day; if false, treats as holiday
  final bool catIncludedInCalculation;

  const AttendanceDay({
    required this.date,
    required this.status,
    required this.isWeekend,
    this.isToday = false,
    this.followsScheduleOf,
    this.isCatDay = false,
    this.catNumber,
    this.catIncludedInCalculation = false,
  });

  /// Copy with method for updating status
  AttendanceDay copyWith({
    DateTime? date,
    DayStatus? status,
    bool? isWeekend,
    bool? isToday,
    int? followsScheduleOf,
    bool? isCatDay,
    int? catNumber,
    bool? catIncludedInCalculation,
  }) {
    return AttendanceDay(
      date: date ?? this.date,
      status: status ?? this.status,
      isWeekend: isWeekend ?? this.isWeekend,
      isToday: isToday ?? this.isToday,
      followsScheduleOf: followsScheduleOf ?? this.followsScheduleOf,
      isCatDay: isCatDay ?? this.isCatDay,
      catNumber: catNumber ?? this.catNumber,
      catIncludedInCalculation:
          catIncludedInCalculation ?? this.catIncludedInCalculation,
    );
  }

  /// Check if this day is Saturday or Sunday
  static bool checkIsWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Create AttendanceDay from date with auto-detection
  factory AttendanceDay.fromDate(DateTime date, {DateTime? today}) {
    final isWeekend = checkIsWeekend(date);
    final todayDate = today ?? DateTime.now();
    final isToday =
        date.year == todayDate.year &&
        date.month == todayDate.month &&
        date.day == todayDate.day;

    return AttendanceDay(
      date: date,
      status: isWeekend ? DayStatus.holiday : DayStatus.absent,
      isWeekend: isWeekend,
      isToday: isToday,
    );
  }

  /// Get day number (1-31)
  int get day => date.day;

  /// Get month name (short)
  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  /// Get weekday name (short)
  String get weekdayName {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  /// Get formatted date string (DD/MM/YYYY)
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDay &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          status == other.status;

  @override
  int get hashCode => date.hashCode ^ status.hashCode;

  @override
  String toString() {
    return 'AttendanceDay{date: $formattedDate, status: ${status.displayName}}';
  }
}
