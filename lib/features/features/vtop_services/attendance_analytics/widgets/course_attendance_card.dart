import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/color_utils.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/widgets/capsule_progress.dart';
import '../logic/attendance_analytics_logic.dart';
import '../presentation/detailed_attendance_page.dart';

/// Individual course attendance card with progress and calculator
class CourseAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> courseData;
  final double targetPercentage;

  const CourseAttendanceCard({
    super.key,
    required this.courseData,
    this.targetPercentage = 75.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logic = AttendanceAnalyticsLogic();

    final baseCourseCode =
        (courseData['course_code'] ?? courseData['code'] ?? 'N/A').toString();
    final courseName =
        (courseData['course_name'] ??
                courseData['course_title'] ??
                courseData['title'] ??
                'Unknown')
            .toString();
    final courseType = courseData['course_type']?.toString();
    final attended = courseData['attended'] as int? ?? 0;
    final total = courseData['total'] as int? ?? 0;
    final percentage = total > 0 ? (attended / total) * 100 : 0.0;

    // Check if this is an embedded course component
    final isEmbeddedTheory =
        courseType?.toLowerCase().contains('embedded theory') ?? false;
    final isEmbeddedLab =
        courseType?.toLowerCase().contains('embedded lab') ?? false;
    final isEmbedded = isEmbeddedTheory || isEmbeddedLab;

    // Add (T) or (L) suffix for embedded courses
    final courseCode =
        isEmbedded
            ? '$baseCourseCode (${isEmbeddedTheory ? 'T' : 'L'})'
            : baseCourseCode;

    final calculatedClasses = logic.calculateClassesToTarget(
      attended: attended,
      total: total,
      targetPercentage: targetPercentage,
    );

    Color getBadgeColor(BuildContext context) {
      return calculatedClasses >= 0
          ? ColorUtils.getAttendanceColor(context, 85)
          : ColorUtils.getAttendanceColor(context, 70);
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Course code (small) - now includes (T) or (L) for embedded courses
                Text(
                  courseCode,
                  style: TextStyle(
                    color: themeProvider.currentTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Course name (large, multiline) with flexible height
                SizedBox(
                  height: 32, // Fixed height for 2 lines
                  child: Text(
                    courseName,
                    style: TextStyle(
                      color: themeProvider.currentTheme.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Spacer to push capsule and button to bottom
                const Spacer(),

                // Centered capsule
                Center(
                  child: CapsuleProgress(
                    percentage: percentage,
                    color: ColorUtils.getAttendanceColor(context, percentage),
                    width: 85,
                    height: 34,
                    label: '$attended/$total',
                  ),
                ),
                const SizedBox(height: 10),

                // Details button
                Center(
                  child: InkWell(
                    onTap: () {
                      final attendanceId = courseData['id'] as int?;
                      if (attendanceId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DetailedAttendancePage(
                                  courseCode: courseCode,
                                  courseName: courseName,
                                  attendanceId: attendanceId,
                                  attended: attended,
                                  total: total,
                                  percentage: percentage,
                                ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeProvider.currentTheme.primary.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: themeProvider.currentTheme.primary.withOpacity(
                            0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: themeProvider.currentTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Details',
                            style: TextStyle(
                              color: themeProvider.currentTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // +/- Badge positioned at top right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getBadgeColor(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                calculatedClasses >= 0
                    ? '+$calculatedClasses'
                    : '$calculatedClasses',
                style: TextStyle(
                  color: getBadgeColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
