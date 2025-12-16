import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import 'semester_performance_chart.dart';

/// Marks analysis card showing overall statistics and semester graph
class MarksAnalysisCard extends StatelessWidget {
  final double overallAverage;
  final int totalCourses;
  final int totalAssessments;
  final double highestAverage;
  final double lowestAverage;
  final List<MapEntry<String, double>> semesterData;
  final Map<String, int> semesterCourseCounts;

  const MarksAnalysisCard({
    super.key,
    required this.overallAverage,
    required this.totalCourses,
    required this.totalAssessments,
    required this.highestAverage,
    required this.lowestAverage,
    required this.semesterData,
    required this.semesterCourseCounts,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

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
                'Performance Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsRow(theme),
          const SizedBox(height: 20),
          if (semesterData.isNotEmpty) _buildGraph(theme, context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Overall',
            '${overallAverage.toStringAsFixed(1)}%',
            Icons.trending_up,
            theme.primary,
            theme,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Courses',
            '$totalCourses',
            Icons.book_outlined,
            theme.info,
            theme,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Tests',
            '$totalAssessments',
            Icons.assignment_outlined,
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
          'Semester-wise Performance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: SemesterPerformanceChart(
            semesterData: semesterData,
            courseCounts: semesterCourseCounts,
            primaryColor: theme.primary,
          ),
        ),
      ],
    );
  }
}
