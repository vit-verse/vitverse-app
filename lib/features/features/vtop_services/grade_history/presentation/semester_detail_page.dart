import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/database/entities/cumulative_mark.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../logic/grade_history_logic.dart';
import '../widgets/grade_radar_chart.dart';

/// Semester detail page showing radar chart and course list
class SemesterDetailPage extends StatefulWidget {
  final String semesterName;
  final List<CumulativeMark> grades;

  const SemesterDetailPage({
    super.key,
    required this.semesterName,
    required this.grades,
  });

  @override
  State<SemesterDetailPage> createState() => _SemesterDetailPageState();
}

class _SemesterDetailPageState extends State<SemesterDetailPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'GradesSemesterDetail',
      screenClass: 'SemesterDetailPage',
    );
  }

  Map<String, double> _calculateCoursePerformance() {
    final performance = <String, double>{};

    for (final grade in widget.grades) {
      final percentage = (grade.gradePoints / 10.0) * 100.0;
      performance[grade.courseCode] = percentage;
    }

    return performance;
  }

  Map<String, String> _getCourseTitles() {
    final titles = <String, String>{};
    for (final grade in widget.grades) {
      titles[grade.courseCode] = grade.courseTitle;
    }
    return titles;
  }

  Map<String, String> _getCourseGrades() {
    final gradeMap = <String, String>{};
    for (final grade in widget.grades) {
      gradeMap[grade.courseCode] = grade.grade;
    }
    return gradeMap;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final logic = GradeHistoryLogic();
    final coursePerformance = _calculateCoursePerformance();
    final courseTitles = _getCourseTitles();
    final courseGrades = _getCourseGrades();

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
                      'Course Performance',
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
                    child: GradeRadarChart(
                      coursePerformance: coursePerformance,
                      courseTitles: courseTitles,
                      courseGrades: courseGrades,
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

          // Courses Section Header
          Text(
            'Courses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),

          // Course Cards
          ...widget.grades.map((grade) {
            final gradeColor = logic.getGradeColorFromProvider(
              themeProvider,
              grade.grade,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Grade Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            grade.grade,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grade.courseCode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              grade.courseTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.text,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          Icons.credit_card_outlined,
                          'Credits',
                          logic.formatCredits(grade.credits),
                          theme,
                        ),
                        _buildDivider(theme),
                        _buildDetailItem(
                          Icons.assessment_outlined,
                          'Type',
                          grade.gradingType,
                          theme,
                        ),
                        _buildDivider(theme),
                        _buildDetailItem(
                          Icons.grade_outlined,
                          'Total',
                          grade.grandTotal.toStringAsFixed(1),
                          theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, theme) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: theme.muted),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 8, color: theme.muted)),
        ],
      ),
    );
  }

  Widget _buildDivider(theme) {
    return Container(
      width: 1,
      height: 30,
      color: theme.border.withValues(alpha: 0.3),
    );
  }
}
