import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../logic/attendance_calculator_provider.dart';
import '../widgets/control_card.dart';
import '../widgets/calendar_preview.dart';
import '../widgets/course_projection_card.dart';

class AttendanceCalculatorPage extends StatefulWidget {
  const AttendanceCalculatorPage({super.key});

  @override
  State<AttendanceCalculatorPage> createState() =>
      _AttendanceCalculatorPageState();
}

class _AttendanceCalculatorPageState extends State<AttendanceCalculatorPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AttendenceCalculator',
      screenClass: 'AttendanceCalculatorPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final provider = Provider.of<AttendanceCalculatorProvider>(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Attendance Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, theme),
            tooltip: 'Help & Information',
          ),
        ],
      ),
      body: _buildBody(context, theme, provider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    theme,
    AttendanceCalculatorProvider provider,
  ) {
    if (provider.isLoading) {
      return _buildLoadingState(theme);
    }

    if (provider.errorMessage != null) {
      return _buildErrorState(context, theme, provider);
    }

    return RefreshIndicator(
      onRefresh: provider.reload,
      color: theme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ControlCard(),
            const SizedBox(height: ThemeConstants.spacingLg),
            if (provider.days.isNotEmpty) ...[
              CalendarPreview(
                days: provider.days,
                onDayTap: provider.updateDayStatus,
              ),
              const SizedBox(height: ThemeConstants.spacingMd),
              _buildWeekdayCountSummary(context, theme, provider),
              const SizedBox(height: ThemeConstants.spacingLg),
            ],
            if (provider.projections.isNotEmpty) ...[
              _buildProjectionsHeader(context, theme, provider),
              const SizedBox(height: ThemeConstants.spacingMd),
              ...(provider.projections.toList()
                    ..sort((a, b) => a.courseTitle.compareTo(b.courseTitle)))
                  .map(
                    (projection) =>
                        CourseProjectionCard(projection: projection),
                  ),
            ] else if (provider.days.isNotEmpty) ...[
              _buildNoProjectionsState(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayCountSummary(
    BuildContext context,
    theme,
    AttendanceCalculatorProvider provider,
  ) {
    final counts = provider.calculateWeekdayCounts();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        side: BorderSide(color: theme.muted.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: ThemeConstants.spacingSm,
          horizontal: ThemeConstants.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final weekday = index + 1;
            final regular = counts[weekday]!['regular'] ?? 0;
            final weekend = counts[weekday]!['weekend'] ?? 0;
            final total = regular + weekend;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayNames[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekend > 0 ? '$regular+$weekend' : '$total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: theme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildProjectionsHeader(
    BuildContext context,
    theme,
    AttendanceCalculatorProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Course Projections',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${provider.projections.length} ${provider.projections.length == 1 ? 'course' : 'courses'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.muted),
        ),
      ],
    );
  }

  Widget _buildLoadingState(theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          Text(
            'Loading attendance data...',
            style: TextStyle(color: theme.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    theme,
    AttendanceCalculatorProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.muted),
            const SizedBox(height: ThemeConstants.spacingMd),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: theme.text),
            ),
            const SizedBox(height: ThemeConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: provider.reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.isDark ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProjectionsState(BuildContext context, theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        side: BorderSide(color: theme.muted.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.spacingLg),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: theme.muted),
              const SizedBox(height: ThemeConstants.spacingMd),
              Text(
                'No projections available',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: theme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, theme) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.surface,
            title: Text(
              'Attendance Calculator Info',
              style: TextStyle(color: theme.text),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Select a date range to simulate attendance\n'
                    '• Set your target attendance percentage\n'
                    '• Integrate calendar to auto-mark holidays\n'
                    '• Mark days as Present, Absent, or Holiday\n'
                    '• View projected attendance for each course',
                    style: TextStyle(color: theme.text, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calendar Integration:',
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Select "Integrate Calendar" to apply holidays\n'
                    '• Automatically marks instructional/non-instructional days\n'
                    '• Detects makeup days (Saturday as weekday)\n'
                    '• Fetch calendars from Settings if not available',
                    style: TextStyle(color: theme.text, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Got it', style: TextStyle(color: theme.primary)),
              ),
            ],
          ),
    );
  }
}
