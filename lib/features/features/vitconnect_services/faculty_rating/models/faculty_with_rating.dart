import 'faculty_rating_aggregate.dart';

/// Faculty information with rating data
class FacultyWithRating {
  final String facultyId;
  final String facultyName;
  final List<String> courseTitles;
  final FacultyRatingAggregate? ratingData;

  FacultyWithRating({
    required this.facultyId,
    required this.facultyName,
    required this.courseTitles,
    this.ratingData,
  });

  /// Check if has rating data
  bool get hasRatings => ratingData?.hasRatings ?? false;

  /// Copy with new rating data
  FacultyWithRating copyWith({
    String? facultyId,
    String? facultyName,
    List<String>? courseTitles,
    FacultyRatingAggregate? ratingData,
  }) {
    return FacultyWithRating(
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      courseTitles: courseTitles ?? this.courseTitles,
      ratingData: ratingData ?? this.ratingData,
    );
  }
}
