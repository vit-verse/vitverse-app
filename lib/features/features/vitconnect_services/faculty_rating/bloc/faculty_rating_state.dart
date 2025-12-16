import '../models/faculty_model.dart';

/// Base class for faculty rating states
abstract class FacultyRatingState {
  const FacultyRatingState();
}

/// Initial state
class FacultyRatingInitial extends FacultyRatingState {
  const FacultyRatingInitial();
}

/// Loading faculties state
class FacultyRatingLoading extends FacultyRatingState {
  final String? message;

  const FacultyRatingLoading({this.message});
}

/// Faculties loaded successfully
class FacultyRatingLoaded extends FacultyRatingState {
  final List<Faculty> faculties;
  final DateTime lastUpdated;
  final bool isRefreshing;
  final String? refreshingFacultyId;

  const FacultyRatingLoaded({
    required this.faculties,
    required this.lastUpdated,
    this.isRefreshing = false,
    this.refreshingFacultyId,
  });

  /// Copy with new data
  FacultyRatingLoaded copyWith({
    List<Faculty>? faculties,
    DateTime? lastUpdated,
    bool? isRefreshing,
    String? refreshingFacultyId,
    bool clearRefreshingId = false,
  }) {
    return FacultyRatingLoaded(
      faculties: faculties ?? this.faculties,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshingFacultyId:
          clearRefreshingId
              ? null
              : (refreshingFacultyId ?? this.refreshingFacultyId),
    );
  }

  /// Update specific faculty
  FacultyRatingLoaded updateFaculty(Faculty updatedFaculty) {
    final updatedList =
        faculties.map((f) {
          if (f.facultyId == updatedFaculty.facultyId) {
            return updatedFaculty;
          }
          return f;
        }).toList();

    return copyWith(faculties: updatedList);
  }
}

/// Error state
class FacultyRatingError extends FacultyRatingState {
  final String message;
  final String? error;
  final List<Faculty>? cachedFaculties;

  const FacultyRatingError({
    required this.message,
    this.error,
    this.cachedFaculties,
  });
}

/// Rating submission states
class RatingSubmissionInProgress extends FacultyRatingState {
  final String facultyId;

  const RatingSubmissionInProgress(this.facultyId);
}

class RatingSubmissionSuccess extends FacultyRatingState {
  final String message;
  final String facultyId;

  const RatingSubmissionSuccess({
    required this.message,
    required this.facultyId,
  });
}

class RatingSubmissionFailure extends FacultyRatingState {
  final String message;
  final String? error;

  const RatingSubmissionFailure({required this.message, this.error});
}

/// Service status states
class ServiceUnavailable extends FacultyRatingState {
  final String message;

  const ServiceUnavailable(this.message);
}

class ServiceMaintenance extends FacultyRatingState {
  final String message;

  const ServiceMaintenance(this.message);
}
