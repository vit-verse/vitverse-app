/// Timetable entity representing weekly schedule with time slots
/// Maps to the 'timetable' table in the database
/// References slots through day columns
/// Toooo Confusingggg... Timetable - slot - map - course - facult - attendence - and all mapping
class Timetable {
  final int? id;
  final String? startTime; // 24-hour format HH:mm
  final String? endTime; // 24-hour format HH:mm
  final int? sunday; // Slot ID for Sunday (nullable)
  final int? monday; // Slot ID for Monday (nullable)
  final int? tuesday; // Slot ID for Tuesday (nullable)
  final int? wednesday; // Slot ID for Wednesday (nullable)
  final int? thursday; // Slot ID for Thursday (nullable)
  final int? friday; // Slot ID for Friday (nullable)
  final int? saturday; // Slot ID for Saturday (nullable)

  const Timetable({
    this.id,
    this.startTime,
    this.endTime,
    this.sunday,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
  });

  /// Create Timetable from database map
  factory Timetable.fromMap(Map<String, dynamic> map) {
    return Timetable(
      id: map['id'] as int?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      sunday: map['sunday'] as int?,
      monday: map['monday'] as int?,
      tuesday: map['tuesday'] as int?,
      wednesday: map['wednesday'] as int?,
      thursday: map['thursday'] as int?,
      friday: map['friday'] as int?,
      saturday: map['saturday'] as int?,
    );
  }

  /// Convert Timetable to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'sunday': sunday,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
    };
  }

  /// Get slot ID for a specific day (1=Sunday, 2=Monday, ..., 7=Saturday)
  int? getSlotForDay(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return sunday;
      case 2:
        return monday;
      case 3:
        return tuesday;
      case 4:
        return wednesday;
      case 5:
        return thursday;
      case 6:
        return friday;
      case 7:
        return saturday;
      default:
        return null;
    }
  }

  /// Check if this time slot has any classes
  bool get hasClasses {
    return sunday != null ||
        monday != null ||
        tuesday != null ||
        wednesday != null ||
        thursday != null ||
        friday != null ||
        saturday != null;
  }

  /// Create copy with updated fields
  Timetable copyWith({
    int? id,
    String? startTime,
    String? endTime,
    int? sunday,
    int? monday,
    int? tuesday,
    int? wednesday,
    int? thursday,
    int? friday,
    int? saturday,
  }) {
    return Timetable(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sunday: sunday ?? this.sunday,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
    );
  }

  @override
  String toString() {
    return 'Timetable{id: $id, startTime: $startTime, endTime: $endTime, sunday: $sunday, monday: $monday, tuesday: $tuesday, wednesday: $wednesday, thursday: $thursday, friday: $friday, saturday: $saturday}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Timetable &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.sunday == sunday &&
        other.monday == monday &&
        other.tuesday == tuesday &&
        other.wednesday == wednesday &&
        other.thursday == thursday &&
        other.friday == friday &&
        other.saturday == saturday;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        sunday.hashCode ^
        monday.hashCode ^
        tuesday.hashCode ^
        wednesday.hashCode ^
        thursday.hashCode ^
        friday.hashCode ^
        saturday.hashCode;
  }
}
