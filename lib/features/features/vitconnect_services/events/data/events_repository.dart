import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/event_comment_model.dart';
import '../../../../../core/utils/logger.dart';
import 'events_vitverse_service.dart';

class EventsRepository {
  final SupabaseClient _client;
  final EventsVitverseService _cacheService;

  EventsRepository(this._client, this._cacheService);

  Future<List<Event>> fetchCachedEvents() async {
    try {
      return await _cacheService.getEvents();
    } catch (e) {
      Logger.e('EventsRepo', 'Fetch cached failed', e);
      return [];
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      return await _cacheService.getLastSyncTime();
    } catch (e) {
      Logger.e('EventsRepo', 'Get last sync failed', e);
      return null;
    }
  }

  Future<List<Event>> fetchAllEvents() async {
    try {
      final officialResponse = await _client
          .from('official_events')
          .select()
          .eq('is_active', true)
          .order('event_date', ascending: false);

      final officialEvents =
          (officialResponse as List)
              .map((json) => Event.fromJson({...json, 'source': 'official'}))
              .toList();

      final userResponse = await _client
          .from('user_events')
          .select()
          .eq('is_active', true)
          .order('event_date', ascending: false);

      final userEvents =
          (userResponse as List)
              .map(
                (json) => Event.fromJson({
                  ...json,
                  'source': 'user',
                  'id': json['id'].toString(),
                }),
              )
              .toList();

      final allEvents = [...officialEvents, ...userEvents];
      allEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));

      await _cacheService.saveEvents(allEvents);

