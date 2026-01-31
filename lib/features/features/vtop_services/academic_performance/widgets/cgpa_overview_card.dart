import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/database/entities/cgpa_summary.dart';
import '../../../../../../core/theme/color_utils.dart';
import '../logic/academic_performance_logic.dart';

/// CGPA Overview Card with Integrated Degree Progress Circle
/// Displays CGPA and credits in format: earned + added / total
/// Example: 79 + 3 / 151 (79 earned in CGPA, 3 added manually, 151 total required)
/// Bridge Course and Non-graded courses marked with * (not counted in total)
class CGPAOverviewCard extends StatelessWidget {
  final CGPASummary cgpaSummary;
  final double
  totalCreditsRequired; // From "Total Credits" row in VTOP (e.g., 151)
  final double totalAddedCredits; // From manual courses (e.g., 3)

  const CGPAOverviewCard({
    super.key,
    required this.cgpaSummary,
    required this.totalCreditsRequired,
    this.totalAddedCredits = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final earnedPercent =
        totalCreditsRequired > 0
            ? (cgpaSummary.creditsEarned / totalCreditsRequired * 100).clamp(
              0.0,
              100.0,
            )
            : 0.0;
    final addedPercent =
        totalCreditsRequired > 0
            ? (totalAddedCredits / totalCreditsRequired * 100).clamp(0.0, 100.0)
            : 0.0;

    // Convert CGPA to percentage for color calculation (e.g., 8.48 -> 84.8%)
    final cgpaPercentage = cgpaSummary.cgpa * 10;
    final cgpaColor = ColorUtils.getMarksColor(context, cgpaPercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Degree Circle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (Left) with warning if exceeding
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVERALL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                          height: 1.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'PERFORMANCE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                          height: 1.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if ((cgpaSummary.creditsEarned + totalAddedCredits) >
                      totalCreditsRequired)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Tooltip(
                        message:
                            'Total credits exceed requirement. Please verify.',
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              // Degree Progress Circle (Top Right)
              _buildDegreeProgressCircle(
                theme,
                earnedPercent,
                addedPercent,
                cgpaSummary.creditsEarned,
                totalAddedCredits,
                totalCreditsRequired,
                cgpaColor, // Pass the color
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CGPA Display (Full Width)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large CGPA
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AcademicPerformanceLogic.formatCGPA(cgpaSummary.cgpa),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: cgpaColor, // Use marks color instead of primary
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ 10.00',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Cumulative GPA',
                style: TextStyle(fontSize: 11, color: theme.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Credits Progress - Format: earned + added / total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credits Earned',
                style: TextStyle(fontSize: 12, color: theme.muted),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    // Earned credits (bold)
                    TextSpan(
                      text: cgpaSummary.creditsEarned.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    // Added credits (smaller, muted) - only show if > 0
                    if (totalAddedCredits > 0)
                      TextSpan(
                        text: ' + ${totalAddedCredits.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.muted,
                        ),
                      ),
                    // Total required
                    TextSpan(
                      text: ' / ${totalCreditsRequired.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar with dual layers (earned + added)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  // Background
                  Container(color: theme.muted.withValues(alpha: 0.2)),
                  // Light gradient for total (earned + added)
                  if (totalAddedCredits > 0)
                    FractionallySizedBox(
                      widthFactor:
                          totalCreditsRequired > 0
                              ? ((cgpaSummary.creditsEarned +
                                          totalAddedCredits) /
                                      totalCreditsRequired)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              (cgpaSummary.creditsEarned + totalAddedCredits) >
                                      totalCreditsRequired
                                  ? Colors.red.shade400.withValues(alpha: 0.4)
                                  : cgpaColor.withOpacity(
                                    0.4,
                                  ), // Use marks color
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  // Solid for earned only
                  FractionallySizedBox(
                    widthFactor:
                        totalCreditsRequired > 0
                            ? (cgpaSummary.creditsEarned / totalCreditsRequired)
                                .clamp(0.0, 1.0)
                            : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            (cgpaSummary.creditsEarned + totalAddedCredits) >
                                    totalCreditsRequired
                                ? Colors.red.shade400
                                : cgpaColor, // Use marks color
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Total Courses',
                  cgpaSummary.totalCourses.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Pass Rate',
                  '${cgpaSummary.passPercentage.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build circular degree progress indicator (top-right)
  Widget _buildDegreeProgressCircle(
    dynamic theme,
    double earnedPercent,
    double addedPercent,
    double earned,
    double added,
    double total,
    Color cgpaColor, // Add color parameter
  ) {
    final totalPercent = (earnedPercent + addedPercent).clamp(0.0, 100.0);
    final isExceeding = (earned + added) > total;

    return SizedBox(
      width: 110, // Increased from 90
      height: 110, // Increased from 90
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            painter: _CircleProgressPainter(
              percentage: 0,
              primaryColor:
                  isExceeding
                      ? Colors.red.shade400
                      : cgpaColor, // Use marks color
              backgroundColor: theme.muted.withValues(alpha: 0.2),
            ),
            child: const SizedBox(width: 110, height: 110),
          ),
          // Light gradient for added courses (if any)
          if (added > 0)
            CustomPaint(
              painter: _CircleProgressPainter(
                percentage: totalPercent,
                primaryColor:
                    isExceeding
                        ? Colors.red.shade400.withValues(alpha: 0.4)
                        : cgpaColor.withValues(alpha: 0.4), // Use marks color
                backgroundColor: Colors.transparent,
              ),
              child: const SizedBox(width: 110, height: 110),
            ),
          // Solid for earned credits
          CustomPaint(
            painter: _CircleProgressPainter(
              percentage: earnedPercent,
              primaryColor:
                  isExceeding
                      ? Colors.red.shade400
                      : cgpaColor, // Use marks color
              backgroundColor: Colors.transparent,
            ),
            child: const SizedBox(width: 110, height: 110),
          ),
          // Center text - Only percentage
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${earnedPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 26, // Increased font size
                          fontWeight: FontWeight.bold,
                          color: isExceeding ? Colors.red.shade400 : theme.text,
                        ),
                      ),
                      if (added > 0)
                        TextSpan(
                          text: '\n+${addedPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14, // Increased font size
                            fontWeight: FontWeight.w600,
                            color:
                                isExceeding ? Colors.red.shade300 : theme.muted,
                          ),
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExceeding ? Colors.red.shade400 : theme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(dynamic theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.muted)),
        const SizedBox(height: 3),
        Text(
          value,
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

/// Custom painter for circular progress
class _CircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.percentage,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    // Background circle
    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint =
        Paint()
          ..color = primaryColor
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
