import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../logic/events_provider.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import 'post_event_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'upcoming';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AnalyticsService.instance.logScreenView(
      screenName: 'Events',
      screenClass: 'EventsPage',
    );
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
      context.read<EventsProvider>().setSearchQuery(_searchQuery);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    try {
      await context.read<EventsProvider>().loadEvents(forceRefresh: true);
      if (mounted) {
        SnackbarUtils.success(context, 'Events refreshed');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to refresh events');
      }
    }
  }

  Widget _buildStatistics(dynamic theme) {
    return Consumer<EventsProvider>(
      builder: (context, provider, _) {
        final eventsCount =
            _tabController.index == 0
                ? provider.exploreEvents.length
                : context
                        .findAncestorStateOfType<_MyEventsTabState>()
                        ?._myEvents
                        .length ??
                    0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 14, color: theme.muted),
              const SizedBox(width: 6),
              Text(
                'Total: $eventsCount ${eventsCount == 1 ? "event" : "events"}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeProvider themeProvider,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      themeProvider.currentTheme.primary,
                    ),
                  ),
                )
                : Icon(icon, size: 20, color: themeProvider.currentTheme.text),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: themeProvider.currentTheme.background,
        appBar: AppBar(
          title: Text(
            'Events',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: themeProvider.currentTheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: themeProvider.currentTheme.text),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: themeProvider.currentTheme.text,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Consumer<EventsProvider>(
              builder: (context, provider, _) {
                if (provider.lastSyncTime != null) {
                  final timeAgo = _getTimeAgo(provider.lastSyncTime!);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 14),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        color: themeProvider.currentTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Consumer<EventsProvider>(
                builder: (context, provider, _) {
                  return _buildActionButton(
                    icon: provider.isSyncing ? Icons.sync : Icons.refresh,
                    onPressed: provider.isSyncing ? () {} : _refreshEvents,
                    themeProvider: themeProvider,
                    isLoading: provider.isSyncing,
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(themeProvider.currentTheme),
            _buildSearchAndSortBar(themeProvider.currentTheme),
            _buildStatistics(themeProvider.currentTheme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [_ExploreTab(), _MyEventsTab()],
              ),
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return _tabController.index == 1
                ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostEventPage(),
                      ),
                    );
                    if (result == true && mounted) {
                      _refreshEvents();
                    }
                  },
                  backgroundColor: themeProvider.currentTheme.primary,
                  label: const Text(
                    'Post Event',
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Explore',
              icon: Icons.explore_outlined,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'My Events',
              icon: Icons.person_outline,
              index: 1,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
    required dynamic theme,
  }) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final animValue = _tabController.animation?.value ?? 0.0;
        final progress = (animValue - index).abs().clamp(0.0, 1.0);
        final colorValue = 1.0 - progress;

        return GestureDetector(
          onTap: () {
            _tabController.animateTo(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, theme.primary, colorValue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Color.lerp(theme.muted, Colors.white, colorValue),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Color.lerp(theme.muted, Colors.white, colorValue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndSortBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.muted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.text, fontSize: 14),
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        hintText: 'Search by title or date...',
                        hintStyle: TextStyle(color: theme.muted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.border),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _sortBy = value);
                context.read<EventsProvider>().setSortBy(value);
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'upcoming',
                      child: Text('Upcoming Events'),
                    ),
                    const PopupMenuItem(
                      value: 'most_liked',
                      child: Text('Most Liked'),
                    ),
                    const PopupMenuItem(
                      value: 'most_commented',
                      child: Text('Most Commented'),
                    ),
                  ],
              child: Row(
                children: [
                  Icon(Icons.sort, color: theme.muted, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _getSortLabel(_sortBy),
                    style: TextStyle(color: theme.text, fontSize: 14),
                  ),
                  Icon(Icons.arrow_drop_down, color: theme.muted, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'upcoming':
        return 'Upcoming';
      case 'most_liked':
        return 'Likes';
      case 'most_commented':
        return 'Comments';
      default:
        return 'Upcoming';
    }
  }
}

class _ExploreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.exploreEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 80,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh:
              () =>
                  context.read<EventsProvider>().loadEvents(forceRefresh: true),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.exploreEvents.length,
            itemBuilder: (context, index) {
              return EventCard(event: provider.exploreEvents[index]);
            },
          ),
        );
      },
    );
  }
}

class _MyEventsTab extends StatefulWidget {
  @override
  State<_MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<_MyEventsTab> {
  String? _userId;
  List<Event> _myEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson != null && profileJson.isNotEmpty) {
        final json = jsonDecode(profileJson) as Map<String, dynamic>;
        final userId = json['registerNumber'] as String?;

        if (userId != null) {
          setState(() => _userId = userId);
          if (!mounted) return;
          final events = await context.read<EventsProvider>().getUserEvents(
            userId,
          );
          setState(() => _myEvents = events);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load your events');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: Text('Are you sure you want to delete "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        if (!mounted) return;
        await context.read<EventsProvider>().deleteUserEvent(event.id);
        setState(() => _myEvents.removeWhere((e) => e.id == event.id));
        if (mounted) {
          SnackbarUtils.success(context, 'Event deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to delete event');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text('Please login to view your events'),
          ],
        ),
      );
    }

    if (_myEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t posted any events yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostEventPage(),
                  ),
                );
                if (result == true) {
                  _loadUserEvents();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Post Your First Event'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserEvents,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _myEvents.length,
        itemBuilder: (context, index) {
          final event = _myEvents[index];
          return EventCard(
            event: event,
            showDeleteButton: true,
            onDelete: () => _deleteEvent(event),
          );
        },
      ),
    );
  }
}
