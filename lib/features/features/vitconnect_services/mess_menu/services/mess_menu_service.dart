import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/config/env_config.dart';
import '../../../../../core/utils/logger.dart';
import '../models/mess_menu_item.dart';

/// Service to fetch and cache mess menu data
class MessMenuService {
  static const String _tag = 'MessMenuService';

  // GitHub API URL base path
  static const String _baseUrl =
      'https://api.github.com/repos/Kanishka-Developer/unmessify/contents/json/en';

  // GitHub Token for authentication
  static String get _githubToken => EnvConfig.githubVitconnectToken;

  // Cache key prefix
  static const String _cachePrefix = 'mess_menu_cache_';
  static const String _cacheTimestampPrefix = 'mess_menu_timestamp_';

  // Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Fetch mess menu from remote or cache
  /// fileName: e.g., 'VITC-M-V.json'
  static Future<List<MessMenuItem>> fetchMessMenu(String fileName) async {
    try {
      Logger.i(_tag, 'Fetching mess menu: $fileName');

      // Check cache first
      final cachedData = await _getCachedMenu(fileName);
      if (cachedData != null) {
        Logger.i(_tag, 'Returning cached mess menu');
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
        final menuResponse = MessMenuResponse.fromJson(jsonData);

        Logger.i(
          _tag,
          'Successfully fetched ${menuResponse.items.length} menu items',
        );

        // Cache the data
        await _cacheMenu(fileName, menuResponse.items);

        return menuResponse.items;
      } else {
        Logger.w(_tag, 'Failed to fetch menu. Status: ${response.statusCode}');
        throw Exception('Failed to load mess menu: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error fetching mess menu: $e', stackTrace);

      // Try to return stale cache if available
      final staleCache = await _getStaleCache(fileName);
      if (staleCache != null) {
        Logger.i(_tag, 'Returning stale cache due to error');
        return staleCache;
      }

      rethrow;
    }
  }

  /// Get cached menu if valid
  static Future<List<MessMenuItem>?> _getCachedMenu(String fileName) async {
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
        final menuResponse = MessMenuResponse.fromJson(jsonData);
        return menuResponse.items;
      }

      return null;
    } catch (e) {
      Logger.e(_tag, 'Error reading cache: $e');
      return null;
    }
  }

  /// Get stale cache (ignore timestamp)
  static Future<List<MessMenuItem>?> _getStaleCache(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$fileName';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final menuResponse = MessMenuResponse.fromJson(jsonData);
      return menuResponse.items;
    } catch (e) {
      Logger.e(_tag, 'Error reading stale cache: $e');
      return null;
    }
  }

  /// Cache menu data
  static Future<void> _cacheMenu(
    String fileName,
    List<MessMenuItem> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$fileName';
      final timestampKey = '$_cacheTimestampPrefix$fileName';

      final menuResponse = MessMenuResponse(items: items);
      final jsonString = jsonEncode(menuResponse.toJson());

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      Logger.d(_tag, 'Menu cached successfully');
    } catch (e) {
      Logger.e(_tag, 'Error caching menu: $e');
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

  /// Clear all mess menu caches
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

      Logger.i(_tag, 'All mess menu caches cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing all caches: $e');
    }
  }

  /// Get menu item for specific day
  static MessMenuItem? getMenuForDay(List<MessMenuItem> items, String day) {
    try {
      return items.firstWhere(
        (item) => item.day.toLowerCase() == day.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get menu item for today
  static MessMenuItem? getTodayMenu(List<MessMenuItem> items) {
    final today = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayName = dayNames[today.weekday - 1];
    return getMenuForDay(items, todayName);
  }
}
