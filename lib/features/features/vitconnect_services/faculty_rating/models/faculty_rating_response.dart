/// API response models for faculty rating operations

/// Response from fetching faculty ratings
class FacultyRatingResponse {
  final bool success;
  final String message;
  final List<FacultyRatingData>? data;
  final String? error;

  FacultyRatingResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory FacultyRatingResponse.fromJson(Map<String, dynamic> json) {
    return FacultyRatingResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data:
          json['data'] != null
              ? (json['data'] as List<dynamic>)
                  .map(
                    (e) =>
                        FacultyRatingData.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.map((e) => e.toJson()).toList(),
      if (error != null) 'error': error,
    };
  }
}

/// Individual faculty rating data from API
class FacultyRatingData {
  final String facultyId;
  final String name;
  final int totalRatings;
  final double overallRating;
  final double teaching;
  final double attendanceFlex;
  final double supportiveness;
  final double marks;
  final DateTime? lastUpdated;

  FacultyRatingData({
    required this.facultyId,
    required this.name,
    required this.totalRatings,
    required this.overallRating,
    required this.teaching,
    required this.attendanceFlex,
    required this.supportiveness,
    required this.marks,
    this.lastUpdated,
  });

  factory FacultyRatingData.fromJson(Map<String, dynamic> json) {
    return FacultyRatingData(
      facultyId: json['faculty_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0.0,
      teaching: (json['teaching'] as num?)?.toDouble() ?? 0.0,
      attendanceFlex: (json['attendance_flex'] as num?)?.toDouble() ?? 0.0,
      supportiveness: (json['supportiveness'] as num?)?.toDouble() ?? 0.0,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          json['last_updated'] != null
              ? DateTime.tryParse(json['last_updated'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'name': name,
      'total_ratings': totalRatings,
      'overall_rating': overallRating,
      'teaching': teaching,
      'attendance_flex': attendanceFlex,
      'supportiveness': supportiveness,
      'marks': marks,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }
}

/// Response from submitting a rating
class RatingSubmissionResponse {
  final bool success;
  final String message;
  final String? error;

  RatingSubmissionResponse({
    required this.success,
    required this.message,
    this.error,
  });

  factory RatingSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return RatingSubmissionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (error != null) 'error': error,
    };
  }
}

/// Response from version check
class VersionCheckResponse {
  final String scriptVersion;
  final String maintenanceMode;
  final String? message;

  VersionCheckResponse({
    required this.scriptVersion,
    required this.maintenanceMode,
    this.message,
  });

  factory VersionCheckResponse.fromJson(Map<String, dynamic> json) {
    return VersionCheckResponse(
      scriptVersion: json['scriptVersion'] as String? ?? 'unknown',
      maintenanceMode: json['maintenanceMode'] as String? ?? 'false',
      message: json['message'] as String?,
    );
  }

  bool get isMaintenanceMode => maintenanceMode.toLowerCase() == 'true';
}
