import 'package:flutter/material.dart';
import '../data/calendar_repository.dart';
import '../models/calendar_metadata.dart';
import '../models/calendar_event.dart';
import '../../../core/config/env_config.dart';
import '../../../core/utils/logger.dart';

class CalendarProvider extends ChangeNotifier {
  final CalendarRepository _repository;

  CalendarMetadata? _metadata;
  final Map<String, CalendarData> _calendarDataCache = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  List<String> _selectedCalendars = [];
  List<PersonalCalendar> _personalCalendars = [];
  List<PersonalEvent> _personalEvents = [];

  bool _isLoading = false;
  String? _error;
  CalendarViewType _viewType = CalendarViewType.month;
  DateTime _selectedDate = DateTime.now();
  String _selectedCalendarFilter = 'all';

  CalendarProvider()
    : _repository = CalendarRepository(
        githubToken:
            EnvConfig.githubVitconnectToken.isNotEmpty
                ? EnvConfig.githubVitconnectToken
                : null,
      );

  bool _isInitialized = false;

  /// Initialize provider and repository (called lazily)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      Logger.d('CalendarProvider', 'Starting provider initialization...');

      // Initialize repository first
      await _repository.initialize();
      Logger.d('CalendarProvider', 'Repository initialized successfully');

      // Then load initial data
      await _loadInitialData();
      Logger.d('CalendarProvider', 'Initial data loaded successfully');

