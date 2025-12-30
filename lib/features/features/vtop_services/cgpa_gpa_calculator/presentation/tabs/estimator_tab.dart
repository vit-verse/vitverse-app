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

class EstimatorTab extends StatefulWidget {
  final CalculatorState state;
  final Function(CalculatorState)? onStateChanged;

  const EstimatorTab({super.key, required this.state, this.onStateChanged});

  @override
  State<EstimatorTab> createState() => _EstimatorTabState();
}

class _EstimatorTabState extends State<EstimatorTab> {
  late TextEditingController _currentCGPAController;
  late TextEditingController _completedCreditsController;
  late TextEditingController _currentSemCreditsController;
  late TextEditingController _targetCGPAController;
  late TextEditingController _totalCreditsController;
  EstimatorResult? _result;
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
    _targetCGPAController = TextEditingController(text: '9.00');
  }

  @override
  void didUpdateWidget(EstimatorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentSemCredits != widget.state.currentSemCredits) {
      _currentSemCreditsController.text = NumberFormatter.formatCredits(
        widget.state.currentSemCredits,
      );
    }
  }

  @override
  void dispose() {
    _currentCGPAController.dispose();
    _completedCreditsController.dispose();
    _currentSemCreditsController.dispose();
    _targetCGPAController.dispose();
    _totalCreditsController.dispose();
    super.dispose();
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
    var targetCGPA = double.tryParse(_targetCGPAController.text) ?? 9.0;

    currentCGPA = currentCGPA.clamp(0.0, 10.0);
    targetCGPA = targetCGPA.clamp(0.0, 10.0);
    completedCredits = completedCredits.clamp(0.0, double.infinity);
    currentSemCredits = currentSemCredits.clamp(0.0, double.infinity);

    setState(() {
      _result = CalculatorLogic.calculateRequiredGPA(
        currentCGPA: currentCGPA,
        completedCredits: completedCredits,
        currentSemCredits: currentSemCredits,
        targetCGPA: targetCGPA,
      );
      _hasCalculated = true;
    });

    widget.onStateChanged?.call(
      widget.state.copyWith(
        currentCGPA: currentCGPA,
        completedCredits: completedCredits,
        currentSemCredits: currentSemCredits,
      ),
    );
  }

  Color _getResultColor(BuildContext context) {
    if (_result == null) return Theme.of(context).primaryColor;

    if (_result!.alreadyAchieved) {
      return Colors.green;
    } else if (_result!.impossible) {
      return Colors.red;
    } else if (_result!.requiredGPA >= 9.5) {
      return Colors.red.shade400;
    } else if (_result!.requiredGPA >= 9.0) {
      return Colors.orange;
    } else if (_result!.requiredGPA >= 8.0) {
      return Colors.blue;
    } else {
      return Colors.green;
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
          Text(
            'Target Tracker',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find what GPA you need this semester to reach your target CGPA',
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
          const SizedBox(height: 24),
          CalculatorInputCard(
            title: 'Current CGPA',
            subtitle: 'Your cumulative GPA',
            icon: Icons.school,
            controller: _currentCGPAController,
            suffixText: '/ 10.00',
            minValue: 0.0,
            maxValue: 10.0,
          ),
          const SizedBox(height: 16),
          CalculatorInputCard(
            title: 'Completed Credits',
            subtitle: 'Credits earned / Total required',
            icon: Icons.check_circle_outline,
            controller: _completedCreditsController,
            suffixText: '/ ${_totalCreditsController.text}',
          ),
          const SizedBox(height: 16),
          CalculatorInputCard(
            title: 'Current Semester Credits',
            subtitle: 'Credits in current semester',
            icon: Icons.pending_actions,
            controller: _currentSemCreditsController,
          ),
          const SizedBox(height: 16),
          _buildAddedCoursesInfo(theme),
          const SizedBox(height: 16),
          CalculatorInputCard(
            title: 'Target CGPA',
            subtitle: 'Enter your desired CGPA',
            icon: Icons.flag,
            controller: _targetCGPAController,
            suffixText: '/ 10.00',
            minValue: 0.0,
            maxValue: 10.0,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate, size: 20),
              label: const Text(
                'Estimate Required GPA',
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
          if (_hasCalculated && _result != null) ...[
            ResultDisplayCard(
              title: _result!.impossible ? 'Not Possible' : 'Required GPA',
              subtitle:
                  _result!.impossible
                      ? 'Target unreachable this semester'
                      : 'Needed this semester',
              mainValue: NumberFormatter.formatCGPA(_result!.requiredGPA),
              subValue: '/ 10.00',
              icon: _result!.impossible ? Icons.warning : Icons.trending_up,
              customColor: _getResultColor(context),
              additionalInfo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.impossible
                            ? Icons.block
                            : Icons.fitness_center,
                        size: 16,
                        color: _result!.impossible ? Colors.red : theme.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Difficulty: ${_result!.difficultyLevel}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _result!.impossible ? Colors.red : theme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result!.message,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          _result!.impossible
                              ? Colors.red.shade700
                              : theme.muted,
                      fontWeight:
                          _result!.impossible
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoBanner(
              message: _result!.getSuggestion(),
              icon: Icons.lightbulb_outline,
              color: _getResultColor(context),
            ),
          ],
        ],
      ),
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

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.assignment_turned_in, color: theme.primary, size: 24),
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
        return {'count': 0, 'credits': 0.0};
      }

      final totalCredits = grades.fold<double>(
        0.0,
        (sum, course) => sum + ((course['credits'] as num?)?.toDouble() ?? 0.0),
      );

      return {'count': grades.length, 'credits': totalCredits};
    } catch (e) {
      return {'count': 0, 'credits': 0.0};
    }
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
