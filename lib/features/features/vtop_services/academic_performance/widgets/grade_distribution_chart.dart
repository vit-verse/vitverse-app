import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/database/entities/cgpa_summary.dart';
import '../logic/academic_performance_logic.dart';

/// Grade Distribution Chart
/// Simple bar chart showing S/A/B/C/D/E/F counts
/// Uses minimal theme colors - no bright/neon colors
class GradeDistributionChart extends StatelessWidget {
  final CGPASummary cgpaSummary;

  const GradeDistributionChart({super.key, required this.cgpaSummary});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final gradeList = AcademicPerformanceLogic.getGradeDistributionList(
      cgpaSummary,
    );

    if (gradeList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border, width: 1),
        ),
        child: Center(
          child: Text(
            'No grade data available',
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
        ),
      );
    }

    final maxCount = gradeList
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grade Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                gradeList.map((entry) {
                  return _buildGradeBar(
                    theme,
                    entry.key,
                    entry.value,
                    maxCount,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBar(dynamic theme, String grade, int count, int maxCount) {
    final double heightPercentage = maxCount > 0 ? count / maxCount : 0.0;
    final double barHeight = 120 * heightPercentage;
    final double opacity = AcademicPerformanceLogic.getGradeOpacity(grade);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Count label
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 4),

        // Bar
        Container(
          width: 32,
          height: barHeight < 20 ? 20 : barHeight,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(opacity),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),

        // Grade label
        Text(
          grade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
      ],
    );
  }
}
