import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/database/database.dart';
import '../../../../authentication/core/auth_service.dart';
import '../models/friend.dart';
import '../models/friend_class_slot.dart';
import '../models/timetable_constants.dart';

/// Service to manage friends' schedule data
/// Handles loading, saving, and combining schedules
class FriendsScheduleService {
  static const String _friendsKey = 'friends_schedule_list';

  List<Friend> _friends = [];

  /// Get all friends
  List<Friend> get friends => List.unmodifiable(_friends);

  /// Get friends for Friends Schedule page
  List<Friend> get friendsForSchedulePage {
    return _friends.where((f) => f.showInFriendsSchedule).toList();
  }

  /// Get friends for Home page
  List<Friend> get friendsForHomePage {
    return _friends.where((f) => f.showInHomePage).toList();
  }

  /// Default ImBot timetable data for first-time users (removed - no longer needed)

  /// Load friends from shared preferences
  Future<void> loadFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString(_friendsKey);

      if (friendsJson != null) {
        final List<dynamic> decoded = jsonDecode(friendsJson);
        _friends =
            decoded
                .map((e) => Friend.fromJson(e as Map<String, dynamic>))
                .toList();
      } else {
        // First time - add default student
        _friends = [];
        await _addDefaultStudent();
      }
    } catch (e) {
      _friends = [];
    }
  }

  /// Add default student for demonstration
  Future<void> _addDefaultStudent() async {
    try {
      const defaultQRData = 'Student 011|99REG0011|Monday|08:00-08:50|BCSE101L|Breaking Bad Chemistry of Bad Decisions|AB1 - 101|L1||Wednesday|08:00-08:50|BCSE202L|Stranger Things Upside Down Algorithms|AB1 - 209|L13||Monday|08:50-09:45|BCSE101L|Breaking Bad Chemistry of Bad Decisions|AB1 - 101|L2||Wednesday|08:50-09:45|BCSE202L|Stranger Things Upside Down Algorithms|AB1 - 209|L14||Monday|09:50-10:40|BCSE303P|Friends Level Communication Skills|AB1 - 614|L3||Monday|10:40-11:35|BCSE303P|Friends Level Communication Skills|AB1 - 614|L4||Monday|14:00-14:50|BCSE303L|How Humans Talk Less Than Machines|AB3 - 503|A2||Tuesday|14:00-14:50|BSTS404P|Squid Game Competitive Survival Coding|AB3 - 509|B2||Wednesday|14:00-14:50|BCSE111L|Money Heist Security and Master Plans|AB3 - 513|C2||Thursday|14:00-14:50|BCSE202L|Stranger Things Upside Down Algorithms|AB3 - 505|D2||Friday|14:00-14:50|BHUM999L|Black Mirror Society Reality Check|AB3 - 709|E2||Monday|14:50-15:45|BCSE404L|Dark Timeline Compiler Confusion|AB3 - 504|F2||Tuesday|14:50-15:45|BCSE505L|Sherlock Level Logical Reasoning AI|AB3 - 506|G2||Wednesday|14:50-15:45|BCSE303L|How Humans Talk Less Than Machines|AB3 - 503|A2||Thursday|14:50-15:45|BSTS404P|Squid Game Competitive Survival Coding|AB3 - 509|B2||Friday|14:50-15:45|BCSE111L|Money Heist Security and Master Plans|AB3 - 513|C2||Monday|15:50-16:40|BCSE202L|Stranger Things Upside Down Algorithms|AB3 - 505|D2||Tuesday|15:50-16:40|BHUM999L|Black Mirror Society Reality Check|AB3 - 709|E2||Wednesday|15:50-16:40|BCSE404L|Dark Timeline Compiler Confusion|AB3 - 504|F2||Thursday|15:50-16:40|BCSE505L|Sherlock Level Logical Reasoning AI|AB3 - 506|G2||Friday|15:50-16:40|BCSE303L|How Humans Talk Less Than Machines|AB3 - 503|TA2||Monday|16:45-17:35|BSTS404P|Squid Game Competitive Survival Coding|AB3 - 509|TB2||Tuesday|16:45-17:35|BCSE111L|Money Heist Security and Master Plans|AB3 - 513|TC2||Wednesday|16:45-17:35|BCSE202L|Stranger Things Upside Down Algorithms|AB3 - 505|TD2||Thursday|16:45-17:35|BHUM999L|Black Mirror Society Reality Check|AB3 - 709|TE2||Friday|16:45-17:35|BCSE404L|Dark Timeline Compiler Confusion|AB3 - 504|TF2||Tuesday|17:40-18:30|BCSE404P|Breaking Bad Level Debugging Lab|AB1 - 205A|L41||Tuesday|18:35-19:25|BCSE404P|Breaking Bad Level Debugging Lab|AB1 - 205A|L42';
      
      final defaultFriend = Friend.fromQRString(defaultQRData);
      
      // Set both toggles to true by default
      final friendWithToggles = defaultFriend.copyWith(
        showInFriendsSchedule: true,
        showInHomePage: true,
      );
      
      _friends.add(friendWithToggles);
      await saveFriends();
      
      Logger.success('FriendsSchedule', 'Added default student: ${friendWithToggles.name}');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to add default student', e);
    }
  }

  /// Save friends to shared preferences
  Future<void> saveFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = jsonEncode(_friends.map((f) => f.toJson()).toList());
      await prefs.setString(_friendsKey, friendsJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new friend
  Future<void> addFriend(Friend friend) async {
    try {
      final existingIndex = _friends.indexWhere((f) => f.id == friend.id);

      if (existingIndex >= 0) {
        _friends[existingIndex] = friend;
      } else {
        _friends.add(friend);
      }

      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      _friends.removeWhere((f) => f.id == friendId);
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle Friends Schedule visibility
  Future<void> toggleFriendsScheduleVisibility(String friendId) async {
    try {
      final friendIndex = _friends.indexWhere((f) => f.id == friendId);
      if (friendIndex < 0) return;

      final friend = _friends[friendIndex];
      _friends[friendIndex] = friend.copyWith(
        showInFriendsSchedule: !friend.showInFriendsSchedule,
      );
      
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle Home Page visibility
  Future<void> toggleHomePageVisibility(String friendId) async {
    try {
      final friendIndex = _friends.indexWhere((f) => f.id == friendId);
      if (friendIndex < 0) return;

      final friend = _friends[friendIndex];
      _friends[friendIndex] = friend.copyWith(
        showInHomePage: !friend.showInHomePage,
      );
      
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Update friend's nickname
  Future<void> updateFriendNickname(String friendId, String nickname) async {
    try {
      final friendIndex = _friends.indexWhere((f) => f.id == friendId);
      if (friendIndex < 0) return;

      final friend = _friends[friendIndex];
      _friends[friendIndex] = friend.copyWith(nickname: nickname);
      
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Update friend's color
  Future<void> updateFriendColor(String friendId, Color newColor) async {
    try {
      final friendIndex = _friends.indexWhere((f) => f.id == friendId);
      if (friendIndex < 0) return;

      final friend = _friends[friendIndex];
      _friends[friendIndex] = friend.copyWith(color: newColor);
      
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Get overlap count for a specific slot
  /// Returns number of friends who have class at this time
  int getOverlapCount(String day, String timeSlot) {
    int count = 0;
    for (final friend in friendsForSchedulePage) {
      if (friend.hasClassAt(day, timeSlot)) {
        count++;
      }
    }
    return count;
  }

  /// Get friends who have class at specific slot
  List<Friend> getFriendsWithClassAt(String day, String timeSlot) {
    return friendsForSchedulePage.where((f) => f.hasClassAt(day, timeSlot)).toList();
  }

  /// Get friends who are free at specific slot
  List<Friend> getFriendsFreeAt(String day, String timeSlot) {
    return friendsForSchedulePage.where((f) => !f.hasClassAt(day, timeSlot)).toList();
  }

  /// Get friends with same venue at specific slot
  Map<String, List<Friend>> getFriendsByVenueAt(String day, String timeSlot) {
    final Map<String, List<Friend>> venueMap = {};

    for (final friend in friendsForSchedulePage) {
      final slot = friend.getSlotForCell(day, timeSlot);
      if (slot != null && slot.venue.isNotEmpty) {
        venueMap.putIfAbsent(slot.venue, () => []);
        venueMap[slot.venue]!.add(friend);
      }
    }

    return venueMap;
  }

  /// Load current user's schedule from database and convert to Friend object
  Future<Friend?> loadOwnSchedule() async {
    try {
      Logger.d('FriendsSchedule', 'Loading own schedule from database...');

      final db = VitConnectDatabase.instance;
      final database = await db.database;

      // Get user info from SharedPreferences (student_profile)
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      String studentName = 'You';
      String studentReg = '';

      if (profileJson != null && profileJson.isNotEmpty) {
        try {
          final profile = jsonDecode(profileJson) as Map<String, dynamic>;
          studentName = profile['name']?.toString() ?? 'You';
          studentReg = profile['registerNumber']?.toString() ?? '';
        } catch (e) {
          Logger.w('FriendsSchedule', 'Failed to parse student profile: $e');
          // Fallback to auth service session
          final authService = VTOPAuthService.instance;
          final session = authService.currentSession;
          studentName = session?.studentName ?? 'You';
          studentReg = session?.registrationNumber ?? '';
        }
      } else {
        // Fallback to auth service session
        final authService = VTOPAuthService.instance;
        final session = authService.currentSession;
        studentName = session?.studentName ?? 'You';
        studentReg = session?.registrationNumber ?? '';
      }

      Logger.d(
        'FriendsSchedule',
        'Loading own schedule for: $studentName ($studentReg)',
      );

      // Get timetable data
      final timetableData = await database.query('timetable');
      final coursesData = await database.query('courses');
      final slotsData = await database.query('slots');

      Logger.d(
        'FriendsSchedule',
        'Database data - Timetable: ${timetableData.length}, Courses: ${coursesData.length}, Slots: ${slotsData.length}',
      );

      // Create maps for quick lookup
      final courseMap = <int, Map<String, dynamic>>{};
      for (var course in coursesData) {
        if (course['id'] != null) {
          courseMap[course['id'] as int] = course;
        }
      }

      final slotMap = <int, Map<String, dynamic>>{};
      for (var slot in slotsData) {
        if (slot['id'] != null) {
          slotMap[slot['id'] as int] = slot;
        }
      }

      // Build class slots
      final List<FriendClassSlot> classSlots = [];

      for (var timetableEntry in timetableData) {
        final startTime = timetableEntry['start_time'] as String?;
        final endTime = timetableEntry['end_time'] as String?;

        if (startTime == null || endTime == null) continue;

        // Format time to match constants (ensure consistent format)
        final formattedStartTime = _formatTime(startTime);
        final formattedEndTime = _formatTime(endTime);
        final timeSlot = '$formattedStartTime-$formattedEndTime';

        // Find matching time slot with ±5 minutes flexibility
        String? matchingTimeSlot = _findMatchingTimeSlot(timeSlot);

        if (matchingTimeSlot == null) {
          Logger.w('FriendsSchedule', 'No matching time slot for: $timeSlot');
          continue;
        }

        // Process each day
        final dayColumns = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
        ];
        for (int dayIndex = 0; dayIndex < dayColumns.length; dayIndex++) {
          final dayColumn = dayColumns[dayIndex];
          final slotId = timetableEntry[dayColumn] as int?;

          if (slotId != null && slotMap.containsKey(slotId)) {
            final slotData = slotMap[slotId]!;
            final courseId = slotData['course_id'] as int?;

            if (courseId != null && courseMap.containsKey(courseId)) {
              final courseData = courseMap[courseId]!;

              classSlots.add(
                FriendClassSlot(
                  day: ScheduleConstants.weekDays[dayIndex],
                  timeSlot: matchingTimeSlot,
                  courseCode: courseData['code'] as String? ?? '',
                  courseTitle: courseData['title'] as String? ?? '',
                  venue: courseData['venue'] as String? ?? '',
                  slotId: slotData['slot'] as String? ?? '',
                ),
              );
            }
          }
        }
      }

      Logger.success(
        'FriendsSchedule',
        'Loaded ${classSlots.length} class slots for own schedule',
      );

      return Friend(
        id: studentReg.isNotEmpty ? studentReg : 'me',
        name: studentName,
        nickname: studentName, // Default nickname is the name
        regNumber: studentReg,
        classSlots: classSlots,
        color: const Color(0xFF6366F1), // Primary app color
        addedAt: DateTime.now(),
        showInFriendsSchedule: false, // Not applicable for own schedule
        showInHomePage: false, // Not applicable for own schedule
      );
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to load own schedule', e);
      return null;
    }
  }

  /// Generate QR data for own schedule
  Future<String?> generateOwnQRData() async {
    final ownSchedule = await loadOwnSchedule();
    return ownSchedule?.toQRString();
  }

  /// Clear all friends
  Future<void> clearAllFriends() async {
    try {
      _friends.clear();
      await saveFriends();
    } catch (e) {
      rethrow;
    }
  }

  /// Format time to ensure consistent format (HH:MM)
  String _formatTime(String time) {
    try {
      // Handle different time formats
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]).toString().padLeft(2, '0');
          final minute = int.parse(parts[1]).toString().padLeft(2, '0');
          return '$hour:$minute';
        }
      }
      return time;
    } catch (e) {
      Logger.w('FriendsSchedule', 'Failed to format time: $time');
      return time;
    }
  }

  /// Find matching time slot with ±5 minutes flexibility for theory/lab compatibility
  String? _findMatchingTimeSlot(String timeSlot) {
    // First try exact match
    if (ScheduleConstants.timeSlots.contains(timeSlot)) {
      return timeSlot;
    }

    // Parse the input time slot
    final parts = timeSlot.split('-');
    if (parts.length != 2) return null;

    final startParts = parts[0].trim().split(':');
    final endParts = parts[1].trim().split(':');

    if (startParts.length != 2 || endParts.length != 2) return null;

    try {
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      // Check each constant time slot for ±5 minute match
      for (final constantSlot in ScheduleConstants.timeSlots) {
        final constantParts = constantSlot.split('-');
        final constantStartParts = constantParts[0].trim().split(':');
        final constantEndParts = constantParts[1].trim().split(':');

        final constantStartMinutes =
            int.parse(constantStartParts[0]) * 60 +
            int.parse(constantStartParts[1]);
        final constantEndMinutes =
            int.parse(constantEndParts[0]) * 60 +
            int.parse(constantEndParts[1]);

        // Check if start and end times are within ±5 minutes
        if ((startTotalMinutes - constantStartMinutes).abs() <= 5 &&
            (endTotalMinutes - constantEndMinutes).abs() <= 5) {
          return constantSlot;
        }
      }
    } catch (e) {
      Logger.w('FriendsSchedule', 'Failed to parse time slot: $timeSlot');
    }

    return null;
  }
}