      _isInitialized = true;
    } catch (e) {
      Logger.e('CalendarProvider', 'Error initializing provider', e);
      _error = 'Failed to initialize calendar';
    } finally {
      _setLoading(false);
    }
  }

  // Getters
  CalendarMetadata? get metadata => _metadata;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CalendarViewType get viewType => _viewType;
  DateTime get selectedDate => _selectedDate;
  String get selectedCalendarFilter => _selectedCalendarFilter;
  List<String> get selectedCalendars => _selectedCalendars;
  List<PersonalCalendar> get personalCalendars => _personalCalendars;
  List<PersonalEvent> get personalEvents => _personalEvents;

  /// Load initial data
  Future<void> _loadInitialData() async {
    // Load user preferences first (instant)
    _selectedCalendars = await _repository.getSelectedCalendars();
    _personalCalendars = await _repository.getPersonalCalendars();
    _personalEvents = await _repository.getPersonalEvents();

    // Load last sync times from database
    final savedSyncTimes = await _repository.getAllLastSyncTimes();
    _lastSyncTimes.addAll(savedSyncTimes);
    Logger.d(
      'CalendarProvider',
      'Loaded ${savedSyncTimes.length} saved sync times',
    );

    // Load cached data (should be fast)
    await loadCachedData();
  }

  /// Load cached data without network calls
  Future<void> loadCachedData() async {
    try {
      // Don't show loading state for cached data - should be instant
      _error = null;

      Logger.d('CalendarProvider', 'Loading cached data...');

      // Load cached metadata (cache-only, no network)
      _metadata = await _repository.fetchMetadata(
        useCache: true,
        forceRefresh: false,
      );
      Logger.d('CalendarProvider', 'Metadata loaded: ${_metadata != null}');

      // If no metadata found in cache, set error but don't fail
      if (_metadata == null) {
        Logger.w('CalendarProvider', 'No cached metadata available');
        // Don't set _error here as it's expected on first launch
      }

      // Load cached calendar data for selected calendars
      for (final calendarId in _selectedCalendars) {
        final classGroup = _findClassGroupById(calendarId);
        if (classGroup != null) {
          try {
            final cachedData = await _repository.fetchCalendarData(
              classGroup.filePath,
              useCache: true,
              forceRefresh: false,
            );
            if (cachedData != null) {
              _calendarDataCache[classGroup.filePath] = cachedData;
              Logger.d(
                'CalendarProvider',
                'Cached data loaded for: ${classGroup.filePath}',
              );
            }
          } catch (e) {
            Logger.e(
              'CalendarProvider',
              'Failed to load cached data for ${classGroup.filePath}',
              e,
            );
          }
        }
      }

      Logger.i('CalendarProvider', 'Cached data loading complete');
    } catch (e) {
      Logger.e('CalendarProvider', 'Error loading cached data', e);
      _error = 'Failed to load cached data';
    }
    // No loading state changes for cached data
    notifyListeners();
  }

  /// Fetch metadata with optimal caching
  Future<void> fetchMetadata({bool forceRefresh = false}) async {
    try {
      // Only show loading during initial load, not during refresh
      if (!forceRefresh) {
        _setLoading(true);
      }
      _error = null;

      _metadata = await _repository.fetchMetadata(
        useCache: true,
        forceRefresh: forceRefresh,
      );

      if (_metadata != null) {
        final now = DateTime.now();
        _lastSyncTimes['metadata'] = now;
        await _repository.saveLastSyncTime('metadata', now);
        Logger.i('CalendarProvider', 'Metadata fetched successfully');
      } else {
        _error = 'Failed to load calendar metadata from network';
        Logger.w('CalendarProvider', 'Metadata fetch returned null');
      }
    } catch (e) {
      _error = 'Failed to load calendar metadata: ${e.toString()}';
      Logger.e('CalendarProvider', 'Error fetching metadata', e);
    } finally {
      // Only hide loading if we showed it (initial load)
      if (!forceRefresh) {
        _setLoading(false);
      }
    }
  }

  /// Refresh all selected calendars with optimal caching
  Future<RefreshStatus> refreshSelectedCalendars() async {
    try {
      // Don't show loading state during refresh - keep UI stable
      _error = null;

      int networkSuccessCount = 0;
      int cacheFallbackCount = 0;
      int totalCount = 0;
      List<String> errors = [];

      // Trigger calendar sync for integration
      _triggerCalendarSync();

      // Refresh metadata first
      final metadataResult = await _repository.fetchMetadataWithStatus(
        forceRefresh: true,
      );
      totalCount++;

      if (metadataResult.isNetworkSuccess) {
        networkSuccessCount++;
        _metadata = metadataResult.data;
        final now = DateTime.now();
        _lastSyncTimes['metadata'] = now;
        await _repository.saveLastSyncTime('metadata', now);
      } else if (metadataResult.isCacheFallback) {
        cacheFallbackCount++;
        _metadata = metadataResult.data;
        if (metadataResult.error != null) {
          errors.add('Metadata: ${metadataResult.error}');
        }
      } else {
        errors.add('Metadata: ${metadataResult.error ?? "Failed to load"}');
      }

      // Refresh all selected calendar data
      for (final calendarId in _selectedCalendars) {
        final classGroup = _findClassGroupById(calendarId);
        if (classGroup != null) {
          totalCount++;
          final result = await _repository.fetchCalendarDataWithStatus(
            classGroup.filePath,
            forceRefresh: true,
          );

          if (result.isNetworkSuccess) {
            networkSuccessCount++;
            _calendarDataCache[classGroup.filePath] = result.data!;
            final now = DateTime.now();
            _lastSyncTimes[classGroup.filePath] = now;
            await _repository.saveLastSyncTime(classGroup.filePath, now);
          } else if (result.isCacheFallback) {
            cacheFallbackCount++;
            if (result.data != null) {
              _calendarDataCache[classGroup.filePath] = result.data!;
            }
            if (result.error != null) {
              errors.add('${classGroup.classGroup}: ${result.error}');
            }
          } else {
            errors.add(
              '${classGroup.classGroup}: ${result.error ?? "Failed to load"}',
            );
          }
        }
      }

      if (networkSuccessCount > 0) {
        _lastSyncTimes['all_calendars'] = DateTime.now();
      }

      Logger.i(
        'CalendarProvider',
        'Refresh complete - Network: $networkSuccessCount, Cache: $cacheFallbackCount, Total: $totalCount',
      );

      // Determine overall status
      if (networkSuccessCount == totalCount) {
        return RefreshStatus.success;
      } else if (networkSuccessCount > 0) {
        return RefreshStatus.partialSuccess;
      } else if (cacheFallbackCount > 0) {
        return RefreshStatus.cacheOnly;
      } else {
        _error = 'Failed to refresh calendars: ${errors.join(', ')}';
        return RefreshStatus.failed;
      }
    } catch (e) {
      _error = 'Failed to refresh calendars: ${e.toString()}';
      Logger.e('CalendarProvider', 'Error refreshing calendars', e);
      return RefreshStatus.failed;
    }
  }

  /// Fetch calendar data for specific class group with optimal caching
  Future<CalendarData?> _fetchCalendarData(
    String filePath, {
    bool forceRefresh = false,
  }) async {
    try {
      final calendarData = await _repository.fetchCalendarData(
        filePath,
        useCache: true,
        forceRefresh: forceRefresh,
      );

      if (calendarData != null) {
        _calendarDataCache[filePath] = calendarData;
        final now = DateTime.now();
        _lastSyncTimes[filePath] = now;
        await _repository.saveLastSyncTime(filePath, now);
      }

      return calendarData;
    } catch (e) {
      Logger.e(
        'CalendarProvider',
        'Error fetching calendar data for $filePath',
        e,
      );
      return null;
    }
  }

  /// Add selected calendar
  Future<void> addSelectedCalendar(String calendarId) async {
    if (!_selectedCalendars.contains(calendarId)) {
      _selectedCalendars.add(calendarId);
      await _repository.saveSelectedCalendars(_selectedCalendars, _metadata);

      // Fetch data for the new calendar
      final classGroup = _findClassGroupById(calendarId);
      if (classGroup != null) {
        await _fetchCalendarData(classGroup.filePath);
      }

      notifyListeners();
    }
  }

  /// Remove selected calendar
  Future<void> removeSelectedCalendar(String calendarId) async {
    _selectedCalendars.remove(calendarId);
    await _repository.saveSelectedCalendars(_selectedCalendars, _metadata);
    notifyListeners();
  }

  // REMOVED: personal calender (deadcodes)
  /// Add personal calendar
  Future<void> addPersonalCalendar(PersonalCalendar calendar) async {
    _personalCalendars.add(calendar);
    await _repository.savePersonalCalendars(_personalCalendars);
    notifyListeners();
  }

  /// Remove personal calendar
  Future<void> removePersonalCalendar(String calendarId) async {
    _personalCalendars.removeWhere((c) => c.id == calendarId);
    await _repository.savePersonalCalendars(_personalCalendars);
    notifyListeners();
  }

  /// Add personal event
  Future<void> addPersonalEvent(PersonalEvent event) async {
    _personalEvents.add(event);
    await _repository.addPersonalEvent(event);
    notifyListeners();
  }

  /// Remove personal event
  Future<void> removePersonalEvent(String eventId) async {
    _personalEvents.removeWhere((e) => e.id == eventId);
    await _repository.removePersonalEvent(eventId);
    notifyListeners();
  }

  /// Set view type
  void setViewType(CalendarViewType viewType) {
    _viewType = viewType;
    notifyListeners();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Set calendar filter
  void setCalendarFilter(String filter) {
    _selectedCalendarFilter = filter;
    notifyListeners();
  }

  /// Get events for a specific date
  List<Event> getEventsForDate(DateTime date) {
    final events = <Event>[];

    // Add academic calendar events
    for (final calendarId in _selectedCalendars) {
      if (_selectedCalendarFilter != 'all' &&
          _selectedCalendarFilter != calendarId) {
        continue;
      }

      final classGroup = _findClassGroupById(calendarId);
      if (classGroup != null) {
        final calendarData = _calendarDataCache[classGroup.filePath];
        if (calendarData != null) {
          final monthKey =
              '${_getMonthName(date.month).toUpperCase()}-${date.year}';
          final monthData = calendarData.months[monthKey];

          if (monthData != null) {
            final dayEvents = monthData.events.days
                .where((dayEvent) => dayEvent.date == date.day)
                .expand((dayEvent) => dayEvent.events);
            events.addAll(dayEvents);
          }
        }
      }
    }

    // Add personal events
    if (_selectedCalendarFilter == 'all' ||
        _selectedCalendarFilter == 'personal') {
      final personalEventsForDate = _personalEvents
          .where(
            (event) =>
                event.date.year == date.year &&
                event.date.month == date.month &&
                event.date.day == date.day,
          )
          .map((event) => event.toEvent());
      events.addAll(personalEventsForDate);
    }

    return events;
  }

  /// Get events for date range (for timeline view)
  Map<DateTime, List<Event>> getEventsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final eventsMap = <DateTime, List<Event>>{};

    for (
      var date = start;
      date.isBefore(end) || date.isAtSameMomentAs(end);
      date = date.add(const Duration(days: 1))
    ) {
      final events = getEventsForDate(date);
      if (events.isNotEmpty) {
        eventsMap[date] = events;
      }
    }

    return eventsMap;
  }

  /// Get upcoming events (next 7 days)
  List<MapEntry<DateTime, List<Event>>> getUpcomingEvents() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final eventsMap = getEventsForDateRange(now, nextWeek);

    return eventsMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Get last sync time for calendar
  DateTime? getLastSyncTime(String calendarId) {
    final classGroup = _findClassGroupById(calendarId);
    if (classGroup != null) {
      return _lastSyncTimes[classGroup.filePath];
    }
    return null;
  }

  /// Get calendar display names for filter
  List<String> getCalendarFilterOptions() {
    final options = ['all'];

    for (final calendarId in _selectedCalendars) {
      final classGroup = _findClassGroupById(calendarId);
      if (classGroup != null) {
        options.add(calendarId);
      }
    }

    // Add personal calendar if there are personal events
    if (_personalEvents.isNotEmpty) {
      options.add('personal');
    }

    for (final personalCalendar in _personalCalendars) {
      if (personalCalendar.isEnabled) {
        options.add(personalCalendar.id);
      }
    }

    return options;
  }

  /// Find class group by ID
  ClassGroup? _findClassGroupById(String calendarId) {
    if (_metadata == null) return null;

    for (final semester in _metadata!.semesters) {
      for (final classGroup in semester.classGroups) {
        final id = '${semester.semesterName}_${classGroup.classGroup}';
        if (id == calendarId) {
          return classGroup;
        }
      }
    }
    return null;
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _repository.clearCache();
    _calendarDataCache.clear();
    _lastSyncTimes.clear();
    notifyListeners();
  }

  /// Trigger calendar sync (deprecated - no longer used)
  void _triggerCalendarSync() {
    // No-op: CalendarSyncService removed
  }
}

enum CalendarViewType { month, timeline }

enum RefreshStatus {
  success, // All data refreshed from network
  partialSuccess, // Some data from network, some from cache
  cacheOnly, // All data from cache (network failed)
  failed, // Complete failure
}
