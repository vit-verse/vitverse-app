import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../models/attendance_day.dart';
import '../logic/attendance_calculator_provider.dart';
import 'unified_day_dialog.dart';

/// Widget for a single day tile in the calendar
class DayTile extends StatelessWidget {
  final AttendanceDay day;
  final Function(AttendanceDay)? onTap;

  const DayTile({super.key, required this.day, this.onTap});

  String _getWeekdayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  Future<void> _showUnifiedDialog(BuildContext context) async {
    final provider = Provider.of<AttendanceCalculatorProvider>(
      context,
      listen: false,
    );

    final result = await UnifiedDayDialog.show(context, day);

    if (result != null) {
      provider.updateDayWithDetails(
        day,
        includeInCalculation: result.includeInCalculation,
        followsScheduleOf: result.weekday,
        status: result.status,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final statusColor = day.status.getColor(theme.primary, theme.isDark);
    final isWeekend =
        day.date.weekday == DateTime.saturday ||
        day.date.weekday == DateTime.sunday;

    return InkWell(
      onTap: () {
        // Show dialog only for CAT days or weekends
        if (day.isCatDay ||
            (day.date.weekday == DateTime.saturday ||
                day.date.weekday == DateTime.sunday)) {
          _showUnifiedDialog(context);
        } else if (onTap != null) {
          // For normal weekdays, just toggle status
          onTap!(day);
        }
      },
      borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
          border: Border.all(
            color: statusColor.withOpacity(day.isToday ? 0.6 : 0.3),
            width: day.isToday ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (day.isCatDay && day.catNumber != null) ...[
                Text(
                  'CAT${day.catNumber}',
                  style: TextStyle(
                    fontSize: 7,
                    height: 1.0,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
              ] else if (isWeekend && day.followsScheduleOf != null) ...[
                Text(
                  _getWeekdayAbbr(day.followsScheduleOf!),
                  style: TextStyle(
                    fontSize: 6,
                    height: 1.0,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Flexible(
                child: Text(
                  day.day.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.text,
                    fontWeight: day.isToday ? FontWeight.bold : FontWeight.w500,
                    height: 1.1,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Icon(day.status.icon, size: 12, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}
