import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../core/theme/theme_provider.dart';
import '../data/grade_history_data_provider.dart';
import '../widgets/grade_analysis_card.dart';
import '../widgets/semester_grade_card.dart';
import '../../../../../firebase/analytics/analytics_service.dart';

/// Main grade history page with semester-wise grades
class GradeHistoryPage extends StatefulWidget {
  const GradeHistoryPage({super.key});

  @override
  State<GradeHistoryPage> createState() => _GradeHistoryPageState();
}

class _GradeHistoryPageState extends State<GradeHistoryPage> {
  final GradeHistoryDataProvider _dataProvider = GradeHistoryDataProvider();

  List<Map<String, dynamic>> _semesterData = [];
  List<String> _orderedSemesters = [];
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'GradeHistory',
      screenClass: 'GradeHistoryPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semesterListJson = prefs.getString('available_semesters');

      if (semesterListJson != null) {
        try {
          final semesterList = json.decode(semesterListJson) as List;
          _orderedSemesters = semesterList.cast<String>();
        } catch (_) {
          _orderedSemesters = [];
        }
      }

      _semesterData = await _dataProvider.getSemesterSummaries();
      _hasData = _semesterData.isNotEmpty;

      if (_orderedSemesters.isEmpty && _semesterData.isNotEmpty) {
        _orderedSemesters =
            _semesterData.map((s) => s['semester_name'] as String).toList();
      }

      _orderedSemesters =
          _orderedSemesters
              .where(
                (semester) =>
                    _semesterData.any((s) => s['semester_name'] == semester),
              )
              .toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Grade History',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _hasData
              ? RefreshIndicator(
                onRefresh: _handleRefresh,
                color: theme.primary,
                child: _buildContent(theme, themeProvider),
              )
              : _buildEmptyState(theme),
    );
  }

  Widget _buildContent(theme, ThemeProvider themeProvider) {
    final semesterGPAs = <String, double>{};
    final semesterCourseCounts = <String, Map<String, int>>{};

    for (final semester in _semesterData) {
      final semesterName = semester['semester_name'] as String;
      final semesterGpa = semester['semester_gpa'] as double? ?? 0.0;
      final totalCourses = semester['total_courses'] as int? ?? 0;
      final passedCourses = semester['passed_courses'] as int? ?? 0;

      semesterGPAs[semesterName] = semesterGpa;
      semesterCourseCounts[semesterName] = {
        'total': totalCourses,
        'passed': passedCourses,
      };
    }

    // Prepare data for graph - reversed so S1 (oldest) is on left
    final semesterDataForChart =
        _orderedSemesters.reversed
            .where((sem) => semesterGPAs.containsKey(sem))
            .map((sem) => MapEntry(sem, semesterGPAs[sem]!))
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 1 + _semesterData.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GradeAnalysisCard(
            semesterData: semesterDataForChart,
            semesterCourseCounts: semesterCourseCounts,
          );
        }

        final semesterIndex = index - 1;
        final semester = _semesterData[semesterIndex];
        final badgeIndex = _semesterData.length - 1 - semesterIndex;

        return SemesterGradeCard(
          key: ValueKey(semester['semester_id']),
          semesterData: semester,
          semesterIndex: badgeIndex,
        );
      },
    );
  }

  Widget _buildEmptyState(theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: theme.muted),
          const SizedBox(height: 16),
          Text(
            'No Grade Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grades will appear here after\ndata extraction from VTOP',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
        ],
      ),
    );
  }
}
