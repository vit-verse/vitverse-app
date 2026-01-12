/// Course info model
class CourseInfo {
  final String code;
  final String title;

  CourseInfo({required this.code, required this.title});

  Map<String, dynamic> toJson() => {'code': code, 'title': title};
  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      CourseInfo(code: json['code'] as String, title: json['title'] as String);
}

/// Student's rating submission for a faculty member
class StudentFacultyRating {
  final String id;
  final String studentRegno;
  final String studentName;
  final String facultyId;
  final String facultyName;
  final double teaching;
  final double attendanceFlex;
  final double supportiveness;
  final double marks;
  final String? review;
  final List<CourseInfo> courses;
  final DateTime submittedAt;

  StudentFacultyRating({
    required this.id,
    required this.studentRegno,
    required this.studentName,
    required this.facultyId,
    required this.facultyName,
    required this.teaching,
    required this.attendanceFlex,
    required this.supportiveness,
    required this.marks,
    this.review,
    this.courses = const [],
    required this.submittedAt,
  });

  /// Calculate overall rating (average of all parameters)
  double get overallRating {
    return (teaching + attendanceFlex + supportiveness + marks) / 4.0;
  }

  /// Create from Supabase response
  factory StudentFacultyRating.fromMap(Map<String, dynamic> map) {
    List<CourseInfo> coursesList = [];
    if (map['courses'] != null) {
      final coursesJson = map['courses'] as List;
      coursesList =
          coursesJson
              .map((c) => CourseInfo.fromJson(c as Map<String, dynamic>))
              .toList();
    }
    return StudentFacultyRating(
      id: map['id'] as String,
      studentRegno: map['student_regno'] as String,
      studentName: map['student_name'] as String? ?? 'Unknown',
      facultyId: map['faculty_id'] as String,
      facultyName: map['faculty_name'] as String,
      teaching: (map['teaching'] as num).toDouble(),
      attendanceFlex: (map['attendance_flex'] as num).toDouble(),
      supportiveness: (map['supportiveness'] as num).toDouble(),
      marks: (map['marks'] as num).toDouble(),
      review: map['review'] as String?,
      courses: coursesList,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
    );
  }

  /// Convert to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_regno': studentRegno,
      'student_name': studentName,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'teaching': teaching,
      'attendance_flex': attendanceFlex,
      'supportiveness': supportiveness,
      'marks': marks,
      'overall_rating': overallRating,
      'review': review,
      'courses': courses.map((c) => c.toJson()).toList(),
    };
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_regno': studentRegno,
      'student_name': studentName,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'teaching': teaching,
      'attendance_flex': attendanceFlex,
      'supportiveness': supportiveness,
      'marks': marks,
      'review': review,
      'courses': courses.map((c) => c.toJson()).toList(),
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  /// Create from JSON (cache)
  factory StudentFacultyRating.fromJson(Map<String, dynamic> json) {
    List<CourseInfo> coursesList = [];
    if (json['courses'] != null) {
      final coursesJson = json['courses'] as List;
      coursesList =
          coursesJson
              .map((c) => CourseInfo.fromJson(c as Map<String, dynamic>))
              .toList();
    }
    return StudentFacultyRating(
      id: json['id'] as String,
      studentRegno: json['student_regno'] as String,
      studentName: json['student_name'] as String? ?? 'Unknown',
      facultyId: json['faculty_id'] as String,
      facultyName: json['faculty_name'] as String,
      teaching: (json['teaching'] as num).toDouble(),
      attendanceFlex: (json['attendance_flex'] as num).toDouble(),
      supportiveness: (json['supportiveness'] as num).toDouble(),
      marks: (json['marks'] as num).toDouble(),
      review: json['review'] as String?,
      courses: coursesList,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  /// Validate ratings (all should be between 0 and 10)
  bool isValid() {
    return teaching >= 0 &&
        teaching <= 10 &&
        attendanceFlex >= 0 &&
        attendanceFlex <= 10 &&
        supportiveness >= 0 &&
        supportiveness <= 10 &&
        marks >= 0 &&
        marks <= 10;
  }
}
