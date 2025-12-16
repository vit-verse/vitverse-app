import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/database/entities/all_semester_mark.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../presentation/semester_detail_page.dart';

/// Semester card that navigates to detail page
class SemesterMarksCard extends StatelessWidget {
  final String semesterName;
  final List<AllSemesterMark> marks;
  final int semesterIndex;

  const SemesterMarksCard({
    super.key,
    required this.semesterName,
    required this.marks,
    required this.semesterIndex,
  });

  Map<String, List<AllSemesterMark>> _groupByCourse() {
    final grouped = <String, List<AllSemesterMark>>{};
    for (final mark in marks) {
      final key = '${mark.courseCode}_${mark.courseTitle}';
      grouped.putIfAbsent(key, () => []).add(mark);
    }
    return grouped;
  }

  double _calculateSemesterPercentage() {
    if (marks.isEmpty) return 0.0;

    double totalScore = 0;
    double totalMax = 0;

    for (final mark in marks) {
      totalScore += mark.score ?? 0;
      totalMax += mark.maxScore ?? 0;
    }

    return totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final groupedByCourse = _groupByCourse();
    final courseCount = groupedByCourse.length;
    final assessmentCount = marks.length;
    final percentage = _calculateSemesterPercentage();
    final percentageColor = themeProvider.marksColorScheme.getColor(percentage);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border, width: 1),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SemesterDetailPage(
                      semesterName: semesterName,
                      marks: marks,
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // S1, S2 badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: percentageColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'S${semesterIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: percentageColor,
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
                        semesterName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 12,
                            color: theme.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$courseCount courses',
                            style: TextStyle(fontSize: 9, color: theme.muted),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.assignment_outlined,
                            size: 12,
                            color: theme.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$assessmentCount assessments',
                            style: TextStyle(fontSize: 9, color: theme.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Percentage Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          percentage.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: percentageColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1, left: 1),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AVG',
                      style: TextStyle(
                        fontSize: 8,
                        color: theme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: theme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
