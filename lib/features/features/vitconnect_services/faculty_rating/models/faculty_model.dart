/// Model representing a faculty member for rating
class Faculty {
  final String facultyId; // ERP ID
  final String name;
  final List<String> courseTitles;
  final FacultyRatingStats? ratingStats;

  Faculty({
    required this.facultyId,
    required this.name,
    required this.courseTitles,
    this.ratingStats,
  });

  /// Create from CourseInfo (from my_course_faculties)
  factory Faculty.fromCourseInfo({
    required String facultyErpId,
    required String facultyName,
    required List<String> courses,
  }) {
    return Faculty(
      facultyId: facultyErpId,
      name: facultyName,
      courseTitles: courses,
    );
  }

  /// Create from JSON
  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      facultyId: json['faculty_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      courseTitles:
          (json['course_titles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ratingStats:
          json['rating_stats'] != null
              ? FacultyRatingStats.fromJson(
                json['rating_stats'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'name': name,
      'course_titles': courseTitles,
      if (ratingStats != null) 'rating_stats': ratingStats!.toJson(),
    };
  }

  /// Copy with new rating stats
  Faculty copyWith({
    String? facultyId,
    String? name,
    List<String>? courseTitles,
    FacultyRatingStats? ratingStats,
  }) {
    return Faculty(
      facultyId: facultyId ?? this.facultyId,
      name: name ?? this.name,
      courseTitles: courseTitles ?? this.courseTitles,
      ratingStats: ratingStats ?? this.ratingStats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Faculty && other.facultyId == facultyId;
  }

  @override
  int get hashCode => facultyId.hashCode;
}

/// Faculty rating statistics
class FacultyRatingStats {
  final int totalRatings;
  final double overallRating;
  final double teachingRating;
  final double attendanceFlexRating;
  final double supportivenessRating;
  final double marksRating;
  final DateTime? lastUpdated;

  FacultyRatingStats({
    required this.totalRatings,
    required this.overallRating,
    required this.teachingRating,
    required this.attendanceFlexRating,
    required this.supportivenessRating,
    required this.marksRating,
    this.lastUpdated,
  });

  /// Create from JSON
  factory FacultyRatingStats.fromJson(Map<String, dynamic> json) {
    return FacultyRatingStats(
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0.0,
      teachingRating: (json['teaching'] as num?)?.toDouble() ?? 0.0,
      attendanceFlexRating:
          (json['attendance_flex'] as num?)?.toDouble() ?? 0.0,
      supportivenessRating: (json['supportiveness'] as num?)?.toDouble() ?? 0.0,
      marksRating: (json['marks'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          json['last_updated'] != null
              ? DateTime.tryParse(json['last_updated'] as String)
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_ratings': totalRatings,
      'overall_rating': overallRating,
      'teaching': teachingRating,
      'attendance_flex': attendanceFlexRating,
      'supportiveness': supportivenessRating,
      'marks': marksRating,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }

  /// Check if has valid ratings
  bool get hasRatings => totalRatings > 0;

  /// Get rating color based on overall rating
  String get ratingCategory {
    if (overallRating >= 8.0) return 'excellent';
    if (overallRating >= 6.0) return 'good';
    if (overallRating >= 4.0) return 'average';
    return 'poor';
  }
}
