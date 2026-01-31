import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_provider.dart';
import '../models/calendar_event.dart';
import 'event_detail_dialog.dart';

class TimelineCalendarView extends StatelessWidget {
  const TimelineCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final selectedDate = provider.selectedDate;
        final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        final endOfMonth = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
        );

        final eventsMap = provider.getEventsForDateRange(
          startOfMonth,
          endOfMonth,
        );
        final sortedDates = eventsMap.keys.toList()..sort();

        return Column(
          children: [
            _buildMonthNavigationBar(context, provider),
            Expanded(
              child:
                  sortedDates.isEmpty
                      ? _buildEmptyTimeline(context)
                      : ListView.builder(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 24,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final events = eventsMap[date] ?? [];
                          return _buildTimelineItem(context, date, events);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthNavigationBar(
    BuildContext context,
    CalendarProvider provider,
  ) {
    final selectedDate = provider.selectedDate;

    return Container(
      height: 50, // Fixed smaller height
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              final previousMonth = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
              );
              provider.setSelectedDate(previousMonth);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
            child: const Text(
              '‹',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          Text(
            _getMonthYearText(selectedDate),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          TextButton(
            onPressed: () {
              final nextMonth = DateTime(
                selectedDate.year,
                selectedDate.month + 1,
              );
              provider.setSelectedDate(nextMonth);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
            child: const Text(
              '›',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No events this month',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    DateTime date,
    List<Event> events,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column - smaller
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _getDayName(date.weekday),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Timeline line - smaller
          Container(
            width: 2,
            height: events.length * 45.0 + 15,
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Events column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  events
                      .map((event) => _buildEventCard(context, event))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Container(
      width: double.infinity, // Same width for all cards
      margin: const EdgeInsets.only(bottom: 6.0),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _showEventDetails(context, event),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: _getEventColor(context, event),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailDialog(event: event),
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

  String _getMonthYearText(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
