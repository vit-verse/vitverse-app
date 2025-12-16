import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/database_vitverse/database.dart';
import '../../../core/database_vitverse/entities/calendar_entities.dart';
import '../models/calendar_metadata.dart';
import '../models/calendar_event.dart';
import '../../../core/utils/logger.dart';

/// Calendar cache service for optimal data storage and retrieval
class CalendarCacheService {
  static const String _metadataCacheType = 'metadata';
  static const String _calendarDataCacheType = 'calendar_data';

  // Cache TTL (Time To Live)
  static const Duration _metadataTtl = Duration(hours: 6);
  static const Duration _calendarDataTtl = Duration(hours: 24);

  final VitVerseDatabase _database;

  CalendarCacheService() : _database = VitVerseDatabase.instance;

  /// Initialize cache service
  Future<void> initialize() async {
    try {
      Logger.d('CalendarCacheService', 'Initializing cache service...');
      await _database.initialize();
      Logger.d('CalendarCacheService', 'Database initialized successfully');

      await _cleanupExpiredCache();
      Logger.d('CalendarCacheService', 'Cache service initialization complete');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Failed to initialize cache service', e);
      rethrow;
    }
  }

  // ============================================================================
  // METADATA CACHE OPERATIONS
  // ============================================================================

  /// Get cached metadata
  Future<CalendarMetadata?> getCachedMetadata() async {
    try {
      const cacheId = 'calendar_metadata';
      final cache = await _database.calendarDao.getCacheById(cacheId);

      if (cache != null &&
          !await _database.calendarDao.isCacheExpired(cacheId)) {
        final data = json.decode(cache.data) as Map<String, dynamic>;
        Logger.d('CalendarCacheService', 'Metadata loaded from cache');
        return CalendarMetadata.fromJson(data);
      }

      Logger.d('CalendarCacheService', 'No valid cached metadata found');
      return null;
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error getting cached metadata', e);
      return null;
    }
  }

  /// Cache metadata
  Future<void> cacheMetadata(CalendarMetadata metadata) async {
    try {
      const cacheId = 'calendar_metadata';
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + _metadataTtl.inMilliseconds;

      final cacheEntity = CalendarCacheEntity(
        id: cacheId,
        data: json.encode(metadata.toJson()),
        lastUpdated: now,
        expiresAt: expiresAt,
        cacheType: _metadataCacheType,
      );

      await _database.calendarDao.insertOrUpdateCache(cacheEntity);
      Logger.i('CalendarCacheService', 'Metadata cached successfully');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error caching metadata', e);
    }
  }

  /// Clear metadata cache
  Future<void> clearMetadataCache() async {
    try {
      await _database.calendarDao.clearCacheByType(_metadataCacheType);
      Logger.i('CalendarCacheService', 'Metadata cache cleared');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error clearing metadata cache', e);
    }
  }

  // ============================================================================
  // CALENDAR DATA CACHE OPERATIONS
  // ============================================================================

