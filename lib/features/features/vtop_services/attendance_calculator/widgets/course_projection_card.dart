import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../models/course_projection.dart';
import '../models/day_status.dart';
import 'buffer_indicator.dart';
import '../presentation/course_detail_page.dart';
import '../logic/attendance_calculator_provider.dart';

/// Widget displaying course attendance projection card
class CourseProjectionCard extends StatelessWidget {
  final CourseProjection projection;

  const CourseProjectionCard({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return InkWell(
      onTap: () {
        final provider = Provider.of<AttendanceCalculatorProvider>(
          context,
          listen: false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ChangeNotifierProvider<AttendanceCalculatorProvider>.value(
                      value: provider,
                      child: CourseDetailPage(projection: projection),
                    ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: theme.isDark,
          customBackgroundColor: theme.surface,
          customBorderColor: _getStatusColor(theme).withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: ThemeConstants.spacingMd),
            _buildAttendanceStats(context, theme),
            const SizedBox(height: ThemeConstants.spacingMd),
            _buildClassBreakdown(context, theme),
            const SizedBox(height: ThemeConstants.spacingMd),
            _buildDayWiseBreakdown(context, theme),
            const SizedBox(height: ThemeConstants.spacingMd),
            BufferIndicator(
              bufferClasses: projection.bufferClasses,
              meetsTarget: projection.meetsTarget,
            ),
            const SizedBox(height: ThemeConstants.spacingSm),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, size: 14, color: theme.muted),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(ThemeConstants.spacingSm),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
          ),
          child: Icon(Icons.book_outlined, color: theme.primary, size: 20),
        ),
        const SizedBox(width: ThemeConstants.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projection.courseCode,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                projection.courseTitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: theme.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(BuildContext context, theme) {
    // Floor percentages to 1 decimal place (truncate, don't round)
    // e.g., 77.777% -> 77.7%, not 77.8%
    final currentFloored = (projection.currentPercentage * 10).floor() / 10;
    final projectedFloored = (projection.projectedPercentage * 10).floor() / 10;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Current',
            '${currentFloored.toStringAsFixed(1)}%',
            projection.currentAttendanceText,
            _getCurrentStatusColor(theme),
          ),
        ),
        const SizedBox(width: ThemeConstants.spacingMd),
        Container(
          width: 1,
          height: 40,
          color: theme.muted.withValues(alpha: 0.2),
        ),
        const SizedBox(width: ThemeConstants.spacingMd),
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            'Projected',
            '${projectedFloored.toStringAsFixed(1)}%',
            projection.projectedAttendanceText,
            _getStatusColor(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    theme,
    String label,
    String percentage,
    String ratio,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.muted, fontSize: 11),
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
          ).textTheme.bodySmall?.copyWith(color: theme.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildClassBreakdown(BuildContext context, theme) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In Selected Range',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total: ${projection.totalClassesInRange}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDayWiseBreakdown(BuildContext context, theme) {
    if (projection.dayWiseClassCount.isEmpty &&
        projection.schedule.daySlots.isEmpty) {
      return const SizedBox.shrink();
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final scheduledDays = projection.schedule.classDays.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, size: 14, color: theme.primary),
              const SizedBox(width: ThemeConstants.spacingXs),
              Text(
                'Day-wise & Slot-wise Breakdown',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          ...scheduledDays.map((weekday) {
            final dayName = dayNames[weekday - 1];
            final dayCount =
                projection.dayWiseClassCount[weekday] ??
                0; // Number of days in range
            final slots = projection.schedule.getSlotsForDay(weekday);
            final slotsPerDay = slots.isNotEmpty ? slots.length : 1;
            final totalClasses =
                dayCount * slotsPerDay; // Total classes = days × slots/day

            return Padding(
              padding: const EdgeInsets.only(bottom: ThemeConstants.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 35,
                    child: Text(
                      dayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeConstants.spacingXs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      slotsPerDay > 1
                          ? '$dayCount×$slotsPerDay=$totalClasses'
                          : '$totalClasses class${totalClasses != 1 ? 'es' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (slots.isNotEmpty) ...[
                    const SizedBox(width: ThemeConstants.spacingXs),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children:
                            slots.map((slot) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.muted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: theme.muted.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  slot.slotName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: theme.muted,
                                    fontSize: 9,
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
        Icon(icon, size: 16, color: color),
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
