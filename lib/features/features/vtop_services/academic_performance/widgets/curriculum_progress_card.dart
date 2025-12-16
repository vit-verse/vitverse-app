import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../models/curriculum_with_progress.dart';

/// Curriculum Progress Card
/// Shows earned/in-progress/required credits breakdown with progress bar
/// Uses theme colors only
class CurriculumProgressCard extends StatelessWidget {
  final CurriculumWithProgress curriculum;

  const CurriculumProgressCard({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    // Check if this is a non-CGPA category (Bridge Course or Non-graded Core Requirement)
    final isNonCGPA =
        curriculum.distributionType.contains('Bridge') ||
        curriculum.distributionType.contains('Non-graded');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with asterisk for non-CGPA courses and warning for exceeding
          Row(
            children: [
              Expanded(
                child: Text(
                  curriculum.distributionType,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isNonCGPA)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.muted,
                    ),
                  ),
                ),
              if (curriculum.isExceeding)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message:
                        'Course credits exceed required amount. Please verify.',
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                )
              else if (curriculum.isComplete)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: theme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Credits Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCreditInfo(theme, 'Earned', curriculum.earnedCredits),
              _buildCreditInfo(
                theme,
                'In Progress',
                curriculum.inProgressCredits,
              ),
              _buildCreditInfo(theme, 'Required', curriculum.requiredCredits),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar (clamped to 100%)
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Earned Progress (clamped)
              FractionallySizedBox(
                widthFactor: curriculum.earnedPercentageClamped / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        curriculum.isExceeding
                            ? Colors.red.shade400
                            : theme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // In-Progress overlay (clamped)
              FractionallySizedBox(
                widthFactor: curriculum.totalProgressPercentageClamped / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        curriculum.isExceeding
                            ? Colors.red.shade400.withOpacity(0.4)
                            : theme.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  curriculum.status,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        curriculum.isExceeding
                            ? Colors.red.shade400
                            : theme.muted,
                    fontWeight:
                        curriculum.isExceeding
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ),
              // Progress percentage (earned% + added%) - clamped display
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${curriculum.earnedPercentageClamped.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            curriculum.isExceeding
                                ? Colors.red.shade400
                                : theme.text,
                      ),
                    ),
                    if (curriculum.inProgressCredits > 0)
                      TextSpan(
                        text:
                            ' +${(curriculum.totalProgressPercentageClamped - curriculum.earnedPercentageClamped).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              curriculum.isExceeding
                                  ? Colors.red.shade300
                                  : theme.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo(dynamic theme, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.muted)),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
      ],
    );
  }
}
