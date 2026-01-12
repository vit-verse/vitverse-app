import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/color_utils.dart';
import '../../../profile/widget_customization/provider/widget_customization_provider.dart';
import '../../../profile/widget_customization/data/widget_preferences_service.dart';
import '../../logic/home_logic.dart';
import 'class_details_dialog.dart';

/// Individual class card widget
class ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final int dayIndex;
  final HomeLogic homeLogic;

  const ClassCard({
    super.key,
    required this.classData,
    required this.dayIndex,
    required this.homeLogic,
  });

  @override
  Widget build(BuildContext context) {
    final isFriendClass = classData['isFriendClass'] == true;

    if (isFriendClass) {
      return _buildFriendClassCard(context);
    } else {
      return _buildUserClassCard(context);
    }
  }

  Widget _buildFriendClassCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final friendNickname =
            classData['friendNickname'] as String? ?? 'Friend';
        final friendColor =
            classData['friendColor'] as Color? ??
            themeProvider.currentTheme.primary;
        final course = classData['course'] as Map<String, dynamic>? ?? {};
        final courseTitle = course['title'] as String? ?? 'Unknown Course';
        final venue = course['venue'] as String? ?? '--';
        final startTime = classData['start_time'] as String? ?? '';
        final endTime = classData['end_time'] as String? ?? '';

        // Check if class has passed (for any day in the current week)
        final hasPassed = _hasClassPassedInWeek(dayIndex, endTime);

        // Format time display
        String displayTime = '--:-- to --:--';
        if (startTime.isNotEmpty && endTime.isNotEmpty) {
          displayTime =
              '${_convertTo12HourFormat(startTime)} - ${_convertTo12HourFormat(endTime)}';
        }

        return Opacity(
          opacity: hasPassed ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: friendColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: friendColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Friend nickname tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: friendColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    friendNickname,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Course details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: friendColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            displayTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: themeProvider.currentTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: friendColor,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              venue,
                              style: TextStyle(
                                fontSize: 10,
                                color: themeProvider.currentTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserClassCard(BuildContext context) {
    return Consumer2<ThemeProvider, WidgetCustomizationProvider>(
      builder: (context, themeProvider, widgetProvider, child) {
        final course = classData['course'] as Map<String, dynamic>?;
        final courseCode = course?['code']?.toString() ?? 'Unknown';
        final courseTitle = course?['title']?.toString() ?? 'Unknown Course';
        final courseType = course?['type']?.toString().toLowerCase() ?? '';
        final startTime = classData['start_time']?.toString() ?? '--:--';
        final endTime = classData['end_time']?.toString() ?? '--:--';

        // Determine if it's lab
        final isLab =
            courseType.contains('lab') || courseType.contains('embedded lab');

        // Check if class is currently ongoing or has passed
        final now = DateTime.now();
        final isToday = dayIndex == (now.weekday - 1);
        final currentTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final isOngoing =
            isToday && _isClassOngoing(startTime, endTime, currentTime);
        final hasPassed = _hasClassPassedInWeek(dayIndex, endTime);
        final classProgress =
            isToday ? _getClassProgress(startTime, endTime, currentTime) : 0.0;

        // Get attendance data for this course
        // For embedded courses, pass the course type to get the correct attendance (theory vs lab)
        final courseAttendance = homeLogic.getCourseAttendance(
          courseCode,
          courseType: courseType,
        );

        // Get slot name(s) for the dialog - handle merged slots
        String slotName = 'Unknown';
        final slotNames = classData['slotNames'] as List?;
        if (slotNames != null && slotNames.isNotEmpty) {
          // Multiple slots merged - join with " + "
          slotName = slotNames.join(' + ');
        } else {
          // Single slot - backward compatibility
          final slotId = classData['slotId'] as int?;
          if (slotId != null) {
            final slot = homeLogic.slotsData.firstWhere(
              (slot) => slot['id'] == slotId,
              orElse: () => {'slot': 'Unknown'},
            );
            slotName = slot['slot']?.toString() ?? 'Slot $slotId';
          }
        }

        return Opacity(
          opacity: hasPassed ? 0.4 : 1.0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => ClassDetailsDialog(
                      classData: classData,
                      courseAttendance: courseAttendance,
                      slotName: slotName,
                    ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeProvider.currentTheme.muted.withValues(
                    alpha: 0.2,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.currentTheme.text.withValues(
                      alpha: 0.02,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Progress indicator for ongoing class
                  if (isOngoing && classProgress > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width * classProgress,
                          decoration: BoxDecoration(
                            color: themeProvider.currentTheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Image.asset(
                              isLab
                                  ? 'assets/icons/lab.png'
                                  : 'assets/icons/theory.png',
                              width: 40,
                              height: 40,
                              color: themeProvider.currentTheme.primary,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  isLab
                                      ? Icons.science_rounded
                                      : Icons.book_rounded,
                                  color: themeProvider.currentTheme.primary,
                                  size: 36,
                                );
                              },
                            ),
                          ),

                          if (isOngoing)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: themeProvider.currentTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeProvider.currentTheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: themeProvider.currentTheme.background,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Class details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.currentTheme.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color:
                                      isOngoing
                                          ? themeProvider.currentTheme.primary
                                          : themeProvider.currentTheme.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_convertTo12HourFormat(startTime)} - ${_convertTo12HourFormat(endTime)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        isOngoing
                                            ? themeProvider.currentTheme.primary
                                            : themeProvider.currentTheme.text,
                                    fontWeight:
                                        isOngoing
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Dynamic widget based on user preference
                      _buildClassCardWidget(
                        context,
                        themeProvider,
                        widgetProvider,
                        classData,
                        courseCode,
                        slotName,
                        courseAttendance,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build dynamic widget for class card based on user preference
  Widget _buildClassCardWidget(
    BuildContext context,
    ThemeProvider themeProvider,
    WidgetCustomizationProvider widgetProvider,
    Map<String, dynamic> classData,
    String courseCode,
    String slotName,
    Map<String, dynamic> courseAttendance,
  ) {
    final displayType = widgetProvider.classCardDisplayType;
    final course = classData['course'] as Map<String, dynamic>?;

    switch (displayType) {
      case ClassCardDisplayType.none:
        return const SizedBox.shrink();

      case ClassCardDisplayType.attendance:
        // Show attendance percentage with proper calculation
        final attendancePercentage =
            courseAttendance['percentage'] as double? ?? 0.0;
        final attendanceColor = ColorUtils.getAttendanceColorFromProvider(
          themeProvider,
          attendancePercentage,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: attendanceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: attendanceColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${attendancePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: attendanceColor,
              ),
            ),
          ),
        );

      case ClassCardDisplayType.venue:
        final venue = course?['venue']?.toString() ?? 'N/A';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.currentTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.currentTheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: themeProvider.currentTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                venue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.currentTheme.primary,
                ),
              ),
            ],
          ),
        );

      case ClassCardDisplayType.slot:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.currentTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.currentTheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: themeProvider.currentTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                slotName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.currentTheme.primary,
                ),
              ),
            ],
          ),
        );

      case ClassCardDisplayType.buffer:
        // Show buffer classes for 75% attendance
        final attended = courseAttendance['attended'] as int? ?? 0;
        final total = courseAttendance['total'] as int? ?? 0;
        final bufferClasses = _calculateBufferClasses(attended, total);
        final canSkip = bufferClasses['can_skip'] ?? 0;
        final mustAttend = bufferClasses['must_attend'] ?? 0;

        if (canSkip > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  '+$canSkip',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        } else if (mustAttend > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.currentTheme.error.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 14,
                  color: themeProvider.currentTheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '$mustAttend',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.currentTheme.error,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.3,
                ),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_rounded,
                  size: 14,
                  color: themeProvider.currentTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '75%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.currentTheme.primary,
                  ),
                ),
              ],
            ),
          );
        }
    }
  }

  // Helper methods
  Map<String, int> _calculateBufferClasses(int attended, int total) {
    if (total == 0) {
      return {'can_skip': 0, 'must_attend': 0};
    }

    final currentPercentage = (attended / total) * 100;

    if (currentPercentage >= 75) {
      // Calculate how many classes can be skipped while staying above 75%
      int canSkip = 0;
      int tempAttended = attended;
      int tempTotal = total;

      while (true) {
        tempTotal += 1;
        final newPercentage = (tempAttended / tempTotal) * 100;
        if (newPercentage >= 75) {
          canSkip++;
        } else {
          break;
        }
      }

      return {'can_skip': canSkip, 'must_attend': 0};
    } else {
      // Calculate how many classes must be attended to reach 75%
      int mustAttend = 0;
      int tempAttended = attended;
      int tempTotal = total;

      while (true) {
        tempTotal += 1;
        tempAttended += 1;
        mustAttend++;
        final newPercentage = (tempAttended / tempTotal) * 100;
        if (newPercentage >= 75) {
          break;
        }
      }

      return {'can_skip': 0, 'must_attend': mustAttend};
    }
  }

  bool _isClassOngoing(String startTime, String endTime, String currentTime) {
    try {
      return currentTime.compareTo(startTime) >= 0 &&
          currentTime.compareTo(endTime) < 0;
    } catch (e) {
      return false;
    }
  }

  bool _hasClassPassedInWeek(int classDayIndex, String endTime) {
    try {
      final now = DateTime.now();
      final currentDayIndex = now.weekday - 1; // 0 = Monday, 6 = Sunday
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // If the class day is before current day in the week, it has passed
      if (classDayIndex < currentDayIndex) {
        return true;
      }

      // If it's the same day, check the time
      if (classDayIndex == currentDayIndex) {
        return currentTime.compareTo(endTime) >= 0;
      }

      // If the class day is after current day, it hasn't passed yet
      return false;
    } catch (e) {
      return false;
    }
  }

  double _getClassProgress(
    String startTime,
    String endTime,
    String currentTime,
  ) {
    try {
      if (!_isClassOngoing(startTime, endTime, currentTime)) {
        return 0.0;
      }

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final currentParts = currentTime.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMinutes =
          int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]);

      final totalDuration = endMinutes - startMinutes;
      final elapsed = currentMinutes - startMinutes;

      return (elapsed / totalDuration).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  String _convertTo12HourFormat(String time24) {
    try {
      if (time24 == '--:--' || time24.isEmpty) return time24;

      final parts = time24.split(':');
      if (parts.length != 2) return time24;

      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24;
    }
  }
}
