import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/color_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../features/vtop_services/attendance_analytics/presentation/detailed_attendance_page.dart';
import '../../../features/vitconnect_services/faculty_rating/services/faculty_rating_api_service.dart';
import '../../../features/vitconnect_services/faculty_rating/models/rating_model.dart';

/// Modern bottom sheet dialog showing detailed class information
class ClassDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Map<String, dynamic>? courseAttendance;
  final String slotName;

  const ClassDetailsDialog({
    super.key,
    required this.classData,
    this.courseAttendance,
    required this.slotName,
  });

  @override
  State<ClassDetailsDialog> createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<ClassDetailsDialog> {
  bool showRatingSection = false;
  final Map<String, double> ratings = {
    'teaching': 5.0,
    'attendance_flex': 5.0,
    'supportiveness': 5.0,
    'marks': 5.0,
  };
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final course = widget.classData['course'] as Map<String, dynamic>?;
    final courseCode = course?['code']?.toString() ?? 'Unknown';
    final courseTitle = course?['title']?.toString() ?? 'Unknown Course';
    final venue = course?['venue']?.toString() ?? 'Unknown';
    final faculty = course?['faculty']?.toString() ?? 'Unknown Faculty';
    final facultyErpId = course?['faculty_erp_id']?.toString() ?? '';
    final startTime = widget.classData['start_time']?.toString() ?? '--:--';
    final endTime = widget.classData['end_time']?.toString() ?? '--:--';

    final attended = widget.courseAttendance?['attended'] as int? ?? 0;
    final total = widget.courseAttendance?['total'] as int? ?? 0;
    final attendancePercentage = total > 0 ? (attended / total) * 100.0 : 0.0;
    final attendanceId = widget.courseAttendance?['id'] as int?;
    final bufferClasses = _calculateBufferClasses(attended, total);
    final attendanceColor = ColorUtils.getAttendanceColorFromProvider(
      themeProvider,
      attendancePercentage,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.muted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Course Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          courseCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.muted.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.slotName,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Content Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Class Info
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.muted.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Time
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        size: 18,
                                        color: theme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${_formatTo12Hour(startTime)} - ${_formatTo12Hour(endTime)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Venue
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 18,
                                        color: theme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        venue,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.text,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Faculty
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: theme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            faculty,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.text,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (facultyErpId.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              facultyErpId,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.muted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: Attendance Card
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: attendanceColor,
                                width: 2.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    // Percentage
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${attendancePercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: attendanceColor,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Count Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: attendanceColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$attended/$total',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Buffer Info
                                    _buildBufferInfo(
                                      bufferClasses,
                                      theme,
                                      attendanceColor,
                                    ),
                                  ],
                                ),

                                // View Details Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  DetailedAttendancePage(
                                                    courseCode: courseCode,
                                                    courseName: courseTitle,
                                                    attendanceId:
                                                        attendanceId ?? 0,
                                                    attended: attended,
                                                    total: total,
                                                    percentage:
                                                        attendancePercentage,
                                                  ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: attendanceColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rate Faculty Button - Full Width
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          showRatingSection = !showRatingSection;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: theme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        showRatingSection
                            ? 'Close Faculty Rating'
                            : 'Submit Rating for this Faculty',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rating Section (Expandable)
            if (showRatingSection) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRatingSection(
                  context,
                  theme,
                  faculty,
                  facultyErpId,
                  courseCode,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    BuildContext context,
    theme,
    String facultyName,
    String facultyErpId,
    String courseCode,
  ) {
    final overallRating =
        ratings.values.reduce((a, b) => a + b) / ratings.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.star_rounded, size: 20, color: theme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate this Faculty',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      'Help others make informed decisions',
                      style: TextStyle(fontSize: 11, color: theme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Sliders
          _buildCompactRatingSlider(
            context,
            theme,
            Icons.school_rounded,
            'Teaching',
            ratings['teaching']!,
            (value) => setState(() => ratings['teaching'] = value),
          ),
          const SizedBox(height: 10),
          _buildCompactRatingSlider(
            context,
            theme,
            Icons.event_available_rounded,
            'Attendance',
            ratings['attendance_flex']!,
            (value) => setState(() => ratings['attendance_flex'] = value),
          ),
          const SizedBox(height: 10),
          _buildCompactRatingSlider(
            context,
            theme,
            Icons.support_agent_rounded,
            'Support',
            ratings['supportiveness']!,
            (value) => setState(() => ratings['supportiveness'] = value),
          ),
          const SizedBox(height: 10),
          _buildCompactRatingSlider(
            context,
            theme,
            Icons.grade_rounded,
            'Grading',
            ratings['marks']!,
            (value) => setState(() => ratings['marks'] = value),
          ),
          const SizedBox(height: 16),

          // Overall Rating
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.1),
                  theme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Rating',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                Text(
                  '${overallRating.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  isSubmitting
                      ? null
                      : () => _submitRating(
                        context,
                        facultyName,
                        facultyErpId,
                        courseCode,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: theme.muted.withOpacity(0.3),
              ),
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRatingSlider(
    BuildContext context,
    theme,
    IconData icon,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toInt()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.muted.withOpacity(0.2),
            thumbColor: theme.primary,
            overlayColor: theme.primary.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBufferInfo(Map<String, int> bufferClasses, theme, Color color) {
    final canSkip = bufferClasses['can_skip'] ?? 0;
    final mustAttend = bufferClasses['must_attend'] ?? 0;

    IconData icon;
    String text;
    Color bgColor;

    if (canSkip > 0) {
      icon = Icons.check_circle_rounded;
      text = 'Skip $canSkip';
      bgColor = color;
    } else if (mustAttend > 0) {
      icon = Icons.warning_rounded;
      text = 'Need $mustAttend';
      bgColor = theme.error;
    } else {
      icon = Icons.info_rounded;
      text = 'At 75%';
      bgColor = color;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: bgColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(
    BuildContext context,
    String facultyName,
    String facultyErpId,
    String courseCode,
  ) async {
    try {
      setState(() {
        isSubmitting = true;
      });

      Logger.i('ClassDetailsDialog', 'Submitting rating for: $facultyName');

      final ratingSubmission = RatingSubmission(
        facultyId: facultyErpId,
        facultyName: facultyName,
        teaching: ratings['teaching']!,
        attendanceFlex: ratings['attendance_flex']!,
        supportiveness: ratings['supportiveness']!,
        marks: ratings['marks']!,
      );

      if (!ratingSubmission.isValid()) {
        throw Exception('Invalid ratings: All must be between 0 and 10');
      }

      final response = await FacultyRatingApiService.submitRating(
        ratingSubmission,
      );

      if (response.success) {
        Logger.i('ClassDetailsDialog', 'Rating submitted successfully');

        if (mounted) {
          Navigator.pop(context);
          SnackbarUtils.success(
            context,
            'Rating submitted! Thank you for your feedback.',
          );
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.e('ClassDetailsDialog', 'Failed to submit rating', e);

      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        String errorMessage = 'Failed to submit rating. Please try again.';

        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'Network error. Check your connection.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Try again.';
        } else if (e.toString().contains('Invalid ratings')) {
          errorMessage = 'Invalid ratings. Check and try again.';
        }

        SnackbarUtils.error(context, errorMessage);
      }
    }
  }

  Map<String, int> _calculateBufferClasses(int attended, int total) {
    if (total == 0) {
      return {'can_skip': 0, 'must_attend': 0};
    }

    final currentPercentage = (attended / total) * 100;

    if (currentPercentage >= 75) {
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

  String _formatTo12Hour(String time24) {
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
