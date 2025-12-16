import '../../../../../core/utils/logger.dart';
import '../models/rating_model.dart';
import '../models/faculty_rating_response.dart';
import '../services/faculty_rating_api_service.dart';

/// Repository for managing rating submissions
class RatingRepository {
  static const String _tag = 'RatingRepository';

  /// Submit a rating for a faculty member
  Future<RatingSubmissionResponse> submitRating(RatingSubmission rating) async {
    try {
      Logger.i(_tag, 'Submitting rating for faculty: ${rating.facultyId}');

      // Validate rating
      if (!rating.isValid()) {
        Logger.w(_tag, 'Invalid rating submission');
        return RatingSubmissionResponse(
          success: false,
          message:
              'Invalid rating values. All ratings must be between 0 and 10.',
          error: 'Validation failed',
        );
      }

      // Submit to API
      final response = await FacultyRatingApiService.submitRating(rating);

      if (response.success) {
        Logger.i(_tag, 'Rating submitted successfully');
      } else {
        Logger.w(_tag, 'Rating submission failed: ${response.message}');
      }

      return response;
    } catch (e) {
      Logger.e(_tag, 'Error submitting rating', e);
      return RatingSubmissionResponse(
        success: false,
        message: 'Failed to submit rating. Please try again.',
        error: e.toString(),
      );
    }
  }

  /// Check if service is available
  Future<bool> isServiceAvailable() async {
    try {
      return await FacultyRatingApiService.isServiceAvailable();
    } catch (e) {
      Logger.e(_tag, 'Error checking service availability', e);
      return false;
    }
  }

  /// Check version compatibility
  Future<bool> checkCompatibility() async {
    try {
      return await FacultyRatingApiService.checkScriptCompatibility();
    } catch (e) {
      Logger.e(_tag, 'Error checking compatibility', e);
      return false;
    }
  }
}
