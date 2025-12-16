/// Constants for Friends' Schedule feature
class ScheduleConstants {
  /// Days of week (Monday to Friday)
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  /// Short day names for display
  static const List<String> shortDays = ['M', 'T', 'W', 'T', 'F'];

  /// Unified 12 Time Slots (Covers both Theory + Lab with ±5 min flexibility)
  /// Based on official VIT timetable layout
  static const List<String> timeSlots = [
    '08:00-08:50', // Slot 1
    '08:50-09:45', // Slot 2
    '09:50-10:40', // Slot 3
    '10:40-11:35', // Slot 4
    '11:40-12:30', // Slot 5
    '12:30-13:25', // Slot 6
    '14:00-14:50', // Slot 7 (Post-lunch)
    '14:50-15:45', // Slot 8
    '15:50-16:40', // Slot 9
    '16:45-17:35', // Slot 10
    '17:40-18:30', // Slot 11
    '18:35-19:25', // Slot 12
  ];

  /// Get time slot label for display (just start time)
  static List<String> get timeSlotLabels {
    return timeSlots.map((slot) => slot.split('-')[0].trim()).toList();
  }

  /// Get current time slot index based on time
  static int? getCurrentTimeSlotIndex() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < timeSlots.length; i++) {
      final slot = timeSlots[i];
      final times = slot.split('-');
      final startParts = times[0].trim().split(':');
      final endParts = times[1].trim().split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
        return i;
      }
    }
    return null;
  }

  /// Get current day index (0-4 for Mon-Fri, null for weekend)
  static int? getCurrentDayIndex() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Monday, 7=Sunday

    if (weekday >= 1 && weekday <= 5) {
      return weekday - 1; // Convert to 0-4
    }
    return null; // Weekend
  }

  /// Check if currently in a class time
  static bool isCurrentSlot(int dayIndex, int timeSlotIndex) {
    final currentDay = getCurrentDayIndex();
    final currentSlot = getCurrentTimeSlotIndex();

    return currentDay == dayIndex && currentSlot == timeSlotIndex;
  }

  /// Friend colors palette
  static const List<int> friendColorValues = [
    0xFFEC4899, // Pink
    0xFF10B981, // Green
    0xFFA855F7, // Purple
    0xFFF59E0B, // Orange
    0xFF3B82F6, // Blue
    0xFFEF4444, // Red
    0xFF14B8A6, // Teal
    0xFF8B5CF6, // Violet
  ];
}
