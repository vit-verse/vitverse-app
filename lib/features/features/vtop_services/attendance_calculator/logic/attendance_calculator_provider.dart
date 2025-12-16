import 'package:flutter/material.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/database/database.dart';
import '../../../../calendar/data/calendar_cache_service.dart';
import '../../../../calendar/models/calendar_event.dart';
import '../data/attendance_calculator_repository.dart';
import '../models/attendance_day.dart';
import '../models/date_range.dart';
import '../models/course_projection.dart';
import '../models/course_schedule.dart';
import '../models/day_status.dart';
import '../logic/attendance_calculator_logic.dart';
import '../logic/date_range_validator.dart';
import '../logic/projection_calculator.dart';

class AttendanceCalculatorProvider extends ChangeNotifier {
  final AttendanceCalculatorRepository _repository =
      AttendanceCalculatorRepository();
  final CalendarCacheService _calendarService = CalendarCacheService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _coursesData = [];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _dateRangeError;

  double _targetPercentage = AttendanceCalculatorLogic.defaultTargetPercentage;
  List<AttendanceDay> _days = [];
  List<CourseProjection> _projections = [];
  Map<int, CourseSchedule> _courseSchedules = {};

  String? _selectedCalendarId;
  String? _selectedCalendarName;
  CalendarData? _selectedCalendarData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get coursesData => _coursesData;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String? get dateRangeError => _dateRangeError;
  double get targetPercentage => _targetPercentage;
  List<AttendanceDay> get days => _days;
  List<CourseProjection> get projections => _projections;
  String? get selectedCalendarName => _selectedCalendarName;

