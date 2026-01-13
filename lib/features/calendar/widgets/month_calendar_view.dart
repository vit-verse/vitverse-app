import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../logic/calendar_provider.dart';
import '../models/calendar_event.dart';
import '../widgets/add_event_dialog.dart';

class MonthCalendarView extends StatelessWidget {
  const MonthCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TableCalendar<Event>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: provider.selectedDate,
                selectedDayPredicate: (day) {
                  return isSameDay(provider.selectedDate, day);
                },
                eventLoader: (day) {
                  return provider.getEventsForDate(day);
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  holidayTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  canMarkersOverflow: true,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  provider.setSelectedDate(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  provider.setSelectedDate(focusedDay);
                },
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, day, focusedDay) {
                    final events = provider.getEventsForDate(day);
                    final isSelected = isSameDay(day, provider.selectedDate);

                    if (!isSelected) return null;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            events.isNotEmpty
                                ? _getDayBackgroundColor(context, events)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              events.isNotEmpty
                                  ? _getEventColor(context, events.first)
                                  : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color:
                                    events.isNotEmpty
                                        ? _getDayTextColor(context, events)
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (events.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  events.first.text.length > 10
                                      ? '${events.first.text.substring(0, 10)}...'
                                      : events.first.text,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color:
                                        events.isNotEmpty
                                            ? _getDayTextColor(context, events)
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final events = provider.getEventsForDate(day);
                    final isToday = isSameDay(day, DateTime.now());

                    if (!isToday) return null;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            events.isNotEmpty
                                ? _getDayBackgroundColor(context, events)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              events.isNotEmpty
                                  ? _getEventColor(context, events.first)
                                  : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color:
                                    events.isNotEmpty
                                        ? _getDayTextColor(context, events)
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (events.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  events.first.text.length > 10
                                      ? '${events.first.text.substring(0, 10)}...'
                                      : events.first.text,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color:
                                        events.isNotEmpty
                                            ? _getDayTextColor(context, events)
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;

                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            events.take(3).map((event) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getEventColor(context, event),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final events = provider.getEventsForDate(day);
                    if (events.isEmpty) return null;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getDayBackgroundColor(context, events),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: _getDayTextColor(context, events),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (events.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  events.first.text.length > 10
                                      ? '${events.first.text.substring(0, 10)}...'
                                      : events.first.text,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: _getDayTextColor(context, events),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Add Event Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _showAddEventDialog(context, provider),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    'Add Event',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        );
      },
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

  Color _getDayBackgroundColor(BuildContext context, List<Event> events) {
    if (events.isEmpty) return Colors.transparent;

    final hasPersonal = events.any((e) => e.category == 'Personal');
    final hasInstructional = events.any((e) => e.isInstructionalDay);
    final hasHoliday = events.any((e) => e.isHoliday);

    if (hasPersonal) {
      return Colors.blue.withValues(alpha: 0.2);
    } else if (hasInstructional) {
      return Colors.lightGreen.withValues(alpha: 0.2);
    } else if (hasHoliday) {
      return Colors.red.withValues(alpha: 0.2);
    }

    return Theme.of(
      context,
    ).colorScheme.secondaryContainer.withValues(alpha: 0.3);
  }

  Color _getDayTextColor(BuildContext context, List<Event> events) {
    if (events.isEmpty) return Theme.of(context).colorScheme.onSurface;

    final hasPersonal = events.any((e) => e.category == 'Personal');
    final hasInstructional = events.any((e) => e.isInstructionalDay);
    final hasHoliday = events.any((e) => e.isHoliday);

    if (hasPersonal) {
      return Colors.blue.shade800;
    } else if (hasInstructional) {
      return Colors.green.shade800;
    } else if (hasHoliday) {
      return Colors.red.shade800;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  void _showAddEventDialog(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AddEventDialog(
            selectedDate: provider.selectedDate,
            onEventAdded: (event) {
              provider.addPersonalEvent(event);
            },
          ),
    );
  }
}
