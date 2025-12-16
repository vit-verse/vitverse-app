import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/logger.dart';
import '../../../vtop_services/my_course_faculties/data/faculty_data_provider.dart';
import '../models/faculty_model.dart';
import '../models/faculty_rating_response.dart';
import '../services/faculty_rating_api_service.dart';

/// Repository for managing faculty data and ratings
class FacultyRepository {
  static const String _tag = 'FacultyRepository';

  // Cache keys
  static const String _cacheKeyRatings = 'faculty_ratings_cache';
  static const String _cacheKeyTimestamp = 'faculty_ratings_timestamp';
  static const Duration _cacheThreshold = Duration(hours: 5);

  final FacultyDataProvider _facultyDataProvider = FacultyDataProvider();

  /// Get all faculties from local database (from VTOP courses)
  Future<List<Faculty>> getFaculties() async {
    try {
      Logger.i(_tag, 'Fetching faculties from local database');

      final facultiesWithCourses =
          await _facultyDataProvider.getFacultiesWithCourses();

      final faculties =
          facultiesWithCourses.map((fwc) {
            String facultyId;
            if (fwc.facultyErpId == null || fwc.facultyErpId!.isEmpty) {
              facultyId = fwc.facultyName.hashCode.toString();
            } else if (int.tryParse(fwc.facultyErpId!) == null) {
              facultyId = fwc.facultyName.hashCode.toString();
            } else {
              facultyId = fwc.facultyErpId!;
            }

            return Faculty(
              facultyId: facultyId,
              name: fwc.facultyName,
              courseTitles:
                  fwc.courses
                      .map((c) => c.title ?? c.code ?? 'Unknown')
                      .toList(),
            );
          }).toList();

      Logger.i(_tag, 'Found ${faculties.length} faculties');
      return faculties;
    } catch (e) {
      Logger.e(_tag, 'Error fetching faculties', e);
      rethrow;
    }
  }

  /// Get faculties with ratings
  Future<List<Faculty>> getFacultiesWithRatings() async {
    try {
      // Get faculties from local database
      final faculties = await getFaculties();

      if (faculties.isEmpty) {
        Logger.w(_tag, 'No faculties found in local database');
        return [];
      }

      // Get faculty IDs
      final facultyIds = faculties.map((f) => f.facultyId).toList();

      // Fetch ratings from API
      Logger.i(_tag, 'Fetching ratings for ${facultyIds.length} faculties');
      final response = await FacultyRatingApiService.fetchRatings(facultyIds);

      if (!response.success || response.data == null) {
        Logger.w(_tag, 'Failed to fetch ratings: ${response.message}');
        return faculties; // Return faculties without ratings
      }

      // Map ratings to faculties
      final ratingsMap = <String, FacultyRatingData>{};
      for (final rating in response.data!) {
        ratingsMap[rating.facultyId] = rating;
      }

      // Update faculties with ratings
      final facultiesWithRatings =
          faculties.map((faculty) {
            final ratingData = ratingsMap[faculty.facultyId];
            if (ratingData != null) {
              return faculty.copyWith(
                ratingStats: FacultyRatingStats(
                  totalRatings: ratingData.totalRatings,
                  overallRating: ratingData.overallRating,
                  teachingRating: ratingData.teaching,
                  attendanceFlexRating: ratingData.attendanceFlex,
                  supportivenessRating: ratingData.supportiveness,
                  marksRating: ratingData.marks,
                  lastUpdated: ratingData.lastUpdated,
                ),
              );
            }
            return faculty;
          }).toList();

      Logger.i(
        _tag,
        'Loaded ${facultiesWithRatings.where((f) => f.ratingStats != null).length} faculties with ratings',
      );

      return facultiesWithRatings;
    } catch (e) {
      Logger.e(_tag, 'Error fetching faculties with ratings', e);
      rethrow;
    }
  }