  Future<void> initialize() async {
    try {
      await _calendarService.initialize();
      _initializeDates();
      await _loadData();
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorProvider',
        'Initialization failed',
        e,
        stackTrace,
      );
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeDates() {
    _startDate = DateTime.now();
    _endDate = DateRangeValidator.getSuggestedEndDate(_startDate);
    _updateDays();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasData = await _repository.hasAttendanceData();

      if (!hasData) {
        _isLoading = false;
        _errorMessage =
            'No attendance data available.\nPlease sync with VTOP first.';
        notifyListeners();
        return;
      }

      final coursesData = await _repository.getCoursesWithAttendance();
      _coursesData = coursesData;
      _isLoading = false;
      notifyListeners();

      await _initializeCourseSchedules();
      _calculateProjections();

      Logger.i(
        'AttendanceCalculatorProvider',
        'Loaded ${coursesData.length} courses',
      );
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorProvider',
        'Failed to load data',
        e,
        stackTrace,
      );
      _isLoading = false;
      _errorMessage = 'Failed to load attendance data.\n${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _initializeCourseSchedules() async {
    try {
      final schedules = <int, CourseSchedule>{};
      final db = VitConnectDatabase.instance;
      final database = await db.database;

      final slotsData = await database.query('slots');
      final slotIdToInfo = <int, Map<String, dynamic>>{};

      for (var slot in slotsData) {
        final slotId = slot['id'] as int?;
        final courseId = slot['course_id'] as int?;
        final slotName = slot['slot'] as String?;

        if (slotId != null && courseId != null && slotName != null) {
          slotIdToInfo[slotId] = {'course_id': courseId, 'slot_name': slotName};
        }
      }

      final timetableData = await database.query('timetable');
      final courseToDays = <int, Set<int>>{};
      final courseToDaySlots = <int, Map<int, List<SlotDetail>>>{};

      final dayColumns = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ];

      for (var timetableRow in timetableData) {
        final startTime = timetableRow['start_time'] as String? ?? '';
        final endTime = timetableRow['end_time'] as String? ?? '';

        for (int i = 0; i < dayColumns.length; i++) {
          final slotId = timetableRow[dayColumns[i]] as int?;

          if (slotId != null && slotIdToInfo.containsKey(slotId)) {
            final slotInfo = slotIdToInfo[slotId]!;
            final courseId = slotInfo['course_id'] as int;
            final slotName = slotInfo['slot_name'] as String;
            final dateTimeWeekday = i == 0 ? 7 : i;

            courseToDays.putIfAbsent(courseId, () => {}).add(dateTimeWeekday);
            courseToDaySlots.putIfAbsent(courseId, () => {});
            courseToDaySlots[courseId]!.putIfAbsent(dateTimeWeekday, () => []);
            courseToDaySlots[courseId]![dateTimeWeekday]!.add(
              SlotDetail(
                slotId: slotId,
                slotName: slotName,
                startTime: startTime,
                endTime: endTime,
              ),
            );
          }
        }
      }

      for (final courseData in _coursesData) {
        final courseId = courseData['course_id'] as int? ?? 0;
        final courseCode = courseData['course_code'] as String? ?? '';

        if (courseToDays.containsKey(courseId)) {
          schedules[courseId] = CourseSchedule(
            courseId: courseId,
            courseCode: courseCode,
            classDays: courseToDays[courseId]!,
            daySlots: courseToDaySlots[courseId] ?? {},
          );
        } else {
          schedules[courseId] = CourseSchedule(
            courseId: courseId,
            courseCode: courseCode,
            classDays: {1, 2, 3, 4, 5},
            daySlots: {},
          );
        }
      }

      _courseSchedules = schedules;
      notifyListeners();
    } catch (e) {
      Logger.e(
        'AttendanceCalculatorProvider',
        'Failed to initialize course schedules',
        e,
      );
      final schedules = <int, CourseSchedule>{};
      for (final courseData in _coursesData) {
        final courseId = courseData['course_id'] as int? ?? 0;
        final courseCode = courseData['course_code'] as String? ?? '';
        schedules[courseId] = CourseSchedule(
          courseId: courseId,
          courseCode: courseCode,
          classDays: {1, 2, 3, 4, 5},
          daySlots: {},
        );
      }
      _courseSchedules = schedules;
      notifyListeners();
    }
  }

  void _updateDays() {
    final dateRange = DateRange(startDate: _startDate, endDate: _endDate);
    final validation = DateRangeValidator.validate(dateRange);

    if (validation.isValid) {
      _days = AttendanceCalculatorLogic.generateDaysForRange(dateRange);
      _dateRangeError = null;
    } else {
      _dateRangeError = validation.errorMessage;
      _days = [];
    }

    if (validation.isValid) {
      _calculateProjections();
    }
    notifyListeners();
  }

  void _calculateProjections() {
    if (_coursesData.isEmpty || _days.isEmpty || _courseSchedules.isEmpty) {
      _projections = [];
      notifyListeners();
      return;
    }

    _projections = ProjectionCalculator.calculateProjections(
      coursesData: _coursesData,
      attendanceDays: _days,
      targetPercentage: _targetPercentage,
      courseSchedules: _courseSchedules,
    );
    notifyListeners();
  }

  void updateStartDate(DateTime newDate) {
    _startDate = newDate;
    _updateDays();
    _reapplyCalendarIfNeeded();
  }

  void updateEndDate(DateTime newDate) {
    _endDate = newDate;
    _updateDays();
    _reapplyCalendarIfNeeded();
  }

  Future<void> _reapplyCalendarIfNeeded() async {
    if (_selectedCalendarId != null &&
        _selectedCalendarName != null &&
        _selectedCalendarData != null) {
      try {
        await applyCalendar(
          _selectedCalendarId!,
          _selectedCalendarName!,
          _selectedCalendarData!,
        );
      } catch (e) {
        Logger.e(
          'AttendanceCalculatorProvider',
          'Failed to reapply calendar',
          e,
        );
      }
    }
  }

  void updateTargetPercentage(double newPercentage) {
    _targetPercentage = newPercentage;
    _calculateProjections();
  }

  void updateDayStatus(AttendanceDay day) {
    _days =
        _days.map((d) {
          final normalizedDate = DateTime(
            d.date.year,
            d.date.month,
            d.date.day,
          );
          final targetDate = DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
          );

          if (normalizedDate.isAtSameMomentAs(targetDate)) {
            return day;
          }
          return d;
        }).toList();

    _calculateProjections();
  }

  void toggleAllDays() {
    final nonHolidayDays = _days.where((d) => d.status != DayStatus.holiday);
    final allPresent = nonHolidayDays.every(
      (d) => d.status == DayStatus.present,
    );
    final targetStatus = allPresent ? DayStatus.absent : DayStatus.present;

    _days =
        _days.map((day) {
          if (day.status == DayStatus.holiday) return day;
          return day.copyWith(status: targetStatus);
        }).toList();

    _calculateProjections();
  }

  Future<void> applyCalendar(
    String calendarId,
    String calendarName,
    CalendarData calendarData,
  ) async {
    try {
      _selectedCalendarId = calendarId;
      _selectedCalendarName = calendarName;
      _selectedCalendarData = calendarData;

      _days =
          _days.map((day) {
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
            final monthKey =
                '${monthNames[day.date.month - 1]}-${day.date.year}';
            final monthData = calendarData.months[monthKey];

            if (monthData != null) {
              final dayEvent = monthData.events.days.firstWhere(
                (d) => d.date == day.date.day,
                orElse: () => const DayEvent(date: 0, events: []),
              );

              if (dayEvent.date != 0 && dayEvent.events.isNotEmpty) {
                for (var event in dayEvent.events) {
                  final eventText = event.text.toLowerCase();
                  final description = event.description.toLowerCase();

                  // Check for CAT-1 or CAT-2
                  // IMPORTANT: Check CAT-2 FIRST to avoid "cat i" matching within "cat ii"
                  if (eventText.contains('cat') ||
                      description.contains('cat')) {
                    int? catNum;
                    // Check CAT-2 first (longer pattern)
                    if (eventText.contains('cat - ii') ||
                        eventText.contains('cat-ii') ||
                        eventText.contains('cat ii') ||
                        eventText.contains('cat 2') ||
                        description.contains('cat ii') ||
                        description.contains('cat 2')) {
                      catNum = 2;
                    }
                    // Check CAT-1 only if CAT-2 not found
                    else if (eventText.contains('cat - i') ||
                        eventText.contains('cat-i') ||
                        eventText.contains('cat i') ||
                        eventText.contains('cat 1') ||
                        description.contains('cat i') ||
                        description.contains('cat 1')) {
                      catNum = 1;
                    }

                    if (catNum != null) {
                      return day.copyWith(
                        isCatDay: true,
                        catNumber: catNum,
                        catIncludedInCalculation: false,
                        status: DayStatus.holiday,
                      );
                    }
                  }

                  if (eventText.contains('no instructional day') ||
                      eventText.contains('holiday') ||
                      description.contains('holiday')) {
                    return day.copyWith(status: DayStatus.holiday);
                  }

                  if (eventText.contains('instructional day')) {
                    int? dayOrder;
                    if (description.contains('monday day order')) {
                      dayOrder = 1;
                    } else if (description.contains('tuesday day order')) {
                      dayOrder = 2;
                    } else if (description.contains('wednesday day order')) {
                      dayOrder = 3;
                    } else if (description.contains('thursday day order')) {
                      dayOrder = 4;
                    } else if (description.contains('friday day order')) {
                      dayOrder = 5;
                    }

                    if (dayOrder != null &&
                        (day.date.weekday == DateTime.saturday ||
                            day.date.weekday == DateTime.sunday)) {
                      return day.copyWith(
                        followsScheduleOf: dayOrder,
                        status: DayStatus.absent,
                      );
                    }

                    return day.copyWith(status: DayStatus.absent);
                  }
                }
              }
            }

            return day;
          }).toList();

      final instructionalDays =
          _days.where((d) => d.status == DayStatus.absent).length;
      final holidays = _days.where((d) => d.status == DayStatus.holiday).length;
      final weekendsWithDayOrder =
          _days.where((d) => d.followsScheduleOf != null).length;

      Logger.i(
        'AttendanceCalculatorProvider',
        'Applied calendar: $calendarName - Instructional: $instructionalDays, Holidays: $holidays, Makeup days: $weekendsWithDayOrder',
      );

      notifyListeners();
      _calculateProjections();
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorProvider',
        'Failed to apply calendar',
        e,
        stackTrace,
      );
    }
  }

  void clearCalendarSelection() {
    _selectedCalendarId = null;
    _selectedCalendarName = null;
    _selectedCalendarData = null;
    _initializeDates();
    notifyListeners();
  }

  void toggleCatDayInclusion(AttendanceDay day) {
    if (!day.isCatDay) return;

    _days =
        _days.map((d) {
          final normalizedDate = DateTime(
            d.date.year,
            d.date.month,
            d.date.day,
          );
          final targetDate = DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
          );

          if (normalizedDate.isAtSameMomentAs(targetDate)) {
            final newInclusionStatus = !d.catIncludedInCalculation;
            return d.copyWith(
              catIncludedInCalculation: newInclusionStatus,
              status: newInclusionStatus ? DayStatus.absent : DayStatus.holiday,
            );
          }
          return d;
        }).toList();

    _calculateProjections();
  }

  void updateDayWithDetails(
    AttendanceDay day, {
    required bool includeInCalculation,
    int? followsScheduleOf,
    required DayStatus status,
  }) {
    _days =
        _days.map((d) {
          final normalizedDate = DateTime(
            d.date.year,
            d.date.month,
            d.date.day,
          );
          final targetDate = DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
          );

          if (normalizedDate.isAtSameMomentAs(targetDate)) {
            if (d.isCatDay) {
              return d.copyWith(
                catIncludedInCalculation: includeInCalculation,
                followsScheduleOf: followsScheduleOf,
                status: includeInCalculation ? status : DayStatus.holiday,
              );
            } else {
              return d.copyWith(
                followsScheduleOf: followsScheduleOf,
                status: status,
              );
            }
          }
          return d;
        }).toList();

    _calculateProjections();
  }

  Map<int, Map<String, int>> calculateWeekdayCounts() {
    final counts = <int, Map<String, int>>{};

    for (int weekday = 1; weekday <= 5; weekday++) {
      counts[weekday] = {'regular': 0, 'weekend': 0};
    }

    for (final day in _days) {
      if (day.status == DayStatus.holiday) continue;

      final weekday = day.date.weekday;

      if (weekday >= 1 && weekday <= 5) {
        counts[weekday]!['regular'] = (counts[weekday]!['regular'] ?? 0) + 1;
      } else if ((weekday == DateTime.saturday || weekday == DateTime.sunday) &&
          day.followsScheduleOf != null) {
        final scheduledAs = day.followsScheduleOf!;
        if (scheduledAs >= 1 && scheduledAs <= 5) {
          counts[scheduledAs]!['weekend'] =
              (counts[scheduledAs]!['weekend'] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  Future<void> reload() async {
    await _loadData();
  }
}
