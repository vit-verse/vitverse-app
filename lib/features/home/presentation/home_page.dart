import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../firebase/analytics/analytics_service.dart';
import '../logic/home_logic.dart';
import 'widgets/greeting_widget.dart';
import 'widgets/home_widgets_section.dart';
import 'widgets/days_selector.dart';
import 'widgets/class_schedule_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _tag = 'HomePage';

  final HomeLogic _homeLogic = HomeLogic();
  late final PageController _dayPageController;

  bool _isRefreshing = false;
  bool _isDataLoading = true;

  /// Current selected day (highlighted)
  int _selectedDay = DateTime.now().weekday - 1;

  /// Actual dates for the current week being viewed
  List<DateTime> _weekDates = [];

  bool _isAnimatingDayChange = false;

  @override
  void initState() {
    super.initState();

    AnalyticsService.instance.logScreenView(
      screenName: 'Home',
      screenClass: 'HomePage',
    );

    // Initialize week dates (current week)
    final now = DateTime.now();
    final weekday = now.weekday - 1; // 0 = Monday
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday));
    _weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));

    _dayPageController = PageController(initialPage: _selectedDay);
    _loadData();
  }

  @override
  void dispose() {
    _dayPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isDataLoading = true);

      await _homeLogic.loadAllData();

      if (mounted) setState(() => _isDataLoading = false);

      Logger.i(_tag, 'Home data loaded');
    } catch (e) {
      Logger.e(_tag, 'Failed to load home data', e);

      if (mounted) {
        setState(() => _isDataLoading = false);
        SnackbarUtils.error(context, 'Failed to load data');
      }
    }
  }

  bool _isCurrentWeek() {
    if (_weekDates.isEmpty) return true;

    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartDate = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );
    final weekStartDate = DateTime(
      _weekDates[0].year,
      _weekDates[0].month,
      _weekDates[0].day,
    );

    return currentWeekStartDate.isAtSameMomentAs(weekStartDate);
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadData();
      if (mounted) SnackbarUtils.success(context, 'Data refreshed');
    } catch (e) {
      Logger.e(_tag, 'Failed refresh', e);
      if (mounted) SnackbarUtils.error(context, 'Refresh failed');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _onDayTap(int dayIndex) async {
    if (_selectedDay == dayIndex || _isAnimatingDayChange) return;

    _isAnimatingDayChange = true;

    // Do NOT update selectedDay yet → avoids flicker
    await _dayPageController.animateToPage(
      dayIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    // After animation, now update the highlight
    if (mounted) {
      setState(() {
        _selectedDay = dayIndex;
      });
    }

    _isAnimatingDayChange = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeProvider.systemOverlayStyle,
          child: Scaffold(
            backgroundColor: themeProvider.currentTheme.background,
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: themeProvider.currentTheme.primary,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxScrolled) {
                  return [
                    // Greeting + Widgets
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top + 24,
                          16,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GreetingWidget(),
                            const SizedBox(height: 28),
                            HomeWidgetsSection(
                              homeLogic: _homeLogic,
                              isRefreshing: _isRefreshing,
                              onRefresh: _handleRefresh,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Sticky Days Bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DaysSelectorDelegate(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          color: themeProvider.currentTheme.background,
                          child: DaysSelector(
                            selectedDay: _selectedDay,
                            onDayChanged: (index) => _onDayTap(index),
                            onWeekChanged: (weekDates) {
                              setState(() {
                                _weekDates = weekDates;
                              });
                            },
                          ),
                        ),
                        isCurrentWeek: _isCurrentWeek(),
                      ),
                    ),
                  ];
                },

                // PageView (Class Schedules)
                body: PageView.builder(
                  controller: _dayPageController,
                  itemCount: 7,

                  // When user SWIPES manually
                  onPageChanged: (index) {
                    if (!_isAnimatingDayChange) {
                      setState(() => _selectedDay = index);
                    }
                  },

                  itemBuilder: (context, index) {
                    return ClassScheduleList(
                      key: ValueKey('class_list_$index'),
                      dayIndex: index,
                      homeLogic: _homeLogic,
                      isDataLoading: _isDataLoading,
                      actualDate:
                          _weekDates.isNotEmpty && index < _weekDates.length
                              ? _weekDates[index]
                              : null,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Sticky header (days selector)
class _DaysSelectorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isCurrentWeek;

  _DaysSelectorDelegate({required this.child, required this.isCurrentWeek});

  @override
  double get minExtent => isCurrentWeek ? 110.0 : 130.0;

  @override
  double get maxExtent => isCurrentWeek ? 110.0 : 130.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, child: child);
  }

  @override
  bool shouldRebuild(_DaysSelectorDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.isCurrentWeek != isCurrentWeek;
  }
}
