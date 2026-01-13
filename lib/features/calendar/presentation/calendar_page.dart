import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../logic/calendar_provider.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/calendar_filter_bar.dart';
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

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Update provider when tab changes via swipe
        final provider = context.read<CalendarProvider>();
        provider.setViewType(
          _tabController.index == 0
              ? CalendarViewType.month
              : CalendarViewType.timeline,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                        _buildTabBar(themeProvider),
                        provider.selectedCalendars.isEmpty
                            ? _buildEmptyState()
                            : SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: TabBarView(
                                controller: _tabController,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildMonthViewTab(provider),
                                  const TimelineCalendarView(),
                                ],
                              ),
                            ),
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

  Widget _buildTabBar(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('Month View', Icons.calendar_month, 0, themeProvider),
          _buildTabButton('Timeline', Icons.view_timeline, 1, themeProvider),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    IconData icon,
    int index,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
                  themeProvider.currentTheme.primary,
                  colorValue,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: Color.lerp(
                      themeProvider.currentTheme.muted,
                      themeProvider.currentTheme.isDark
                          ? Colors.black
                          : Colors.white,
                      colorValue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: Color.lerp(
                        themeProvider.currentTheme.muted,
                        themeProvider.currentTheme.isDark
                            ? Colors.black
                            : Colors.white,
                        colorValue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthViewTab(CalendarProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const MonthCalendarView(),
          Consumer<CalendarProvider>(
            builder: (_, p, __) {
              return p.getEventsForDate(p.selectedDate).isNotEmpty
                  ? const DayDetailsCard()
                  : const SizedBox.shrink();
            },
          ),
          Consumer<CalendarProvider>(
            builder: (_, p, __) {
              return p.getUpcomingEvents().isNotEmpty
                  ? const UpcomingEventsCard()
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
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
