import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/database/entities/all_semester_mark.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../models/course_type.dart';
import '../widgets/course_radar_chart.dart';

/// Semester detail page showing radar chart and course list
class SemesterDetailPage extends StatefulWidget {
  final String semesterName;
  final List<AllSemesterMark> marks;

  const SemesterDetailPage({
    super.key,
    required this.semesterName,
    required this.marks,
  });

  @override
  State<SemesterDetailPage> createState() => _SemesterDetailPageState();
}

class _SemesterDetailPageState extends State<SemesterDetailPage> {
  final Map<String, bool> _expandedCourses = {};

  Map<String, List<AllSemesterMark>> _groupByCourse() {
    final grouped = <String, List<AllSemesterMark>>{};
    for (final mark in widget.marks) {
      final key = mark.courseCode ?? 'Unknown';
      grouped.putIfAbsent(key, () => []).add(mark);
    }
    return grouped;
  }

  Map<String, double> _calculateCoursePerformance() {
    final grouped = _groupByCourse();
    final performance = <String, double>{};

    for (final entry in grouped.entries) {
      final courseMarks = entry.value;
      double totalScore = 0;
      double totalMax = 0;

      for (final mark in courseMarks) {
        totalScore += mark.score ?? 0;
        totalMax += mark.maxScore ?? 0;
      }

      final percentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
      performance[entry.key] = percentage.toDouble();
    }

    return performance;
  }

  Map<String, String> _getCourseTitles() {
    final grouped = _groupByCourse();
    final titles = <String, String>{};

    for (final entry in grouped.entries) {
      if (entry.value.isNotEmpty) {
        titles[entry.key] = entry.value.first.courseTitle ?? '';
      }
    }

    return titles;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final groupedByCourse = _groupByCourse();
    final coursePerformance = _calculateCoursePerformance();
    final courseTitles = _getCourseTitles();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          widget.semesterName,
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Radar Chart Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.radar, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Performance Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (coursePerformance.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: CourseRadarChart(
                      coursePerformance: coursePerformance,
                      courseTitles: courseTitles,
                      primaryColor: theme.primary,
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No performance data',
                        style: TextStyle(color: theme.muted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Course List Section
          Text(
            'Courses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),

          ...groupedByCourse.entries.map((entry) {
            final courseCode = entry.key;
            final courseMarks = entry.value;
            final firstMark = courseMarks.first;
            final courseType = CourseType.fromCourseCode(courseCode);
            final isExpanded = _expandedCourses[courseCode] ?? false;

            return _buildCourseCard(
              theme,
              themeProvider,
              courseCode,
              firstMark.courseTitle ?? '',
              courseType,
              courseMarks,
              isExpanded,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    theme,
    ThemeProvider themeProvider,
    String courseCode,
    String courseTitle,
    CourseType courseType,
    List<AllSemesterMark> marks,
    bool isExpanded,
  ) {
    final marksColorScheme = themeProvider.marksColorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedCourses[courseCode] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCourseTypeColor(
                                  courseType,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                courseType.displayName,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _getCourseTypeColor(courseType),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                courseCode,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          courseTitle,
                          style: TextStyle(fontSize: 12, color: theme.text),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: theme.border.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children:
                    marks.map((mark) {
                      final percentage =
                          mark.maxScore != null &&
                                  mark.maxScore! > 0 &&
                                  mark.score != null
                              ? (mark.score! / mark.maxScore!) * 100
                              : 0.0;
                      final color = marksColorScheme.getColor(
                        percentage,
                        theme.primary,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mark.title ?? 'Assessment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.text.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            if (mark.score != null &&
                                mark.maxScore != null) ...[
                              Text(
                                '${mark.score!.toStringAsFixed(0)}/${mark.maxScore!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ] else
                              Text(
                                'N/A',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.muted,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCourseTypeColor(CourseType type) {
    switch (type) {
      case CourseType.theory:
        return Colors.blue;
      case CourseType.lab:
        return Colors.purple;
      case CourseType.online:
        return Colors.green;
      case CourseType.embedded:
        return Colors.orange;
    }
  }
}
