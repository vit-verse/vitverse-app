import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_provider.dart';
import '../models/calendar_event.dart';
import '../../../core/utils/snackbar_utils.dart';

class DayDetailsCard extends StatelessWidget {
  const DayDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final selectedDate = provider.selectedDate;
        final events = provider.getEventsForDate(selectedDate);

        return Container(
          margin: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Text(
                    _formatDate(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Events list
                  if (events.isEmpty)
                    _buildNoEventsMessage(context)
                  else
                    ...events.map(
                      (event) => _buildEventItem(context, provider, event),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoEventsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'No events scheduled for this day',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    CalendarProvider provider,
    Event event,
  ) {
    final eventColor = _getEventColor(context, event);
    final isPersonalEvent = event.category == 'Personal';

    return Container(
      width: double.infinity, // Equal width for all cards
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.15), // More visible background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (event.description.isNotEmpty &&
                    event.description != event.text) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                if (event.category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      event.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delete button for personal events
          if (isPersonalEvent) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deletePersonalEvent(context, provider, event),
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  void _deletePersonalEvent(
    BuildContext context,
    CalendarProvider provider,
    Event event,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: Text('Are you sure you want to delete "${event.text}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  // Find the personal event by matching text and description
                  final personalEvent = provider.personalEvents.firstWhere(
                    (pe) =>
                        pe.name == event.text &&
                        pe.description == event.description,
                    orElse: () => throw StateError('Personal event not found'),
                  );

                  provider.removePersonalEvent(personalEvent.id);
                  Navigator.of(context).pop();
                  SnackbarUtils.success(context, 'Event deleted successfully');
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _getEventColor(BuildContext context, Event event) {
    if (event.category == 'Personal') {
      return Colors.blue.shade300;
    } else if (event.isInstructionalDay) {
      return Colors.lightGreen;
    } else if (event.isHoliday) {
      return Colors.red.shade300;
    }
    return Theme.of(context).colorScheme.secondary;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName, $monthName ${date.day}, ${date.year}';
  }
}
