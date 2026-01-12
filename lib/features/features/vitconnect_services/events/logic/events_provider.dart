import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/event_model.dart';
import '../models/event_comment_model.dart';
import '../data/events_repository.dart';
import '../../../../../core/utils/logger.dart';

class EventsProvider extends ChangeNotifier {
  final EventsRepository _repository;

  List<Event> _events = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _disposed = false;
  String? _errorMessage;
  String? _searchQuery;
  String? _selectedCategory;
  String _sortBy = 'date'; // 'date', 'most_liked', 'most_commented'
  DateTime? _lastSyncTime;

  EventsProvider(this._repository) {
    // Set default sort to show upcoming events first
    _sortBy = 'upcoming';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  String get sortBy => _sortBy;
  DateTime? get lastSyncTime => _lastSyncTime;

  List<Event> get exploreEvents {
    var filtered = _events;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    filtered =
        filtered.where((e) {
          final eventDay = DateTime(
            e.eventDate.year,
            e.eventDate.month,
            e.eventDate.day,
          );
          return eventDay.isAtSameMomentAs(today) || eventDay.isAfter(today);
        }).toList();

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered =
          filtered
              .where(
                (e) =>
                    e.title.toLowerCase().contains(
                      _searchQuery!.toLowerCase(),
                    ) ||
                    e.description.toLowerCase().contains(
                      _searchQuery!.toLowerCase(),
                    ) ||
                    e.formattedDate.toLowerCase().contains(
                      _searchQuery!.toLowerCase(),
                    ) ||
                    e.eventDate.toString().contains(_searchQuery!),
              )
              .toList();
    }

    switch (_sortBy) {
      case 'upcoming':
        filtered.sort((a, b) {
          final aIsUpcoming = a.eventDate.isAfter(now);
          final bIsUpcoming = b.eventDate.isAfter(now);
          if (aIsUpcoming && !bIsUpcoming) return -1;
          if (!aIsUpcoming && bIsUpcoming) return 1;
          if (aIsUpcoming && bIsUpcoming) {
            return a.eventDate.compareTo(b.eventDate);
          }
          return b.eventDate.compareTo(a.eventDate);
        });
        break;
      case 'most_liked':
        filtered.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case 'most_commented':
        filtered.sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
    }

    return filtered;
  }

  List<Event> getMyEvents(String userId) {
    return _events
        .where((e) => e.source == 'user' && e.userId == userId)
        .toList();
  }

  Future<void> loadEvents({bool forceRefresh = false}) async {
    try {
      final cachedEvents = await _repository.fetchCachedEvents();
      if (cachedEvents.isNotEmpty) {
        _events = cachedEvents;
        _lastSyncTime = await _repository.getLastSyncTime();
        _setLoading(false);
        if (!_disposed) {
          notifyListeners();
          Logger.i(
            'EventsProvider',
            'Loaded ${_events.length} events from cache',
          );
        }
      } else {
        _setLoading(true);
      }

      if (forceRefresh || cachedEvents.isEmpty) {
        await _syncFromServer();
      } else {
        _syncFromServer();
      }
    } catch (e) {
      _setError(e.toString());
      Logger.e('EventsProvider', 'Load failed', e);
      _setLoading(false);
    }
  }

  Future<void> _syncFromServer() async {
    if (_disposed) return;
    _isSyncing = true;
    notifyListeners();

    try {
      _events = await _repository.fetchAllEvents();
      _lastSyncTime = await _repository.getLastSyncTime();
      Logger.i('EventsProvider', 'Synced ${_events.length} events from API');

      String? currentUserId = await _getCurrentUserId();
      await _enrichEventsWithMetadata(currentUserId);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Sync failed', e);
      if (_events.isEmpty) {
        _setError(e.toString());
      }
    } finally {
      if (!_disposed) {
        _isSyncing = false;
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('student_profile');
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json['registerNumber'] as String?;
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Failed to get current user ID', e);
    }
    return null;
  }

  Future<void> _enrichEventsWithMetadata(String? userId) async {
    try {
      Logger.d(
        'EventsProvider',
        'Fetching bulk metadata for ${_events.length} events',
      );

      final likesCountsMap = await _repository.getAllLikesCounts();
      final commentsCountsMap = await _repository.getAllCommentsCounts();
      final userLikedEvents =
          userId != null && userId.isNotEmpty
              ? await _repository.getUserLikedEvents(userId)
              : <String>{};

      for (var i = 0; i < _events.length; i++) {
        try {
          final eventId = _events[i].id;
          final eventSource = _events[i].source;
          final key = '${eventId}_$eventSource';

          final likesCount = likesCountsMap[key] ?? 0;
          final commentsCount = commentsCountsMap[key] ?? 0;
          final isLikedByMe = userLikedEvents.contains(key);

          Logger.d(
            'EventsProvider',
            'Event: $eventId, Likes: $likesCount, Comments: $commentsCount, IsLiked: $isLikedByMe',
          );

          _events[i] = _events[i].copyWith(
            likesCount: likesCount,
            commentsCount: commentsCount,
            isLikedByMe: isLikedByMe,
          );
        } catch (e) {
          Logger.e(
            'EventsProvider',
            'Enrich metadata failed for ${_events[i].id}',
            e,
          );
        }
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Bulk metadata fetch failed', e);
    }
  }

  Future<void> enrichEventWithUserLike(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    try {
      final isLiked = await _repository.isLikedByUser(
        _events[index].id,
        _events[index].source,
        userId,
      );
      _events[index] = _events[index].copyWith(isLikedByMe: isLiked);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Enrich user like failed', e);
    }
  }

  Future<void> toggleLike(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    final wasLiked = event.isLikedByMe;

    _events[index] = event.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: wasLiked ? event.likesCount - 1 : event.likesCount + 1,
    );
    if (!_disposed) {
      notifyListeners();
    }

    try {
      await _repository.toggleLike(event.id, event.source, userId);
    } catch (e) {
      _events[index] = event.copyWith(
        isLikedByMe: wasLiked,
        likesCount: event.likesCount,
      );
      if (!_disposed) {
        notifyListeners();
      }
      Logger.e('EventsProvider', 'Toggle like failed', e);
      rethrow;
    }
  }

  Future<List<EventComment>> fetchComments(String eventId) async {
    try {
      final event = _events.firstWhere((e) => e.id == eventId);
      return await _repository.fetchComments(event.id, event.source);
    } catch (e) {
      Logger.e('EventsProvider', 'Fetch comments failed', e);
      return [];
    }
  }

  Future<void> addComment(
    String eventId,
    String userId,
    String userName,
    String comment,
  ) async {
    try {
      final event = _events.firstWhere((e) => e.id == eventId);
      await _repository.addComment(
        eventId,
        event.source,
        userId,
        userName,
        comment,
      );

      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(
          commentsCount: _events[index].commentsCount + 1,
        );
        if (!_disposed) {
          notifyListeners();
        }
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Add comment failed', e);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Delete comment failed', e);
      rethrow;
    }
  }

  void setSearchQuery(String? query) {
    if (_disposed) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    if (_disposed) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_disposed) return;
    _sortBy = sortBy;
    notifyListeners();
  }

  Future<List<Event>> getUserEvents(String userId) async {
    try {
      return await _repository.getUserEvents(userId);
    } catch (e) {
      Logger.e('EventsProvider', 'Get user events failed', e);
      return [];
    }
  }

  Future<void> deleteUserEvent(String eventId) async {
    try {
      await _repository.deleteEvent(eventId);
      _events.removeWhere((event) => event.id == eventId);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      Logger.e('EventsProvider', 'Delete event failed', e);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    if (_disposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
