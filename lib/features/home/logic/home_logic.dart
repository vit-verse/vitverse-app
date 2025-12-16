import '../../../core/utils/logger.dart';
import '../../../core/database/database.dart';
import '../data/home_data_provider.dart';
import '../../profile/widget_customization/data/calendar_home_service.dart';

class HomeLogic {
  static const String _tag = 'HomeLogic';

  final HomeDataProvider _dataProvider = HomeDataProvider();
  final CalendarHomeService _calendarService = CalendarHomeService.instance;

  // Cached data
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _timetableData = [];
  List<Map<String, dynamic>> _examData = [];
  List<Map<String, dynamic>> _coursesData = [];
  List<Map<String, dynamic>> _slotsData = [];
  int _onDutyCount = 0;

  // Getters for cached data
  Map<String, dynamic> get userData => _userData;
  List<Map<String, dynamic>> get attendanceData => _attendanceData;
  List<Map<String, dynamic>> get timetableData => _timetableData;
  List<Map<String, dynamic>> get examData => _examData;
  List<Map<String, dynamic>> get coursesData => _coursesData;
  List<Map<String, dynamic>> get slotsData => _slotsData;
  int get onDutyCount => _onDutyCount;

  Future<void> loadAllData() async {
    try {
      Logger.i(_tag, 'Loading all home data...');

      // Load all data concurrently
      final futures = [
        _dataProvider.getUserData(),
        _dataProvider.getAttendanceData(),
        _dataProvider.getTimetableData(),
        _dataProvider.getExamData(),
        _dataProvider.getCoursesData(),
        _dataProvider.getSlotsData(),
      ];

      final results = await Future.wait(futures);

      _userData = results[0] as Map<String, dynamic>;
      _attendanceData = results[1] as List<Map<String, dynamic>>;
      _timetableData = results[2] as List<Map<String, dynamic>>;
      _examData = results[3] as List<Map<String, dynamic>>;
      _coursesData = results[4] as List<Map<String, dynamic>>;
      _slotsData = results[5] as List<Map<String, dynamic>>;

      // Load OD count
      await _loadOnDutyCount();

      Logger.success(_tag, 'All home data loaded successfully');
    } catch (e) {
      Logger.e(_tag, 'Failed to load home data', e);
      rethrow;
    }
  }

  /// Load On Duty count from attendance_detail table
  Future<void> _loadOnDutyCount() async {
    try {
      final db = await VitConnectDatabase.instance.database;
      final result = await db.rawQuery(
        "SELECT attendance_slot FROM attendance_detail WHERE attendance_status = 'On Duty'",
      );

      // Count slots, splitting by '+' if present
      int totalOdCount = 0;
      for (final row in result) {
        final slot = row['attendance_slot'] as String?;
        if (slot != null && slot.isNotEmpty) {
          final slotCount = slot.split('+').length;
          totalOdCount += slotCount;
        }
      }

      _onDutyCount = totalOdCount;
      Logger.d(_tag, 'Loaded OD count: $_onDutyCount');
    } catch (e) {
      Logger.e(_tag, 'Failed to load OD count', e);
      _onDutyCount = 0;
    }
  }

  int getOnDutyCount() {
    return _onDutyCount;
  }

