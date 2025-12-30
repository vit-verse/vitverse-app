import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../models/day_status.dart';
import '../models/attendance_day.dart';

/// Result from the unified day dialog
class UnifiedDayResult {
  final bool includeInCalculation; // For CAT days
  final int? weekday; // Which weekday schedule to follow (1=Mon...5=Fri)
  final DayStatus status; // Present or Absent

  const UnifiedDayResult({
    required this.includeInCalculation,
    this.weekday,
    required this.status,
  });
}

/// Unified dialog that handles both CAT days and regular makeup days
class UnifiedDayDialog extends StatefulWidget {
  final AttendanceDay day;

  const UnifiedDayDialog({super.key, required this.day});

  /// Show the dialog and return the result
  static Future<UnifiedDayResult?> show(
    BuildContext context,
    AttendanceDay day,
  ) async {
    return await showDialog<UnifiedDayResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => UnifiedDayDialog(day: day),
    );
  }

  @override
  State<UnifiedDayDialog> createState() => _UnifiedDayDialogState();
}

class _UnifiedDayDialogState extends State<UnifiedDayDialog> {
  late bool includeInCalculation;
  late int? selectedWeekday;
  late DayStatus selectedStatus;

  @override
  void initState() {
    super.initState();

    if (widget.day.isCatDay) {
      includeInCalculation = widget.day.catIncludedInCalculation;
      selectedWeekday = widget.day.followsScheduleOf ?? widget.day.date.weekday;
      selectedStatus =
          widget.day.status == DayStatus.holiday
              ? DayStatus.absent
              : widget.day.status;
    } else {
      includeInCalculation = true;
      selectedWeekday = widget.day.followsScheduleOf ?? widget.day.date.weekday;
      selectedStatus =
          widget.day.status == DayStatus.holiday
              ? DayStatus.absent
              : widget.day.status;
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final isWeekend =
        widget.day.date.weekday == DateTime.saturday ||
        widget.day.date.weekday == DateTime.sunday;
    final isHoliday = widget.day.status == DayStatus.holiday;
    final isCatDay = widget.day.isCatDay;

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCatDay ? Icons.assignment : Icons.event_note,
                color: theme.primary,
                size: 24,
              ),
              const SizedBox(width: ThemeConstants.spacingXs),
              Expanded(
                child: Text(
                  isCatDay
                      ? 'CAT-${widget.day.catNumber} Day'
                      : (isHoliday || isWeekend
                          ? 'Makeup Day Schedule'
                          : 'Day Details'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          Text(
            '${_getDayName(widget.day.date.weekday)}, ${_formatDate(widget.day.date)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.muted),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCatDay) _buildCatDayOptions(theme),
            if ((isHoliday || isWeekend) && includeInCalculation) ...[
              const SizedBox(height: ThemeConstants.spacingMd),
              _buildWeekdaySelection(theme),
            ],
            if (includeInCalculation || !isCatDay) ...[
              const SizedBox(height: ThemeConstants.spacingMd),
              _buildStatusSelection(theme),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.muted)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              UnifiedDayResult(
                includeInCalculation: includeInCalculation,
                weekday: selectedWeekday,
                status: selectedStatus,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildCatDayOptions(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primary, size: 20),
              const SizedBox(width: ThemeConstants.spacingSm),
              Expanded(
                child: Text(
                  'CAT Exam Day Settings',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Include in Attendance Calculation',
              style: TextStyle(color: theme.text, fontSize: 13),
            ),
            subtitle: Text(
              includeInCalculation
                  ? 'Treated as working day'
                  : 'Treated as holiday (excluded)',
              style: TextStyle(color: theme.muted, fontSize: 11),
            ),
            value: includeInCalculation,
            activeColor: theme.primary,
            onChanged: (value) {
              setState(() {
                includeInCalculation = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelection(dynamic theme) {
    final weekdays = [
      {'name': 'Monday', 'value': 1},
      {'name': 'Tuesday', 'value': 2},
      {'name': 'Wednesday', 'value': 3},
      {'name': 'Thursday', 'value': 4},
      {'name': 'Friday', 'value': 5},
    ];

    final isWeekend =
        widget.day.date.weekday == DateTime.saturday ||
        widget.day.date.weekday == DateTime.sunday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(ThemeConstants.spacingMd),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_view_week, color: theme.primary, size: 18),
              const SizedBox(width: ThemeConstants.spacingSm),
              Expanded(
                child: Text(
                  isWeekend
                      ? 'Which weekday schedule does this day follow?'
                      : 'Select day order for this instructional day:',
                  style: TextStyle(color: theme.text, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              weekdays.map((weekday) {
                final isSelected = selectedWeekday == weekday['value'];
                return ChoiceChip(
                  label: Text(weekday['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedWeekday =
                          selected ? (weekday['value'] as int) : null;
                    });
                  },
                  selectedColor: theme.primary.withValues(alpha: 0.2),
                  backgroundColor: theme.background,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.primary : theme.text,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color:
                        isSelected
                            ? theme.primary
                            : theme.muted.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusSelection(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(ThemeConstants.spacingMd),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.how_to_reg, color: theme.primary, size: 18),
              const SizedBox(width: ThemeConstants.spacingSm),
              Text(
                'Attendance Status:',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingSm),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                theme,
                DayStatus.present,
                'Present',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: ThemeConstants.spacingSm),
            Expanded(
              child: _buildStatusOption(
                theme,
                DayStatus.absent,
                'Absent',
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(
    dynamic theme,
    DayStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: ThemeConstants.spacingMd,
          horizontal: ThemeConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : theme.background,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          border: Border.all(
            color: isSelected ? color : theme.muted.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : theme.muted, size: 28),
            const SizedBox(height: ThemeConstants.spacingXs),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : theme.text,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
