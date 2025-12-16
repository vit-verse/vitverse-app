import '../models/faculty_model.dart';
import '../models/rating_model.dart';

/// Base class for faculty rating events
abstract class FacultyRatingEvent {
  const FacultyRatingEvent();
}

/// Event to load faculties with ratings
class LoadFacultiesEvent extends FacultyRatingEvent {
  const LoadFacultiesEvent();
}

/// Event to refresh ratings
class RefreshRatingsEvent extends FacultyRatingEvent {
  final List<Faculty> faculties;

  const RefreshRatingsEvent(this.faculties);
}

/// Event to submit a rating
class SubmitRatingEvent extends FacultyRatingEvent {
  final RatingSubmission rating;

  const SubmitRatingEvent(this.rating);
}

/// Event to refresh specific faculty rating
class RefreshSingleFacultyRatingEvent extends FacultyRatingEvent {
  final String facultyId;

  const RefreshSingleFacultyRatingEvent(this.facultyId);
}

/// Event to check service availability
class CheckServiceAvailabilityEvent extends FacultyRatingEvent {
  const CheckServiceAvailabilityEvent();
}
