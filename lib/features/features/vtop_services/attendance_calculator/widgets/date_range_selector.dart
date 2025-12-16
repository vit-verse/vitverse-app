import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/theme/app_card_styles.dart';

/// Widget for selecting date range (start and end date in same row)
class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final String? errorMessage;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingSm),
        Row(
          children: [
            // Start Date Picker
            Expanded(
              child: _DatePickerButton(
                label: 'Start Date',
                date: startDate,
                onDateSelected: onStartDateChanged,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: ThemeConstants.spacingMd),
            // End Date Picker
            Expanded(
              child: _DatePickerButton(
                label: 'End Date',
                date: endDate,
                onDateSelected: onEndDateChanged,
                icon: Icons.event,
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: ThemeConstants.spacingSm),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color:
                    theme.isDark
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFE53935),
              ),
              const SizedBox(width: ThemeConstants.spacingXs),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        theme.isDark
                            ? const Color(0xFFEF5350)
                            : const Color(0xFFE53935),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Internal widget for date picker button
class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final Function(DateTime) onDateSelected;
  final IconData icon;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onDateSelected,
    required this.icon,
  });

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.currentTheme;

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Normalize to start of day

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          date.isBefore(today) ? today : date, // Use today if date is in past
      firstDate: today, // Cannot select past dates
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.primary,
              onPrimary: theme.isDark ? Colors.black : Colors.white,
              surface: theme.surface,
              onSurface: theme.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != date) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: theme.isDark,
          customBackgroundColor: theme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.muted),
                const SizedBox(width: ThemeConstants.spacingXs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeConstants.spacingXs),
            Text(
              formattedDate,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: theme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
