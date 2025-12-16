import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calendar_metadata.dart';
import '../models/calendar_event.dart';
import '../../../core/utils/logger.dart';
import 'calendar_cache_service.dart';

/// Result class to track refresh status
class RefreshResult<T> {
  final T? data;
  final bool isFromNetwork;
  final bool isFromCache;
  final String? error;
  final bool isExpiredCache;

  const RefreshResult({
    this.data,
    this.isFromNetwork = false,
    this.isFromCache = false,
    this.error,
    this.isExpiredCache = false,
  });

  bool get isSuccess => data != null;
  bool get isNetworkSuccess => isFromNetwork && data != null;
  bool get isCacheFallback => isFromCache && !isFromNetwork;
}

class CalendarRepository {
  static const String _baseUrl =
      'https://raw.githubusercontent.com/vit-verse/vit-academic-calendar/main';
  static const String _metadataUrl = '$_baseUrl/metadata.json';

  final String? _githubToken;
  final CalendarCacheService _cacheService;

  CalendarRepository({String? githubToken})
    : _githubToken = githubToken,
      _cacheService = CalendarCacheService();

  /// Initialize repository
  Future<void> initialize() async {
    try {
      Logger.d('CalendarRepository', 'Initializing repository...');
      await _cacheService.initialize();
      Logger.i('CalendarRepository', 'Repository initialized successfully');
    } catch (e) {
      Logger.e('CalendarRepository', 'Failed to initialize repository', e);
      rethrow;
    }
  }

