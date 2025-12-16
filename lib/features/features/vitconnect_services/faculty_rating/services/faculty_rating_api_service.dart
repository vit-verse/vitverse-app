import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../../../core/utils/logger.dart';
import '../../../../../../../core/config/app_version.dart';
import '../models/faculty_rating_response.dart';
import '../models/rating_model.dart';
import '../utils/rating_constants.dart';

/// Google Sheets API Service for Faculty Rating
/// Handles all CRUD operations with Google Apps Script backend
/// Uses FACULTY_RATING_SCRIPT_URL from .env file
///
/// Version: 1.1.0
/// Compatible with Google Apps Script versions: 1.x.x
class FacultyRatingApiService {
  // ============================================================================
  // VERSION MANAGEMENT
  // ============================================================================

  /// App version
  static String get _appVersion => FacultyRatingConstants.appVersion;

  /// Minimum supported script version
  static const String _minSupportedScriptVersion =
      FacultyRatingConstants.minSupportedScriptVersion;

  /// Cached script version
  static String? _cachedScriptVersion;
  static DateTime? _scriptVersionCheckTime;

  // Base URL loaded from .env
  static String _baseUrlValue = '';

  /// Initialize the API service with the base URL from .env
  /// MUST be called in main.dart after dotenv.load()
  static void initialize(String googleScriptUrl) {
    if (googleScriptUrl.isEmpty) {
      Logger.w(
        _tag,
        'initialize() called with empty URL. This might cause API failures.',
      );
    }
    _baseUrlValue = googleScriptUrl;
    Logger.i(
      _tag,
      'Initialized with Google Apps Script URL: ${googleScriptUrl.substring(0, 50)}...',
    );
  }

  /// Get the base URL
  static String get _baseUrl {
    if (_baseUrlValue.isEmpty) {
      const message =
          'Faculty Rating Script URL not initialized. '
          'Make sure FacultyRatingApiService.initialize(scriptUrl) is called in main.dart '
          'after loading .env file.';
      Logger.e(_tag, message, null);
      throw Exception(message);
    }
    return _baseUrlValue;
  }

  /// Manually set the base URL (useful for testing)
  static void setBaseUrlForTesting(String url) {
    _baseUrlValue = url;
    Logger.i(_tag, 'Base URL updated for testing');
  }

  static const String _tag = 'FacultyRatingAPI';

  // ============================================================================
  // VERSION CHECK
  // ============================================================================

