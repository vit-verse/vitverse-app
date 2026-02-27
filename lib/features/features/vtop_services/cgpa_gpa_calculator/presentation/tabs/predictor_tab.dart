import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../models/calculator_state.dart';
import '../../models/calculator_result.dart';
import '../../logic/calculator_logic.dart';
import '../../utils/number_formatter.dart';
import '../widgets/calculator_input_card.dart';
import '../widgets/result_display_card.dart';

class PredictorTab extends StatefulWidget {
  final CalculatorState state;
  final Function(CalculatorState)? onStateChanged;

  const PredictorTab({super.key, required this.state, this.onStateChanged});

  @override
  State<PredictorTab> createState() => _PredictorTabState();
}

class _PredictorTabState extends State<PredictorTab> {
  late TextEditingController _currentCGPAController;
  late TextEditingController _completedCreditsController;
  late TextEditingController _currentSemCreditsController;
  late TextEditingController _expectedGPAController;
  late TextEditingController _totalCreditsController;
  PredictorResult? _result;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    _currentCGPAController = TextEditingController(
      text: NumberFormatter.formatCGPA(widget.state.currentCGPA),
    );
    _completedCreditsController = TextEditingController(
      text: NumberFormatter.formatCredits(widget.state.completedCredits),
    );
    _currentSemCreditsController = TextEditingController(
      text: NumberFormatter.formatCredits(widget.state.currentSemCredits),
    );
    _totalCreditsController = TextEditingController(
      text: NumberFormatter.formatCredits(widget.state.totalProgramCredits),
    );
    _expectedGPAController = TextEditingController(text: '8.50');
    _loadExpectedGPAFromCourses();
  }

  /// GPA = Σ(credits × grade_point) / Σ(credits)
  Future<void> _loadExpectedGPAFromCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gradesJson = prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> savedGrades = jsonDecode(gradesJson);

      if (savedGrades.isNotEmpty) {
        double totalWeightedPoints = 0.0;
        double totalCredits = 0.0;

        for (var courseData in savedGrades) {
          final credits = (courseData['credits'] as num?)?.toDouble() ?? 0.0;
          final grade = courseData['grade']?.toString() ?? 'S';
          final gradePoint = _getGradePoint(grade);

          totalWeightedPoints += credits * gradePoint;
          totalCredits += credits;
        }

        if (totalCredits > 0) {
          final calculatedGPA = totalWeightedPoints / totalCredits;
          setState(() {
            _expectedGPAController.text = calculatedGPA.toStringAsFixed(2);
            _currentSemCreditsController.text = totalCredits.toStringAsFixed(1);
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  double _getGradePoint(String grade) {
    const gradePoints = {
      'S': 10.0,
      'A': 9.0,
      'B': 8.0,
      'C': 7.0,
      'D': 6.0,
      'E': 5.0,
      'F': 0.0,
      'N': 0.0,
    };
    return gradePoints[grade.toUpperCase()] ?? 0.0;
  }

  @override
  void dispose() {
    _currentCGPAController.dispose();
    _completedCreditsController.dispose();
    _currentSemCreditsController.dispose();
    _expectedGPAController.dispose();
    _totalCreditsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PredictorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadExpectedGPAFromCourses();
  }

  void _calculate() {
    var currentCGPA =
        double.tryParse(_currentCGPAController.text) ??
        widget.state.currentCGPA;
    var completedCredits =
        double.tryParse(_completedCreditsController.text) ??
        widget.state.completedCredits;
    var currentSemCredits =
        double.tryParse(_currentSemCreditsController.text) ??
        widget.state.currentSemCredits;
    var expectedGPA = double.tryParse(_expectedGPAController.text) ?? 8.5;

    currentCGPA = currentCGPA.clamp(0.0, 10.0);
    expectedGPA = expectedGPA.clamp(0.0, 10.0);
    completedCredits = completedCredits.clamp(0.0, double.infinity);
    currentSemCredits = currentSemCredits.clamp(0.0, double.infinity);

    setState(() {
      _result = CalculatorLogic.calculateProjectedCGPA(
        currentCGPA: currentCGPA,
        completedCredits: completedCredits,
        expectedGPA: expectedGPA,
        currentSemCredits: currentSemCredits,
      );
      _hasCalculated = true;
    });
    if (widget.onStateChanged != null) {
      widget.onStateChanged!(
        widget.state.copyWith(
          currentCGPA: currentCGPA,
          completedCredits: completedCredits,
          currentSemCredits: currentSemCredits,
        ),
      );
    }
  }

  Color _getTrendColor() {
    if (_result == null) return Colors.blue;

    if (_result!.cgpaChange >= 0.3) {
      return Colors.green;
    } else if (_result!.cgpaChange >= 0.1) {
      return Colors.blue;
    } else if (_result!.cgpaChange >= -0.1) {
      return Colors.orange;
    } else if (_result!.cgpaChange >= -0.3) {
      return Colors.red.shade300;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Future Simulator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Predict your CGPA after this semester',
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
          const SizedBox(height: 24),

          // Current CGPA Input
          CalculatorInputCard(
            title: 'Current CGPA',
            subtitle: 'Your current cumulative GPA',
            icon: Icons.school,
            controller: _currentCGPAController,
            suffixText: '/ 10.00',
            minValue: 0.0,
            maxValue: 10.0,
          ),
          const SizedBox(height: 16),

          // Completed Credits Input
          CalculatorInputCard(
            title: 'Completed Credits',
            subtitle: 'Credits earned so far',
            icon: Icons.check_circle,
            controller: _completedCreditsController,
            suffixText: 'credits',
          ),
          const SizedBox(height: 16),

          // Current Semester Credits Input
          CalculatorInputCard(
            title: 'Current Semester Credits',
            subtitle: 'Credits enrolled this semester',
            icon: Icons.pending,
            controller: _currentSemCreditsController,
            suffixText: 'credits',
          ),
          const SizedBox(height: 16),

          // Added Courses Info Card
          _buildAddedCoursesInfo(theme),
          const SizedBox(height: 16),

          // Expected GPA Input
          CalculatorInputCard(
            title: 'Expected GPA',
            subtitle: 'Your predicted GPA this semester',
            icon: Icons.psychology,
            controller: _expectedGPAController,
            suffixText: '/ 10.00',
            minValue: 0.0,
            maxValue: 10.0,
          ),
          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.analytics, size: 20),
              label: const Text(
                'Predict Future CGPA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Result Display
          if (_hasCalculated && _result != null) ...[
            ResultDisplayCard(
              title: 'Projected CGPA',
              subtitle: 'After this semester',
              mainValue: NumberFormatter.formatCGPA(_result!.projectedCGPA),
              subValue: '/ 10.00',
              icon: Icons.analytics,
              customColor: _getTrendColor(),
              additionalInfo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Change indicator
                  Row(
                    children: [
                      Icon(
                        _result!.cgpaChange >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: _getTrendColor(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_result!.cgpaChange >= 0 ? "+" : ""}${NumberFormatter.truncateToDecimal(_result!.cgpaChange, 3)} points',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getTrendColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Percentage
                  Text(
                    'Equivalent to ${_result!.projectedPercentage}%',
                    style: TextStyle(fontSize: 13, color: theme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Trend Banner
            InfoBanner(
              message: '${_result!.trendIcon} ${_result!.trendDescription}',
              icon: Icons.trending_up,
              color: _getTrendColor(),
              isSuccess: _result!.cgpaChange >= 0.1,
              isWarning: _result!.cgpaChange < -0.1,
            ),
            const SizedBox(height: 16),

            // Comparison Card
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
                    'CGPA Comparison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonRow(
                    'Before',
                    NumberFormatter.formatCGPA(widget.state.currentCGPA),
                    theme.muted,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildComparisonRow(
                    'After',
                    NumberFormatter.formatCGPA(_result!.projectedCGPA),
                    _getTrendColor(),
                    theme,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildComparisonRow(
                    'Change',
                    '${_result!.cgpaChange >= 0 ? "+" : ""}${NumberFormatter.truncateToDecimal(_result!.cgpaChange, 3)}',
                    _getTrendColor(),
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String value,
    Color valueColor,
    dynamic theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: theme.muted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAddedCoursesInfo(dynamic theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCoursesInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || (snapshot.data!['count'] ?? 0) == 0) {
          return const SizedBox.shrink();
        }

        final courseCount = snapshot.data!['count'] ?? 0;
        final totalCredits =
            (snapshot.data!['credits'] as num?)?.toDouble() ?? 0.0;
        final calculatedGPA =
            (snapshot.data!['gpa'] as num?)?.toDouble() ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    color: theme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Added Courses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          '$courseCount courses • ${NumberFormatter.formatCredits(totalCredits)} credits',
                          style: TextStyle(fontSize: 12, color: theme.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear_all, color: theme.error),
                    onPressed: _clearCourses,
                    tooltip: 'Clear added courses (not CGPA/Credits)',
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calculated Expected GPA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        calculatedGPA.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.info_outline, size: 20),
                        color: theme.primary,
                        onPressed: _showDetailedBreakdown,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'View detailed calculation',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 16,
                      color: theme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This GPA is auto-filled in "Expected GPA" field below',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCoursesInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gradesJson = prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> grades = jsonDecode(gradesJson);

      if (grades.isEmpty) {
        return {'count': 0, 'credits': 0.0, 'gpa': 0.0};
      }

      double totalCredits = 0.0;
      double totalWeightedPoints = 0.0;

      for (var course in grades) {
        final credits = (course['credits'] as num?)?.toDouble() ?? 0.0;
        final grade = course['grade']?.toString() ?? 'S';
        final gradePoint = _getGradePoint(grade);

        totalCredits += credits;
        totalWeightedPoints += credits * gradePoint;
      }

      final gpa = totalCredits > 0 ? totalWeightedPoints / totalCredits : 0.0;

      return {'count': grades.length, 'credits': totalCredits, 'gpa': gpa};
    } catch (e) {
      return {'count': 0, 'credits': 0.0, 'gpa': 0.0};
    }
  }

  void _showDetailedBreakdown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gradesJson = prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> savedGrades = jsonDecode(gradesJson);

      if (savedGrades.isEmpty) {
        if (mounted) SnackbarUtils.info(context, 'No courses added yet');
        return;
      }

      // Calculate breakdown
      List<Map<String, dynamic>> breakdown = [];
      double totalCredits = 0.0;
      double totalCreditPoints = 0.0;

      for (var course in savedGrades) {
        final credits = (course['credits'] as num?)?.toDouble() ?? 0.0;
        final grade = course['grade']?.toString() ?? 'S';
        final gradePoint = _getGradePoint(grade);
        final creditPoints = credits * gradePoint;

        breakdown.add({
          'title': course['title'] ?? 'Unknown',
          'code':
              course['code'] ?? (course['isManual'] == true ? 'Manual' : 'N/A'),
          'credits': credits,
          'grade': grade,
          'gradePoint': gradePoint,
          'creditPoints': creditPoints,
        });

        totalCredits += credits;
        totalCreditPoints += creditPoints;
      }

      final calculatedGPA =
          totalCredits > 0 ? totalCreditPoints / totalCredits : 0.0;

      // Show dialog
      if (!mounted) return;
      final theme =
          Provider.of<ThemeProvider>(context, listen: false).currentTheme;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: theme.surface,
              title: Row(
                children: [
                  Icon(Icons.calculate, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Expected GPA Details',
                      style: TextStyle(color: theme.text, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDialogSummaryRow(
                            'Total Courses',
                            breakdown.length.toString(),
                            theme,
                          ),
                          const SizedBox(height: 4),
                          _buildDialogSummaryRow(
                            'Total Credits',
                            totalCredits.toStringAsFixed(1),
                            theme,
                          ),
                          const SizedBox(height: 4),
                          _buildDialogSummaryRow(
                            'Total Credit Points',
                            totalCreditPoints.toStringAsFixed(2),
                            theme,
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Expected GPA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.text,
                                ),
                              ),
                              Text(
                                calculatedGPA.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Formula
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.functions,
                                size: 16,
                                color: theme.muted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Formula',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GPA = Σ(Credits × Grade Point) / Total Credits',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GPA = ${totalCreditPoints.toStringAsFixed(2)} / ${totalCredits.toStringAsFixed(1)} = ${calculatedGPA.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Course breakdown
                    Text(
                      'Course-wise Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...breakdown.map((course) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['title'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course['code'],
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Credits: ${course['credits']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.muted,
                                  ),
                                ),
                                Text(
                                  'Grade: ${course['grade']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Grade Point: ${course['gradePoint']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.muted,
                                  ),
                                ),
                                Text(
                                  'Credit Points: ${course['creditPoints'].toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(${course['credits']} × ${course['gradePoint']} = ${course['creditPoints'].toStringAsFixed(1)})',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: theme.primary)),
                ),
              ],
            ),
      );
    } catch (e) {
      SnackbarUtils.error(context, 'Error loading breakdown: $e');
    }
  }

  Widget _buildDialogSummaryRow(String label, String value, dynamic theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.muted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
      ],
    );
  }

  Future<void> _clearCourses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Added Courses?'),
            content: const Text(
              'This will remove all added courses but keep your Current CGPA and Completed Credits.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_semester_grades');

      // Reset current semester credits to 0
      setState(() {
        _currentSemCreditsController.text = '0';
      });

      // Trigger callback if available
      if (widget.onStateChanged != null) {
        widget.onStateChanged!(widget.state);
      }

      if (mounted) {
        SnackbarUtils.success(context, 'Courses cleared successfully');
      }
    }
  }
}
