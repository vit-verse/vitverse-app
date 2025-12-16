/// Model to track slot details for a specific day
class SlotDetail {
  final int slotId;
  final String slotName;
  final String startTime;
  final String endTime;

  const SlotDetail({
    required this.slotId,
    required this.slotName,
    required this.startTime,
    required this.endTime,
  });
}

/// Model to track which days a specific course has classes
class CourseSchedule {
  final int courseId;
  final String courseCode;
  final Set<int> classDays; // Set of weekdays (1=Mon, 2=Tue, ..., 7=Sun)
  final Map<int, List<SlotDetail>> daySlots; // Map of weekday to list of slots

  const CourseSchedule({
    required this.courseId,
    required this.courseCode,
    required this.classDays,
    this.daySlots = const {},
  });

  /// Check if course has class on a given date
  /// Uses DateTime.weekday format: 1=Monday, 2=Tuesday, ..., 7=Sunday
  bool hasClassOnDate(DateTime date) {
    // Check if this weekday is in the course's schedule
    // classDays uses DateTime.weekday format after conversion
    return classDays.contains(date.weekday);
  }

  /// Check if course has class on a given weekday number
  /// weekday: DateTime.weekday format (1=Monday, ..., 7=Sunday)
  bool hasClassOnDay(int weekday) {
    return classDays.contains(weekday);
  }

  /// Copy with method
  CourseSchedule copyWith({
    int? courseId,
    String? courseCode,
    Set<int>? classDays,
    Map<int, List<SlotDetail>>? daySlots,
  }) {
    return CourseSchedule(
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      classDays: classDays ?? this.classDays,
      daySlots: daySlots ?? this.daySlots,
    );
  }

  /// Add a weekday to the schedule
  CourseSchedule addDay(int weekday) {
    final newDays = Set<int>.from(classDays);
    newDays.add(weekday);
    return copyWith(classDays: newDays);
  }

  /// Remove a weekday from the schedule
  CourseSchedule removeDay(int weekday) {
    final newDays = Set<int>.from(classDays);
    newDays.remove(weekday);
    return copyWith(classDays: newDays);
  }

  /// Toggle a weekday in the schedule
  CourseSchedule toggleDay(int weekday) {
    if (classDays.contains(weekday)) {
      return removeDay(weekday);
    } else {
      return addDay(weekday);
    }
  }

  /// Get weekday names for display
  List<String> get weekdayNames {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return classDays.map((day) => names[day - 1]).toList()..sort();
  }

  /// Get display text for schedule
  String get scheduleText {
    if (classDays.isEmpty) return 'No classes scheduled';
    return weekdayNames.join(', ');
  }

  /// Get slots for a specific day
  List<SlotDetail> getSlotsForDay(int weekday) {
    return daySlots[weekday] ?? [];
  }

  /// Get total number of slots per week
  int get totalSlotsPerWeek {
    return daySlots.values.fold(0, (sum, slots) => sum + slots.length);
  }

  @override
  String toString() {
    return 'CourseSchedule{$courseCode: ${scheduleText}, $totalSlotsPerWeek slots/week}';
  }
}
