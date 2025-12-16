import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_provider.dart';
import '../models/calendar_event.dart';

class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final upcomingEvents = provider.getUpcomingEvents();

        if (upcomingEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Upcoming Events',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        'Next 7 days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Events list - show all events for 7 days
                  ...upcomingEvents.map(
                    (entry) => _buildUpcomingEventItem(
                      context,
                      entry.key,
                      entry.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEventItem(
    BuildContext context,
    DateTime date,
    List<Event> events,
  ) {
    final primaryEvent = events.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          Container(
            width: 50,
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _getShortDayName(date.weekday),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Event details
          Expanded(
            child: Container(
              width: double.infinity, // Equal width for all cards
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: _getEventColor(
                  context,
                  primaryEvent,
                ).withOpacity(0.15), // More visible background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getEventColor(context, primaryEvent),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryEvent.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (primaryEvent.description.isNotEmpty &&
                      primaryEvent.description != primaryEvent.text) ...[
                    const SizedBox(height: 4),
                    Text(
                      primaryEvent.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (events.length > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${events.length - 1} more event${events.length > 2 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  String _getShortDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
