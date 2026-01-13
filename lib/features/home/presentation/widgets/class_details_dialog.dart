import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/color_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../features/vtop_services/attendance_analytics/presentation/detailed_attendance_page.dart';
import '../../../features/vitconnect_services/faculty_rating/data/faculty_rating_repository.dart';
import '../../../features/vitconnect_services/faculty_rating/models/faculty_rating_aggregate.dart';

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
  final _ratingRepository = FacultyRatingRepository();
  FacultyRatingAggregate? _facultyRating;

  @override
  void initState() {
    super.initState();
    _fetchFacultyRating();
  }

  Future<void> _fetchFacultyRating() async {
    final facultyErpId =
        widget.classData['course']?['faculty_erp_id']?.toString() ?? '';
    final facultyName =
        widget.classData['course']?['faculty']?.toString() ?? '';

    if (facultyErpId.isEmpty && facultyName.isEmpty) return;

    // Generate ID (use ERP ID or hash of name)
    final facultyId =
        facultyErpId.isNotEmpty
            ? facultyErpId
            : facultyName.hashCode.abs().toString();

    try {
      await _ratingRepository.initialize();
      final ratings = await _ratingRepository.getRatings([facultyId]);
      if (ratings.isNotEmpty && mounted) {
        setState(() {
          _facultyRating = ratings.first;
        });
      }
    } catch (e) {
      Logger.e('ClassDetailsDialog', 'Error fetching rating', e);
    }
  }

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
                color: theme.muted.withValues(alpha: 0.3),
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
                          color: theme.primary.withValues(alpha: 0.15),
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
                          color: theme.muted.withValues(alpha: 0.15),
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
                                color: theme.muted.withValues(alpha: 0.2),
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
                                        color: theme.primary.withValues(
                                          alpha: 0.1,
                                        ),
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
                                        color: theme.primary.withValues(
                                          alpha: 0.1,
                                        ),
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
                                        color: theme.primary.withValues(
                                          alpha: 0.1,
                                        ),
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

                  // Submit Rating Button - Full Width
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _submitRating(
                            context,
                            faculty,
                            facultyErpId.isNotEmpty
                                ? facultyErpId
                                : faculty.hashCode.abs().toString(),
                            courseCode,
                          ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
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
        color: bgColor.withValues(alpha: 0.15),
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
      Logger.i(
        'ClassDetailsDialog',
        'Opening Faculty Rating page for $facultyName',
      );

      // Close dialog first
      if (mounted) {
        Navigator.pop(context);

        // Navigate to rating page with faculty ID
        Navigator.pushNamed(
          context,
          '/features/vitconnect/faculty_rating',
          arguments: facultyErpId,
        );
      }
    } catch (e) {
      Logger.e('ClassDetailsDialog', 'Failed to open rating page', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to open rating page');
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
