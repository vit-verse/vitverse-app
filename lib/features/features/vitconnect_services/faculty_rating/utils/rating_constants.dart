import '../../../../../core/config/app_version.dart';

/// Constants for faculty rating feature
class FacultyRatingConstants {
  // ============================================================================
  // API & VERSION CONFIGURATION
  // ============================================================================

  /// App version for faculty rating feature
  static String get appVersion => AppVersion.version;

  /// Minimum supported script version
  static const String minSupportedScriptVersion = '1.0.0';

  // ============================================================================
  // CACHE & REFRESH CONFIGURATION
  // ============================================================================

  /// Cache duration for faculty ratings (5 minutes)
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Timeout for API requests
  static const Duration apiTimeout = Duration(seconds: 10);

  /// Version check cache duration
  static const Duration versionCheckCacheDuration = Duration(minutes: 5);

  // ============================================================================
  // RATING CONFIGURATION
  // ============================================================================

  /// Minimum rating value
  static const double minRating = 0.0;

  /// Maximum rating value
  static const double maxRating = 10.0;

  /// Default rating value
  static const double defaultRating = 5.0;

  /// Number of rating parameters
  static const int ratingParametersCount = 4;

  /// Minimum ratings required to show statistics
  static const int minRatingsForStats = 1;

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================

  /// Rating card elevation
  static const double cardElevation = 2.0;

  /// Rating card border radius
  static const double cardBorderRadius = 12.0;

  /// Slider divisions (for star rating from 0-10)
  static const int sliderDivisions = 20; // 0.5 increments

  /// Star size for display
  static const double starSize = 16.0;

  /// Large star size for rating input
  static const double largeStarSize = 24.0;

  // ============================================================================
  // PRIVACY & SECURITY
  // ============================================================================

  /// Privacy notice text
  static const String privacyNotice =
      ' Anonymous & Secure\n'
      'Your identity is never stored or shared.\n\n'
      ' Help the Community\n'
      'Your honest ratings help make better choices during FFCS.';

  // ============================================================================
  // RATING CATEGORIES
  // ============================================================================

  /// Get rating category color key based on rating value
  static String getRatingCategory(double rating) {
    if (rating >= 8.0) return 'excellent';
    if (rating >= 6.0) return 'good';
    if (rating >= 4.0) return 'average';
    return 'poor';
  }

  /// Get rating category label
  static String getRatingLabel(double rating) {
    if (rating >= 8.0) return 'Excellent';
    if (rating >= 6.0) return 'Good';
    if (rating >= 4.0) return 'Average';
    if (rating >= 2.0) return 'Below Average';
    return 'Poor';
  }

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  static const String errorNetworkFailure =
      'Network error. Please check your connection.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorInvalidData = 'Invalid data received from server.';
  static const String errorSubmissionFailed = 'Failed to submit rating.';
  static const String errorFetchFailed = 'Failed to fetch faculty ratings.';
  static const String errorMaintenanceMode =
      'Service is under maintenance. Please try again later.';
  static const String errorVersionMismatch =
      'App needs to be updated. Please update from the store.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String successRatingSubmitted =
      'Rating submitted successfully! Thank you for your feedback.';
  static const String successRatingsRefreshed =
      'Ratings refreshed successfully.';
}