  /// Check script version compatibility
  static Future<bool> checkScriptCompatibility() async {
    try {
      // Use cached version if checked recently
      if (_cachedScriptVersion != null && _scriptVersionCheckTime != null) {
        final timeDiff = DateTime.now().difference(_scriptVersionCheckTime!);
        if (timeDiff.inMinutes < 5) {
          Logger.i(_tag, 'Using cached script version: $_cachedScriptVersion');
          return _isVersionCompatible(_cachedScriptVersion!);
        }
      }

      Logger.i(_tag, 'Checking script version compatibility...');
      final response = await http
          .get(
            Uri.parse('$_baseUrl?action=getVersion&v=$_appVersion'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(FacultyRatingConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scriptVersion = data['scriptVersion'] as String? ?? 'unknown';

        _cachedScriptVersion = scriptVersion;
        _scriptVersionCheckTime = DateTime.now();

        Logger.i(
          _tag,
          'Version check: App=$_appVersion, Script=$scriptVersion',
        );

        if (!_isVersionCompatible(scriptVersion)) {
          Logger.w(
            _tag,
            'Version mismatch! Min required: $_minSupportedScriptVersion, Got: $scriptVersion',
          );
          return false;
        }

        return true;
      } else {
        Logger.w(_tag, 'Version check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.e(_tag, 'Version check error', e);
      return false;
    }
  }

  /// Check if script version is compatible
  static bool _isVersionCompatible(String scriptVersion) {
    if (scriptVersion == 'unknown') return false;

    try {
      final scriptParts = scriptVersion.split('.').map(int.parse).toList();
      final minParts =
          _minSupportedScriptVersion.split('.').map(int.parse).toList();

      // Major version must match
      if (scriptParts[0] != minParts[0]) return false;

      // Minor version must be >= minimum
      if (scriptParts[1] < minParts[1]) return false;

      return true;
    } catch (e) {
      Logger.e(_tag, 'Error parsing version numbers', e);
      return false;
    }
  }

  /// Get version info
  static Future<VersionCheckResponse> getVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl?action=getVersion&v=$_appVersion'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(FacultyRatingConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VersionCheckResponse.fromJson(data);
      } else {
        throw Exception('Failed to get version: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e(_tag, 'Error getting version', e);
      rethrow;
    }
  }

  // ============================================================================
  // FETCH RATINGS
  // ============================================================================

  /// Fetch ratings for specific faculty members
  /// [facultyIds] - List of faculty ERP IDs
  static Future<FacultyRatingResponse> fetchRatings(
    List<String> facultyIds,
  ) async {
    try {
      Logger.i(
        _tag,
        'Fetching ratings for ${facultyIds.length} faculty members',
      );

      final queryParams = {
        'action': 'getRatings',
        'faculty_ids': facultyIds.join(','),
        'v': _appVersion,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(FacultyRatingConstants.apiTimeout);

      Logger.d(_tag, 'Response status: ${response.statusCode}');
      Logger.d(_tag, 'Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = FacultyRatingResponse.fromJson(data);

        if (result.success) {
          Logger.i(
            _tag,
            'Successfully fetched ratings for ${result.data?.length ?? 0} faculty',
          );
        } else {
          Logger.w(_tag, 'Fetch ratings failed: ${result.message}');
        }

        return result;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.e(_tag, 'Error fetching ratings', e);
      return FacultyRatingResponse(
        success: false,
        message: 'Failed to fetch ratings',
        error: e.toString(),
      );
    }
  }

  // ============================================================================
  // SUBMIT RATING
  // ============================================================================

  /// Submit a rating for a faculty member
  static Future<RatingSubmissionResponse> submitRating(
    RatingSubmission rating,
  ) async {
    try {
      if (!rating.isValid()) {
        return RatingSubmissionResponse(
          success: false,
          message: 'Invalid rating values',
          error: 'All ratings must be between 0 and 10',
        );
      }

      Logger.i(_tag, 'Submitting rating for faculty: ${rating.facultyId}');
      Logger.d(_tag, 'Rating details: $rating');

      // Convert all values to strings for application/x-www-form-urlencoded
      final body = {
        'action': 'submitRating',
        'v': _appVersion,
        'faculty_id': rating.facultyId,
        'faculty_name': rating.facultyName,
        'teaching': rating.teaching.toString(),
        'attendance_flex': rating.attendanceFlex.toString(),
        'supportiveness': rating.supportiveness.toString(),
        'marks': rating.marks.toString(),
        'overall_rating': rating.overallRating.toString(),
        'timestamp': rating.timestamp.toIso8601String(),
      };

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(FacultyRatingConstants.apiTimeout);

      Logger.d(_tag, 'Response status: ${response.statusCode}');
      Logger.d(_tag, 'Response body: ${response.body}');

      // Google Apps Script may return 302 redirect which is actually success
      // Treat both 200 and 302 as success
      if (response.statusCode == 200 || response.statusCode == 302) {
        // For 302, the body might be HTML redirect page
        // Check if body contains JSON
        if (response.body.trim().startsWith('{')) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final result = RatingSubmissionResponse.fromJson(data);

            if (result.success) {
              Logger.i(_tag, 'Rating submitted successfully');
            } else {
              Logger.w(_tag, 'Rating submission failed: ${result.message}');
            }

            return result;
          } catch (e) {
            Logger.w(
              _tag,
              'Failed to parse JSON response, treating as success',
            );
          }
        }

        // If we get here with 302 or can't parse JSON, assume success
        Logger.i(
          _tag,
          'Rating submitted successfully (status: ${response.statusCode})',
        );
        return RatingSubmissionResponse(
          success: true,
          message: 'Rating submitted successfully',
        );
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.e(_tag, 'Error submitting rating', e);
      return RatingSubmissionResponse(
        success: false,
        message: 'Failed to submit rating',
        error: e.toString(),
      );
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Clear cached version (for testing)
  static void clearVersionCache() {
    _cachedScriptVersion = null;
    _scriptVersionCheckTime = null;
    Logger.i(_tag, 'Version cache cleared');
  }

  /// Check if service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final version = await getVersion();
      return !version.isMaintenanceMode;
    } catch (e) {
      Logger.e(_tag, 'Service availability check failed', e);
      return false;
    }
  }
}
