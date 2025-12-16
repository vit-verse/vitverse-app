/// Model for submitting a faculty rating
class RatingSubmission {
  final String facultyId;
  final String facultyName;
  final double teaching;
  final double attendanceFlex;
  final double supportiveness;
  final double marks;
  final DateTime timestamp;

  RatingSubmission({
    required this.facultyId,
    required this.facultyName,
    required this.teaching,
    required this.attendanceFlex,
    required this.supportiveness,
    required this.marks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calculate overall rating (average of all parameters)
  double get overallRating {
    return (teaching + attendanceFlex + supportiveness + marks) / 4.0;
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'teaching': teaching,
      'attendance_flex': attendanceFlex,
      'supportiveness': supportiveness,
      'marks': marks,
      'overall_rating': overallRating,
      'timestamp': timestamp.toIso8601String(),
    };
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

  @override
  String toString() {
    return 'RatingSubmission(facultyId: $facultyId, overall: ${overallRating.toStringAsFixed(1)})';
  }
}

/// Rating parameter definition
class RatingParameter {
  final String id;
  final String title;
  final String description;
  final String icon;

  const RatingParameter({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Available rating parameters
class RatingParameters {
  static const teaching = RatingParameter(
    id: 'teaching',
    title: 'Teaching Quality',
    description:
        'How well does the faculty explain concepts and engage students?',
    icon: '📚',
  );

  static const attendanceFlex = RatingParameter(
    id: 'attendance_flex',
    title: 'Attendance Flexibility',
    description: 'How understanding is the faculty regarding attendance?',
    icon: '📅',
  );

  static const supportiveness = RatingParameter(
    id: 'supportiveness',
    title: 'Supportiveness',
    description: 'How helpful and approachable is the faculty?',
    icon: '🤝',
  );

  static const marks = RatingParameter(
    id: 'marks',
    title: 'Marks & Evaluation',
    description: 'How fair and reasonable is the grading?',
    icon: '📊',
  );

  static const List<RatingParameter> all = [
    teaching,
    attendanceFlex,
    supportiveness,
    marks,
  ];

  static RatingParameter? getById(String id) {
    try {
      return all.firstWhere((param) => param.id == id);
    } catch (e) {
      return null;
    }
  }
}