  /// Get classes for a specific day (0=Monday, 6=Sunday)
  List<Map<String, dynamic>> getClassesForDay(int dayIndex) {
    final effectiveDayIndex = _getEffectiveDayIndex(dayIndex);

    if (effectiveDayIndex == -1) {
      Logger.d(_tag, 'Holiday - returning empty class list');
      return [];
    }

    // Convert dayIndex to database day format
    final dbDayOfWeek =
        (effectiveDayIndex + 1) % 7 +
        1; // Maps: 0→2, 1→3, 2→4, 3→5, 4→6, 5→7, 6→1

    final dayClasses = <Map<String, dynamic>>[];

    // Create lookup maps
    final courseMap = <int, Map<String, dynamic>>{};
    for (var course in _coursesData) {
      if (course['id'] != null) {
        courseMap[course['id'] as int] = course;
      }
    }

    final slotMap = <int, Map<String, dynamic>>{};
    for (var slot in _slotsData) {
      if (slot['id'] != null) {
        slotMap[slot['id'] as int] = slot;
      }
    }

    // Get day column name
    final dayColumn =
        [
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
        ][dbDayOfWeek - 1];

    Logger.d(_tag, 'Getting classes for day $dayIndex (DB: $dayColumn)');

    for (var timetableEntry in _timetableData) {
      final slotId = timetableEntry[dayColumn];

      if (slotId != null) {
        final slot = slotMap[slotId];
        final courseId = slot?['course_id'] as int?;
        final course = courseId != null ? courseMap[courseId] : null;

        // Enhance course data with faculty ERP ID if available
        Map<String, dynamic>? enhancedCourse;
        if (course != null) {
          enhancedCourse = Map<String, dynamic>.from(course);
          // Only generate fallback ERP ID if the database field is null or empty (ie NPTEL, STS, and some random subjects)
          final existingErpId = enhancedCourse['faculty_erp_id']?.toString();
          if (existingErpId == null || existingErpId.isEmpty) {
            final generatedId =
                enhancedCourse['faculty']?.toString().hashCode.toString();
            enhancedCourse['faculty_erp_id'] = generatedId;
            Logger.d(
              _tag,
              'Generated fallback ERP ID for ${enhancedCourse['faculty']}: $generatedId',
            );
          } else {
            Logger.d(
              _tag,
              'Using real ERP ID for ${enhancedCourse['faculty']}: $existingErpId',
            );
          }
        }

        dayClasses.add({
          ...timetableEntry,
          'slotId': slotId,
          'slotName': slot?['slot']?.toString() ?? 'Unknown',
          'course': enhancedCourse,
          'isFriendClass': false,
        });
      }
    }

    Logger.d(_tag, 'Found ${dayClasses.length} classes for $dayColumn');

    // Merge consecutive classes with the same course
    final mergedClasses = _mergeConsecutiveClasses(dayClasses);
    Logger.d(_tag, 'After merging: ${mergedClasses.length} classes');

    return mergedClasses;
  }

  /// Merge consecutive classes with the same course code and title
  List<Map<String, dynamic>> _mergeConsecutiveClasses(
    List<Map<String, dynamic>> classes,
  ) {
    if (classes.isEmpty) return classes;

    // Sort classes by start time first
    classes.sort((a, b) {
      final timeA = a['start_time']?.toString() ?? '';
      final timeB = b['start_time']?.toString() ?? '';
      return timeA.compareTo(timeB);
    });

    final merged = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentClass;

    for (var classData in classes) {
      if (currentClass == null) {
        // First class
        currentClass = Map<String, dynamic>.from(classData);
        currentClass['slotIds'] = [classData['slotId']];
        currentClass['slotNames'] = [classData['slotName']];
        continue;
      }

      final currentCourse = currentClass['course'] as Map<String, dynamic>?;
      final nextCourse = classData['course'] as Map<String, dynamic>?;

      // Check if courses match (same code and title)
      final isSameCourse =
          currentCourse != null &&
          nextCourse != null &&
          currentCourse['code'] == nextCourse['code'] &&
          currentCourse['title'] == nextCourse['title'];

      // Check if times are consecutive (current end time = next start time)
      final currentEndTime = currentClass['end_time']?.toString() ?? '';
      final nextStartTime = classData['start_time']?.toString() ?? '';
      final isConsecutive = currentEndTime == nextStartTime;

      if (isSameCourse && isConsecutive) {
        // Merge with current class
        currentClass['end_time'] = classData['end_time'];
        (currentClass['slotIds'] as List).add(classData['slotId']);
        (currentClass['slotNames'] as List).add(classData['slotName']);

        Logger.d(
          _tag,
          'Merged ${currentCourse['title']} slots: ${currentClass['slotNames']}',
        );
      } else {
        // Not consecutive or different course, save current and start new
        merged.add(currentClass);
        currentClass = Map<String, dynamic>.from(classData);
        currentClass['slotIds'] = [classData['slotId']];
        currentClass['slotNames'] = [classData['slotName']];
      }
    }

    // Add the last class
    if (currentClass != null) {
      merged.add(currentClass);
    }

    return merged;
  }

