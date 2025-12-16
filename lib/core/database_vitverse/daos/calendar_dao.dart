import 'package:sqflite/sqflite.dart';
import '../entities/calendar_entities.dart';
import '../../utils/logger.dart';

/// Data Access Object for calendar operations
class CalendarDao {
  final Database _database;

  CalendarDao(this._database);

  // CALENDAR CACHE OPERATIONS

  /// Get cached data by ID
  Future<CalendarCacheEntity?> getCacheById(String id) async {
    try {
      final results = await _database.query(
        'calendar_cache',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return CalendarCacheEntity.fromMap(results.first);
      }
      return null;
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting cache by ID: $id', e);
      return null;
    }
  }

  /// Get cached data by type
  Future<List<CalendarCacheEntity>> getCacheByType(String cacheType) async {
    try {
      final results = await _database.query(
        'calendar_cache',
        where: 'cache_type = ?',
        whereArgs: [cacheType],
        orderBy: 'last_updated DESC',
      );

      return results.map((map) => CalendarCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting cache by type: $cacheType', e);
      return [];
    }
  }

  /// Check if cache is expired
  Future<bool> isCacheExpired(String id) async {
    try {
      final cache = await getCacheById(id);
      if (cache == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      return now > cache.expiresAt;
    } catch (e) {
      Logger.e('CalendarDao', 'Error checking cache expiry: $id', e);
      return true;
    }
  }

  /// Insert or update cache
  Future<void> insertOrUpdateCache(CalendarCacheEntity cache) async {
    try {
      await _database.insert(
        'calendar_cache',
        cache.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Logger.d('CalendarDao', 'Cache updated: ${cache.id}');
    } catch (e) {
      Logger.e('CalendarDao', 'Error inserting/updating cache: ${cache.id}', e);
    }
  }

  /// Delete cache by ID
  Future<void> deleteCacheById(String id) async {
    try {
      await _database.delete(
        'calendar_cache',
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.d('CalendarDao', 'Cache deleted: $id');
    } catch (e) {
      Logger.e('CalendarDao', 'Error deleting cache: $id', e);
    }
  }

  /// Clear all cache of specific type
  Future<void> clearCacheByType(String cacheType) async {
    try {
      final deletedCount = await _database.delete(
        'calendar_cache',
        where: 'cache_type = ?',
        whereArgs: [cacheType],
      );
      Logger.i(
        'CalendarDao',
        'Cleared $deletedCount cache entries of type: $cacheType',
      );
    } catch (e) {
      Logger.e('CalendarDao', 'Error clearing cache by type: $cacheType', e);
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deletedCount = await _database.delete(
        'calendar_cache',
        where: 'expires_at < ?',
        whereArgs: [now],
      );
      Logger.i('CalendarDao', 'Cleared $deletedCount expired cache entries');
    } catch (e) {
      Logger.e('CalendarDao', 'Error clearing expired cache', e);
    }
  }

  // PERSONAL EVENTS OPERATIONS

  /// Get all personal events
  Future<List<PersonalEventEntity>> getAllPersonalEvents() async {
    try {
      final results = await _database.query(
        'personal_events',
        orderBy: 'date ASC, time_hour ASC, time_minute ASC',
      );

      return results.map((map) => PersonalEventEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting all personal events', e);
      return [];
    }
  }

  /// Get personal events for specific date range
  Future<List<PersonalEventEntity>> getPersonalEventsInRange(
    int startDate,
    int endDate,
  ) async {
    try {
      final results = await _database.query(
        'personal_events',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date ASC, time_hour ASC, time_minute ASC',
      );

      return results.map((map) => PersonalEventEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting personal events in range', e);
      return [];
    }
  }

  /// Get personal events for specific date
  Future<List<PersonalEventEntity>> getPersonalEventsForDate(int date) async {
    try {
      final results = await _database.query(
        'personal_events',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'time_hour ASC, time_minute ASC',
      );

      return results.map((map) => PersonalEventEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting personal events for date', e);
      return [];
    }
  }

  /// Insert personal event
  Future<void> insertPersonalEvent(PersonalEventEntity event) async {
    try {
      await _database.insert('personal_events', event.toMap());
      Logger.d('CalendarDao', 'Personal event inserted: ${event.id}');
    } catch (e) {
      Logger.e('CalendarDao', 'Error inserting personal event: ${event.id}', e);
    }
  }

  /// Update personal event
  Future<void> updatePersonalEvent(PersonalEventEntity event) async {
    try {
      await _database.update(
        'personal_events',
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id],
      );
      Logger.d('CalendarDao', 'Personal event updated: ${event.id}');
    } catch (e) {
      Logger.e('CalendarDao', 'Error updating personal event: ${event.id}', e);
    }
  }

  /// Delete personal event
  Future<void> deletePersonalEvent(String eventId) async {
    try {
      await _database.delete(
        'personal_events',
        where: 'id = ?',
        whereArgs: [eventId],
      );
      Logger.d('CalendarDao', 'Personal event deleted: $eventId');
    } catch (e) {
      Logger.e('CalendarDao', 'Error deleting personal event: $eventId', e);
    }
  }

  // SELECTED CALENDARS OPERATIONS

  /// Get all selected calendars
  Future<List<SelectedCalendarEntity>> getAllSelectedCalendars() async {
    try {
      final results = await _database.query(
        'selected_calendars',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'added_at DESC',
      );

      return results.map((map) => SelectedCalendarEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting selected calendars', e);
      return [];
    }
  }

  /// Insert selected calendar
  Future<void> insertSelectedCalendar(SelectedCalendarEntity calendar) async {
    try {
      await _database.insert(
        'selected_calendars',
        calendar.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Logger.d('CalendarDao', 'Selected calendar inserted: ${calendar.id}');
    } catch (e) {
      Logger.e(
        'CalendarDao',
        'Error inserting selected calendar: ${calendar.id}',
        e,
      );
    }
  }

  /// Remove selected calendar
  Future<void> removeSelectedCalendar(String calendarId) async {
    try {
      await _database.update(
        'selected_calendars',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [calendarId],
      );
      Logger.d('CalendarDao', 'Selected calendar removed: $calendarId');
    } catch (e) {
      Logger.e(
        'CalendarDao',
        'Error removing selected calendar: $calendarId',
        e,
      );
    }
  }

  // APP PREFERENCES OPERATIONS

  /// Get preference by key
  Future<AppPreferenceEntity?> getPreference(String key) async {
    try {
      final results = await _database.query(
        'app_preferences',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return AppPreferenceEntity.fromMap(results.first);
      }
      return null;
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting preference: $key', e);
      return null;
    }
  }

  /// Set preference
  Future<void> setPreference(AppPreferenceEntity preference) async {
    try {
      await _database.insert(
        'app_preferences',
        preference.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Logger.d('CalendarDao', 'Preference set: ${preference.key}');
    } catch (e) {
      Logger.e('CalendarDao', 'Error setting preference: ${preference.key}', e);
    }
  }

  /// Delete preference
  Future<void> deletePreference(String key) async {
    try {
      await _database.delete(
        'app_preferences',
        where: 'key = ?',
        whereArgs: [key],
      );
      Logger.d('CalendarDao', 'Preference deleted: $key');
    } catch (e) {
      Logger.e('CalendarDao', 'Error deleting preference: $key', e);
    }
  }

  /// Get all preferences
  Future<List<AppPreferenceEntity>> getAllPreferences() async {
    try {
      final results = await _database.query(
        'app_preferences',
        orderBy: 'key ASC',
      );

      return results.map((map) => AppPreferenceEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CalendarDao', 'Error getting all preferences', e);
      return [];
    }
  }

  // UTILITY OPERATIONS

  /// Get table counts for debugging
  Future<Map<String, int>> getTableCounts() async {
    final counts = <String, int>{};
    final tables = [
      'calendar_cache',
      'personal_events',
      'selected_calendars',
      'app_preferences',
    ];

    for (final table in tables) {
      try {
        final result = await _database.rawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );
        counts[table] = result.first['count'] as int;
      } catch (e) {
        counts[table] = 0;
        Logger.e('CalendarDao', 'Error counting table $table', e);
      }
    }

    return counts;
  }

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    try {
      await _database.transaction((txn) async {
        await txn.delete('calendar_cache');
        await txn.delete('personal_events');
        await txn.delete('selected_calendars');
        await txn.delete('app_preferences');
      });
      Logger.i('CalendarDao', 'All VIT Verse data cleared');
    } catch (e) {
      Logger.e('CalendarDao', 'Error clearing all data', e);
    }
  }
}
