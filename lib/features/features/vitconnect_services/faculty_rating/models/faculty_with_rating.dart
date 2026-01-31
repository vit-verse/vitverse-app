import 'faculty_rating_aggregate.dart';

/// Course information for display
class SimpleCourseInfo {
  final String code;
  final String title;

  SimpleCourseInfo({required this.code, required this.title});
}

/// Faculty information with rating data
class FacultyWithRating {
  final String facultyId;
  final String facultyName;
  final List<String> courseTitles;
  final List<SimpleCourseInfo> courses;
  final FacultyRatingAggregate? ratingData;

  FacultyWithRating({
    required this.facultyId,
    required this.facultyName,
    required this.courseTitles,
    required this.courses,
    this.ratingData,
  });

  /// Check if has rating data
  bool get hasRatings => ratingData?.hasRatings ?? false;

  /// Copy with new rating data
  FacultyWithRating copyWith({
    String? facultyId,
    String? facultyName,
    List<String>? courseTitles,
    List<SimpleCourseInfo>? courses,
    FacultyRatingAggregate? ratingData,
  }) {
    return FacultyWithRating(
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      courseTitles: courseTitles ?? this.courseTitles,
      courses: courses ?? this.courses,
      ratingData: ratingData ?? this.ratingData,
    );
  }
}
