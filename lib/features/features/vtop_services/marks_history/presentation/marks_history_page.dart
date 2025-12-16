import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../core/theme/theme_provider.dart';
import '../logic/marks_history_provider.dart';
import '../models/marks_analysis.dart';
import '../widgets/marks_analysis_card.dart';
import '../widgets/semester_marks_card.dart';
import '../../../../../core/database/entities/all_semester_mark.dart';
import '../../../../../firebase/analytics/analytics_service.dart';

/// Main marks history page with lazy loading support
class MarksHistoryPage extends StatefulWidget {
  const MarksHistoryPage({super.key});

  @override
  State<MarksHistoryPage> createState() => _MarksHistoryPageState();
}

class _MarksHistoryPageState extends State<MarksHistoryPage> {
  final MarksHistoryService _service = MarksHistoryService();

  Map<String, List<AllSemesterMark>> _marksData = {};
  MarksAnalysis _analysis = MarksAnalysis.empty();
  List<String> _orderedSemesters = [];
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'MarksHistory',
      screenClass: 'MarksHistoryPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load semester order from preferences
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

      // Load marks data and analysis
      _marksData = await _service.getAllMarksGroupedBySemester();
      _analysis = await _service.calculateMarksAnalysis();
      _hasData = _marksData.isNotEmpty;

      // Fallback to data keys if no order set
      if (_orderedSemesters.isEmpty && _marksData.isNotEmpty) {
        _orderedSemesters = _marksData.keys.toList();
      }

      // Filter to only include semesters with data
      _orderedSemesters =
          _orderedSemesters
              .where((semester) => _marksData.containsKey(semester))
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
          'Marks History',
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
                child: _buildContent(theme),
              )
              : _buildEmptyState(theme),
    );
  }

  Widget _buildContent(theme) {
    // Prepare data for graph - reversed so S1 (oldest) is on left
    final semesterData =
        _orderedSemesters.reversed
            .where((sem) => _analysis.semesterAverages.containsKey(sem))
            .map((sem) => MapEntry(sem, _analysis.semesterAverages[sem]!))
            .toList();

    // Calculate course counts per semester
    final semesterCourseCounts = <String, int>{};
    for (final semester in _orderedSemesters) {
      if (_marksData.containsKey(semester)) {
        final marks = _marksData[semester]!;
        final groupedByCourse = <String, List<AllSemesterMark>>{};
        for (final mark in marks) {
          final key = '${mark.courseCode}_${mark.courseTitle}';
          groupedByCourse.putIfAbsent(key, () => []).add(mark);
        }
        semesterCourseCounts[semester] = groupedByCourse.length;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 1 + _orderedSemesters.length, // Analysis card + semester cards
      itemBuilder: (context, index) {
        if (index == 0) {
          // Analysis card at top
          return MarksAnalysisCard(
            overallAverage: _analysis.overallAverage,
            totalCourses: _analysis.totalCourses,
            totalAssessments: _analysis.totalAssessments,
            highestAverage: _analysis.highestSemesterAverage,
            lowestAverage: _analysis.lowestSemesterAverage,
            semesterData: semesterData,
            semesterCourseCounts: semesterCourseCounts,
          );
        }

        // Semester cards
        final semesterIndex = index - 1;
        final semesterName = _orderedSemesters[semesterIndex];
        final marks = _marksData[semesterName]!;
        // Reverse badge: S1 for oldest (at bottom), highest number for newest (at top)
        final badgeIndex = _orderedSemesters.length - 1 - semesterIndex;

        return SemesterMarksCard(
          key: ValueKey(semesterName),
          semesterName: semesterName,
          marks: marks,
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
          Icon(Icons.assignment_outlined, size: 64, color: theme.muted),
          const SizedBox(height: 16),
          Text(
            'No Marks Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marks will appear here after\ndata extraction from VTOP',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
        ],
      ),
    );
  }
}
