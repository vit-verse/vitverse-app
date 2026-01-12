import '../../../../../core/database_vitverse/database.dart';
import '../../../../../core/database_vitverse/entities/events_cache.dart';
import '../../../../../core/utils/logger.dart';
import '../models/event_model.dart';

/// Service for managing events cache in VitVerse database
class EventsVitverseService {
  static const String _tag = 'EventsVitverseService';
  static const String _syncKey = 'events_last_sync';

  final VitVerseDatabase _database;

  EventsVitverseService(this._database);

  /// Save events to cache
  Future<void> saveEvents(List<Event> events) async {
    try {
      final entities =
          events.map((event) {
            return EventsCacheEntity(
              id: event.id,
              source: event.source,
              title: event.title,
              description: event.description,
              category: event.category,
              eventDate: event.eventDate.millisecondsSinceEpoch,
              venue: event.venue,
              posterUrl: event.posterUrl,
              contactInfo: event.contactInfo,
              eventLink: event.eventLink,
              participantType: event.participantType,
              entryFee: event.entryFee,
              teamSize: event.teamSize,
              userNameRegno: event.userNameRegno ?? '',
              userEmail: event.userEmail ?? '',
              likesCount: event.likesCount,
              commentsCount: event.commentsCount,
              isLikedByMe: event.isLikedByMe,
              notifyAll: false,
              isActive: event.isActive,
              isVerified: event.isVerified,
              createdAt:
                  event.createdAt?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
              cachedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }).toList();

      await _database.eventsDao.insertAll(entities);
      await _saveSyncTime();
      Logger.i(_tag, 'Cached ${events.length} events');
    } catch (e) {
      Logger.e(_tag, 'Error saving events', e);
    }
  }

  /// Get all cached events
  Future<List<Event>> getEvents() async {
    try {
      final entities = await _database.eventsDao.getAllEvents();
      return entities.map(_entityToEvent).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting events', e);
      return [];
    }
  }

  /// Get events by category
  Future<List<Event>> getEventsByCategory(String category) async {
    try {
      final entities = await _database.eventsDao.getEventsByCategory(category);
      return entities.map(_entityToEvent).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting events by category', e);
      return [];
    }
  }

  /// Get user's events
  Future<List<Event>> getUserEvents(String userEmail) async {
    try {
      final entities = await _database.eventsDao.getUserEvents(userEmail);
      return entities.map(_entityToEvent).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting user events', e);
      return [];
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final syncTime = await _database.eventsDao.getLastSyncTime();
      return syncTime;
    } catch (e) {
      Logger.e(_tag, 'Error getting last sync time', e);
      return null;
    }
  }

  /// Save sync time
  Future<void> _saveSyncTime() async {
    try {
      await _database.eventsDao.updateLastSyncTime();
    } catch (e) {
      Logger.e(_tag, 'Error saving sync time', e);
    }
  }

  /// Clear all cached events
  Future<void> clearCache() async {
    try {
      await _database.eventsDao.clearAll();
      Logger.i(_tag, 'Cache cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing cache', e);
    }
  }

  /// Convert entity to event model
  Event _entityToEvent(EventsCacheEntity entity) {
    return Event(
      id: entity.id,
      source: entity.source,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      eventDate: DateTime.fromMillisecondsSinceEpoch(entity.eventDate),
      venue: entity.venue,
      posterUrl: entity.posterUrl,
      contactInfo: entity.contactInfo,
      eventLink: entity.eventLink,
      participantType: entity.participantType,
      entryFee: entity.entryFee,
      teamSize: entity.teamSize,
      userNameRegno: entity.userNameRegno.isEmpty ? null : entity.userNameRegno,
      userEmail: entity.userEmail.isEmpty ? null : entity.userEmail,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      isLikedByMe: entity.isLikedByMe,
      isActive: entity.isActive,
      isVerified: entity.isVerified,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }
}
