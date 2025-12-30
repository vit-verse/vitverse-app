import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../features/vtop_services/attendance_calculator/widgets/calendar_selection_dialog.dart';
import '../data/calendar_home_service.dart';

class CalendarIntegrationCard extends StatefulWidget {
  const CalendarIntegrationCard({super.key});

  @override
  State<CalendarIntegrationCard> createState() =>
      _CalendarIntegrationCardState();
}

class _CalendarIntegrationCardState extends State<CalendarIntegrationCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final calendarService = CalendarHomeService.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Calendar Integration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Integrate calendar to show holidays and Saturday day orders on home screen',
            style: TextStyle(fontSize: 13, color: theme.muted),
          ),
          const SizedBox(height: 16),

          if (calendarService.calendarName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      calendarService.calendarName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.muted, size: 18),
                    onPressed: () async {
                      await calendarService.clearCalendar();
                      if (mounted) {
                        setState(() {});
                        SnackbarUtils.info(context, 'Calendar cleared');
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder:
                      (context) => CalendarSelectionDialog(
                        onCalendarSelected: (id, name, data) async {
                          await calendarService.applyCalendar(id, name, data);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            if (mounted) setState(() {});
                            SnackbarUtils.success(
                              context,
                              'Calendar applied successfully',
                            );
                          }
                        },
                      ),
                );
              },
              icon: Icon(
                calendarService.calendarName != null ? Icons.sync : Icons.add,
                size: 18,
              ),
              label: Text(
                calendarService.calendarName != null
                    ? 'Change Calendar'
                    : 'Select Calendar',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