  /// Check if network is available by testing GitHub connectivity
  Future<bool> checkNetworkConnectivity() async {
    try {
      final response = await http
          .head(Uri.parse('https://api.github.com'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      Logger.e('CalendarRepository', 'Network connectivity check failed', e);
      return false;
    }
  }

  /// Fetch calendar metadata with optimal caching
  Future<CalendarMetadata?> fetchMetadata({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (useCache && !forceRefresh) {
        try {
          final cached = await _cacheService.getCachedMetadata();
          if (cached != null) {
            Logger.d('CalendarRepository', 'Metadata loaded from cache');
            return cached;
          }
        } catch (e) {
          Logger.e(
            'CalendarRepository',
            'Failed to load from cache, trying network',
            e,
          );
        }
      }

      // Fetch from network with retry logic
      return await _fetchMetadataFromNetwork();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error fetching metadata', e);

      // Final fallback to cache even if expired
      try {
        final cached = await _cacheService.getCachedMetadata();
        if (cached != null) {
          Logger.w('CalendarRepository', 'Using expired cache as fallback');
          return cached;
        }
      } catch (cacheError) {
        Logger.e(
          'CalendarRepository',
          'Cache fallback also failed',
          cacheError,
        );
      }

      return null;
    }
  }

  /// Fetch calendar metadata with status tracking for refresh operations
  Future<RefreshResult<CalendarMetadata>> fetchMetadataWithStatus({
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        try {
          final cached = await _cacheService.getCachedMetadata();
          if (cached != null) {
            Logger.d('CalendarRepository', 'Metadata loaded from cache');
            return RefreshResult(data: cached, isFromCache: true);
          }
        } catch (e) {
          Logger.e(
            'CalendarRepository',
            'Failed to load from cache, trying network',
            e,
          );
        }
      }

      // Fetch from network
      try {
        final networkData = await _fetchMetadataFromNetwork();
        if (networkData != null) {
          return RefreshResult(data: networkData, isFromNetwork: true);
        }
      } catch (e) {
        Logger.e(
          'CalendarRepository',
          'Network fetch failed, trying cache fallback',
          e,
        );

        // Network failed, try cache fallback
        try {
          final cached = await _cacheService.getCachedMetadata();
          if (cached != null) {
            Logger.w('CalendarRepository', 'Using expired cache as fallback');
            return RefreshResult(
              data: cached,
              isFromCache: true,
              isExpiredCache: true,
              error: 'Network unavailable, using cached data',
            );
          }
        } catch (cacheError) {
          Logger.e(
            'CalendarRepository',
            'Cache fallback also failed',
            cacheError,
          );
        }

        return RefreshResult(
          error: 'Failed to fetch metadata: ${e.toString()}',
        );
      }

      return RefreshResult(error: 'No data available');
    } catch (e) {
      Logger.e('CalendarRepository', 'Unexpected error fetching metadata', e);
      return RefreshResult(error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch metadata from network with proper error handling
  Future<CalendarMetadata?> _fetchMetadataFromNetwork() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'VIT-Connect-Flutter/1.0',
    };

    // raw.githubusercontent.com does NOT support Bearer token authentication
    // It works best without authentication for public repos
    // Token is only needed for GitHub API endpoints, not raw content
    Logger.d(
      'CalendarRepository',
      'Fetching from public raw content URL (no auth needed)',
    );

    Logger.d(
      'CalendarRepository',
      'Fetching metadata from network: $_metadataUrl',
    );

    try {
      final response = await http
          .get(Uri.parse(_metadataUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      Logger.d(
        'CalendarRepository',
        'Network response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final metadata = CalendarMetadata.fromJson(data);

        // Cache the fresh data
        await _cacheService.cacheMetadata(metadata);
        Logger.i(
          'CalendarRepository',
          'Metadata fetched and cached successfully',
        );
        return metadata;
      } else if (response.statusCode == 403) {
        Logger.e(
          'CalendarRepository',
          'GitHub API rate limit or authentication failed: ${response.statusCode}',
        );
        throw Exception(
          'GitHub API access denied. Check token or rate limits.',
        );
      } else {
        Logger.e(
          'CalendarRepository',
          'Failed to fetch metadata: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch metadata',
        );
      }
    } on TimeoutException {
      Logger.e('CalendarRepository', 'Network request timed out');
      throw Exception('Network timeout: Please check your internet connection');
    } catch (e) {
      Logger.e('CalendarRepository', 'Network error fetching metadata', e);
      rethrow;
    }
  }

  /// Fetch calendar data for specific class group with optimal caching
  Future<CalendarData?> fetchCalendarData(
    String filePath, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (useCache && !forceRefresh) {
        try {
          final cached = await _cacheService.getCachedCalendarData(filePath);
          if (cached != null) {
            Logger.d(
              'CalendarRepository',
              'Calendar data loaded from cache: $filePath',
            );
            return cached;
          }
        } catch (e) {
          Logger.e(
            'CalendarRepository',
            'Failed to load calendar data from cache, trying network: $filePath',
            e,
          );
        }
      }

      // Fetch from network
      return await _fetchCalendarDataFromNetwork(filePath);
    } catch (e) {
      Logger.e(
        'CalendarRepository',
        'Error fetching calendar data: $filePath',
        e,
      );

      // Final fallback to cache even if expired
      try {
        final cached = await _cacheService.getCachedCalendarData(filePath);
        if (cached != null) {
          Logger.w(
            'CalendarRepository',
            'Using expired cache as fallback for: $filePath',
          );
          return cached;
        }
      } catch (cacheError) {
        Logger.e(
          'CalendarRepository',
          'Cache fallback also failed for: $filePath',
          cacheError,
        );
      }

      return null;
    }
  }

  /// Fetch calendar data with status tracking for refresh operations
  Future<RefreshResult<CalendarData>> fetchCalendarDataWithStatus(
    String filePath, {
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        try {
          final cached = await _cacheService.getCachedCalendarData(filePath);
          if (cached != null) {
            Logger.d(
              'CalendarRepository',
              'Calendar data loaded from cache: $filePath',
            );
            return RefreshResult(data: cached, isFromCache: true);
          }
        } catch (e) {
          Logger.e(
            'CalendarRepository',
            'Failed to load calendar data from cache, trying network: $filePath',
            e,
          );
        }
      }

      // Fetch from network
      try {
        final networkData = await _fetchCalendarDataFromNetwork(filePath);
        if (networkData != null) {
          return RefreshResult(data: networkData, isFromNetwork: true);
        }
      } catch (e) {
        Logger.e(
          'CalendarRepository',
          'Network fetch failed for $filePath, trying cache fallback',
          e,
        );

        // Network failed, try cache fallback
        try {
          final cached = await _cacheService.getCachedCalendarData(filePath);
          if (cached != null) {
            Logger.w(
              'CalendarRepository',
              'Using expired cache as fallback for: $filePath',
            );
            return RefreshResult(
              data: cached,
              isFromCache: true,
              isExpiredCache: true,
              error: 'Network unavailable, using cached data',
            );
          }
        } catch (cacheError) {
          Logger.e(
            'CalendarRepository',
            'Cache fallback also failed for: $filePath',
            cacheError,
          );
        }

        return RefreshResult(
          error: 'Failed to fetch calendar data: ${e.toString()}',
        );
      }

      return RefreshResult(error: 'No data available');
    } catch (e) {
      Logger.e(
        'CalendarRepository',
        'Unexpected error fetching calendar data for $filePath',
        e,
      );
      return RefreshResult(error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch calendar data from network with proper error handling
  Future<CalendarData?> _fetchCalendarDataFromNetwork(String filePath) async {
    final url = '$_baseUrl/$filePath';
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'VIT-Connect-Flutter/1.0',
    };

    // raw.githubusercontent.com does NOT support token authentication
    // Works best without any auth headers for public repos

    Logger.d('CalendarRepository', 'Fetching calendar data from network: $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      Logger.d(
        'CalendarRepository',
        'Network response for $filePath: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final calendarData = CalendarData.fromJson(data);

        // Cache the fresh data
        await _cacheService.cacheCalendarData(filePath, calendarData);
        Logger.i(
          'CalendarRepository',
          'Calendar data fetched and cached: $filePath',
        );
        return calendarData;
      } else if (response.statusCode == 403) {
        Logger.e(
          'CalendarRepository',
          'GitHub API rate limit or authentication failed for $filePath: ${response.statusCode}',
        );
        throw Exception('GitHub API access denied for $filePath');
      } else if (response.statusCode == 404) {
        Logger.e('CalendarRepository', 'Calendar file not found: $filePath');
        throw Exception('Calendar file not found: $filePath');
      } else {
        Logger.e(
          'CalendarRepository',
          'Failed to fetch calendar data for $filePath: ${response.statusCode}',
        );
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch calendar data',
        );
      }
    } on TimeoutException {
      Logger.e(
        'CalendarRepository',
        'Network request timed out for: $filePath',
      );
      throw Exception('Network timeout for $filePath');
    } catch (e) {
      Logger.e(
        'CalendarRepository',
        'Network error fetching calendar data: $filePath',
        e,
      );
      rethrow;
    }
  }

  /// Save selected calendars
  Future<void> saveSelectedCalendars(
    List<String> selectedCalendars, [
    CalendarMetadata? metadata,
  ]) async {
    try {
      await _cacheService.saveSelectedCalendars(selectedCalendars, metadata);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error saving selected calendars', e);
    }
  }

  /// Get selected calendars
  Future<List<String>> getSelectedCalendars() async {
    try {
      return await _cacheService.getSelectedCalendars();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error getting selected calendars', e);
      return [];
    }
  }

  /// Save personal calendars (deprecated) (If i add again)
  Future<void> savePersonalCalendars(List<PersonalCalendar> calendars) async {
    Logger.d(
      'CalendarRepository',
      'Personal calendars save called (deprecated)',
    );
  }

  /// Get personal calendars (deprecated)
  Future<List<PersonalCalendar>> getPersonalCalendars() async {
    Logger.d(
      'CalendarRepository',
      'Personal calendars get called (deprecated)',
    );
    return [];
  }

  /// Save personal events
  Future<void> savePersonalEvents(List<PersonalEvent> events) async {
    try {
      await _cacheService.savePersonalEvents(events);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error saving personal events', e);
    }
  }

  /// Get personal events
  Future<List<PersonalEvent>> getPersonalEvents() async {
    try {
      return await _cacheService.getPersonalEvents();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error getting personal events', e);
      return [];
    }
  }

  /// Add personal event
  Future<void> addPersonalEvent(PersonalEvent event) async {
    try {
      await _cacheService.addPersonalEvent(event);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error adding personal event', e);
    }
  }

  /// Remove personal event
  Future<void> removePersonalEvent(String eventId) async {
    try {
      await _cacheService.removePersonalEvent(eventId);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error removing personal event', e);
    }
  }

  /// Get cache timestamp for a calendar (deprecated)
  Future<DateTime?> getCacheTimestamp(String filePath) async {
    // Cache timestamps are now handled internally by the cache service
    Logger.d('CalendarRepository', 'Cache timestamp check called (deprecated)');
    return null;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await _cacheService.clearAllCache();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error clearing cache', e);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _cacheService.getCacheStats();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error getting cache stats', e);
      return {};
    }
  }

  /// Save last sync time for a calendar
  Future<void> saveLastSyncTime(String calendarId, DateTime syncTime) async {
    try {
      await _cacheService.saveLastSyncTime(calendarId, syncTime);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error saving last sync time', e);
    }
  }

  /// Get last sync time for a calendar
  Future<DateTime?> getLastSyncTime(String calendarId) async {
    try {
      return await _cacheService.getLastSyncTime(calendarId);
    } catch (e) {
      Logger.e('CalendarRepository', 'Error getting last sync time', e);
      return null;
    }
  }

  /// Get all last sync times
  Future<Map<String, DateTime>> getAllLastSyncTimes() async {
    try {
      return await _cacheService.getAllLastSyncTimes();
    } catch (e) {
      Logger.e('CalendarRepository', 'Error getting all last sync times', e);
      return {};
    }
  }
}