      return allEvents;
    } catch (e) {
      Logger.e('EventsRepo', 'Fetch failed', e);
      throw Exception('Failed to load events');
    }
  }

  Future<void> createEvent(Event event) async {
    try {
      await _client.from('user_events').insert({
        'user_id': event.userId,
        'user_name_regno': event.userNameRegno,
        'user_email': event.userEmail,
        'title': event.title,
        'description': event.description,
        'venue': event.venue,
        'category': event.category,
        'event_date': event.eventDate.toIso8601String(),
        'entry_fee': event.entryFee,
        'team_size': event.teamSize,
        'poster_url': event.posterUrl,
        'contact_info': event.contactInfo,
        'event_link': event.eventLink,
      });
      Logger.success('EventsRepo', 'Event created successfully');
    } catch (e) {
      Logger.e('EventsRepo', 'Create failed', e);
      throw Exception('Failed to create event');
    }
  }

  Future<List<Event>> getUserEvents(String userId) async {
    try {
      final response = await _client
          .from('user_events')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('event_date', ascending: false);

      final userEvents =
          (response as List)
              .map((json) => Event.fromJson({...json, 'source': 'user'}))
              .toList();

      Logger.d('EventsRepo', 'Fetched ${userEvents.length} user events');
      return userEvents;
    } catch (e) {
      Logger.e('EventsRepo', 'Get user events failed', e);
      return [];
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _client
          .from('user_events')
          .update({
            'title': event.title,
            'description': event.description,
            'venue': event.venue,
            'category': event.category,
            'event_date': event.eventDate.toIso8601String(),
            'entry_fee': event.entryFee,
            'team_size': event.teamSize,
            'poster_url': event.posterUrl,
            'contact_info': event.contactInfo,
            'event_link': event.eventLink,
          })
          .eq('id', event.id);
      Logger.success('EventsRepo', 'Event updated successfully');
    } catch (e) {
      Logger.e('EventsRepo', 'Update failed', e);
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _client
          .from('user_events')
          .update({'is_active': false})
          .eq('id', eventId);
      Logger.success('EventsRepo', 'Event deleted successfully');
    } catch (e) {
      Logger.e('EventsRepo', 'Delete failed', e);
      throw Exception('Failed to delete event');
    }
  }

  Future<void> toggleLike(String eventId, String source, String userId) async {
    try {
      final existing =
          await _client
              .from('event_likes')
              .select()
              .eq('event_id', eventId)
              .eq('event_source', source)
              .eq('user_id', userId)
              .maybeSingle();

      if (existing != null) {
        await _client
            .from('event_likes')
            .delete()
            .eq('event_id', eventId)
            .eq('event_source', source)
            .eq('user_id', userId);
      } else {
        await _client.from('event_likes').insert({
          'event_id': eventId,
          'event_source': source,
          'user_id': userId,
        });
      }
    } catch (e) {
      Logger.e('EventsRepo', 'Like failed', e);
      throw Exception('Failed to update like');
    }
  }

  Future<Map<String, int>> getAllLikesCounts() async {
    try {
      final response = await _client
          .from('event_likes')
          .select('event_id, event_source');

      final counts = <String, int>{};
      for (final row in response as List) {
        final key = '${row['event_id']}_${row['event_source']}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      Logger.d(
        'EventsRepo',
        'Fetched likes for ${counts.length} unique events',
      );
      return counts;
    } catch (e) {
      Logger.e('EventsRepo', 'Get all likes counts failed', e);
      return {};
    }
  }

  Future<int> getLikesCount(String eventId, String source) async {
    try {
      Logger.d(
        'EventsRepo',
        'Getting likes count for event_id: $eventId, event_source: $source',
      );

      final response = await _client
          .from('event_likes')
          .select('id')
          .eq('event_id', eventId)
          .eq('event_source', source)
          .count(CountOption.exact);

      Logger.d('EventsRepo', 'Likes count for $eventId: ${response.count}');

      return response.count;
    } catch (e) {
      Logger.e('EventsRepo', 'Get likes count failed', e);
      return 0;
    }
  }

  Future<Set<String>> getUserLikedEvents(String userId) async {
    try {
      final response = await _client
          .from('event_likes')
          .select('event_id, event_source')
          .eq('user_id', userId);

      final likedEvents = <String>{};
      for (final row in response as List) {
        final key = '${row['event_id']}_${row['event_source']}';
        likedEvents.add(key);
      }

      Logger.d(
        'EventsRepo',
        'User $userId has liked ${likedEvents.length} events',
      );
      return likedEvents;
    } catch (e) {
      Logger.e('EventsRepo', 'Get user liked events failed', e);
      return {};
    }
  }

  Future<bool> isLikedByUser(
    String eventId,
    String source,
    String userId,
  ) async {
    try {
      Logger.d(
        'EventsRepo',
        'Checking if user $userId liked event_id: $eventId, event_source: $source',
      );

      final response =
          await _client
              .from('event_likes')
              .select()
              .eq('event_id', eventId)
              .eq('event_source', source)
              .eq('user_id', userId)
              .maybeSingle();

      final isLiked = response != null;
      Logger.d('EventsRepo', 'User $userId like status for $eventId: $isLiked');

      return isLiked;
    } catch (e) {
      Logger.e('EventsRepo', 'Check like failed', e);
      return false;
    }
  }

  Future<void> addComment(
    String eventId,
    String source,
    String userId,
    String userName,
    String comment,
  ) async {
    try {
      await _client.from('event_comments').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'event_id': eventId,
        'event_source': source,
        'user_id': userId,
        'user_name': userName,
        'comment': comment,
      });
    } catch (e) {
      Logger.e('EventsRepo', 'Comment failed', e);
      throw Exception('Failed to add comment');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('event_comments').delete().eq('id', commentId);
      Logger.d('EventsRepo', 'Comment deleted: $commentId');
    } catch (e) {
      Logger.e('EventsRepo', 'Delete comment failed', e);
      throw Exception('Failed to delete comment');
    }
  }

  Future<List<EventComment>> fetchComments(
    String eventId,
    String source,
  ) async {
    try {
      final response = await _client
          .from('event_comments')
          .select()
          .eq('event_id', eventId)
          .eq('event_source', source)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EventComment.fromJson(json))
          .toList();
    } catch (e) {
      Logger.e('EventsRepo', 'Fetch comments failed', e);
      return [];
    }
  }

  Future<Map<String, int>> getAllCommentsCounts() async {
    try {
      final response = await _client
          .from('event_comments')
          .select('event_id, event_source');

      final counts = <String, int>{};
      for (final row in response as List) {
        final key = '${row['event_id']}_${row['event_source']}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      Logger.d(
        'EventsRepo',
        'Fetched comments for ${counts.length} unique events',
      );
      return counts;
    } catch (e) {
      Logger.e('EventsRepo', 'Get all comments counts failed', e);
      return {};
    }
  }

  Future<int> getCommentsCount(String eventId, String source) async {
    try {
      Logger.d(
        'EventsRepo',
        'Getting comments count for event_id: $eventId, event_source: $source',
      );

      final response = await _client
          .from('event_comments')
          .select('id')
          .eq('event_id', eventId)
          .eq('event_source', source)
          .count(CountOption.exact);

      Logger.d('EventsRepo', 'Comments count for $eventId: ${response.count}');

      return response.count;
    } catch (e) {
      Logger.e('EventsRepo', 'Get comments count failed', e);
      return 0;
    }
  }
}
