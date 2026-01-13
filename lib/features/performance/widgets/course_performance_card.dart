import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/color_utils.dart';
import '../../../core/theme/app_card_styles.dart';
import '../../../core/widgets/capsule_progress.dart';
import '../models/performance_models.dart';
import 'performance_widgets.dart';
import 'assessment_mark_tile.dart';

/// Collapsible card showing course performance with all assessments
class CoursePerformanceCard extends StatefulWidget {
  final CoursePerformance performance;
  final Function(int markId, double average) onUpdateAverage;
  final bool forceExpanded;

  const CoursePerformanceCard({
    super.key,
    required this.performance,
    required this.onUpdateAverage,
    this.forceExpanded = false,
  });

  @override
  State<CoursePerformanceCard> createState() => _CoursePerformanceCardState();
}

class _CoursePerformanceCardState extends State<CoursePerformanceCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.forceExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CoursePerformanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceExpanded != oldWidget.forceExpanded) {
      setState(() {
        _isExpanded = widget.forceExpanded;
        if (_isExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course code and title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.performance.courseCode,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.currentTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.performance.courseTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.currentTheme.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Capsule progress bar with score
                        _buildCapsuleProgress(themeProvider),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Course type, credits, and new badge
                    Row(
                      children: [
                        // Course type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.currentTheme.muted.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.performance.courseType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.currentTheme.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Credits
                        CreditPill(credits: widget.performance.credits),
                        const Spacer(),
                        // Dropdown icon
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: themeProvider.currentTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expandable assessments list
              if (_isExpanded)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: themeProvider.currentTheme.muted.withOpacity(
                          0.2,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessments (${widget.performance.assessments.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Assessment tiles
                      ...widget.performance.assessments.map((assessment) {
                        return AssessmentMarkTile(
                          assessment: assessment,
                          onAddAverage: () {
                            _showAddAverageDialog(context, assessment);
                          },
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleProgress(ThemeProvider themeProvider) {
    final obtainedWeightage = widget.performance.obtainedWeightage;
    final totalWeightage = widget.performance.totalWeightage;
    final percentage =
        totalWeightage > 0 ? (obtainedWeightage / totalWeightage * 100) : 0.0;
    final progressColor = ColorUtils.getMarksColorFromProvider(
      themeProvider,
      percentage,
    );

    return CapsuleProgress(
      percentage: percentage,
      color: progressColor,
      width: 120,
      height: 55,
      label:
          '${obtainedWeightage.toStringAsFixed(1)}/${totalWeightage.toStringAsFixed(1)}',
    );
  }

  void _showAddAverageDialog(BuildContext context, AssessmentMark assessment) {
    final controller = TextEditingController(
      text:
          assessment.average != null && assessment.average! > 0
              ? assessment.average!.toStringAsFixed(1)
              : '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AddAverageDialog(
            controller: controller,
            assessmentTitle: assessment.title,
            onSave: (value) {
              final average = double.tryParse(value);
              if (average != null && average >= 0) {
                widget.onUpdateAverage(assessment.id, average);
              }
            },
          ),
    );
  }
}

/// Dialog for adding/editing average
class AddAverageDialog extends StatelessWidget {
  final TextEditingController controller;
  final String assessmentTitle;
  final Function(String) onSave;

  const AddAverageDialog({
    super.key,
    required this.controller,
    required this.assessmentTitle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AlertDialog(
      backgroundColor: themeProvider.currentTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Add/Edit Average',
        style: TextStyle(
          color: themeProvider.currentTheme.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assessmentTitle,
            style: TextStyle(
              color: themeProvider.currentTheme.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: TextStyle(color: themeProvider.currentTheme.text),
            decoration: InputDecoration(
              labelText: 'Average Score',
              hintText: 'Enter average score',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: themeProvider.currentTheme.muted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(controller.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.currentTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
