import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../data/eventhub_repository.dart';
import '../../../../../core/utils/logger.dart';

enum EventTimeFilter { all, upcoming, past, today, thisWeek, thisMonth }

enum EventSortOption {
  dateNewest,
  dateOldest,
  alphaAZ,
  alphaZA,
  feeLow,
  feeHigh,
}

class EventHubProvider with ChangeNotifier {
  static const String _tag = 'EventHubProvider';

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  EventTimeFilter _timeFilter = EventTimeFilter.upcoming;
  EventSortOption _sortOption = EventSortOption.dateNewest;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastRefresh;

  List<Event> get filteredEvents => _filteredEvents;
  List<Event> get allEvents => _allEvents;
  EventTimeFilter get timeFilter => _timeFilter;
  EventSortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;

  int get allCount => _allEvents.length;
  int get upcomingCount => _allEvents.where((e) => e.isUpcoming).length;
  int get pastCount => _allEvents.where((e) => !e.isUpcoming).length;
  int get todayCount => _allEvents.where((e) => e.isToday).length;
  int get thisWeekCount => _allEvents.where((e) => e.isThisWeek).length;
  int get thisMonthCount => _allEvents.where((e) => e.isThisMonth).length;

  Future<void> init() async {
    await loadEvents();
  }

  Future<void> loadEvents({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      _allEvents = await EventHubRepository.loadEvents(
        forceRefresh: forceRefresh,
      );
      _lastRefresh = await EventHubRepository.getLastRefreshTime();
      _applyFiltersAndSort();
      _error = null;
      Logger.i(_tag, 'Loaded ${_allEvents.length} events');
    } catch (e) {
      _error = e.toString();
      Logger.e(_tag, 'Failed to load events', e);
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadEvents(forceRefresh: true);
  }

  void setTimeFilter(EventTimeFilter filter) {
    _timeFilter = filter;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(EventSortOption sort) {
    _sortOption = sort;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    List<Event> filtered = List.from(_allEvents);

    switch (_timeFilter) {
      case EventTimeFilter.all:
        break;
      case EventTimeFilter.upcoming:
        filtered = filtered.where((e) => e.isUpcoming).toList();
        break;
      case EventTimeFilter.past:
        filtered = filtered.where((e) => !e.isUpcoming).toList();
        break;
      case EventTimeFilter.today:
        filtered = filtered.where((e) => e.isToday).toList();
        break;
      case EventTimeFilter.thisWeek:
        filtered = filtered.where((e) => e.isThisWeek).toList();
        break;
      case EventTimeFilter.thisMonth:
        filtered = filtered.where((e) => e.isThisMonth).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((e) {
            return e.title.toLowerCase().contains(query) ||
                e.venue.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query);
          }).toList();
    }

    switch (_sortOption) {
      case EventSortOption.dateNewest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case EventSortOption.dateOldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case EventSortOption.alphaAZ:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case EventSortOption.alphaZA:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case EventSortOption.feeLow:
        filtered.sort((a, b) => a.fee.compareTo(b.fee));
        break;
      case EventSortOption.feeHigh:
        filtered.sort((a, b) => b.fee.compareTo(a.fee));
        break;
    }

    _filteredEvents = filtered;
  }

  String getLastRefreshFormatted() {
    if (_lastRefresh == null) return 'Never';

    final difference = DateTime.now().difference(_lastRefresh!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String getSortOptionText(EventSortOption option) {
    switch (option) {
      case EventSortOption.dateNewest:
        return 'Newest First';
      case EventSortOption.dateOldest:
        return 'Oldest First';
      case EventSortOption.alphaAZ:
        return 'Alphabetical (A-Z)';
      case EventSortOption.alphaZA:
        return 'Alphabetical (Z-A)';
      case EventSortOption.feeLow:
        return 'Fee (Low to High)';
      case EventSortOption.feeHigh:
        return 'Fee (High to Low)';
    }
  }

  String getFilterText(EventTimeFilter filter) {
    switch (filter) {
      case EventTimeFilter.all:
        return 'All ($allCount)';
      case EventTimeFilter.upcoming:
        return 'Upcoming ($upcomingCount)';
      case EventTimeFilter.past:
        return 'Past ($pastCount)';
      case EventTimeFilter.today:
        return 'Today ($todayCount)';
      case EventTimeFilter.thisWeek:
        return 'This Week ($thisWeekCount)';
      case EventTimeFilter.thisMonth:
        return 'This Month ($thisMonthCount)';
    }
  }
}
