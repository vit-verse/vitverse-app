/// Aggregated rating statistics for a faculty member
class FacultyRatingAggregate {
  final String facultyId;
  final String facultyName;
  final int totalRatings;
  final double avgTeaching;
  final double avgAttendanceFlex;
  final double avgSupportiveness;
  final double avgMarks;
  final double avgOverall;
  final List<Map<String, String>> courses;
  final DateTime lastUpdated;

  FacultyRatingAggregate({
    required this.facultyId,
    required this.facultyName,
    required this.totalRatings,
    required this.avgTeaching,
    required this.avgAttendanceFlex,
    required this.avgSupportiveness,
    required this.avgMarks,
    required this.avgOverall,
    this.courses = const [],
    required this.lastUpdated,
  });

  /// Create from Supabase response
  factory FacultyRatingAggregate.fromMap(Map<String, dynamic> map) {
    List<Map<String, String>> coursesList = [];
    if (map['courses'] != null) {
      final coursesJson = map['courses'] as List;
      coursesList =
          coursesJson
              .map(
                (c) => {
                  'code': c['code'] as String? ?? '',
                  'title': c['title'] as String? ?? '',
                },
              )
              .toList();
    }
    return FacultyRatingAggregate(
      facultyId: map['faculty_id'] as String,
      facultyName: map['faculty_name'] as String,
      totalRatings: map['total_ratings'] as int,
      avgTeaching: (map['avg_teaching'] as num?)?.toDouble() ?? 0.0,
      avgAttendanceFlex:
          (map['avg_attendance_flex'] as num?)?.toDouble() ?? 0.0,
      avgSupportiveness: (map['avg_supportiveness'] as num?)?.toDouble() ?? 0.0,
      avgMarks: (map['avg_marks'] as num?)?.toDouble() ?? 0.0,
      avgOverall: (map['avg_overall'] as num?)?.toDouble() ?? 0.0,
      courses: coursesList,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'total_ratings': totalRatings,
      'avg_teaching': avgTeaching,
      'avg_attendance_flex': avgAttendanceFlex,
      'avg_supportiveness': avgSupportiveness,
      'avg_marks': avgMarks,
      'avg_overall': avgOverall,
      'courses': courses,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON (cache)
  factory FacultyRatingAggregate.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> coursesList = [];
    if (json['courses'] != null) {
      final coursesJson = json['courses'] as List;
      coursesList =
          coursesJson
              .map(
                (c) => {
                  'code': c['code'] as String? ?? '',
                  'title': c['title'] as String? ?? '',
                },
              )
              .toList();
    }
    return FacultyRatingAggregate(
      facultyId: json['faculty_id'] as String,
      facultyName: json['faculty_name'] as String,
      totalRatings: json['total_ratings'] as int,
      avgTeaching: (json['avg_teaching'] as num).toDouble(),
      avgAttendanceFlex: (json['avg_attendance_flex'] as num).toDouble(),
      avgSupportiveness: (json['avg_supportiveness'] as num).toDouble(),
      avgMarks: (json['avg_marks'] as num).toDouble(),
      avgOverall: (json['avg_overall'] as num).toDouble(),
      courses: coursesList,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  /// Check if has ratings
  bool get hasRatings => totalRatings > 0;

  /// Get rating category
  String get ratingCategory {
    if (avgOverall >= 8.0) return 'excellent';
    if (avgOverall >= 6.0) return 'good';
    if (avgOverall >= 4.0) return 'average';
    return 'poor';
  }
}
