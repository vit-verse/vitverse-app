/// CumulativeMark entity representing final grades for all semesters
/// Maps to the 'cumulative_marks' table in the database
/// Stores complete academic history across all semesters
class CumulativeMark {
  final int? id;
  final String semesterId; // e.g., "CH20242505"
  final String semesterName; // e.g., "Winter Semester 2024-25"
  final String courseCode; // e.g., "BCSE203E"
  final String courseTitle; // e.g., "Web Programming"
  final String courseType; // e.g., "Embedded Theory and Lab"
  final double credits; // Total credits (C column)
  final String gradingType; // "AG" or "RG"
  final double grandTotal; // Marks obtained
  final String grade; // Letter grade: S, A, B, C, D, E, F, P, N
  final bool isOnlineCourse; // MOOC/online courses (not in GPA)
  final double? semesterGpa; // GPA for this semester

  const CumulativeMark({
    this.id,
    required this.semesterId,
    required this.semesterName,
    required this.courseCode,
    required this.courseTitle,
    required this.courseType,
    required this.credits,
    required this.gradingType,
    required this.grandTotal,
    required this.grade,
    this.isOnlineCourse = false,
    this.semesterGpa,
  });

  /// Create CumulativeMark from database map
  factory CumulativeMark.fromMap(Map<String, dynamic> map) {
    return CumulativeMark(
      id: map['id'] as int?,
      semesterId: map['semester_id'] as String? ?? '',
      semesterName: map['semester_name'] as String? ?? '',
      courseCode: map['course_code'] as String? ?? '',
      courseTitle: map['course_title'] as String? ?? '',
      courseType: map['course_type'] as String? ?? '',
      credits: (map['credits'] as num?)?.toDouble() ?? 0.0,
      gradingType: map['grading_type'] as String? ?? '',
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] as String? ?? '',
      isOnlineCourse: (map['is_online_course'] as int?) == 1,
      semesterGpa: (map['semester_gpa'] as num?)?.toDouble(),
    );
  }

  /// Convert CumulativeMark to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_id': semesterId,
      'semester_name': semesterName,
      'course_code': courseCode,
      'course_title': courseTitle,
      'course_type': courseType,
      'credits': credits,
      'grading_type': gradingType,
      'grand_total': grandTotal,
      'grade': grade,
      'is_online_course': isOnlineCourse ? 1 : 0,
      'semester_gpa': semesterGpa,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'semesterName': semesterName,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'courseType': courseType,
      'credits': credits,
      'gradingType': gradingType,
      'grandTotal': grandTotal,
      'grade': grade,
      'isOnlineCourse': isOnlineCourse,
      'semesterGpa': semesterGpa,
    };
  }

  /// Check if grade is passing
  bool get isPassing {
    return !['F', 'N'].contains(grade.toUpperCase());
  }

  /// Get grade points for CGPA calculation
  double get gradePoints {
    switch (grade.toUpperCase()) {
      case 'S':
        return 10.0;
      case 'A':
        return 9.0;
      case 'B':
        return 8.0;
      case 'C':
        return 7.0;
      case 'D':
        return 6.0;
      case 'E':
        return 5.0;
      case 'P':
        return 4.0; // Pass for online courses
      default:
        return 0.0; // F or N
    }
  }

  /// Create copy with updated fields
  CumulativeMark copyWith({
    int? id,
    String? semesterId,
    String? semesterName,
    String? courseCode,
    String? courseTitle,
    String? courseType,
    double? credits,
    String? gradingType,
    double? grandTotal,
    String? grade,
    bool? isOnlineCourse,
    double? semesterGpa,
  }) {
    return CumulativeMark(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      semesterName: semesterName ?? this.semesterName,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      courseType: courseType ?? this.courseType,
      credits: credits ?? this.credits,
      gradingType: gradingType ?? this.gradingType,
      grandTotal: grandTotal ?? this.grandTotal,
      grade: grade ?? this.grade,
      isOnlineCourse: isOnlineCourse ?? this.isOnlineCourse,
      semesterGpa: semesterGpa ?? this.semesterGpa,
    );
  }

  @override
  String toString() {
    return 'CumulativeMark{id: $id, semester: $semesterName, course: $courseCode, grade: $grade, credits: $credits, gpa: $semesterGpa}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CumulativeMark &&
        other.id == id &&
        other.semesterId == semesterId &&
        other.courseCode == courseCode &&
        other.grade == grade;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        semesterId.hashCode ^
        courseCode.hashCode ^
        grade.hashCode;
  }
}
