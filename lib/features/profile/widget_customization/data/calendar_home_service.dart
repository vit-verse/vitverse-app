import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/logger.dart';
import '../../../calendar/models/calendar_event.dart';

/// Manages calendar integration for home screen to show holidays and Saturday day orders
class CalendarHomeService {
  static const String _tag = 'CalendarHomeService';
  static const String _keyEnabled = 'home_calendar_enabled';
  static const String _keyCalendarId = 'home_calendar_id';
  static const String _keyCalendarName = 'home_calendar_name';
  static const String _keyCalendarData = 'home_calendar_data';

  static CalendarHomeService? _instance;
  static CalendarHomeService get instance {
    _instance ??= CalendarHomeService._();
    return _instance!;
  }

  CalendarHomeService._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  CalendarData? _calendarData;

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _prefs?.getBool(_keyEnabled) ?? false;
  String? get calendarName => _prefs?.getString(_keyCalendarName);
  CalendarData? get calendarData => _calendarData;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      if (isEnabled) {
        _loadCalendarData();
      }

      Logger.i(_tag, 'Calendar home service initialized');
    } catch (e) {
      Logger.e(_tag, 'Error initializing', e);
    }
  }

  void _loadCalendarData() {
    try {
      final jsonStr = _prefs?.getString(_keyCalendarData);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _calendarData = CalendarData.fromJson(json);
        Logger.d(_tag, 'Calendar data loaded from prefs');
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading calendar data', e);
    }
  }

  /// Saves selected calendar and its data to SharedPreferences
  Future<void> applyCalendar(
    String calendarId,
    String calendarName,
    CalendarData calendarData,
  ) async {
    try {
      await _prefs?.setBool(_keyEnabled, true);
      await _prefs?.setString(_keyCalendarId, calendarId);
      await _prefs?.setString(_keyCalendarName, calendarName);
      await _prefs?.setString(
        _keyCalendarData,
        jsonEncode(calendarData.toJson()),
      );

      _calendarData = calendarData;

      Logger.i(_tag, 'Calendar applied: $calendarName');
    } catch (e) {
      Logger.e(_tag, 'Error applying calendar', e);
    }
  }

  /// Removes calendar integration from SharedPreferences
  Future<void> clearCalendar() async {
    try {
      await _prefs?.setBool(_keyEnabled, false);
      await _prefs?.remove(_keyCalendarId);
      await _prefs?.remove(_keyCalendarName);
      await _prefs?.remove(_keyCalendarData);

      _calendarData = null;

      Logger.i(_tag, 'Calendar cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing calendar', e);
    }
  }

  /// Returns day order index (0-4 for Mon-Fri) if Saturday matches a day order pattern
  int? getDayOrderForDate(DateTime date) {
    if (!isEnabled || _calendarData == null || !_isInitialized) {
      return null;
    }

    // Get event from calendar for this specific date
    final event = _getEventForDate(date);
    if (event == null) return null;

    // Extract day order from event text (e.g., "Thursday Day Order")
    final combinedText = '${event.text} ${event.description}'.toLowerCase();
    final dayOrderMatch = RegExp(
      r'(monday|tuesday|wednesday|thursday|friday)\s+(day\s+)?order',
      caseSensitive: false,
    ).firstMatch(combinedText);

    if (dayOrderMatch != null) {
      final dayName = dayOrderMatch.group(1)!.toLowerCase();
      final mappedDay = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
      ].indexOf(dayName);

      if (mappedDay >= 0) {
        Logger.d(
          'CalendarHomeService',
          'Date $date has day order: ${dayName.toUpperCase()} (index: $mappedDay)',
        );
        return mappedDay;
      }
    }

    return null;
  }

  /// Checks if a given date is marked as a holiday in the calendar
  bool isHolidayDate(DateTime date) {
    if (!isEnabled || _calendarData == null || !_isInitialized) {
      return false;
    }

    final event = _getEventForDate(date);
    return event?.isHoliday ?? false;
  }

  // Finds event for a specific date from calendar data
  Event? _getEventForDate(DateTime date) {
    if (_calendarData == null) return null;

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

    final monthData = _calendarData!.months[monthKey];
    if (monthData == null) return null;

    final dayEvent = monthData.events.days.firstWhere(
      (d) => d.date == date.day,
      orElse: () => const DayEvent(date: 0, events: []),
    );

    return dayEvent.date != 0 && dayEvent.events.isNotEmpty
        ? dayEvent.events.first
        : null;
  }
}
