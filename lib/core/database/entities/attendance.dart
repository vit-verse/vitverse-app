/// Attendance entity representing course attendance records
/// Maps to the 'attendance' table in the database
/// Child of Course with CASCADE delete
class Attendance {
  final int? id;
  final int? courseId;
  final String? courseType;
  final int? attended;
  final int? total;
  final int? percentage;

  const Attendance({
    this.id,
    this.courseId,
    this.courseType,
    this.attended,
    this.total,
    this.percentage,
  });

  /// Create Attendance from database map
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      courseId: map['course_id'] as int?,
      courseType: map['course_type'] as String?,
      attended: map['attended'] as int?,
      total: map['total'] as int?,
      percentage: map['percentage'] as int?,
    );
  }

  /// Convert Attendance to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      if (courseType != null) 'course_type': courseType,
      'attended': attended,
      'total': total,
      'percentage': percentage,
    };
  }

  /// Create copy with updated fields
  Attendance copyWith({
    int? id,
    int? courseId,
    String? courseType,
    int? attended,
    int? total,
    int? percentage,
  }) {
    return Attendance(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseType: courseType ?? this.courseType,
      attended: attended ?? this.attended,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  String toString() {
    return 'Attendance{id: $id, courseId: $courseId, courseType: $courseType, attended: $attended, total: $total, percentage: $percentage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance &&
        other.id == id &&
        other.courseId == courseId &&
        other.courseType == courseType &&
        other.attended == attended &&
        other.total == total &&
        other.percentage == percentage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        courseType.hashCode ^
        attended.hashCode ^
        total.hashCode ^
        percentage.hashCode;
  }
}
