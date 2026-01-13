import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_card_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../logic/performance_logic.dart';
import '../models/performance_models.dart';
import '../widgets/course_performance_card.dart';

class PerformancePage extends StatefulWidget {
  final List<CoursePerformance> initialPerformances;

  const PerformancePage({super.key, required this.initialPerformances});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  static const String _tag = 'PerformancePage';
  final PerformanceLogic _logic = PerformanceLogic();

  late List<CoursePerformance> _performances;
  String _semesterName = '';
  bool _expandAll = false;

  @override
  void initState() {
    super.initState();
    _performances = widget.initialPerformances;
    _loadSemesterName();
  }

  Future<void> _loadSemesterName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semester = prefs.getString('semester') ?? 'Current Semester';
      if (mounted) {
        setState(() {
          _semesterName = semester;
        });
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading semester name: $e');
      if (mounted) {
        setState(() {
          _semesterName = 'Current Semester';
        });
      }
    }
  }

  Future<void> _loadPerformanceData() async {
    try {
      final performances = await _logic.getCoursePerformances();
      Logger.d(_tag, 'Loaded ${performances.length} course performances');

      if (mounted) {
        setState(() {
          _performances = performances;
        });
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading performance data: $e');
    }
  }

  void _toggleExpandAll() {
    setState(() {
      _expandAll = !_expandAll;
    });
  }

  Future<void> _handleUpdateAverage(int markId, double average) async {
    final success = await _logic.updateMarkAverage(markId, average);
    if (success && mounted) {
      SnackbarUtils.success(context, 'Average updated successfully');
      _loadPerformanceData();
    }
  }

  /// Build consistent action button with border for AppBar
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, size: 20, color: themeProvider.currentTheme.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: themeProvider.currentTheme.background,
        appBar: AppBar(
          title: const Text('Academic'),
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildActionButton(
                icon: _expandAll ? Icons.unfold_less : Icons.unfold_more,
                onPressed: _toggleExpandAll,
                tooltip: _expandAll ? 'Collapse all' : 'Expand all',
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(themeProvider),
            const SizedBox(height: 20),
            ..._performances.asMap().entries.map((entry) {
              final performance = entry.value;
              return CoursePerformanceCard(
                key: ValueKey('course_${performance.courseId}'),
                performance: performance,
                forceExpanded: _expandAll,
                onUpdateAverage: _handleUpdateAverage,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeProvider themeProvider) {
    final totalCourses = _performances.length;

    // Calculate total assessments
    int totalAssessments = 0;
    int presentAssessments = 0;

    for (final performance in _performances) {
      totalAssessments += performance.assessments.length;
      for (final assessment in performance.assessments) {
        if (assessment.isPresent) {
          presentAssessments++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester heading
          Text(
            _semesterName.isNotEmpty ? _semesterName : 'Current Semester',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.currentTheme.text,
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          _buildStatRow('Courses', totalCourses.toString(), themeProvider),
          const SizedBox(height: 12),
          _buildStatRow(
            'Total Assessments',
            totalAssessments.toString(),
            themeProvider,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Present',
            '$presentAssessments / $totalAssessments',
            themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.currentTheme.muted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: themeProvider.currentTheme.text,
          ),
        ),
      ],
    );
  }
}
