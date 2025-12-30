import '../../../core/utils/logger.dart';
import '../../../core/database/database.dart';
import '../data/home_data_provider.dart';
import '../../profile/widget_customization/data/calendar_home_service.dart';
import '../services/home_friends_integration_service.dart';

class HomeLogic {
  static const String _tag = 'HomeLogic';

  final HomeDataProvider _dataProvider = HomeDataProvider();
  final CalendarHomeService _calendarService = CalendarHomeService.instance;
  final HomeFriendsIntegrationService _friendsIntegration = HomeFriendsIntegrationService();

  // Cached data
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _timetableData = [];
  List<Map<String, dynamic>> _examData = [];
  List<Map<String, dynamic>> _coursesData = [];
  List<Map<String, dynamic>> _slotsData = [];
  int _onDutyCount = 0;
  
  // Cache for combined classes per day
  final Map<int, List<Map<String, dynamic>>> _combinedClassesCache = {};

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

      // Clear combined classes cache when reloading data
      clearCombinedClassesCache();

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
    } catch (e) {
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
          final existingErpId = enhancedCourse['faculty_erp_id']?.toString();
          if (existingErpId == null || existingErpId.isEmpty) {
            final generatedId =
                enhancedCourse['faculty']?.toString().hashCode.toString();
            enhancedCourse['faculty_erp_id'] = generatedId;
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

    // Merge consecutive classes with the same course
    final mergedClasses = _mergeConsecutiveClasses(dayClasses);

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

  /// Get combined classes for a specific day (user + friends)
  Future<List<Map<String, dynamic>>> getCombinedClassesForDay(int dayIndex) async {
    // Return cached data if available
    if (_combinedClassesCache.containsKey(dayIndex)) {
      return _combinedClassesCache[dayIndex]!;
    }
    
    try {
      // Get user's classes (existing logic)
      final userClasses = getClassesForDay(dayIndex);
      
      // Get friends' classes
      final friendsClasses = await _getFriendsClassesForDay(dayIndex);
      
      // Merge consecutive classes for friends too
      final mergedFriendsClasses = _mergeConsecutiveFriendClasses(friendsClasses);
      
      // Combine and sort by time
      final allClasses = <Map<String, dynamic>>[];
      allClasses.addAll(userClasses);
      allClasses.addAll(mergedFriendsClasses);
      
      // Sort by start time
      allClasses.sort((a, b) {
        final timeA = a['start_time']?.toString() ?? '';
        final timeB = b['start_time']?.toString() ?? '';
        return timeA.compareTo(timeB);
      });
      
      // Cache the result
      _combinedClassesCache[dayIndex] = allClasses;
      
      return allClasses;
    } catch (e) {
      // Fallback to user classes only
      final userClasses = getClassesForDay(dayIndex);
      _combinedClassesCache[dayIndex] = userClasses;
      return userClasses;
    }
  }
  
  /// Clear the combined classes cache (call when data changes)
  void clearCombinedClassesCache() {
    _combinedClassesCache.clear();
  }

  /// Get friends' classes for a specific day
  Future<List<Map<String, dynamic>>> _getFriendsClassesForDay(int dayIndex) async {
    try {
      final friends = await _friendsIntegration.getFriendsForHomePage();
      final friendsClasses = <Map<String, dynamic>>[];
      
      for (final friend in friends) {
        final dayName = _getDayNameFromIndex(dayIndex);
        if (dayName == null) continue;
        
        final dayClasses = friend.getClassesForDay(dayName);
        
        for (final classSlot in dayClasses) {
          friendsClasses.add({
            'start_time': _parseTimeSlotStart(classSlot.timeSlot),
            'end_time': _parseTimeSlotEnd(classSlot.timeSlot),
            'course': {
              'code': classSlot.courseCode,
              'title': classSlot.courseTitle,
              'venue': classSlot.venue,
            },
            'slotName': classSlot.slotId,
            'slotNames': [classSlot.slotId], // For merging compatibility
            'isFriendClass': true,
            'friend': friend,
            'friendNickname': friend.nickname,
            'friendColor': friend.color,
          });
        }
      }
      
      return friendsClasses;
    } catch (e) {
      return [];
    }
  }

  /// Merge consecutive friend classes with the same course code and title
  List<Map<String, dynamic>> _mergeConsecutiveFriendClasses(
    List<Map<String, dynamic>> classes,
  ) {
    if (classes.isEmpty) return classes;

    // Group classes by friend first
    final Map<String, List<Map<String, dynamic>>> classesByFriend = {};
    for (var classData in classes) {
      final friendId = classData['friend']?.id ?? 'unknown';
      classesByFriend.putIfAbsent(friendId, () => []);
      classesByFriend[friendId]!.add(classData);
    }

    final allMergedClasses = <Map<String, dynamic>>[];

    // Merge consecutive classes for each friend separately
    for (var friendClasses in classesByFriend.values) {
      // Sort classes by start time first
      friendClasses.sort((a, b) {
        final timeA = a['start_time']?.toString() ?? '';
        final timeB = b['start_time']?.toString() ?? '';
        return timeA.compareTo(timeB);
      });

      final merged = <Map<String, dynamic>>[];
      Map<String, dynamic>? currentClass;

      for (var classData in friendClasses) {
        if (currentClass == null) {
          // First class
          currentClass = Map<String, dynamic>.from(classData);
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

        // Check if times are consecutive
        final currentEndTime = currentClass['end_time']?.toString() ?? '';
        final nextStartTime = classData['start_time']?.toString() ?? '';
        final isConsecutive = currentEndTime == nextStartTime;

        if (isSameCourse && isConsecutive) {
          // Merge with current class
          currentClass['end_time'] = classData['end_time'];
          (currentClass['slotNames'] as List).add(classData['slotName']);
        } else {
          // Not consecutive or different course, save current and start new
          merged.add(currentClass);
          currentClass = Map<String, dynamic>.from(classData);
          currentClass['slotNames'] = [classData['slotName']];
        }
      }

      // Add the last class
      if (currentClass != null) {
        merged.add(currentClass);
      }

      allMergedClasses.addAll(merged);
    }

    return allMergedClasses;
  }

  /// Convert day index to day name
  String? _getDayNameFromIndex(int dayIndex) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayIndex >= 0 && dayIndex < dayNames.length) {
      return dayNames[dayIndex];
    }
    return null;
  }

  /// Parse time slot start time (e.g., "08:00-08:50" -> "08:00")
  String _parseTimeSlotStart(String timeSlot) {
    try {
      return timeSlot.split('-')[0];
    } catch (e) {
      return timeSlot;
    }
  }

  /// Parse time slot end time (e.g., "08:00-08:50" -> "08:50")
  String _parseTimeSlotEnd(String timeSlot) {
    try {
      return timeSlot.split('-')[1];
    } catch (e) {
      return timeSlot;
    }
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
