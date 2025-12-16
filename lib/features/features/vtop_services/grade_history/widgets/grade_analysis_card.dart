import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import 'grade_performance_chart.dart';

/// Grade analysis card showing GPA trends and statistics
class GradeAnalysisCard extends StatelessWidget {
  final List<MapEntry<String, double>> semesterData;
  final Map<String, Map<String, int>> semesterCourseCounts;

  const GradeAnalysisCard({
    super.key,
    required this.semesterData,
    required this.semesterCourseCounts,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final avgGPA =
        semesterData.isEmpty
            ? 0.0
            : semesterData.map((e) => e.value).reduce((a, b) => a + b) /
                semesterData.length;

    final totalSemesters = semesterData.length;

    int totalCourses = 0;
    for (final counts in semesterCourseCounts.values) {
      totalCourses += counts['total'] ?? 0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary.withValues(alpha: 0.1),
            theme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: theme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Academic Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsRow(theme, avgGPA, totalSemesters, totalCourses),
          const SizedBox(height: 20),
          if (semesterData.isNotEmpty) _buildGraph(theme, context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(theme, double avgGPA, int semesters, int courses) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Avg GPA',
            avgGPA.toStringAsFixed(2),
            Icons.trending_up,
            theme.primary,
            theme,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Semesters',
            '$semesters',
            Icons.calendar_today_outlined,
            theme.info,
            theme,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Courses',
            '$courses',
            Icons.book_outlined,
            theme.success,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 8, color: theme.muted)),
      ],
    );
  }

  Widget _buildGraph(theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPA Trend',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: GradePerformanceChart(
            semesterData: semesterData,
            courseCounts: semesterCourseCounts,
            primaryColor: theme.primary,
          ),
        ),
      ],
    );
  }
}
