import '../../features/vitconnect_services/friends_schedule/models/friend.dart';
import '../../features/vitconnect_services/friends_schedule/services/friends_timetable_service.dart';
import '../../features/vitconnect_services/friends_schedule/models/timetable_constants.dart';

/// Unified class item for displaying both user and friend classes
class ClassItem {
  final String courseCode;
  final String courseTitle;
  final String timeSlot;
  final String venue;
  final String slotId;
  final bool isUserClass;
  final Friend? friend;
  final String? friendNickname;

  const ClassItem({
    required this.courseCode,
    required this.courseTitle,
    required this.timeSlot,
    required this.venue,
    required this.slotId,
    required this.isUserClass,
    this.friend,
    this.friendNickname,
  });

  /// Get start time for sorting
  DateTime get startTime {
    try {
      final timeParts = timeSlot.split('-')[0].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(2024, 1, 1, hour, minute);
    } catch (e) {
      return DateTime(2024, 1, 1, 0, 0);
    }
  }
}

/// Service to integrate friends' schedules with home page
class HomeFriendsIntegrationService {
  final FriendsScheduleService _friendsService = FriendsScheduleService();

  /// Get friends that should be shown on home page
  Future<List<Friend>> getFriendsForHomePage() async {
    try {
      await _friendsService.loadFriends();
      return _friendsService.friendsForHomePage;
    } catch (e) {
      return [];
    }
  }

  /// Get combined classes for a specific day (user + friends)
  Future<List<ClassItem>> getCombinedClassesForDay(
    int dayIndex,
    List<Map<String, dynamic>> userTimetableData,
  ) async {
    try {
      final List<ClassItem> allClasses = [];

      // Add user's classes
      allClasses.addAll(_getUserClassesForDay(dayIndex, userTimetableData));

      // Add friends' classes
      final friends = await getFriendsForHomePage();
      for (final friend in friends) {
        allClasses.addAll(_getFriendClassesForDay(dayIndex, friend));
      }

      // Sort by time
      allClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

      return allClasses;
    } catch (e) {
      return _getUserClassesForDay(dayIndex, userTimetableData);
    }
  }

  /// Convert user's timetable data to ClassItem list for specific day
  List<ClassItem> _getUserClassesForDay(
    int dayIndex,
    List<Map<String, dynamic>> userTimetableData,
  ) {
    final List<ClassItem> userClasses = [];

    try {
      for (final classData in userTimetableData) {
        userClasses.add(
          ClassItem(
            courseCode: classData['course']?['code'] as String? ?? '',
            courseTitle: classData['course']?['title'] as String? ?? '',
            timeSlot:
                '${classData['start_time'] ?? ''}-${classData['end_time'] ?? ''}',
            venue: classData['course']?['venue'] as String? ?? '',
            slotId: classData['slotName'] as String? ?? '',
            isUserClass: true,
          ),
        );
      }
    } catch (e) {
      // Silent error handling
    }

    return userClasses;
  }

  /// Convert friend's schedule to ClassItem list for specific day
  List<ClassItem> _getFriendClassesForDay(int dayIndex, Friend friend) {
    final List<ClassItem> friendClasses = [];

    try {
      if (dayIndex < 0 || dayIndex >= ScheduleConstants.weekDays.length) {
        return friendClasses;
      }

      final dayName = ScheduleConstants.weekDays[dayIndex];
      final dayClasses = friend.getClassesForDay(dayName);

      for (final classSlot in dayClasses) {
        friendClasses.add(
          ClassItem(
            courseCode: classSlot.courseCode,
            courseTitle: classSlot.courseTitle,
            timeSlot: classSlot.timeSlot,
            venue: classSlot.venue,
            slotId: classSlot.slotId,
            isUserClass: false,
            friend: friend,
            friendNickname: friend.nickname,
          ),
        );
      }
    } catch (e) {
      // Silent error handling
    }

    return friendClasses;
  }

  /// Refresh friends data
  Future<void> refreshFriendsData() async {
    try {
      await _friendsService.loadFriends();
    } catch (e) {
      // Silent error handling
    }
  }
}
