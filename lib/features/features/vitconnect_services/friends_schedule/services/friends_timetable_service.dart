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
  static const String _selectedFriendsKey = 'selected_friends_ids';
  static const String _initializedKey = 'friends_schedule_initialized';

  List<Friend> _friends = [];
  List<String> _selectedFriendIds = [];

  /// Default ImBot timetable data for first-time users
  static const String _defaultImBotQRData =
      'ImBot|99BOT9876|Wednesday|08:00-08:50|BCSE999P|AI-Powered Napping Lab|FUN1 - 007|L13||Tuesday|08:00-08:50|BCSE888L|Quantum Meme Theory|LOL2 - 404|B1||Thursday|08:00-08:50|BMAT777L|Discrete Pizza Graphs|YUM3 - 666|D1||Wednesday|08:50-09:45|BCSE999P|AI-Powered Napping Lab|FUN1 - 007|L14||Monday|08:50-09:45|BCSE555L|Software for Robots that Compliment You|GIG3 - 101|F1||Thursday|08:50-09:45|BCSE888L|Quantum Meme Theory|LOL2 - 404|B1||Monday|09:50-10:40|BMAT777L|Discrete Pizza Graphs|YUM3 - 666|D1||Wednesday|09:50-10:40|BCSE555L|Software for Robots that Compliment You|GIG3 - 101|F1||Monday|10:40-11:35|BCSE888L|Quantum Meme Theory|LOL2 - 404|TB1||Wednesday|10:40-11:35|BMAT777L|Discrete Pizza Graphs|YUM3 - 666|TD1||Friday|10:40-11:35|BCSE555L|Software for Robots that Compliment You|GIG3 - 101|TF1||Friday|11:40-12:30|BMAT777L|Discrete Pizza Graphs|YUM3 - 666|TDD1||Monday|14:00-14:50|BMAT123L|Advanced Procrastination Techniques|NAP3 - 909|A2||Tuesday|14:00-14:50|BCSE321L|Clouds: The Musical|SKY3 - 808|B2||Thursday|14:00-14:50|BSTS999P|Competitive Gaming for Cats|MEOW3 - 505|D2||Tuesday|14:50-15:45|BCSE999L|AI-Powered Napping Lab|FUN1 - 007|G2||Wednesday|14:50-15:45|BMAT123L|Advanced Procrastination Techniques|NAP3 - 909|A2||Thursday|14:50-15:45|BCSE321L|Clouds: The Musical|SKY3 - 808|B2||Tuesday|15:50-16:40|BCSE555P|Software for Robots that Compliment You Lab|GIG3 - 101|L39||Monday|15:50-16:40|BSTS999P|Competitive Gaming for Cats|MEOW3 - 505|D2||Thursday|15:50-16:40|BCSE999L|AI-Powered Napping Lab|FUN1 - 007|G2||Friday|15:50-16:40|BMAT123L|Advanced Procrastination Techniques|NAP3 - 909|TA2||Tuesday|16:45-17:35|BCSE555P|Software for Robots that Compliment You Lab|GIG3 - 101|L40||Monday|16:45-17:35|BCSE321L|Clouds: The Musical|SKY3 - 808|TB2||Wednesday|16:45-17:35|BSTS999P|Competitive Gaming for Cats|MEOW3 - 505|TD2||Monday|17:40-18:30|BCSE999L|AI-Powered Napping Lab|FUN1 - 007|TG2||Tuesday|17:40-18:30|BMAT123L|Advanced Procrastination Techniques|NAP3 - 909|TAA2';

  /// Get all friends
  List<Friend> get friends => List.unmodifiable(_friends);

  /// Get selected friends
  List<Friend> get selectedFriends {
    return _friends.where((f) => _selectedFriendIds.contains(f.id)).toList();
  }

  /// Load friends from shared preferences
  Future<void> loadFriends() async {
    try {
      Logger.d('FriendsSchedule', 'Loading friends from storage...');

      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString(_friendsKey);
      final selectedIds = prefs.getStringList(_selectedFriendsKey) ?? [];
      final isInitialized = prefs.getBool(_initializedKey) ?? false;

      if (friendsJson != null) {
        final List<dynamic> decoded = jsonDecode(friendsJson);
        _friends =
            decoded
                .map((e) => Friend.fromJson(e as Map<String, dynamic>))
                .toList();
        _selectedFriendIds = selectedIds;

        Logger.success('FriendsSchedule', 'Loaded ${_friends.length} friends');
      } else if (!isInitialized) {
        Logger.d(
          'FriendsSchedule',
          'First launch detected - adding default ImBot friend',
        );
        await _initializeDefaultFriend();
        await prefs.setBool(_initializedKey, true);
      } else {
        Logger.d('FriendsSchedule', 'No friends found in storage');
      }
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to load friends', e);
      _friends = [];
      _selectedFriendIds = [];
    }
  }

  /// Initialize default ImBot friend for first-time users
  Future<void> _initializeDefaultFriend() async {
    try {
      final imBotFriend = Friend.fromQRString(
        _defaultImBotQRData,
        color: const Color(0xFFFFB800),
      );

      _friends.add(imBotFriend);
      _selectedFriendIds.add(imBotFriend.id);

      await saveFriends();

      Logger.success(
        'FriendsSchedule',
        'Default ImBot friend added successfully',
      );
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to add default ImBot friend', e);
    }
  }

  /// Save friends to shared preferences
  Future<void> saveFriends() async {
    try {
      Logger.d('FriendsSchedule', 'Saving ${_friends.length} friends...');

      final prefs = await SharedPreferences.getInstance();
      final friendsJson = jsonEncode(_friends.map((f) => f.toJson()).toList());

      await prefs.setString(_friendsKey, friendsJson);
      await prefs.setStringList(_selectedFriendsKey, _selectedFriendIds);

      Logger.success('FriendsSchedule', 'Friends saved successfully');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to save friends', e);
      rethrow;
    }
  }

  /// Add a new friend
  Future<void> addFriend(Friend friend) async {
    try {
      final existingIndex = _friends.indexWhere((f) => f.id == friend.id);

      if (existingIndex >= 0) {
        _friends[existingIndex] = friend;
        Logger.d('FriendsSchedule', 'Updated friend: ${friend.name}');
      } else {
        _friends.add(friend);
        _selectedFriendIds.add(friend.id);
        Logger.success('FriendsSchedule', 'Added friend: ${friend.name}');
      }

      await saveFriends();
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to add friend', e);
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      _friends.removeWhere((f) => f.id == friendId);
      _selectedFriendIds.remove(friendId);
      await saveFriends();

      Logger.success('FriendsSchedule', 'Removed friend: $friendId');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to remove friend', e);
      rethrow;
    }
  }

  /// Toggle friend selection
  Future<void> toggleFriendSelection(String friendId) async {
    try {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
      await saveFriends();

      Logger.d('FriendsSchedule', 'Toggled selection for: $friendId');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to toggle friend selection', e);
      rethrow;
    }
  }

  /// Update friend's color
  Future<void> updateFriendColor(String friendId, Color newColor) async {
    try {
      final friendIndex = _friends.indexWhere((f) => f.id == friendId);
      if (friendIndex < 0) {
        Logger.w('FriendsSchedule', 'Friend not found: $friendId');
        return;
      }

      final friend = _friends[friendIndex];
      final updatedFriend = Friend(
        id: friend.id,
        name: friend.name,
        regNumber: friend.regNumber,
        classSlots: friend.classSlots,
        color: newColor,
        addedAt: friend.addedAt,
      );

      _friends[friendIndex] = updatedFriend;
      await saveFriends();

      Logger.success(
        'FriendsSchedule',
        'Updated color for ${friend.name}: ${newColor.value}',
      );
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to update friend color', e);
      rethrow;
    }
  }

  /// Get overlap count for a specific slot
  /// Returns number of selected friends who have class at this time
  int getOverlapCount(String day, String timeSlot) {
    int count = 0;
    for (final friend in selectedFriends) {
      if (friend.hasClassAt(day, timeSlot)) {
        count++;
      }
    }
    return count;
  }

  /// Get friends who have class at specific slot
  List<Friend> getFriendsWithClassAt(String day, String timeSlot) {
    return selectedFriends.where((f) => f.hasClassAt(day, timeSlot)).toList();
  }

  /// Get friends who are free at specific slot
  List<Friend> getFriendsFreeAt(String day, String timeSlot) {
    return selectedFriends.where((f) => !f.hasClassAt(day, timeSlot)).toList();
  }

  /// Get friends with same venue at specific slot
  Map<String, List<Friend>> getFriendsByVenueAt(String day, String timeSlot) {
    final Map<String, List<Friend>> venueMap = {};

    for (final friend in selectedFriends) {
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
        regNumber: studentReg,
        classSlots: classSlots,
        color: const Color(0xFF6366F1), // Primary app color
        addedAt: DateTime.now(),
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
      _selectedFriendIds.clear();
      await saveFriends();

      Logger.success('FriendsSchedule', 'Cleared all friends');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to clear friends', e);
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
