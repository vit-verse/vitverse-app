import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/database/entities/cumulative_mark.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../presentation/semester_detail_page.dart';
import '../logic/grade_history_logic.dart';

/// Semester card that navigates to detail page
class SemesterGradeCard extends StatelessWidget {
  final Map<String, dynamic> semesterData;
  final int semesterIndex;

  const SemesterGradeCard({
    super.key,
    required this.semesterData,
    required this.semesterIndex,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final logic = GradeHistoryLogic();

    final semesterName =
        semesterData['semester_name'] as String? ?? 'Unknown Semester';
    final semesterGPA = semesterData['semester_gpa'] as double? ?? 0.0;
    final totalCourses = semesterData['total_courses'] as int? ?? 0;
    final passedCourses = semesterData['passed_courses'] as int? ?? 0;
    final grades = semesterData['grades'] as List<CumulativeMark>? ?? [];

    final gpaColor = logic.getGPAColorFromProvider(themeProvider, semesterGPA);

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
                      grades: grades,
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
                    color: gpaColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'S${semesterIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gpaColor,
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
                            '$totalCourses courses',
                            style: TextStyle(fontSize: 9, color: theme.muted),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_outlined,
                            size: 12,
                            color: theme.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$passedCourses passed',
                            style: TextStyle(fontSize: 9, color: theme.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // GPA Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          logic.formatGPA(semesterGPA),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: gpaColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1, left: 1),
                          child: Text(
                            '/10',
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
                      'GPA',
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