  /// Get next upcoming exam
  Map<String, dynamic>? getNextExam() {
    if (_examData.isEmpty) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic>? nextExam;
    int? closestTime;

    for (var exam in _examData) {
      final startTime = exam['start_time'] as int?;
      if (startTime != null && startTime > now) {
        if (closestTime == null || startTime < closestTime) {
          closestTime = startTime;
          nextExam = exam;
        }
      }
    }

    return nextExam;
  }

  /// Calculate overall attendance percentage
  double calculateOverallAttendance(List<Map<String, dynamic>> attendanceData) {
    if (attendanceData.isEmpty) return 0.0;

    int totalAttended = 0;
    int totalClasses = 0;

    for (var attendance in attendanceData) {
      totalAttended += (attendance['attended'] as int?) ?? 0;
      totalClasses += (attendance['total'] as int?) ?? 0;
    }

    if (totalClasses == 0) return 0.0;

    return (totalAttended / totalClasses) * 100;
  }

  /// Get attendance data for a specific course
  /// For embedded courses, pass the course type to get the correct attendance record
  Map<String, dynamic> getCourseAttendance(
    String courseCode, {
    String? courseType,
  }) {
    // Get all attendance records matching this course code
    final matchingRecords =
        _attendanceData
            .where((attendance) => attendance['course_code'] == courseCode)
            .toList();

    // If no records found, return empty
    if (matchingRecords.isEmpty) {
      return {
        'id': null,
        'course_code': courseCode,
        'percentage': 0.0,
        'attended': 0,
        'total': 0,
      };
    }

    // If only one record, return it (most common case)
    if (matchingRecords.length == 1) {
      final attendance = matchingRecords.first;
      final attended = attendance['attended'] as int? ?? 0;
      final total = attendance['total'] as int? ?? 0;
      final precisePercentage = total > 0 ? (attended / total) * 100.0 : 0.0;

      return {
        'id': attendance['id'],
        'course_code': courseCode,
        'percentage': precisePercentage,
        'attended': attended,
        'total': total,
      };
    }

    // Multiple records exist (embedded courses) - need to filter by type
    if (courseType != null && courseType.isNotEmpty) {
      final searchType = courseType.toLowerCase();

      // Try to find matching record by type
      final typeMatched = matchingRecords.firstWhere((attendance) {
        final attendanceCourseType =
            attendance['course_type']?.toString().toLowerCase() ?? '';

        if (attendanceCourseType.isEmpty) return false;

        // Check if types match (for embedded: theory matches "embedded theory", lab matches "embedded lab")
        return attendanceCourseType.contains(searchType) ||
            searchType.contains(attendanceCourseType);
      }, orElse: () => matchingRecords.first);

      final attended = typeMatched['attended'] as int? ?? 0;
      final total = typeMatched['total'] as int? ?? 0;
      final precisePercentage = total > 0 ? (attended / total) * 100.0 : 0.0;

      return {
        'id': typeMatched['id'],
        'course_code': courseCode,
        'percentage': precisePercentage,
        'attended': attended,
        'total': total,
      };
    }

    // Multiple records but no type specified - return first one
    final attendance = matchingRecords.first;
    final attended = attendance['attended'] as int? ?? 0;
    final total = attendance['total'] as int? ?? 0;
    final precisePercentage = total > 0 ? (attended / total) * 100.0 : 0.0;

    return {
      'id': attendance['id'],
      'course_code': courseCode,
      'percentage': precisePercentage,
      'attended': attended,
      'total': total,
    };
  }

  /// Get effective day index considering calendar integration
  int _getEffectiveDayIndex(int requestedDayIndex) {
    if (!_calendarService.isEnabled) {
      return requestedDayIndex;
    }

    final today = DateTime.now().weekday - 1;
    final targetDate = DateTime.now().add(
      Duration(days: requestedDayIndex - today),
    );

    final isHoliday = _calendarService.isHolidayDate(targetDate);
    if (isHoliday) {
      Logger.d(_tag, 'Date $targetDate is a holiday, showing no classes');
      return -1;
    }

    final dayOrder = _calendarService.getDayOrderForDate(targetDate);
    if (dayOrder != null && targetDate.weekday == 6) {
      Logger.d(_tag, 'Saturday mapped to day order $dayOrder');
      return dayOrder;
    }

    return requestedDayIndex;
  }
}