  /// Refresh ratings for specific faculties
  Future<Map<String, FacultyRatingStats>> refreshRatings(
    List<String> facultyIds,
  ) async {
    try {
      Logger.i(_tag, 'Refreshing ratings for ${facultyIds.length} faculties');

      // Try to fetch from API
      final response = await FacultyRatingApiService.fetchRatings(facultyIds);

      if (!response.success || response.data == null) {
        Logger.w(_tag, 'Failed to refresh ratings: ${response.message}');

        // Try to load from cache as fallback
        final cachedRatings = await _loadCachedRatings();
        if (cachedRatings.isNotEmpty) {
          Logger.i(_tag, 'Using cached ratings as fallback');
          return cachedRatings;
        }

        return {};
      }

      final ratingsMap = <String, FacultyRatingStats>{};
      for (final rating in response.data!) {
        ratingsMap[rating.facultyId] = FacultyRatingStats(
          totalRatings: rating.totalRatings,
          overallRating: rating.overallRating,
          teachingRating: rating.teaching,
          attendanceFlexRating: rating.attendanceFlex,
          supportivenessRating: rating.supportiveness,
          marksRating: rating.marks,
          lastUpdated: rating.lastUpdated,
        );
      }

      // Cache the ratings permanently
      await _cacheRatings(ratingsMap);

      Logger.i(_tag, 'Refreshed ${ratingsMap.length} ratings');
      return ratingsMap;
    } catch (e) {
      Logger.e(_tag, 'Error refreshing ratings', e);

      // Try to load from cache as fallback on error
      final cachedRatings = await _loadCachedRatings();
      if (cachedRatings.isNotEmpty) {
        Logger.i(_tag, 'Using cached ratings due to error');
        return cachedRatings;
      }

      rethrow;
    }
  }

  /// Load cached ratings from SharedPreferences
  Future<Map<String, FacultyRatingStats>> _loadCachedRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKeyRatings);

      if (cachedJson == null) {
        return {};
      }

      final Map<String, dynamic> decodedMap = json.decode(cachedJson);
      final Map<String, FacultyRatingStats> ratingsMap = {};

      decodedMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          ratingsMap[key] = FacultyRatingStats(
            totalRatings: value['totalRatings'] ?? 0,
            overallRating: (value['overallRating'] ?? 0.0).toDouble(),
            teachingRating: (value['teachingRating'] ?? 0.0).toDouble(),
            attendanceFlexRating:
                (value['attendanceFlexRating'] ?? 0.0).toDouble(),
            supportivenessRating:
                (value['supportivenessRating'] ?? 0.0).toDouble(),
            marksRating: (value['marksRating'] ?? 0.0).toDouble(),
            lastUpdated:
                value['lastUpdated'] != null
                    ? DateTime.parse(value['lastUpdated'])
                    : DateTime.now(),
          );
        }
      });

      Logger.i(_tag, 'Loaded ${ratingsMap.length} ratings from cache');
      return ratingsMap;
    } catch (e) {
      Logger.e(_tag, 'Error loading cached ratings', e);
      return {};
    }
  }

  /// Cache ratings permanently to SharedPreferences
  Future<void> _cacheRatings(Map<String, FacultyRatingStats> ratingsMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> cacheMap = {};
      ratingsMap.forEach((key, stats) {
        cacheMap[key] = {
          'totalRatings': stats.totalRatings,
          'overallRating': stats.overallRating,
          'teachingRating': stats.teachingRating,
          'attendanceFlexRating': stats.attendanceFlexRating,
          'supportivenessRating': stats.supportivenessRating,
          'marksRating': stats.marksRating,
          'lastUpdated':
              stats.lastUpdated?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        };
      });

      await prefs.setString(_cacheKeyRatings, json.encode(cacheMap));
      await prefs.setInt(
        _cacheKeyTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );

      Logger.i(_tag, 'Cached ${ratingsMap.length} ratings permanently');
    } catch (e) {
      Logger.e(_tag, 'Error caching ratings', e);
    }
  }

  /// Check if cache is still fresh (within threshold)
  Future<bool> isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheKeyTimestamp);

      if (timestamp == null) {
        return false;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);

      return age < _cacheThreshold;
    } catch (e) {
      return false;
    }
  }
}
