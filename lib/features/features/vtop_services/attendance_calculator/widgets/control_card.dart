import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../logic/attendance_calculator_provider.dart';
import '../models/day_status.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/target_attendance_input.dart';
import '../widgets/calendar_selection_dialog.dart';

class ControlCard extends StatelessWidget {
  const ControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final provider = Provider.of<AttendanceCalculatorProvider>(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        side: BorderSide(color: theme.muted.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.selectedCalendarName != null) ...[
              _buildCalendarInfo(context, theme, provider),
              const SizedBox(height: ThemeConstants.spacingMd),
            ],
            DateRangeSelector(
              startDate: provider.startDate,
              endDate: provider.endDate,
              onStartDateChanged: provider.updateStartDate,
              onEndDateChanged: provider.updateEndDate,
              errorMessage: provider.dateRangeError,
            ),
            const SizedBox(height: ThemeConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TargetAttendanceInput(
                    targetPercentage: provider.targetPercentage,
                    onChanged: provider.updateTargetPercentage,
                  ),
                ),
                const SizedBox(width: ThemeConstants.spacingSm),
                _buildSaveButton(context, theme, provider),
              ],
            ),
            const SizedBox(height: ThemeConstants.spacingMd),
            Row(
              children: [
                Expanded(child: _buildToggleButton(context, theme, provider)),
                const SizedBox(width: ThemeConstants.spacingXs),
                Expanded(child: _buildCalendarButton(context, theme, provider)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarInfo(
    BuildContext context,
    dynamic theme,
    AttendanceCalculatorProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingSm),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 20, color: theme.primary),
          const SizedBox(width: ThemeConstants.spacingSm),
          Expanded(
            child: Text(
              'Calendar: ${provider.selectedCalendarName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: theme.muted),
            onPressed: () {
              provider.clearCalendarSelection();
              SnackbarUtils.info(context, 'Calendar cleared');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    dynamic theme,
    AttendanceCalculatorProvider provider,
  ) {
    return ElevatedButton(
      onPressed: () {
        SnackbarUtils.success(context, 'Settings saved');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingSm,
          vertical: ThemeConstants.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        ),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Save'),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    dynamic theme,
    AttendanceCalculatorProvider provider,
  ) {
    final days = provider.days;
    final nonHolidayDays = days.where((d) => d.status != DayStatus.holiday);
    final allPresent = nonHolidayDays.every(
      (d) => d.status == DayStatus.present,
    );

    return OutlinedButton.icon(
      onPressed: () {
        provider.toggleAllDays();
        final statusText = allPresent ? 'absent' : 'present';
        SnackbarUtils.info(context, 'Marked all days as $statusText');
      },
      icon: Icon(allPresent ? Icons.cancel : Icons.check_circle, size: 18),
      label: Text(allPresent ? 'Mark All Absent' : 'Mark All Present'),
      style: OutlinedButton.styleFrom(
        foregroundColor: allPresent ? Colors.red : Colors.green,
        side: BorderSide(
          color: (allPresent ? Colors.red : Colors.green).withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingXs,
          vertical: ThemeConstants.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(
    BuildContext context,
    dynamic theme,
    AttendanceCalculatorProvider provider,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (context) => CalendarSelectionDialog(
                onCalendarSelected: (id, name, data) {
                  provider.applyCalendar(id, name, data);
                  SnackbarUtils.success(context, 'Applied calendar: $name');
                },
              ),
        );
      },
      icon: const Icon(Icons.event_available, size: 18),
      label: const Text('Integrate Calendar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primary,
        side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingXs,
          vertical: ThemeConstants.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        ),
      ),
    );
  }
}
