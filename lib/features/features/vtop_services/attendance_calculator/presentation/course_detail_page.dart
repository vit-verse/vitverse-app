import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../models/course_projection.dart';
import '../models/attendance_day.dart';
import '../models/day_status.dart';
import '../logic/attendance_calculator_provider.dart';
import '../widgets/buffer_indicator.dart';

class CourseDetailPage extends StatelessWidget {
  final CourseProjection projection;

  const CourseDetailPage({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final provider = Provider.of<AttendanceCalculatorProvider>(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projection.courseCode,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              projection.courseTitle,
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceOverview(context, theme),
            const SizedBox(height: ThemeConstants.spacingLg),
            _buildScheduleInfo(context, theme),
            const SizedBox(height: ThemeConstants.spacingLg),
            _buildCalendarSection(context, theme, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceOverview(BuildContext context, theme) {
    final currentFloored = (projection.currentPercentage * 10).floor() / 10;
    final projectedFloored = (projection.projectedPercentage * 10).floor() / 10;
    final statusColor = _getStatusColor(theme);

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
        customBorderColor: statusColor.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  theme,
                  'Current',
                  '${currentFloored.toStringAsFixed(1)}%',
                  projection.currentAttendanceText,
                  _getCurrentStatusColor(theme),
                ),
              ),
              const SizedBox(width: ThemeConstants.spacingMd),
              Expanded(
                child: _buildStatCard(
                  context,
                  theme,
                  'Projected',
                  '${projectedFloored.toStringAsFixed(1)}%',
                  projection.projectedAttendanceText,
                  statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          BufferIndicator(
            bufferClasses: projection.bufferClasses,
            meetsTarget: projection.meetsTarget,
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          _buildClassBreakdown(context, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    theme,
    String label,
    String percentage,
    String ratio,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: theme.muted, fontSize: 12),
          ),
          const SizedBox(height: ThemeConstants.spacingXs),
          Text(
            percentage,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ratio,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: theme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildClassBreakdown(BuildContext context, theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBreakdownItem(
          context,
          theme,
          DayStatus.present.icon,
          projection.presentInRange.toString(),
          'Present',
          DayStatus.present.getColor(theme.primary, theme.isDark),
        ),
        _buildBreakdownItem(
          context,
          theme,
          DayStatus.absent.icon,
          projection.absentInRange.toString(),
          'Absent',
          DayStatus.absent.getColor(theme.primary, theme.isDark),
        ),
        _buildBreakdownItem(
          context,
          theme,
          DayStatus.holiday.icon,
          projection.holidayInRange.toString(),
          'Holiday',
          DayStatus.holiday.getColor(theme.primary, theme.isDark),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    theme,
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: ThemeConstants.spacingXs),
        Text(
          count,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.muted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(BuildContext context, theme) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final scheduledDays = projection.schedule.classDays.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, color: theme.primary, size: 20),
              const SizedBox(width: ThemeConstants.spacingSm),
              Text(
                'Schedule Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: theme.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          ...scheduledDays.map((weekday) {
            final dayName = dayNames[weekday - 1];
            final dayCount = projection.dayWiseClassCount[weekday] ?? 0;
            final slots = projection.schedule.getSlotsForDay(weekday);
            final slotsPerDay = slots.isNotEmpty ? slots.length : 1;
            final totalClasses = dayCount * slotsPerDay;

            return Padding(
              padding: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            ThemeConstants.radiusSm,
                          ),
                        ),
                        child: Text(
                          dayName,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: ThemeConstants.spacingMd),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            ThemeConstants.radiusSm,
                          ),
                        ),
                        child: Text(
                          slotsPerDay > 1
                              ? '$dayCount days × $slotsPerDay slots = $totalClasses classes'
                              : '$totalClasses class${totalClasses != 1 ? 'es' : ''}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (slots.isNotEmpty) ...[
                    const SizedBox(height: ThemeConstants.spacingSm),
                    Padding(
                      padding: const EdgeInsets.only(left: 66),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            slots.map((slot) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.muted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    ThemeConstants.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: theme.muted.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  slot.slotName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: theme.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(
    BuildContext context,
    theme,
    AttendanceCalculatorProvider provider,
  ) {
    final days = provider.days;
    final groupedByMonth = <String, List<AttendanceDay>>{};

    for (final day in days) {
      final monthKey = '${day.monthName} ${day.date.year}';
      groupedByMonth.putIfAbsent(monthKey, () => []).add(day);
    }

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: theme.primary, size: 20),
              const SizedBox(width: ThemeConstants.spacingSm),
              Text(
                'Calendar View',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: theme.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          ...groupedByMonth.entries.map((entry) {
            return _buildMonthSection(
              context,
              theme,
              entry.key,
              entry.value,
              provider,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    theme,
    String monthLabel,
    List<AttendanceDay> monthDays,
    AttendanceCalculatorProvider provider,
  ) {
    final weeks = <List<AttendanceDay?>>[];
    List<AttendanceDay?> currentWeek = [];

    monthDays.sort((a, b) => a.date.compareTo(b.date));

    // Fill initial days if month doesn't start on Monday
    final firstDay = monthDays.first;
    final firstWeekday = firstDay.date.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(null);
    }

    for (final day in monthDays) {
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      currentWeek.add(day);
    }

    // Fill remaining days in last week
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstants.spacingMd,
              vertical: ThemeConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
            ),
            child: Text(
              monthLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          // Weekday headers
          Row(
            children:
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          // Weeks
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: ThemeConstants.spacingSm),
              child: Row(
                children:
                    week.map((day) {
                      if (day == null) {
                        return const Expanded(child: SizedBox());
                      }
                      return Expanded(
                        child: _buildDayCell(context, theme, day, provider),
                      );
                    }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    theme,
    AttendanceDay day,
    AttendanceCalculatorProvider provider,
  ) {
    final statusColor = day.status.getColor(theme.primary, theme.isDark);
    final isWeekend =
        day.date.weekday == DateTime.saturday ||
        day.date.weekday == DateTime.sunday;

    // Check if this course has class on this day
    final effectiveWeekday = day.followsScheduleOf ?? day.date.weekday;
    final hasClassOnThisDay = projection.schedule.classDays.contains(
      effectiveWeekday,
    );
    final opacity = hasClassOnThisDay ? 1.0 : 0.3;

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(hasClassOnThisDay ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        border: Border.all(
          color: statusColor.withOpacity(
            hasClassOnThisDay ? (day.isToday ? 0.6 : 0.4) : 0.1,
          ),
          width: hasClassOnThisDay && day.isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (day.isCatDay && day.catNumber != null) ...[
            Text(
              'CAT${day.catNumber}',
              style: TextStyle(
                fontSize: 7,
                color: statusColor.withOpacity(opacity),
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (isWeekend && day.followsScheduleOf != null) ...[
            Text(
              _getWeekdayAbbr(day.followsScheduleOf!),
              style: TextStyle(
                fontSize: 6,
                color: statusColor.withOpacity(opacity),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          Text(
            day.day.toString(),
            style: TextStyle(
              fontSize: 12,
              color: theme.text.withOpacity(opacity),
              fontWeight:
                  hasClassOnThisDay && day.isToday
                      ? FontWeight.bold
                      : FontWeight.w500,
            ),
          ),
          Icon(
            day.status.icon,
            size: 11,
            color: statusColor.withOpacity(opacity),
          ),
        ],
      ),
    );
  }

  String _getWeekdayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  bool _hasClassOnDay(AttendanceDay day) {
    // Check if this course has classes on this day of the week
    final effectiveWeekday = day.followsScheduleOf ?? day.date.weekday;
    return projection.schedule.classDays.contains(effectiveWeekday);
  }

  Color _getCurrentStatusColor(theme) {
    if (projection.currentPercentage >= 85) {
      return theme.isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
    } else if (projection.currentPercentage >= 75) {
      return theme.isDark ? const Color(0xFFFFCA28) : const Color(0xFFFFA000);
    } else {
      return theme.isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935);
    }
  }

  Color _getStatusColor(theme) {
    if (projection.projectedPercentage >= 85) {
      return theme.isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
    } else if (projection.projectedPercentage >= 75) {
      return theme.isDark ? const Color(0xFFFFCA28) : const Color(0xFFFFA000);
    } else {
      return theme.isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935);
    }
  }
}
