/// Slot entity representing time slot mappings for courses
/// Maps to the 'slots' table in the database
/// Child of Course with CASCADE delete
class Slot {
  final int? id;
  final String? slot;
  final int? courseId;

  const Slot({this.id, this.slot, this.courseId});

  /// Create Slot from database map
  factory Slot.fromMap(Map<String, dynamic> map) {
    return Slot(
      id: map['id'] as int?,
      slot: map['slot'] as String?,
      courseId: map['course_id'] as int?,
    );
  }

  /// Convert Slot to database map
  Map<String, dynamic> toMap() {
    return {'id': id, 'slot': slot, 'course_id': courseId};
  }

  /// Create copy with updated fields
  Slot copyWith({int? id, String? slot, int? courseId}) {
    return Slot(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      courseId: courseId ?? this.courseId,
    );
  }

  @override
  String toString() {
    return 'Slot{id: $id, slot: $slot, courseId: $courseId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Slot &&
        other.id == id &&
        other.slot == slot &&
        other.courseId == courseId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ slot.hashCode ^ courseId.hashCode;
  }
}
