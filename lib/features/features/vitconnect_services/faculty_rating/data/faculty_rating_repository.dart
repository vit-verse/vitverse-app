import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../../../../../core/utils/logger.dart';
import '../models/student_faculty_rating.dart';
import '../models/faculty_rating_aggregate.dart';
import 'faculty_rating_cache_service.dart';

/// Faculty Rating repository
/// Handles all data operations with Supabase
class FacultyRatingRepository {
  static const String _tag = 'FacultyRatingRepo';

  final SupabaseClient _supabase = SupabaseClientService.client;
  final _cacheService = FacultyRatingCacheService();

  /// Initialize repository
  Future<void> initialize() async {
    await _cacheService.initialize();
  }

  /// Get aggregated ratings for specific faculty members (cache-first)
  Future<List<FacultyRatingAggregate>> getRatings(
    List<String> facultyIds,
  ) async {
    try {
      // Try cache first
      final cached = await _cacheService.getCachedRatings();
      if (cached.isNotEmpty) {
        Logger.d(_tag, 'Showing ${cached.length} cached ratings');
        // Refresh in background
        _refreshInBackground(facultyIds);
        return cached;
      }

      // No cache - fetch from Supabase
      return await _fetchFromSupabase(facultyIds);
    } catch (e, stack) {
      Logger.e(_tag, 'Error getting ratings', e, stack);
      return [];
    }
  }

  /// Fetch ratings from Supabase
  Future<List<FacultyRatingAggregate>> _fetchFromSupabase(
    List<String> facultyIds,
  ) async {
    try {
      Logger.d(_tag, 'Fetching ratings for ${facultyIds.length} faculties');

      final response = await _supabase
          .from('faculty_rating_aggregates')
          .select()
          .inFilter('faculty_id', facultyIds)
          .order('last_updated', ascending: false);

      final ratings =
          (response as List)
              .map((e) => FacultyRatingAggregate.fromMap(e))
              .toList();

      // Cache ratings locally
      Logger.d(_tag, 'Caching ${ratings.length} ratings...');
      await _cacheService.saveRatings(ratings);

      Logger.success(
        _tag,
        'Fetched ${ratings.length} ratings (${await _cacheService.getCacheCount()} cached)',
      );

      return ratings;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching from Supabase', e, stack);
      rethrow;
    }
  }

  /// Refresh in background
  void _refreshInBackground(List<String> facultyIds) async {
    try {
      final ratings = await _fetchFromSupabase(facultyIds);
      Logger.d(_tag, 'Background refresh: ${ratings.length} ratings');
    } catch (e) {
      Logger.w(_tag, 'Background refresh failed: $e');
    }
  }

  /// Submit rating (replaces old rating if exists)
  Future<void> submitRating({
    required String studentRegno,
    required String facultyId,
    required String facultyName,
    required double teaching,
    required double attendanceFlex,
    required double supportiveness,
    required double marks,
    List<CourseInfo> courses = const [],
  }) async {
    try {
      Logger.d(_tag, 'Submitting rating for faculty: $facultyId');

      final rating = StudentFacultyRating(
        id: const Uuid().v4(),
        studentRegno: studentRegno,
        facultyId: facultyId,
        facultyName: facultyName,
        teaching: teaching,
        attendanceFlex: attendanceFlex,
        supportiveness: supportiveness,
        marks: marks,
        courses: courses,
        submittedAt: DateTime.now(),
      );

      // Validate
      if (!rating.isValid()) {
        throw Exception(
          'Invalid rating values. All ratings must be between 0 and 10.',
        );
      }

      // Step 1: Delete old rating (same student + faculty)
      Logger.d(_tag, 'Deleting old rating if exists...');
      await _supabase
          .from('faculty_ratings')
          .delete()
          .eq('student_regno', studentRegno)
          .eq('faculty_id', facultyId);

      // Step 2: Insert new rating
      Logger.d(_tag, 'Inserting new rating...');
      await _supabase.from('faculty_ratings').insert(rating.toMap());

      // Step 3: Clear cache to force refresh
      await _cacheService.clearCache();

      Logger.success(_tag, 'Rating submitted successfully');
    } catch (e, stack) {
      Logger.e(_tag, 'Error submitting rating', e, stack);
      rethrow;
    }
  }

  /// Get student's rating for a specific faculty
  Future<StudentFacultyRating?> getMyRating({
    required String studentRegno,
    required String facultyId,
  }) async {
    try {
      Logger.d(
        _tag,
        'Fetching rating: student=$studentRegno, faculty=$facultyId',
      );

      final response =
          await _supabase
              .from('faculty_ratings')
              .select()
              .eq('student_regno', studentRegno)
              .eq('faculty_id', facultyId)
              .maybeSingle();

      if (response == null) {
        Logger.d(_tag, 'No rating found');
        return null;
      }

      final rating = StudentFacultyRating.fromMap(response);
      Logger.d(_tag, 'Found existing rating');
      return rating;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching student rating', e, stack);
      return null;
    }
  }

  /// Force refresh ratings
  Future<List<FacultyRatingAggregate>> forceRefresh(
    List<String> facultyIds,
  ) async {
    try {
      await _cacheService.clearCache();
      return await _fetchFromSupabase(facultyIds);
    } catch (e, stack) {
      Logger.e(_tag, 'Force refresh failed', e, stack);
      rethrow;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Get all faculty ratings from Supabase
  Future<List<FacultyRatingAggregate>> getAllFacultyRatings() async {
    try {
      Logger.d(_tag, 'Fetching all faculty ratings from Supabase');

      final response = await _supabase
          .from('faculty_rating_aggregates')
          .select()
          .order('last_updated', ascending: false);

      final ratings =
          (response as List)
              .map((e) => FacultyRatingAggregate.fromMap(e))
              .toList();

      Logger.success(_tag, 'Fetched ${ratings.length} faculty ratings');

      return ratings;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching all faculty ratings', e, stack);
      rethrow;
    }
  }
}
