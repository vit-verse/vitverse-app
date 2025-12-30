import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/examination_data_provider.dart';
import '../logic/examination_logic.dart';
import '../widgets/examination_schedule_widgets.dart';

/// Examination Schedule Page
class ExaminationSchedulePage extends StatefulWidget {
  const ExaminationSchedulePage({super.key});

  @override
  State<ExaminationSchedulePage> createState() =>
      _ExaminationSchedulePageState();
}

class _ExaminationSchedulePageState extends State<ExaminationSchedulePage> {
  @override
  String get screenName => 'ExamSchedule';

  final ExaminationDataProvider _dataProvider = ExaminationDataProvider();
  final ExaminationLogic _logic = ExaminationLogic();

  Map<String, List<Map<String, dynamic>>> _examsByType = {};
  List<String> _examTypes = [];
  String? _selectedType;
  Map<String, dynamic>? _nextExam;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ExaminationSchedule',
      screenClass: 'ExaminationSchedulePage',
    );
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load exams grouped by type
      final examsByType = await _dataProvider.getExamsByType();
      final nextExam = await _dataProvider.getNextExam();

      // Extract exam types (sorted by earliest exam date)
      final examTypes = _logic.extractExamTypes(examsByType);

      // Find the most upcoming exam type (first non-completed exam type)
      String? mostUpcomingType;
      if (examTypes.isNotEmpty) {
        for (var type in examTypes) {
          final examsOfType = examsByType[type] ?? [];
          // Check if this type has any non-completed exams
          final hasUpcomingExams = examsOfType.any((exam) {
            final startTime = exam['start_time'] as int?;
            return _logic.getExamStatus(startTime) != ExamStatus.completed;
          });

          if (hasUpcomingExams) {
            mostUpcomingType = type;
            break;
          }
        }

        // If all exams are completed, select the first type
        mostUpcomingType ??= examTypes.first;
      }

      setState(() {
        _examsByType = examsByType;
        _examTypes = examTypes;
        _selectedType = mostUpcomingType;
        _nextExam = nextExam;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load exam schedule';
        _isLoading = false;
      });
      Logger.e('ExaminationSchedulePage', 'Error loading exam data', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.currentTheme.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Examination Schedule',
          style: TextStyle(
            color: themeProvider.currentTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(themeProvider),
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.currentTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading exam schedule...',
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: themeProvider.currentTheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExamData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_examsByType.isEmpty) {
      return EmptyExamState(
        message:
            'No exams scheduled at the moment.\nPlease check back later or sync your data from VTOP.',
        themeProvider: themeProvider,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExamData,
      color: themeProvider.currentTheme.primary,
      child: Column(
        children: [
          // Next exam countdown banner
          if (_nextExam != null)
            ExamCountdownBanner(
              nextExam: _nextExam,
              themeProvider: themeProvider,
              logic: _logic,
            ),

          // Exam type tabs
          ExamTypeTabs(
            examTypes: _examTypes,
            selectedType: _selectedType ?? '',
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
              });
            },
            themeProvider: themeProvider,
          ),

          const SizedBox(height: 8),

          // Exam list
          Expanded(child: _buildExamList(themeProvider)),
        ],
      ),
    );
  }

  Widget _buildExamList(ThemeProvider themeProvider) {
    if (_selectedType == null || !_examsByType.containsKey(_selectedType)) {
      return EmptyExamState(
        message: 'No exams found for this type.',
        themeProvider: themeProvider,
      );
    }

    final exams = _examsByType[_selectedType!]!;

    if (exams.isEmpty) {
      return EmptyExamState(
        message: 'No $_selectedType exams scheduled.',
        themeProvider: themeProvider,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return ExamCard(
          exam: exam,
          themeProvider: themeProvider,
          logic: _logic,
        );
      },
    );
  }
}
