import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/color_utils.dart';
import '../../../core/widgets/capsule_progress.dart';
import '../models/performance_models.dart';

/// Individual assessment mark tile
class AssessmentMarkTile extends StatelessWidget {
  final AssessmentMark assessment;
  final VoidCallback? onAddAverage;

  const AssessmentMarkTile({
    super.key,
    required this.assessment,
    this.onAddAverage,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status badge
              Row(
                children: [
                  // Assessment title
                  Expanded(
                    child: Text(
                      assessment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.currentTheme.text,
                      ),
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(themeProvider),
                ],
              ),
              const SizedBox(height: 12),

              // Score and Weightage in capsule progress bars
              Row(
                children: [
                  // Score capsule
                  Expanded(
                    child: _buildCapsuleProgress(
                      label: 'Score',
                      obtained: assessment.score ?? 0,
                      total: assessment.maxScore ?? 1,
                      themeProvider: themeProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Weightage capsule
                  Expanded(
                    child: _buildCapsuleProgress(
                      label: 'Weightage',
                      obtained: assessment.weightage ?? 0,
                      total: assessment.maxWeightage ?? 1,
                      themeProvider: themeProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Average section
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      label: 'Average',
                      value:
                          assessment.average != null && assessment.average! > 0
                              ? assessment.average!.toStringAsFixed(1)
                              : 'Not set',
                      themeProvider: themeProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add/Edit Average button
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onAddAverage,
                      icon: Icon(
                        assessment.average != null && assessment.average! > 0
                            ? Icons.edit
                            : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        assessment.average != null && assessment.average! > 0
                            ? 'Edit'
                            : 'Add',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: themeProvider.currentTheme.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleProgress({
    required String label,
    required double obtained,
    required double total,
    required ThemeProvider themeProvider,
  }) {
    final percentage = total > 0 ? (obtained / total * 100) : 0.0;
    final progressColor = ColorUtils.getMarksColorFromProvider(
      themeProvider,
      percentage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: themeProvider.currentTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        CapsuleProgress(
          percentage: percentage,
          color: progressColor,
          width: double.infinity,
          height: 40,
          label: '${obtained.toStringAsFixed(1)}/${total.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeProvider themeProvider) {
    Color bgColor;
    Color textColor;
    String text;

    if (assessment.isPresent) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      text = 'Present';
    } else if (assessment.isAbsent) {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      text = 'Absent';
    } else {
      bgColor = themeProvider.currentTheme.muted.withValues(alpha: 0.1);
      textColor = themeProvider.currentTheme.muted;
      text = assessment.status ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
