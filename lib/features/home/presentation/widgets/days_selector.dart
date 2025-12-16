import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../profile/widget_customization/data/calendar_home_service.dart';

/// Widget for selecting days of the week with holiday management
class DaysSelector extends StatefulWidget {
  static const String _tag = 'DaysSelector';

  final int selectedDay;
  final Function(int) onDayChanged;

  const DaysSelector({
    super.key,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  State<DaysSelector> createState() => _DaysSelectorState();
}

class _DaysSelectorState extends State<DaysSelector> {
  static const String _tag = 'DaysSelector';

  Set<int> _holidayDays = {};
  final _calendarService = CalendarHomeService.instance;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final holidayList = prefs.getStringList('holiday_days') ?? [];

      if (mounted) {
        setState(() {
          _holidayDays = holidayList.map((day) => int.parse(day)).toSet();
        });
      }

      Logger.d(_tag, 'Loaded holidays: $_holidayDays');
    } catch (e) {
      Logger.e(_tag, 'Failed to load holidays', e);
    }
  }

  Future<void> _saveHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'holiday_days',
        _holidayDays.map((day) => day.toString()).toList(),
      );

      Logger.d(_tag, 'Saved holidays: $_holidayDays');
    } catch (e) {
      Logger.e(_tag, 'Failed to save holidays', e);
    }
  }

  void _toggleHoliday(int dayIndex) {
    setState(() {
      if (_holidayDays.contains(dayIndex)) {
        _holidayDays.remove(dayIndex);
      } else {
        _holidayDays.add(dayIndex);
      }
    });
    _saveHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final today = DateTime.now().weekday - 1; // 0=Monday, 6=Sunday
        final now = DateTime.now();

        return Container(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = index == widget.selectedDay;
              final isHoliday = _holidayDays.contains(index);
              final isToday = index == today;

              final dayDate = now.add(Duration(days: index - today));
              final dayOrderMapping = _calendarService.getDayOrderForDate(
                dayDate,
              );
              final isCalendarHoliday = _calendarService.isHolidayDate(dayDate);
              final isHolidayOrMarked = isHoliday || isCalendarHoliday;

              return GestureDetector(
                onTap: () => widget.onDayChanged(index),
                onLongPress: () {
                  _toggleHoliday(index);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? themeProvider.currentTheme.primary.withOpacity(
                              0.15,
                            )
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isHolidayOrMarked
                              ? themeProvider.currentTheme.primary.withOpacity(
                                0.4,
                              )
                              : isSelected
                              ? themeProvider.currentTheme.primary
                              : themeProvider.currentTheme.muted.withOpacity(
                                0.3,
                              ),
                      width: isHolidayOrMarked ? 2.5 : 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Date at top
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: themeProvider.currentTheme.muted,
                            ),
                          ),
                        ),
                      ),

                      // Main day letter
                      Center(
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isHolidayOrMarked
                                    ? themeProvider.currentTheme.primary
                                        .withOpacity(0.6)
                                    : isSelected
                                    ? themeProvider.currentTheme.primary
                                    : themeProvider.currentTheme.text,
                          ),
                        ),
                      ),

                      // Day order mapping (if Saturday has a day order)
                      if (dayOrderMapping != null && dayDate.weekday == 6)
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
                                fontSize: 6,
                                fontWeight: FontWeight.w700,
                                color: themeProvider.currentTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),

                      // Today indicator dot
                      if (isToday)
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
                                        ? themeProvider.currentTheme.primary
                                        : isHolidayOrMarked
                                        ? themeProvider.currentTheme.primary
                                            .withOpacity(0.6)
                                        : themeProvider.currentTheme.primary,
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
        );
      },
    );
  }
}
