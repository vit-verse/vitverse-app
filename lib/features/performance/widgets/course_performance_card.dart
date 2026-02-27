import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/color_utils.dart';
import '../../../core/theme/app_card_styles.dart';
import '../../../core/widgets/capsule_progress.dart';
import '../models/performance_models.dart';
import 'performance_widgets.dart';
import 'assessment_mark_tile.dart';

class CoursePerformanceCard extends StatefulWidget {
  final CoursePerformance performance;
  final Function(int markId, double average) onUpdateAverage;
  final Function(List<int> markIds) onMarkRead;
  final bool forceExpanded;

  const CoursePerformanceCard({
    super.key,
    required this.performance,
    required this.onUpdateAverage,
    required this.onMarkRead,
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
          _markUnreadVisible();
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
        _markUnreadVisible();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _markUnreadVisible() {
    final unreadIds =
        widget.performance.assessments
            .where((a) => !a.isRead)
            .map((a) => a.id)
            .toList();
    if (unreadIds.isNotEmpty) widget.onMarkRead(unreadIds);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final unreadCount =
        widget.performance.assessments.where((a) => !a.isRead).length;

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
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeProvider.currentTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$unreadCount NEW',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
                          onMarkRead:
                              assessment.isRead
                                  ? null
                                  : () => widget.onMarkRead([assessment.id]),
                          onAddAverage:
                              () => _showAddAverageDialog(context, assessment),
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
    showDialog(
      context: context,
      builder:
          (context) => _AddAverageDialog(
            assessment: assessment,
            onSave: (average) => widget.onUpdateAverage(assessment.id, average),
          ),
    );
  }
}

class _AddAverageDialog extends StatefulWidget {
  final AssessmentMark assessment;
  final Function(double average) onSave;

  const _AddAverageDialog({required this.assessment, required this.onSave});

  @override
  State<_AddAverageDialog> createState() => _AddAverageDialogState();
}

class _AddAverageDialogState extends State<_AddAverageDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text:
          widget.assessment.average != null && widget.assessment.average! > 0
              ? widget.assessment.average!.toStringAsFixed(1)
              : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final raw = _controller.text.trim();
    final parsed = double.tryParse(raw);
    final maxScore = widget.assessment.maxScore;

    if (parsed == null || raw.isEmpty) {
      setState(() => _errorText = 'Enter a valid number');
      return;
    }
    if (parsed < 0) {
      setState(() => _errorText = 'Cannot be negative');
      return;
    }
    if (maxScore != null && maxScore > 0 && parsed > maxScore) {
      setState(
        () =>
            _errorText =
                'Cannot exceed max score (${maxScore.toStringAsFixed(1)})',
      );
      return;
    }
    widget.onSave(parsed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final maxScore = widget.assessment.maxScore;

    return AlertDialog(
      backgroundColor: themeProvider.currentTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Set Average',
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
            widget.assessment.title,
            style: TextStyle(
              color: themeProvider.currentTheme.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            style: TextStyle(color: themeProvider.currentTheme.text),
            decoration: InputDecoration(
              labelText: 'Average Score',
              hintText:
                  maxScore != null && maxScore > 0
                      ? '0 – ${maxScore.toStringAsFixed(1)}'
                      : 'Enter average score',
              helperText:
                  maxScore != null && maxScore > 0
                      ? 'Max: ${maxScore.toStringAsFixed(1)}'
                      : null,
              errorText: _errorText,
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
          onPressed: _handleSave,
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