  /// Get cached calendar data
  Future<CalendarData?> getCachedCalendarData(String filePath) async {
    try {
      final cacheId = _generateCalendarCacheId(filePath);
      final cache = await _database.calendarDao.getCacheById(cacheId);

      if (cache != null &&
          !await _database.calendarDao.isCacheExpired(cacheId)) {
        final data = json.decode(cache.data) as Map<String, dynamic>;
        Logger.d(
          'CalendarCacheService',
          'Calendar data loaded from cache: $filePath',
        );
        return CalendarData.fromJson(data);
      }

      Logger.d(
        'CalendarCacheService',
        'No valid cached calendar data found: $filePath',
      );
      return null;
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error getting cached calendar data: $filePath',
        e,
      );
      return null;
    }
  }

  /// Cache calendar data
  Future<void> cacheCalendarData(
    String filePath,
    CalendarData calendarData,
  ) async {
    try {
      final cacheId = _generateCalendarCacheId(filePath);
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + _calendarDataTtl.inMilliseconds;

      final cacheEntity = CalendarCacheEntity(
        id: cacheId,
        data: json.encode(calendarData.toJson()),
        lastUpdated: now,
        expiresAt: expiresAt,
        cacheType: _calendarDataCacheType,
      );

      await _database.calendarDao.insertOrUpdateCache(cacheEntity);
      Logger.i('CalendarCacheService', 'Calendar data cached: $filePath');
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error caching calendar data: $filePath',
        e,
      );
    }
  }

  /// Clear calendar data cache for specific file
  Future<void> clearCalendarDataCache(String filePath) async {
    try {
      final cacheId = _generateCalendarCacheId(filePath);
      await _database.calendarDao.deleteCacheById(cacheId);
      Logger.i(
        'CalendarCacheService',
        'Calendar data cache cleared: $filePath',
      );
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error clearing calendar data cache: $filePath',
        e,
      );
    }
  }

  /// Clear all calendar data cache
  Future<void> clearAllCalendarDataCache() async {
    try {
      await _database.calendarDao.clearCacheByType(_calendarDataCacheType);
      Logger.i('CalendarCacheService', 'All calendar data cache cleared');
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error clearing all calendar data cache',
        e,
      );
    }
  }

  // ============================================================================
  // SELECTED CALENDARS OPERATIONS
  // ============================================================================

  /// Get selected calendars from database
  Future<List<String>> getSelectedCalendars() async {
    try {
      final entities = await _database.calendarDao.getAllSelectedCalendars();
      return entities.map((e) => e.id).toList();
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error getting selected calendars', e);
      return [];
    }
  }

  /// Save selected calendars to database
  Future<void> saveSelectedCalendars(
    List<String> calendarIds,
    CalendarMetadata? metadata,
  ) async {
    try {
      // First, deactivate all existing calendars
      final existing = await _database.calendarDao.getAllSelectedCalendars();
      for (final calendar in existing) {
        await _database.calendarDao.removeSelectedCalendar(calendar.id);
      }

      // Add new selected calendars
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final calendarId in calendarIds) {
        final classGroup = _findClassGroupById(calendarId, metadata);
        if (classGroup != null) {
          final entity = SelectedCalendarEntity(
            id: calendarId,
            semesterName: classGroup.semesterName ?? '',
            classGroup: classGroup.classGroup,
            filePath: classGroup.filePath,
            isActive: 1,
            addedAt: now,
          );
          await _database.calendarDao.insertSelectedCalendar(entity);
        }
      }

      Logger.i(
        'CalendarCacheService',
        'Selected calendars saved: ${calendarIds.length}',
      );
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error saving selected calendars', e);
    }
  }

  // ============================================================================
  // PERSONAL EVENTS OPERATIONS
  // ============================================================================

  /// Get all personal events
  Future<List<PersonalEvent>> getPersonalEvents() async {
    try {
      final entities = await _database.calendarDao.getAllPersonalEvents();
      return entities.map(_entityToPersonalEvent).toList();
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error getting personal events', e);
      return [];
    }
  }

  /// Get personal events for date range
  Future<List<PersonalEvent>> getPersonalEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startTimestamp = _dateToTimestamp(start);
      final endTimestamp = _dateToTimestamp(end);

      final entities = await _database.calendarDao.getPersonalEventsInRange(
        startTimestamp,
        endTimestamp,
      );

      return entities.map(_entityToPersonalEvent).toList();
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error getting personal events in range',
        e,
      );
      return [];
    }
  }

  /// Save personal events
  Future<void> savePersonalEvents(List<PersonalEvent> events) async {
    try {
      // Clear existing personal events only (not all data)
      final existingEvents = await _database.calendarDao.getAllPersonalEvents();
      for (final event in existingEvents) {
        await _database.calendarDao.deletePersonalEvent(event.id);
      }

      // Insert new events
      for (final event in events) {
        final entity = _personalEventToEntity(event);
        await _database.calendarDao.insertPersonalEvent(entity);
      }

      Logger.i(
        'CalendarCacheService',
        'Personal events saved: ${events.length}',
      );
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error saving personal events', e);
    }
  }

  /// Add personal event
  Future<void> addPersonalEvent(PersonalEvent event) async {
    try {
      final entity = _personalEventToEntity(event);
      await _database.calendarDao.insertPersonalEvent(entity);
      Logger.i('CalendarCacheService', 'Personal event added: ${event.id}');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error adding personal event', e);
    }
  }

  /// Remove personal event
  Future<void> removePersonalEvent(String eventId) async {
    try {
      await _database.calendarDao.deletePersonalEvent(eventId);
      Logger.i('CalendarCacheService', 'Personal event removed: $eventId');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error removing personal event', e);
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate cache ID for calendar data
  String _generateCalendarCacheId(String filePath) {
    return 'calendar_data_${filePath.hashCode.abs()}';
  }

  /// Find class group by ID in metadata
  ClassGroup? _findClassGroupById(
    String calendarId,
    CalendarMetadata? metadata,
  ) {
    if (metadata == null) return null;

    for (final semester in metadata.semesters) {
      for (final classGroup in semester.classGroups) {
        final id = '${semester.semesterName}_${classGroup.classGroup}';
        if (id == calendarId) {
          return ClassGroup(
            classGroup: classGroup.classGroup,
            filePath: classGroup.filePath,
            semesterName: semester.semesterName,
          );
        }
      }
    }
    return null;
  }

  /// Convert date to timestamp
  int _dateToTimestamp(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  /// Convert PersonalEvent to Entity
  PersonalEventEntity _personalEventToEntity(PersonalEvent event) {
    return PersonalEventEntity(
      id: event.id,
      name: event.name,
      description: event.description,
      date: _dateToTimestamp(event.date),
      timeHour: event.time?.hour,
      timeMinute: event.time?.minute,
      createdAt: event.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert Entity to PersonalEvent
  PersonalEvent _entityToPersonalEvent(PersonalEventEntity entity) {
    return PersonalEvent(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      date: DateTime.fromMillisecondsSinceEpoch(entity.date),
      time:
          entity.timeHour != null && entity.timeMinute != null
              ? TimeOfDay(hour: entity.timeHour!, minute: entity.timeMinute!)
              : null,
      hasNotification: false,
      notificationMinutes: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }

  /// Cleanup expired cache entries
  Future<void> _cleanupExpiredCache() async {
    try {
      await _database.calendarDao.clearExpiredCache();
      Logger.d('CalendarCacheService', 'Expired cache cleaned up');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error cleaning up expired cache', e);
    }
  }

  /// Check if cache is fresh
  Future<bool> isCacheFresh(String cacheId) async {
    try {
      return !await _database.calendarDao.isCacheExpired(cacheId);
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error checking cache freshness', e);
      return false;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final counts = await _database.getTableCounts();
      final size = await _database.getDatabaseSize();

      return {
        'database_size_kb': (size / 1024).toStringAsFixed(2),
        'calendar_cache_entries': counts['calendar_cache'] ?? 0,
        'personal_events': counts['personal_events'] ?? 0,
        'selected_calendars': counts['selected_calendars'] ?? 0,
        'app_preferences': counts['app_preferences'] ?? 0,
      };
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error getting cache stats', e);
      return {};
    }
  }

  /// Save last sync time for a calendar
  Future<void> saveLastSyncTime(String calendarId, DateTime syncTime) async {
    try {
      final preference = AppPreferenceEntity(
        key: 'last_sync_$calendarId',
        value: syncTime.millisecondsSinceEpoch.toString(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _database.calendarDao.setPreference(preference);

      Logger.d('CalendarCacheService', 'Last sync time saved for: $calendarId');
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error saving last sync time for $calendarId',
        e,
      );
    }
  }

  /// Get last sync time for a calendar
  Future<DateTime?> getLastSyncTime(String calendarId) async {
    try {
      final prefs = await _database.calendarDao.getPreference(
        'last_sync_$calendarId',
      );

      if (prefs != null) {
        final timestamp = int.tryParse(prefs.value);
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }

      return null;
    } catch (e) {
      Logger.e(
        'CalendarCacheService',
        'Error getting last sync time for $calendarId',
        e,
      );
      return null;
    }
  }

  /// Get all last sync times
  Future<Map<String, DateTime>> getAllLastSyncTimes() async {
    try {
      final allPrefs = await _database.calendarDao.getAllPreferences();
      final syncTimes = <String, DateTime>{};

      for (final pref in allPrefs) {
        if (pref.key.startsWith('last_sync_')) {
          final calendarId = pref.key.replaceFirst('last_sync_', '');
          final timestamp = int.tryParse(pref.value);
          if (timestamp != null) {
            syncTimes[calendarId] = DateTime.fromMillisecondsSinceEpoch(
              timestamp,
            );
          }
        }
      }

      Logger.d(
        'CalendarCacheService',
        'Loaded ${syncTimes.length} sync times from database',
      );
      return syncTimes;
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error getting all last sync times', e);
      return {};
    }
  }

  /// Clear all cache (for logout)
  Future<void> clearAllCache() async {
    try {
      await _database.clearAllData();
      Logger.i('CalendarCacheService', 'All cache cleared');
    } catch (e) {
      Logger.e('CalendarCacheService', 'Error clearing all cache', e);
    }
  }
}

/// Extended ClassGroup with semester name
class ClassGroup {
  final String classGroup;
  final String filePath;
  final String? semesterName;

  ClassGroup({
    required this.classGroup,
    required this.filePath,
    this.semesterName,
  });
}
