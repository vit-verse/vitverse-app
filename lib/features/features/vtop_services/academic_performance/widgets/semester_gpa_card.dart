import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../models/semester_performance.dart';

/// Semester GPA Card
/// Displays semester name, GPA, course count, and credits
/// Simple card - no expansion, tap to navigate to Grade History
class SemesterGpaCard extends StatelessWidget {
  final SemesterPerformance semester;
  final VoidCallback? onTap;

  const SemesterGpaCard({super.key, required this.semester, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border, width: 1),
        ),
        child: Row(
          children: [
            // Semester Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.semesterName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfo(theme, '${semester.courseCount} courses'),
                      const SizedBox(width: 12),
                      _buildInfo(theme, '${semester.creditsFormatted} credits'),
                    ],
                  ),
                ],
              ),
            ),

            // GPA Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    semester.gpaFormatted,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
                  ),
                  Text(
                    'GPA',
                    style: TextStyle(fontSize: 12, color: theme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(dynamic theme, String text) {
    return Text(text, style: TextStyle(fontSize: 13, color: theme.muted));
  }
}
