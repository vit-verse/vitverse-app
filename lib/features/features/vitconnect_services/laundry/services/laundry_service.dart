import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/config/env_config.dart';
import '../../../../../core/utils/logger.dart';
import '../models/laundry_schedule.dart';

/// Service to fetch and cache laundry schedule data
class LaundryService {
  static const String _tag = 'LaundryService';

  // GitHub API URL base path
  static const String _baseUrl =
      'https://api.github.com/repos/Kanishka-Developer/unmessify/contents/json/en';

  // GitHub Token for authentication
  static String get _githubToken => EnvConfig.githubVitconnectToken;

  // Cache key prefix
  static const String _cachePrefix = 'laundry_cache_';
  static const String _cacheTimestampPrefix = 'laundry_timestamp_';

  // Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Fetch laundry schedule from remote or cache
  /// fileName: e.g., 'VITC-A-L.json'
  static Future<List<LaundrySchedule>> fetchLaundrySchedule(
    String fileName,
  ) async {
    try {
      Logger.i(_tag, 'Fetching laundry schedule: $fileName');

      // Check cache first
      final cachedData = await _getCachedSchedule(fileName);
      if (cachedData != null) {
        Logger.i(_tag, 'Returning cached laundry schedule');
        return cachedData;
      }

      // Fetch from remote
      final url = '$_baseUrl/$fileName';
      Logger.d(_tag, 'Fetching from URL: $url');

      // Build headers - GitHub token auth for higher rate limits
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3.raw', // Get raw file content
      };

      // Add GitHub token if available (increases rate limit from 60 to 5000 req/hour)
      if (_githubToken.isNotEmpty) {
        headers['Authorization'] = 'token $_githubToken';
        Logger.d(_tag, 'Using GitHub token for authentication');
      } else {
        Logger.w(
          _tag,
          'No GitHub token found - using unauthenticated requests (lower rate limit)',
        );
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final scheduleResponse = LaundryScheduleResponse.fromJson(jsonData);

        Logger.i(
          _tag,
          'Successfully fetched ${scheduleResponse.items.length} schedule items',
        );

        // Cache the data
        await _cacheSchedule(fileName, scheduleResponse.items);

        return scheduleResponse.items;
      } else {
        Logger.w(
          _tag,
          'Failed to fetch schedule. Status: ${response.statusCode}',
        );
        throw Exception(
          'Failed to load laundry schedule: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error fetching laundry schedule: $e', stackTrace);

      // Try to return stale cache if available
      final staleCache = await _getStaleCache(fileName);
      if (staleCache != null) {
        Logger.i(_tag, 'Returning stale cache due to error');
        return staleCache;
      }

      rethrow;
    }
  }

  /// Get cached schedule if valid
  static Future<List<LaundrySchedule>?> _getCachedSchedule(
    String fileName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$fileName';
      final timestampKey = '$_cacheTimestampPrefix$fileName';

      final cachedJson = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Check if cache is still valid
      if (now.difference(cacheTime) < _cacheDuration) {
        final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
        final scheduleResponse = LaundryScheduleResponse.fromJson(jsonData);
        return scheduleResponse.items;
      }

      return null;
    } catch (e) {
      Logger.e(_tag, 'Error reading cache: $e');
      return null;
    }
  }

  /// Get stale cache (ignore timestamp)
  static Future<List<LaundrySchedule>?> _getStaleCache(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$fileName';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final scheduleResponse = LaundryScheduleResponse.fromJson(jsonData);
      return scheduleResponse.items;
    } catch (e) {
      Logger.e(_tag, 'Error reading stale cache: $e');
      return null;
    }
  }

  /// Cache schedule data
  static Future<void> _cacheSchedule(
    String fileName,
    List<LaundrySchedule> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$fileName';
      final timestampKey = '$_cacheTimestampPrefix$fileName';

      final scheduleResponse = LaundryScheduleResponse(items: items);
      final jsonString = jsonEncode(scheduleResponse.toJson());

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      Logger.d(_tag, 'Schedule cached successfully');
    } catch (e) {
      Logger.e(_tag, 'Error caching schedule: $e');
      // Don't rethrow - caching failure shouldn't stop the app
    }
  }

  /// Clear cache for specific file
  static Future<void> clearCache(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$fileName');
      await prefs.remove('$_cacheTimestampPrefix$fileName');
      Logger.i(_tag, 'Cache cleared for: $fileName');
    } catch (e) {
      Logger.e(_tag, 'Error clearing cache: $e');
    }
  }

  /// Clear all laundry caches
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) ||
            key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }

      Logger.i(_tag, 'All laundry caches cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing all caches: $e');
    }
  }

  /// Get next laundry date for a specific room
  static LaundrySchedule? getNextLaundryForRoom(
    List<LaundrySchedule> items,
    int roomNumber,
  ) {
    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    // Filter schedules that contain the room and are for the current month
    // Check if createdAt is in the current month
    final relevantSchedules =
        items.where((item) {
          if (!item.containsRoom(roomNumber)) return false;

          // Validate schedule is for current month by checking createdAt
          final createdMonth = item.createdAt.month;
          final createdYear = item.createdAt.year;

          // Only include if created in current month/year
          return createdYear == currentYear && createdMonth == currentMonth;
        }).toList();

    if (relevantSchedules.isEmpty) {
      Logger.d(
        _tag,
        'No schedules found for room: $roomNumber in current month',
      );
      return null;
    }

    // Find next upcoming laundry date in the current month only
    LaundrySchedule? nextSchedule;
    int? minDiff;

    for (final schedule in relevantSchedules) {
      final scheduleDate = schedule.dateNumber;
      if (scheduleDate == 0) continue;

      // Only consider dates in the current month that are >= today
      if (scheduleDate < currentDay) continue;

      // Create DateTime for this schedule date in current month
      final scheduleDateTime = DateTime(
        currentYear,
        currentMonth,
        scheduleDate,
      );

      final diff = scheduleDateTime.difference(now).inDays;
      if (diff >= 0 && (minDiff == null || diff < minDiff)) {
        minDiff = diff;
        nextSchedule = schedule;
      }
    }

    if (nextSchedule == null) {
      Logger.d(
        _tag,
        'No more laundry scheduled for room: $roomNumber this month',
      );
    }

    return nextSchedule;
  }

  /// Get schedule for specific date
  static LaundrySchedule? getScheduleForDate(
    List<LaundrySchedule> items,
    int date,
  ) {
    try {
      return items.firstWhere((item) => item.dateNumber == date);
    } catch (e) {
      return null;
    }
  }

  /// Get all schedules with room numbers (filter out null room numbers)
  static List<LaundrySchedule> getActiveSchedules(List<LaundrySchedule> items) {
    return items
        .where((item) => item.roomNumber != null && item.roomNumber!.isNotEmpty)
        .toList();
  }
}
