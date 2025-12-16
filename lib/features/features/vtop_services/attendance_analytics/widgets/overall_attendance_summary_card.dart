import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/color_utils.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/widgets/capsule_progress.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../logic/attendance_analytics_logic.dart';

/// Overall attendance summary with expandable calculator
class OverallAttendanceSummaryCard extends StatefulWidget {
  final Map<String, dynamic> overallStats;
  final String lastSynced;
  final Function(double)? onTargetChanged; // Callback to sync target to courses

  const OverallAttendanceSummaryCard({
    super.key,
    required this.overallStats,
    required this.lastSynced,
    this.onTargetChanged,
  });

  @override
  State<OverallAttendanceSummaryCard> createState() =>
      _OverallAttendanceSummaryCardState();
}

class _OverallAttendanceSummaryCardState
    extends State<OverallAttendanceSummaryCard> {
  final AttendanceAnalyticsLogic _logic = AttendanceAnalyticsLogic();
  bool _isCalculatorExpanded = false;
  final TextEditingController _targetController = TextEditingController(
    text: '75',
  );
  int _calculatedClasses = 0;

  @override
  void initState() {
    super.initState();
    _calculateDefault();
  }

  void _calculateDefault() {
    final attended = widget.overallStats['present'] as int;
    final total = widget.overallStats['total'] as int;
    final target = double.tryParse(_targetController.text) ?? 75.0;

    setState(() {
      _calculatedClasses = _logic.calculateClassesToTarget(
        attended: attended,
        total: total,
        targetPercentage: target,
      );
    });
  }

  void _calculate() {
    final target = double.tryParse(_targetController.text) ?? 75.0;

    if (target < 0 || target > 100) {
      SnackbarUtils.error(context, 'Target must be between 0 and 100');
      return;
    }

    _calculateDefault();
    widget.onTargetChanged?.call(target);

    SnackbarUtils.success(
      context,
      'Target updated to ${target.toStringAsFixed(1)}%',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final percentage = widget.overallStats['percentage'] as double;
    final present = widget.overallStats['present'] as int;
    final absent = widget.overallStats['absent'] as int;
    final onDuty = widget.overallStats['onDuty'] as int;
    final total = widget.overallStats['total'] as int;

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Attendance',
                  style: TextStyle(
                    color: themeProvider.currentTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CapsuleProgress(
                  percentage: percentage,
                  color: ColorUtils.getAttendanceColor(context, percentage),
                  width: 110,
                  height: 32,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Present',
                    value: '$present',
                    color: ColorUtils.getAttendanceColor(context, percentage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Absent',
                    value: '$absent',
                    color: ColorUtils.getAttendanceColor(
                      context,
                      percentage < 75 ? percentage : 70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'On Duty',
                    value: '$onDuty',
                    color: const Color(0xFFEAB308),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Total',
                    value: '$total',
                    color: themeProvider.currentTheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (_calculatedClasses >= 0
                        ? ColorUtils.getAttendanceColor(context, percentage)
                        : ColorUtils.getAttendanceColor(
                          context,
                          percentage < 75 ? percentage : 70,
                        ))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _calculatedClasses >= 0
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color:
                        _calculatedClasses >= 0
                            ? ColorUtils.getAttendanceColor(context, percentage)
                            : ColorUtils.getAttendanceColor(
                              context,
                              percentage < 75 ? percentage : 70,
                            ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _calculatedClasses >= 0
                        ? 'Can miss $_calculatedClasses classes'
                        : 'Need ${-_calculatedClasses} classes',
                    style: TextStyle(
                      color: themeProvider.currentTheme.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            InkWell(
              onTap: () {
                setState(() {
                  _isCalculatorExpanded = !_isCalculatorExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isCalculatorExpanded
                        ? 'Hide Calculator'
                        : 'Show Calculator',
                    style: TextStyle(
                      color: themeProvider.currentTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isCalculatorExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: themeProvider.currentTheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),

            if (_isCalculatorExpanded) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.currentTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Custom Target',
                          style: TextStyle(
                            color: themeProvider.currentTheme.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _targetController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: themeProvider.currentTheme.text,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Target %',
                                  hintStyle: TextStyle(
                                    color: themeProvider.currentTheme.muted,
                                  ),
                                  filled: true,
                                  fillColor: themeProvider.currentTheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    themeProvider.currentTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Calculate'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeProvider.currentTheme.primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _calculatedClasses >= 0
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                color: themeProvider.currentTheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _calculatedClasses >= 0
                                      ? 'You can miss $_calculatedClasses more classes'
                                      : 'Attend ${-_calculatedClasses} more classes',
                                  style: TextStyle(
                                    color: themeProvider.currentTheme.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.currentTheme.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
