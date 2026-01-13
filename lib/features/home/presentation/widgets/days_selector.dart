import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../profile/widget_customization/data/calendar_home_service.dart';
import '../../../calendar/models/calendar_event.dart';
import '../../../features/vtop_services/attendance_calculator/widgets/calendar_selection_dialog.dart';

class DaysSelector extends StatefulWidget {
  final int selectedDay;
  final Function(int)? onDayChanged;
  final Function(List<DateTime>)? onWeekChanged;

  const DaysSelector({
    super.key,
    required this.selectedDay,
    this.onDayChanged,
    this.onWeekChanged,
  });

  @override
  State<DaysSelector> createState() => _DaysSelectorState();
}

class _DaysSelectorState extends State<DaysSelector> {
  final _calendarService = CalendarHomeService.instance;
  DateTime _weekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateWeekStart();
  }

  void _updateWeekStart() {
    final now = DateTime.now();
    final daysFromMonday = (now.weekday - 1) % 7;
    _weekStart = now.subtract(Duration(days: daysFromMonday));
  }

  void _navigateWeek(int weeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weeks));
    });
    widget.onWeekChanged?.call(_getWeekDates());
  }

  List<DateTime> _getWeekDates() {
    return List.generate(7, (index) => _weekStart.add(Duration(days: index)));
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartDate = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );
    final weekStartDate = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day,
    );
    return currentWeekStartDate.isAtSameMomentAs(weekStartDate);
  }

  void _goToCurrentWeek() {
    setState(() {
      _updateWeekStart();
    });
    widget.onWeekChanged?.call(_getWeekDates());
  }

  Event? _getEventForDate(DateTime date) {
    final calendarData = _calendarService.calendarData;
    if (calendarData == null) return null;

    final monthNames = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final monthKey = '${monthNames[date.month - 1]}-${date.year}';
    final monthData = calendarData.months[monthKey];

    if (monthData != null) {
      for (final dayEvent in monthData.events.days) {
        if (dayEvent.date == date.day && dayEvent.events.isNotEmpty) {
          return dayEvent.events.first;
        }
      }
    }
    return null;
  }

  void _showCalendarSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CalendarSelectionDialog(
            onCalendarSelected: (id, name, data) async {
              await _calendarService.applyCalendar(id, name, data);
              if (context.mounted) {
                Navigator.of(context).pop();
                setState(() {});
                SnackbarUtils.success(
                  context,
                  'Calendar integrated successfully',
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    final hasCalendar = _calendarService.isEnabled;
    final weekDates = _getWeekDates();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCurrentWeek = _isCurrentWeek();

    final circleSize = ((screenWidth - 48) / 7).clamp(34.0, 42.0);
    final dateFontSize = (circleSize * 0.19).clamp(7.0, 9.0);
    final dayFontSize = (circleSize * 0.38).clamp(14.0, 18.0);
    final dayOrderFontSize = (circleSize * 0.14).clamp(5.0, 7.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasCalendar) _buildAddCalendarButton(theme),
        if (!hasCalendar) const SizedBox(height: 3),

        if (hasCalendar) _buildCalendarEventRow(theme, weekDates),
        if (hasCalendar) const SizedBox(height: 3),

        if (!isCurrentWeek) _buildWeekNavigationIndicator(theme, weekDates),
        if (!isCurrentWeek) const SizedBox(height: 3),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final isSelected = index == widget.selectedDay;
            final dayDate = weekDates[index];
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);
            final isToday =
                dayDate.year == todayDate.year &&
                dayDate.month == todayDate.month &&
                dayDate.day == todayDate.day;
            final dayOrderMapping = _calendarService.getDayOrderForDate(
              dayDate,
            );
            final isCalendarHoliday = _calendarService.isHolidayDate(dayDate);
            final hasDayOrder = dayOrderMapping != null;

            return GestureDetector(
              onTap: () => widget.onDayChanged?.call(index),
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? theme.primary.withOpacity(0.15)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isCalendarHoliday
                            ? theme.primary.withOpacity(0.4)
                            : isSelected
                            ? theme.primary
                            : theme.muted.withOpacity(0.3),
                    width: isCalendarHoliday ? 2.5 : 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isToday && hasDayOrder)
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              fontSize: dateFontSize,
                              fontWeight: FontWeight.w500,
                              color: theme.muted,
                            ),
                          ),
                          if (isToday && hasDayOrder)
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),

                    Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w600,
                          color:
                              isCalendarHoliday
                                  ? theme.primary.withValues(alpha: 0.6)
                                  : isSelected
                                  ? theme.primary
                                  : theme.text,
                        ),
                      ),
                    ),

                    if (hasDayOrder)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            [
                              'MON',
                              'TUE',
                              'WED',
                              'THU',
                              'FRI',
                            ][dayOrderMapping],
                            style: TextStyle(
                              fontSize: dayOrderFontSize,
                              fontWeight: FontWeight.w700,
                              color: theme.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),

                    if (isToday && !hasDayOrder)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? theme.primary
                                      : isCalendarHoliday
                                      ? theme.primary.withValues(alpha: 0.6)
                                      : theme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: isCurrentWeek ? 20 : 16),
      ],
    );
  }

  Widget _buildWeekNavigationIndicator(theme, List<DateTime> weekDates) {
    final startDate = weekDates.first;
    final endDate = weekDates.last;
    final monthNames = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    String weekRange;
    if (startDate.month == endDate.month) {
      weekRange =
          '${startDate.day} - ${endDate.day} ${monthNames[startDate.month - 1]}';
    } else {
      weekRange =
          '${startDate.day} ${monthNames[startDate.month - 1]} - ${endDate.day} ${monthNames[endDate.month - 1]}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekRange,
            style: TextStyle(
              color: theme.text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _goToCurrentWeek,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 9, color: theme.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Back to Current Week',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarEventRow(theme, List<DateTime> weekDates) {
    final selectedDate = weekDates[widget.selectedDay];
    final selectedEvent = _getEventForDate(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _navigateWeek(-1),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                color: theme.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),

          Expanded(child: _buildEventDisplay(theme, selectedEvent)),

          const SizedBox(width: 4),

          InkWell(
            onTap: () => _navigateWeek(1),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: theme.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDisplay(theme, Event? event) {
    if (event == null) {
      return Center(
        child: Text(
          'No event today',
          style: TextStyle(
            color: theme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final isHoliday = event.isHoliday;
    final eventColor = isHoliday ? theme.error : theme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.text,
            style: TextStyle(
              color: eventColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (event.description.isNotEmpty)
            Text(
              event.description,
              style: TextStyle(
                color: theme.muted,
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildAddCalendarButton(theme) {
    return InkWell(
      onTap: _showCalendarSelectionDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primary.withOpacity(0.3), width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: theme.primary, size: 14),
            const SizedBox(width: 4),
            Text(
              'Integrate Calendar',
              style: TextStyle(
                color: theme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
