import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/logger.dart';
import '../models/faculty_rating_aggregate.dart';

/// Cache service for faculty ratings using SharedPreferences
class FacultyRatingCacheService {
  static const String _tag = 'FacultyRatingCache';
  static const String _cacheKey = 'faculty_ratings_cache';
  static const String _timestampKey = 'faculty_ratings_cache_timestamp';
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Initialize cache service
  Future<void> initialize() async {
    try {
      Logger.d(_tag, 'Cache service initialized');
    } catch (e) {
      Logger.e(_tag, 'Error initializing cache', e);
    }
  }

  /// Save ratings to cache
  Future<void> saveRatings(List<FacultyRatingAggregate> ratings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ratingsJson = ratings.map((r) => r.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(ratingsJson));
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());

      Logger.d(_tag, 'Saved ${ratings.length} ratings to cache');
    } catch (e, stack) {
      Logger.e(_tag, 'Error saving ratings to cache', e, stack);
    }
  }

  /// Get cached ratings
  Future<List<FacultyRatingAggregate>> getCachedRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ratingsStr = prefs.getString(_cacheKey);
      final timestampStr = prefs.getString(_timestampKey);

      if (ratingsStr == null || timestampStr == null) {
        Logger.d(_tag, 'No cached ratings found');
        return [];
      }

      // Check if cache is fresh
      final cachedAt = DateTime.parse(timestampStr);
      final cacheAge = DateTime.now().difference(cachedAt);

      if (cacheAge > _cacheTTL) {
        Logger.d(_tag, 'Cache expired (age: ${cacheAge.inMinutes}m)');
        await clearCache();
        return [];
      }

      final ratingsJson = jsonDecode(ratingsStr) as List<dynamic>;
      final ratings =
          ratingsJson
              .map(
                (json) => FacultyRatingAggregate.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();

      Logger.d(_tag, 'Retrieved ${ratings.length} cached ratings');
      return ratings;
    } catch (e, stack) {
      Logger.e(_tag, 'Error getting cached ratings', e, stack);
      return [];
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      Logger.d(_tag, 'Cache cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing cache', e);
    }
  }

  /// Get cache count
  Future<int> getCacheCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsStr = prefs.getString(_cacheKey);
      if (ratingsStr == null) return 0;

      final ratingsJson = jsonDecode(ratingsStr) as List<dynamic>;
      return ratingsJson.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if cache is fresh
  Future<bool> isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_timestampKey);

      if (timestampStr == null) return false;

      final cachedAt = DateTime.parse(timestampStr);
      final cacheAge = DateTime.now().difference(cachedAt);

      return cacheAge < _cacheTTL;
    } catch (e) {
      return false;
    }
  }
}
