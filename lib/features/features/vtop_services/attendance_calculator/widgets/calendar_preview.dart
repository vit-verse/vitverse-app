import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../models/attendance_day.dart';
import '../models/day_status.dart';
import '../logic/attendance_calculator_logic.dart';
import 'day_tile.dart';
import 'unified_day_dialog.dart';

/// Widget displaying calendar preview with interactive days
class CalendarPreview extends StatelessWidget {
  final List<AttendanceDay> days;
  final Function(AttendanceDay) onDayTap;

  const CalendarPreview({
    super.key,
    required this.days,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    if (days.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    final groupedByMonth = AttendanceCalculatorLogic.groupDaysByMonth(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, theme),
        const SizedBox(height: ThemeConstants.spacingSm),
        _buildInstructionText(context, theme),
        const SizedBox(height: ThemeConstants.spacingMd),
        _buildLegend(context, theme),
        const SizedBox(height: ThemeConstants.spacingMd),
        ...groupedByMonth.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ThemeConstants.spacingLg),
            child: _buildMonthCalendar(context, theme, entry.key, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, theme) {
    return Text(
      'Calendar Preview',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: theme.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context, theme) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: AppCardStyles.smallWidgetDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.primary.withOpacity(0.1),
        customBorderColor: theme.primary.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.primary),
          const SizedBox(width: ThemeConstants.spacingSm),
          Expanded(
            child: Text(
              'Weekdays: Tap to cycle Absent → Present → Holiday. Weekends: Schedule as any weekday or mark holiday.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: theme.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, theme) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(context, theme, DayStatus.absent, 'Absent'),
          _buildLegendItem(context, theme, DayStatus.present, 'Present'),
          _buildLegendItem(context, theme, DayStatus.holiday, 'Holiday'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    theme,
    DayStatus status,
    String label,
  ) {
    final color = status.getColor(theme.primary, theme.isDark);
    return Row(
      children: [
        Icon(status.icon, size: 16, color: color),
        const SizedBox(width: ThemeConstants.spacingXs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.text),
        ),
      ],
    );
  }

  Widget _buildMonthCalendar(
    BuildContext context,
    theme,
    String monthYear,
    List<AttendanceDay> monthDays,
  ) {
    final weeks = AttendanceCalculatorLogic.getCalendarWeeks(monthDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthYear,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingSm),
        Container(
          padding: const EdgeInsets.all(ThemeConstants.spacingSm),
          decoration: AppCardStyles.compactCardDecoration(
            isDark: theme.isDark,
            customBackgroundColor: theme.surface,
          ),
          child: Column(
            children: [
              // Weekday headers
              _buildWeekdayHeaders(context, theme),
              const SizedBox(height: ThemeConstants.spacingXs),
              // Calendar grid
              ...weeks.map((week) => _buildWeekRow(context, week)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context, theme) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children:
          weekdays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildWeekRow(BuildContext context, List<AttendanceDay?> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeConstants.spacingXs),
      child: Row(
        children:
            week.map((day) {
              return Expanded(
                child:
                    day != null
                        ? AspectRatio(
                          aspectRatio: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: DayTile(
                              day: day,
                              onTap:
                                  (tappedDay) =>
                                      _handleDayTap(context, tappedDay),
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              );
            }).toList(),
      ),
    );
  }

  /// Handle day tap with unified dialog
  Future<void> _handleDayTap(BuildContext context, AttendanceDay day) async {
    // Check if it's a weekend, holiday, or CAT day - show unified dialog
    final isWeekend =
        day.date.weekday == DateTime.saturday ||
        day.date.weekday == DateTime.sunday;
    final isHoliday = day.status == DayStatus.holiday;
    final isCatDay = day.isCatDay;

    if (isWeekend || isHoliday || isCatDay) {
      // Show unified dialog for complex cases
      final result = await UnifiedDayDialog.show(context, day);

      if (result != null) {
        final updatedDay = day.copyWith(
          catIncludedInCalculation: result.includeInCalculation,
          status: result.status,
          followsScheduleOf: result.weekday,
        );
        onDayTap(updatedDay);
      }
    } else {
      // Weekday logic: Quick cycle through Absent → Present → Holiday
      DayStatus nextStatus;
      switch (day.status) {
        case DayStatus.absent:
          nextStatus = DayStatus.present;
          break;
        case DayStatus.present:
          nextStatus = DayStatus.holiday;
          break;
        case DayStatus.holiday:
          nextStatus = DayStatus.absent;
          break;
      }

      final updatedDay = day.copyWith(status: nextStatus);
      onDayTap(updatedDay);
    }
  }

  Widget _buildEmptyState(BuildContext context, theme) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_month_outlined, size: 48, color: theme.muted),
            const SizedBox(height: ThemeConstants.spacingMd),
            Text(
              'Select a date range to view calendar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
