import 'package:sqflite/sqflite.dart';
import '../entities/events_cache.dart';
import '../../utils/logger.dart';

/// Data Access Object for Events cache
class EventsDao {
  final Database _database;

  EventsDao(this._database);

  /// Get all cached events
  Future<List<EventsCacheEntity>> getAllEvents() async {
    try {
      final results = await _database.query(
        'events_cache',
        orderBy: 'event_date ASC',
      );

      return results.map((map) => EventsCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('EventsDao', 'Error getting all events', e);
      return [];
    }
  }

  /// Get events by category
  Future<List<EventsCacheEntity>> getEventsByCategory(String category) async {
    try {
      final results = await _database.query(
        'events_cache',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'event_date ASC',
      );

      return results.map((map) => EventsCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('EventsDao', 'Error getting events by category: $category', e);
      return [];
    }
  }

  /// Get user's posted events
  Future<List<EventsCacheEntity>> getUserEvents(String userEmail) async {
    try {
      final results = await _database.query(
        'events_cache',
        where: 'user_email = ? AND event_source = ?',
        whereArgs: [userEmail, 'user'],
        orderBy: 'event_date DESC',
      );

      return results.map((map) => EventsCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('EventsDao', 'Error getting user events', e);
      return [];
    }
  }

  /// Get event by ID
  Future<EventsCacheEntity?> getEventById(String id) async {
    try {
      final results = await _database.query(
        'events_cache',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return EventsCacheEntity.fromMap(results.first);
    } catch (e) {
      Logger.e('EventsDao', 'Error getting event by ID: $id', e);
      return null;
    }
  }

  /// Insert or update event
  Future<void> insertOrUpdate(EventsCacheEntity event) async {
    try {
      await _database.insert(
        'events_cache',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.e('EventsDao', 'Error inserting/updating event: ${event.id}', e);
    }
  }

  /// Insert multiple events
  Future<void> insertAll(List<EventsCacheEntity> events) async {
    try {
      await _database.transaction((txn) async {
        for (final event in events) {
          await txn.insert(
            'events_cache',
            event.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      Logger.d('EventsDao', 'Cached ${events.length} events');
    } catch (e) {
      Logger.e('EventsDao', 'Error inserting all events', e);
    }
  }

  /// Update event like status
  Future<void> updateLikeStatus(
    String eventId,
    bool isLiked,
    int likesCount,
  ) async {
    try {
      await _database.update(
        'events_cache',
        {'is_liked_by_me': isLiked ? 1 : 0, 'likes_count': likesCount},
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e) {
      Logger.e('EventsDao', 'Error updating like status: $eventId', e);
    }
  }

  /// Update event comments count
  Future<void> updateCommentsCount(String eventId, int count) async {
    try {
      await _database.update(
        'events_cache',
        {'comments_count': count},
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e) {
      Logger.e('EventsDao', 'Error updating comments count: $eventId', e);
    }
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _database.delete(
        'events_cache',
        where: 'id = ?',
        whereArgs: [eventId],
      );
      Logger.d('EventsDao', 'Deleted event: $eventId');
    } catch (e) {
      Logger.e('EventsDao', 'Error deleting event: $eventId', e);
    }
  }

  /// Clear all cached events
  Future<void> clearAll() async {
    try {
      await _database.delete('events_cache');
      Logger.d('EventsDao', 'Events cache cleared');
    } catch (e) {
      Logger.e('EventsDao', 'Error clearing events cache', e);
    }
  }

  /// Clear old/expired events (older than 30 days)
  Future<void> clearExpiredEvents() async {
    try {
      final thirtyDaysAgo =
          DateTime.now()
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch;

      final deleted = await _database.delete(
        'events_cache',
        where: 'event_date < ?',
        whereArgs: [thirtyDaysAgo],
      );

      Logger.d('EventsDao', 'Cleared $deleted expired events');
    } catch (e) {
      Logger.e('EventsDao', 'Error clearing expired events', e);
    }
  }

  /// Get cache count
  Future<int> getCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM events_cache',
      );
      return result.first['count'] as int;
    } catch (e) {
      Logger.e('EventsDao', 'Error getting cache count', e);
      return 0;
    }
  }

  /// Get last cached time
  Future<DateTime?> getLastCachedTime() async {
    try {
      final result = await _database.query(
        'events_cache',
        columns: ['cached_at'],
        orderBy: 'cached_at DESC',
        limit: 1,
      );

      if (result.isEmpty) return null;

      final cachedAt = result.first['cached_at'] as int;
      return DateTime.fromMillisecondsSinceEpoch(cachedAt);
    } catch (e) {
      Logger.e('EventsDao', 'Error getting last cached time', e);
      return null;
    }
  }

  /// Get last sync time from app_preferences
  Future<DateTime?> getLastSyncTime() async {
    try {
      final result = await _database.query(
        'app_preferences',
        where: 'key = ?',
        whereArgs: ['events_last_sync'],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final syncTime = int.tryParse(result.first['value'] as String);
      if (syncTime == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(syncTime);
    } catch (e) {
      Logger.e('EventsDao', 'Error getting last sync time', e);
      return null;
    }
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database.insert('app_preferences', {
        'key': 'events_last_sync',
        'value': now.toString(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      Logger.e('EventsDao', 'Error updating last sync time', e);
    }
  }
}
