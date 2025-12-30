import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../models/calculator_state.dart';
import '../../logic/calculator_logic.dart';
import '../../utils/number_formatter.dart';
import '../widgets/result_display_card.dart';

class SummaryTab extends StatelessWidget {
  final CalculatorState state;

  const SummaryTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final summary = CalculatorLogic.calculateSummary(
      currentCGPA: state.currentCGPA,
      completedCredits: state.completedCredits,
      totalProgramCredits: state.totalProgramCredits,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your academic health and future possibilities',
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Standing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Current CGPA',
                  NumberFormatter.formatCGPA(state.currentCGPA),
                  Icons.school,
                  theme,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Credits Completed',
                  '${NumberFormatter.formatCredits(state.completedCredits)} / ${NumberFormatter.formatCredits(state.totalProgramCredits)}',
                  Icons.check_circle,
                  theme,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Remaining Credits',
                  NumberFormatter.formatCredits(summary.remainingCredits),
                  Icons.pending,
                  theme,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Completion',
                  NumberFormatter.formatPercentage(
                    summary.completionPercentage,
                  ),
                  Icons.pie_chart,
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress Bar
          _buildProgressBar(summary.completionPercentage, theme),
          const SizedBox(height: 24),

          // CGPA Range
          Text(
            'Possible CGPA Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCGPACard(
                  'Maximum',
                  summary.maxPossibleCGPA,
                  'All S grades',
                  Colors.green,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCGPACard(
                  'Minimum',
                  summary.minPossibleCGPA,
                  'All F grades',
                  Colors.red,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grade Simulations
          Text(
            'Grade Simulations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CGPA if all remaining courses get:',
            style: TextStyle(fontSize: 13, color: theme.muted),
          ),
          const SizedBox(height: 16),

          // Grade simulation cards
          ...summary.gradeSimulations.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGradeSimulationRow(entry.key, entry.value, theme),
            );
          }),
          const SizedBox(height: 20),

          // Motivational Message
          InfoBanner(
            message: summary.getMotivationalMessage(),
            icon: Icons.emoji_events,
            isSuccess: summary.currentCGPA >= 8.0,
            isWarning: summary.atRiskOfDropping,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    dynamic theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percentage, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Degree Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            Text(
              NumberFormatter.formatPercentage(percentage),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: theme.border,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCGPACard(
    String label,
    double cgpa,
    String description,
    Color color,
    dynamic theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.muted)),
          const SizedBox(height: 8),
          Text(
            NumberFormatter.formatCGPA(cgpa),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: theme.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSimulationRow(String grade, double cgpa, dynamic theme) {
    Color gradeColor;
    switch (grade) {
      case 'S':
        gradeColor = Colors.green;
        break;
      case 'A':
        gradeColor = Colors.blue;
        break;
      case 'B':
        gradeColor = Colors.cyan;
        break;
      case 'C':
        gradeColor = Colors.orange;
        break;
      case 'D':
        gradeColor = Colors.deepOrange;
        break;
      case 'E':
        gradeColor = Colors.red.shade300;
        break;
      default:
        gradeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: gradeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'All $grade grades',
              style: TextStyle(fontSize: 14, color: theme.text),
            ),
          ),
          Text(
            NumberFormatter.formatCGPA(cgpa),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: gradeColor,
            ),
          ),
        ],
      ),
    );
  }
}
