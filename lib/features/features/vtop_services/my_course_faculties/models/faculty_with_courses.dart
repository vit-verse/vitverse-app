/// Model representing a faculty member with all their courses
class FacultyWithCourses {
  final String facultyName;
  final String? facultyErpId; // Faculty ERP ID (extracted from first course)
  final List<CourseInfo> courses;

  FacultyWithCourses({
    required this.facultyName,
    this.facultyErpId,
    required this.courses,
  });

  /// Get total credits taught by this faculty
  double get totalCredits =>
      courses.fold(0.0, (sum, course) => sum + (course.credits ?? 0.0));

  /// Get total number of courses (including labs as separate courses)
  int get totalCourses => courses.length;

  /// Group courses by type
  Map<String, List<CourseInfo>> get coursesByType {
    final Map<String, List<CourseInfo>> grouped = {};
    for (var course in courses) {
      final type = course.type?.toLowerCase() ?? 'theory';
      grouped.putIfAbsent(type, () => []).add(course);
    }
    return grouped;
  }
}

/// Model representing course information for faculty view
class CourseInfo {
  final String? code;
  final String? title;
  final String? type;
  final double? credits;
  final String? venue;
  final String? slot;
  final String? facultyErpId; // Faculty ERP ID
  final String? classId; // VTOP Class ID

  CourseInfo({
    this.code,
    this.title,
    this.type,
    this.credits,
    this.venue,
    this.slot,
    this.facultyErpId,
    this.classId,
  });

  factory CourseInfo.fromMap(Map<String, dynamic> map) {
    // Convert credits to double to handle decimal values
    double? creditsValue;
    final creditsRaw = map['credits'];
    if (creditsRaw != null) {
      if (creditsRaw is int) {
        creditsValue = creditsRaw.toDouble();
      } else if (creditsRaw is double) {
        creditsValue = creditsRaw;
      } else if (creditsRaw is String) {
        creditsValue = double.tryParse(creditsRaw);
      }
    }

    return CourseInfo(
      code: map['code'] as String?,
      title: map['title'] as String?,
      type: map['type'] as String?,
      credits: creditsValue,
      venue: map['venue'] as String?,
      slot: map['slot'] as String?,
      facultyErpId: map['faculty_erp_id'] as String?,
      classId: map['class_id'] as String?,
    );
  }

  /// Get formatted course type
  String get formattedType {
    if (type == null) return 'Theory';
    return type!.substring(0, 1).toUpperCase() +
        type!.substring(1).toLowerCase();
  }

  /// Get formatted credits display
  String get creditsDisplay {
    if (credits == null) return 'N/A';
    // If credits is a whole number, show without decimal
    if (credits! % 1 == 0) {
      return credits!.toInt().toString();
    }
    // Otherwise show with one decimal place
    return credits!.toStringAsFixed(1);
  }
}
