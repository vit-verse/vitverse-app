import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../models/event_model.dart';
import '../logic/eventhub_provider.dart';
import '../eventhub_constants.dart';

class EventHubPage extends StatefulWidget {
  const EventHubPage({super.key});

  @override
  State<EventHubPage> createState() => _EventHubPageState();
}

class _EventHubPageState extends State<EventHubPage> {
  late EventHubProvider _provider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = EventHubProvider();
    _provider.init();
    AnalyticsService.instance.logScreenView(
      screenName: 'Eventhub',
      screenClass: 'EventHbPage'
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<EventHubProvider>(
        builder:
            (context, provider, _) => Scaffold(
              backgroundColor: themeProvider.currentTheme.background,
              appBar: _buildAppBar(themeProvider),
              body: _buildBody(themeProvider, provider),
            ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider theme) {
    return AppBar(
      backgroundColor: theme.currentTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.currentTheme.text),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'EventHub',
        style: TextStyle(
          color: theme.currentTheme.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeProvider theme, EventHubProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(theme.currentTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading events...',
              style: TextStyle(color: theme.currentTheme.muted),
            ),
          ],
        ),
      );
    }

    if (provider.error != null && provider.allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: theme.currentTheme.muted),
              const SizedBox(height: 16),
              Text(
                'Failed to load events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.currentTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your internet connection',
                style: TextStyle(color: theme.currentTheme.muted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: provider.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.currentTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (provider.lastRefresh != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: theme.currentTheme.surface,
            child: Center(
              child: Text(
                'Last refreshed: ${provider.getLastRefreshFormatted()}',
                style: TextStyle(fontSize: 10, color: theme.currentTheme.muted),
              ),
            ),
          ),
        _buildFilterChips(provider, theme),
        _buildSearchBar(provider, theme),
        Expanded(
          child:
              provider.filteredEvents.isEmpty
                  ? _buildEmptyState(theme, provider)
                  : RefreshIndicator(
                    onRefresh: () async {
                      await provider.refresh();
                      if (mounted) {
                        SnackbarUtils.show(
                          context,
                          message: 'Events refreshed',
                          type: SnackbarType.success,
                        );
                      }
                    },
                    child: _buildEventList(theme, provider),
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(EventHubProvider provider, ThemeProvider theme) {
    final filters = [
      ('All (${provider.allCount})', EventTimeFilter.all),
      ('Upcoming (${provider.upcomingCount})', EventTimeFilter.upcoming),
      ('Past (${provider.pastCount})', EventTimeFilter.past),
      ('Today (${provider.todayCount})', EventTimeFilter.today),
      ('This Week (${provider.thisWeekCount})', EventTimeFilter.thisWeek),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children:
            filters.map((f) {
              final isSelected = provider.timeFilter == f.$2;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => provider.setTimeFilter(f.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.currentTheme.primary
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.currentTheme.primary
                                : theme.currentTheme.border,
                      ),
                    ),
                    child: Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color:
                            isSelected ? Colors.white : theme.currentTheme.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(EventHubProvider provider, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.currentTheme.surface,
        border: Border(bottom: BorderSide(color: theme.currentTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: theme.currentTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.sort, size: 16, color: theme.currentTheme.muted),
                const SizedBox(width: 4),
                DropdownButton<EventSortOption>(
                  value: provider.sortOption,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    color: theme.currentTheme.text,
                    fontSize: 13,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: theme.currentTheme.muted,
                  ),
                  onChanged:
                      (o) => o != null ? provider.setSortOption(o) : null,
                  items:
                      EventSortOption.values
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                provider.getSortOptionText(o),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.currentTheme.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search keyword or title',
                hintStyle: TextStyle(
                  color: theme.currentTheme.muted,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: theme.currentTheme.muted,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: theme.currentTheme.muted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              provider.clearSearch();
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: theme.currentTheme.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.currentTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.currentTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.currentTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (q) => setState(() => provider.setSearchQuery(q)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme, EventHubProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.event_busy,
              size: 64,
              color: theme.currentTheme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No events match your search'
                  : 'No events found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.currentTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Try different keywords'
                  : 'Try changing your filter or refresh',
              style: TextStyle(color: theme.currentTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(ThemeProvider theme, EventHubProvider provider) {
    final grouped = <String, List<Event>>{};
    for (var e in provider.filteredEvents) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final sorted =
        grouped.keys.toList()..sort(
          (a, b) =>
              provider.sortOption == EventSortOption.dateNewest
                  ? b.compareTo(a)
                  : a.compareTo(b),
        );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final key = sorted[i];
        final events = grouped[key]!;
        final parts = key.split('-');
        final month = EventHubConstants.monthNames[int.parse(parts[1]) - 1];
        final year = parts[0];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: theme.currentTheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.currentTheme.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: theme.currentTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$month $year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.currentTheme.text,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.currentTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${events.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.currentTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              children:
                  events
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildEventCard(e, theme),
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Event e, ThemeProvider theme) {
    return GestureDetector(
      onTap: () => _showEventDetail(e, theme),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.currentTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.currentTheme.border),
          boxShadow: [
            BoxShadow(
              color: theme.currentTheme.text.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEventDetail(e, theme),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.currentTheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: theme.currentTheme.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.currentTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.currentTheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.currentTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.venue,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.currentTheme.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: 16,
                        color: theme.currentTheme.text,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.fee.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.currentTheme.text,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        e.isTeamEvent ? Icons.groups : Icons.person_outline,
                        size: 16,
                        color: theme.currentTheme.text,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.teamSizeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.currentTheme.text,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.currentTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.currentTheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetail(Event e, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, ctrl) => Container(
                  decoration: BoxDecoration(
                    color: theme.currentTheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.currentTheme.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: ctrl,
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              e.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.currentTheme.text,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Event Date',
                              e.formattedDateWithDay,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.location_on,
                              'Venue',
                              e.venue,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.people,
                              'Participant Type',
                              e.participantType,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.label,
                              'Category',
                              e.category,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.currency_rupee,
                              'Registration Fee',
                              '₹${e.fee} per participant',
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              e.isTeamEvent
                                  ? Icons.groups
                                  : Icons.person_outline,
                              'Team Size',
                              e.teamSizeDisplay,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.tag,
                              'Event ID',
                              '#${e.id}',
                              theme,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _addToCalendar(e),
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    label: const Text('Add to Calendar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          theme.currentTheme.primary,
                                      side: BorderSide(
                                        color: theme.currentTheme.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _shareEvent(e),
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          theme.currentTheme.primary,
                                      side: BorderSide(
                                        color: theme.currentTheme.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openEventHub(e),
                              icon: const Icon(Icons.open_in_browser, size: 18),
                              label: const Text('View Details on Website'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.currentTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                minimumSize: const Size(double.infinity, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeProvider theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.currentTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.currentTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 15, color: theme.currentTheme.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addToCalendar(Event e) async {
    final start =
        e.date
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')[0] +
        'Z';
    final end =
        e.date
            .add(Duration(hours: EventHubConstants.addToCalendarDurationHours))
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')[0] +
        'Z';
    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(e.title)}&dates=$start/$end&details=${Uri.encodeComponent('Category: ${e.category}\nFee: ₹${e.fee}')}&location=${Uri.encodeComponent(e.venue)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        SnackbarUtils.show(
          context,
          message: 'Opening calendar...',
          type: SnackbarType.info,
        );
      }
    } else {
      if (mounted) {
        SnackbarUtils.show(
          context,
          message: 'Could not open calendar',
          type: SnackbarType.error,
        );
      }
      Share.share(
        'Add to Calendar:\n\n${e.title}\nDate: ${e.formattedDateWithDay}\nVenue: ${e.venue}',
      );
    }
  }

  void _shareEvent(Event e) {
    Share.share(
      '${e.title}\n\nDate: ${e.formattedDateWithDay}\nVenue: ${e.venue}\nCategory: ${e.category}\nFee: ₹${e.fee}\n\nEvent ID: #${e.id}',
      subject: e.title,
    );
  }

  Future<void> _openEventHub(Event e) async {
    final url = Uri.parse(
      '${EventHubConstants.baseUrl}${EventHubConstants.eventsEndpoint}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        SnackbarUtils.show(
          context,
          message: 'Could not open EventHub website',
          type: SnackbarType.error,
        );
      }
    }
  }
}
