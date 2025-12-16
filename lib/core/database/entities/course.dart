/// Course entity representing academic courses
/// Maps to the 'courses' table in the database
class Course {
  final int? id;
  final String? code;
  final String? title;
  final String? type;
  final double? credits;
  final String? venue;
  final String? faculty;
  final String? facultyErpId; //facultyid
  final String? semesterId;
  final String? classId; // VTOP Class ID (e.g., CH2025260102084)
  final String? category; // e.g., "Discipline Core", "Open Elective", "FCHSSM"
  final String? courseOption; // e.g., "Embedded Systems Design"

  const Course({
    this.id,
    this.code,
    this.title,
    this.type,
    this.credits,
    this.venue,
    this.faculty,
    this.facultyErpId,
    this.semesterId,
    this.classId,
    this.category,
    this.courseOption,
  });

  /// Create Course from database map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      code: map['code'] as String?,
      title: map['title'] as String?,
      type: map['type'] as String?,
      credits: (map['credits'] as num?)?.toDouble(),
      venue: map['venue'] as String?,
      faculty: map['faculty'] as String?,
      facultyErpId: map['faculty_erp_id'] as String?,
      semesterId: map['semester_id'] as String?,
      classId: map['class_id'] as String?,
      category: map['category'] as String?,
      courseOption: map['course_option'] as String?,
    );
  }

  /// Convert Course to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'type': type,
      'credits': credits,
      'venue': venue,
      'faculty': faculty,
      'faculty_erp_id': facultyErpId,
      'semester_id': semesterId,
      'class_id': classId,
      'category': category,
      'course_option': courseOption,
    };
  }

  /// Create copy with updated fields
  Course copyWith({
    int? id,
    String? code,
    String? title,
    String? type,
    double? credits,
    String? venue,
    String? faculty,
    String? facultyErpId,
    String? semesterId,
    String? classId,
    String? category,
    String? courseOption,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      type: type ?? this.type,
      credits: credits ?? this.credits,
      venue: venue ?? this.venue,
      faculty: faculty ?? this.faculty,
      facultyErpId: facultyErpId ?? this.facultyErpId,
      semesterId: semesterId ?? this.semesterId,
      classId: classId ?? this.classId,
      category: category ?? this.category,
      courseOption: courseOption ?? this.courseOption,
    );
  }

  @override
  String toString() {
    return 'Course{id: $id, code: $code, title: $title, type: $type, credits: $credits, venue: $venue, faculty: $faculty, semesterId: $semesterId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course &&
        other.id == id &&
        other.code == code &&
        other.title == title &&
        other.type == type &&
        other.credits == credits &&
        other.venue == venue &&
        other.faculty == faculty &&
        other.semesterId == semesterId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        code.hashCode ^
        title.hashCode ^
        type.hashCode ^
        credits.hashCode ^
        venue.hashCode ^
        faculty.hashCode ^
        semesterId.hashCode;
  }
}
