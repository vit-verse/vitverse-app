/// Model representing a date range selection
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  /// Validate if the date range is valid
  bool get isValid {
    return !endDate.isBefore(startDate);
  }

  /// Get the number of days in the range (inclusive)
  int get dayCount {
    if (!isValid) return 0;
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get the number of weekdays in the range
  int get weekdayCount {
    if (!isValid) return 0;

    int count = 0;
    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// Get the number of weekend days in the range
  int get weekendCount {
    return dayCount - weekdayCount;
  }

  /// Check if range exceeds maximum allowed days
  bool exceedsMaxDays(int maxDays) {
    return dayCount > maxDays;
  }

  /// Copy with method
  DateRange copyWith({DateTime? startDate, DateTime? endDate}) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Get formatted date range string
  String get formattedRange {
    final startFormatted =
        '${startDate.day.toString().padLeft(2, '0')}/'
        '${startDate.month.toString().padLeft(2, '0')}/'
        '${startDate.year}';
    final endFormatted =
        '${endDate.day.toString().padLeft(2, '0')}/'
        '${endDate.month.toString().padLeft(2, '0')}/'
        '${endDate.year}';
    return '$startFormatted - $endFormatted';
  }

  /// Generate list of all dates in range
  List<DateTime> generateDateList() {
    if (!isValid) return [];

    final dates = <DateTime>[];
    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;

  @override
  String toString() {
    return 'DateRange{$formattedRange, days: $dayCount}';
  }
}
