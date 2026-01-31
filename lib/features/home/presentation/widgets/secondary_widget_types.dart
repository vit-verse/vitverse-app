import 'package:flutter/material.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../logic/home_logic.dart';
import '../../../profile/widget_customization/data/widget_preferences_service.dart';

/// Factory class for building different types of secondary widgets
class SecondaryWidgetTypes {
  static Widget buildWidget(
    HomeSecondaryWidgetType type,
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    switch (type) {
      case HomeSecondaryWidgetType.todayClasses:
        return _buildTodayClassesWidget(homeLogic, themeProvider);
      case HomeSecondaryWidgetType.ongoingClass:
        return _buildOngoingClassWidget(homeLogic, themeProvider);
      case HomeSecondaryWidgetType.nextClass:
        return _buildNextClassWidget(homeLogic, themeProvider);
      case HomeSecondaryWidgetType.nextExam:
        return _buildNextExamWidget(homeLogic, themeProvider);
      case HomeSecondaryWidgetType.totalODs:
        return _buildTotalODsWidget(homeLogic, themeProvider);
    }
  }

  static Widget _buildTodayClassesWidget(
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    final now = DateTime.now();
    final selectedDay = now.weekday - 1; // 0=Monday, 6=Sunday
    final todaysClasses = homeLogic.getClassesForDay(selectedDay);

    // Filter user's classes only
    final userClasses =
        todaysClasses
            .where((classData) => classData['isFriendClass'] != true)
            .toList();

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final selectedDate = now.add(
      Duration(days: selectedDay - (now.weekday - 1)),
    );
    final dateStr = '${selectedDate.day}/${selectedDate.month}';
    final isToday = selectedDay == (now.weekday - 1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TOTAL CLASSES',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.muted,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${userClasses.length}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTheme.text,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isToday ? 'Today' : dayNames[selectedDay],
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.currentTheme.text,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 10,
              color: themeProvider.currentTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _buildOngoingClassWidget(
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final todaysClasses = homeLogic.getClassesForDay(now.weekday - 1);

    // Filter user's classes only
    final userClasses =
        todaysClasses
            .where((classData) => classData['isFriendClass'] != true)
            .toList();

    // Find ongoing class
    Map<String, dynamic>? ongoingClass;
    for (var classData in userClasses) {
      final startTime = classData['start_time']?.toString() ?? '';
      final endTime = classData['end_time']?.toString() ?? '';

      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        final startParts = startTime.split(':');
        final endParts = endTime.split(':');
        final startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        if (currentTime >= startMinutes && currentTime < endMinutes) {
          ongoingClass = classData;
          break;
        }
      }
    }

    if (ongoingClass == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ONGOING CLASS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: themeProvider.currentTheme.muted,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.free_breakfast_rounded,
              size: 32,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'No class right now',
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.currentTheme.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final course = ongoingClass['course'] as Map<String, dynamic>?;
    final courseTitle = course?['title']?.toString() ?? 'Unknown';
    final courseCode = course?['code']?.toString() ?? '';
    final startTime = ongoingClass['start_time']?.toString() ?? '';
    final endTime = ongoingClass['end_time']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ONGOING CLASS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.muted,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            courseTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeProvider.currentTheme.text,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          Text(
            courseCode,
            style: TextStyle(
              fontSize: 9,
              color: themeProvider.currentTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_formatTimeTo12Hour(startTime)} - ${_formatTimeTo12Hour(endTime)}',
                style: TextStyle(
                  fontSize: 10,
                  color: themeProvider.currentTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNextClassWidget(
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final todaysClasses = homeLogic.getClassesForDay(now.weekday - 1);

    // Filter user's classes only
    final userClasses =
        todaysClasses
            .where((classData) => classData['isFriendClass'] != true)
            .toList();

    // Find next class
    Map<String, dynamic>? nextClass;
    for (var classData in userClasses) {
      final startTime = classData['start_time']?.toString() ?? '';

      if (startTime.isNotEmpty) {
        final startParts = startTime.split(':');
        final startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

        if (currentTime < startMinutes) {
          nextClass = classData;
          break;
        }
      }
    }

    if (nextClass == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NEXT CLASS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: themeProvider.currentTheme.muted,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.check_circle_outline,
              size: 36,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'All done for today',
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.currentTheme.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final course = nextClass['course'] as Map<String, dynamic>?;
    final courseTitle = course?['title']?.toString() ?? 'Unknown';
    final courseCode = course?['code']?.toString() ?? '';
    final startTime = nextClass['start_time']?.toString() ?? '';
    final endTime = nextClass['end_time']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NEXT CLASS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            courseTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeProvider.currentTheme.text,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          Text(
            courseCode,
            style: TextStyle(
              fontSize: 9,
              color: themeProvider.currentTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_formatTimeTo12Hour(startTime)} - ${_formatTimeTo12Hour(endTime)}',
                style: TextStyle(
                  fontSize: 10,
                  color: themeProvider.currentTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNextExamWidget(
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    final nextExam = homeLogic.getNextExam();

    if (nextExam == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NEXT EXAM',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: themeProvider.currentTheme.muted,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.celebration_outlined,
              size: 32,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'No exams scheduled',
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.currentTheme.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final courseCode = nextExam['course_code']?.toString() ?? '';
    final courseTitle = nextExam['title']?.toString() ?? 'Exam';
    final examName = nextExam['title']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NEXT EXAM',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.muted,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            courseTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeProvider.currentTheme.text,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (examName.isNotEmpty && examName != courseTitle) ...[
            const SizedBox(height: 3),
            Text(
              examName,
              style: TextStyle(
                fontSize: 9,
                color: themeProvider.currentTheme.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 4),
          Text(
            courseCode,
            style: TextStyle(
              fontSize: 10,
              color: themeProvider.currentTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          if (nextExam['start_time'] != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.currentTheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatExamCountdown(nextExam['start_time'] as int),
                  style: TextStyle(
                    fontSize: 10,
                    color: themeProvider.currentTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildTotalODsWidget(
    HomeLogic homeLogic,
    ThemeProvider themeProvider,
  ) {
    final onDutyCount = homeLogic.getOnDutyCount();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ON DUTY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.muted,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$onDutyCount',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTheme.text,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';

    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;

      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }

      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  static String _formatExamCountdown(int timestamp) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inDays > 0) {
        return 'in ${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} hours';
      } else if (difference.inMinutes > 0) {
        return 'in ${difference.inMinutes} minutes';
      } else {
        return 'Soon';
      }
    } catch (e) {
      return 'Date unknown';
    }
  }
}
