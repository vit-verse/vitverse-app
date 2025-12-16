import 'package:flutter/material.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../models/models.dart';
import '../logic/attendance_logic.dart';
import 'attendance_widgets.dart';

class OverallAttendanceSection extends StatelessWidget {
  final double percentage;
  final int attended;
  final int total;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const OverallAttendanceSection({
    super.key,
    required this.percentage,
    required this.attended,
    required this.total,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = AttendanceMatrixLogic.getStatus(percentage);
    final bufferIndicator = AttendanceMatrixLogic.getBufferIndicator(
      attended: attended,
      total: total,
    );
    final formattedPercentage = AttendanceMatrixLogic.formatPercentage(
      percentage,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: isDark,
        customBackgroundColor: surfaceColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment_outlined, size: 20, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plan your classes smartly',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT OVERALL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$formattedPercentage%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: status.color,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              bufferIndicator,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: status.color.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$attended / $total classes',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: status.color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OverallMatrixCard extends StatelessWidget {
  final List<List<AttendanceMatrixCell>> matrix;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const OverallMatrixCard({
    super.key,
    required this.matrix,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.compactCardDecoration(
        isDark: isDark,
        customBackgroundColor: surfaceColor,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Absent ↓ / Attend →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Now',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '= Current',
                    style: TextStyle(
                      fontSize: 10,
                      color: mutedColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AttendanceMatrixGrid(
            matrix: matrix,
            isDark: isDark,
            onCellTap: (cell) {
              AttendanceCellDetailModal.show(
                context,
                cell: cell,
                primaryColor: primaryColor,
                backgroundColor: backgroundColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Tap any cell for detailed projection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseSelectionCard extends StatelessWidget {
  final List<CourseAttendance> courses;
  final CourseAttendance? selectedCourse;
  final Function(CourseAttendance) onCourseSelected;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const CourseSelectionCard({
    super.key,
    required this.courses,
    required this.selectedCourse,
    required this.onCourseSelected,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: isDark,
          customBackgroundColor: surfaceColor,
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: mutedColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Courses Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Course data will appear here once synced',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: mutedColor),
            ),
          ],
        ),
      );
    }

    final status =
        selectedCourse != null
            ? AttendanceMatrixLogic.getStatus(selectedCourse!.percentage)
            : AttendanceStatus.atRisk;
    final bufferIndicator =
        selectedCourse != null
            ? AttendanceMatrixLogic.getBufferIndicator(
              attended: selectedCourse!.attended,
              total: selectedCourse!.total,
            )
            : '(±0)';
    final formattedPercentage =
        selectedCourse != null
            ? AttendanceMatrixLogic.formatPercentage(selectedCourse!.percentage)
            : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: isDark,
        customBackgroundColor: surfaceColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book_outlined, size: 24, color: primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Selection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track individual course attendance',
                      style: TextStyle(fontSize: 13, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CourseAttendance>(
                value: selectedCourse,
                isExpanded: true,
                hint: Text('Select a course'),
                icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                dropdownColor: surfaceColor,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                items:
                    courses.map((course) {
                      return DropdownMenuItem<CourseAttendance>(
                        value: course,
                        child: Text(
                          course.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (course) {
                  if (course != null) {
                    onCourseSelected(course);
                  }
                },
              ),
            ),
          ),
          if (selectedCourse != null) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COURSE STATISTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$formattedPercentage%',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: status.color,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  bufferIndicator,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: status.color.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedCourse!.attended} / ${selectedCourse!.total} classes',
                            style: TextStyle(fontSize: 14, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: status.color.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CourseMatrixCard extends StatelessWidget {
  final List<List<AttendanceMatrixCell>> matrix;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const CourseMatrixCard({
    super.key,
    required this.matrix,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.compactCardDecoration(
        isDark: isDark,
        customBackgroundColor: surfaceColor,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Absent ↓ / Attend →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Now',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '= Current',
                    style: TextStyle(
                      fontSize: 10,
                      color: mutedColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AttendanceMatrixGrid(
            matrix: matrix,
            isDark: isDark,
            onCellTap: (cell) {
              AttendanceCellDetailModal.show(
                context,
                cell: cell,
                primaryColor: primaryColor,
                backgroundColor: backgroundColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Tap any cell for detailed projection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
