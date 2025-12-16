import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../logic/calendar_provider.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/calendar_filter_bar.dart';
import '../widgets/calendar_view_switcher.dart';
import '../widgets/month_calendar_view.dart';
import '../widgets/timeline_calendar_view.dart';
import '../widgets/day_details_card.dart';
import '../widgets/upcoming_events_card.dart';
import 'calendar_settings_page.dart';

import '../../../core/loading/optimized_lazy_loader.dart';
import '../../../core/utils/snackbar_utils.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Future<void> _refreshCalendars() async {
    final provider = context.read<CalendarProvider>();
    final status = await provider.refreshSelectedCalendars();

    if (!mounted) return;

    switch (status) {
      case RefreshStatus.success:
        SnackbarUtils.success(context, 'Calendars refreshed successfully');
        break;
      case RefreshStatus.partialSuccess:
        SnackbarUtils.warning(context, 'Some data refreshed, some from cache');
        break;
      case RefreshStatus.cacheOnly:
        SnackbarUtils.warning(context, 'Offline — showing cached data');
        break;
      case RefreshStatus.failed:
        SnackbarUtils.error(context, provider.error ?? 'Refresh failed');
        break;
    }
  }

  void _showSettingsPage(BuildContext context) {
    final provider = context.read<CalendarProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OptimizedLazyLoader(
              featureKey: 'calendar_settings',
              title: 'Calendar Settings',
              pageBuilder:
                  () => CalendarSettingsPageLoader(calendarProvider: provider),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        body: Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: _refreshCalendars,
              child: CustomScrollView(
                slivers: [
                  // 🔥 Sticky, fixed AppBar at top
                  CalendarAppBar(
                    onRefresh: _refreshCalendars,
                    onSettings: () => _showSettingsPage(context),
                  ),

                  // MAIN CONTENT
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const CalendarFilterBar(),
                        const CalendarViewSwitcher(),
                        provider.selectedCalendars.isEmpty
                            ? _buildEmptyState()
                            : _buildCalendarContent(provider),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarContent(CalendarProvider provider) {
    return Column(
      children: [
        // Main calendar view
        provider.viewType == CalendarViewType.month
            ? const MonthCalendarView()
            : const TimelineCalendarView(),

        // Selected day details (month view only)
        if (provider.viewType == CalendarViewType.month)
          Consumer<CalendarProvider>(
            builder: (_, p, __) {
              return p.getEventsForDate(p.selectedDate).isNotEmpty
                  ? const DayDetailsCard()
                  : const SizedBox.shrink();
            },
          ),

        // Upcoming events
        if (provider.viewType == CalendarViewType.month)
          Consumer<CalendarProvider>(
            builder: (_, p, __) {
              return p.getUpcomingEvents().isNotEmpty
                  ? const UpcomingEventsCard()
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Calendars Selected',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Open settings to select your academic calendar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showSettingsPage(context),
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class CalendarSettingsPageLoader extends StatelessWidget {
  final CalendarProvider calendarProvider;

  const CalendarSettingsPageLoader({super.key, required this.calendarProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: calendarProvider,
      child: const CalendarSettingsPage(),
    );
  }
}
