import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/cgpa_summary.dart';
import '../../../../../core/database/entities/course.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/academic_performance_data_provider.dart';
import '../models/curriculum_with_progress.dart';
import '../models/basket_with_progress.dart';
import '../models/semester_performance.dart';
import '../widgets/cgpa_overview_card.dart';
import '../widgets/semester_gpa_card.dart';
import '../widgets/curriculum_progress_card.dart';
import '../widgets/basket_progress_card.dart';
import '../widgets/grade_distribution_chart.dart';

/// Academic Performance Page
/// Displays CGPA, semester GPAs, curriculum progress, and basket progress
class AcademicPerformancePage extends StatefulWidget {
  const AcademicPerformancePage({super.key});

  @override
  State<AcademicPerformancePage> createState() =>
      _AcademicPerformancePageState();
}

class _AcademicPerformancePageState extends State<AcademicPerformancePage> {
  final AcademicPerformanceDataProvider _dataProvider =
      AcademicPerformanceDataProvider();

  bool _isLoading = true;
  String? _errorMessage;

  CGPASummary? _cgpaSummary;
  double _totalCreditsRequired = 0.0;
  double _totalAddedCredits = 0.0;
  List<CurriculumWithProgress> _curriculums = [];
  List<BasketWithProgress> _baskets = [];
  List<SemesterPerformance> _semesters = [];

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AcademicPerformance',
      screenClass: 'AcademicPerformancePage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cgpa = await _dataProvider.getCGPASummary();
      final curriculums = await _dataProvider.getCurriculumWithProgress();
      final baskets = await _dataProvider.getBasketWithProgress();
      final semesters = await _dataProvider.getSemesterPerformances();

      final prefs = await SharedPreferences.getInstance();
      final totalRequired = prefs.getDouble('total_credits_required') ?? 151.0;

      final manualCoursesJson = prefs.getString('manual_courses') ?? '[]';
      final List<dynamic> manualCourses = jsonDecode(manualCoursesJson);
      double manualAdded = manualCourses.fold<double>(
        0.0,
        (sum, course) => sum + ((course['credits'] as num?)?.toDouble() ?? 0.0),
      );

      final classificationsJson =
          prefs.getString('course_classifications') ?? '{}';
      final Map<String, dynamic> classifications = jsonDecode(
        classificationsJson,
      );
      double classifiedAdded = 0.0;
      for (final entry in classifications.entries) {
        final key = entry.key;
        if (key.startsWith('course_')) {
          final courseIdStr = key.replaceFirst('course_', '');
          final courseId = int.tryParse(courseIdStr);
          if (courseId != null) {
            final course = await CourseDao().getById(courseId);
            if (course != null) {
              classifiedAdded += (course.credits ?? 0.0);
            }
          }
        }
      }

      final totalAdded = manualAdded + classifiedAdded;

      setState(() {
        _cgpaSummary = cgpa;
        _totalCreditsRequired = totalRequired;
        _totalAddedCredits = totalAdded;
        _curriculums = curriculums;
        _baskets = baskets;
        _semesters = semesters;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.e('AcademicPerformance', 'Failed to load data', e, stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load academic data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Academic Performance',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: theme.primary),
            onPressed: _showAddCoursesDialog,
            tooltip: 'Add Courses to Categories',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.muted),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 14, color: theme.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cgpaSummary == null) {
      return Center(
        child: Text(
          'No academic data available',
          style: TextStyle(fontSize: 14, color: theme.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: theme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CGPAOverviewCard(
              cgpaSummary: _cgpaSummary!,
              totalCreditsRequired: _totalCreditsRequired,
              totalAddedCredits: _totalAddedCredits,
            ),
            const SizedBox(height: 16),
            GradeDistributionChart(cgpaSummary: _cgpaSummary!),
            const SizedBox(height: 24),
            if (_semesters.isNotEmpty) ...[
              _buildSectionTitle(theme, 'Semester Performance'),
              const SizedBox(height: 12),
              ..._semesters.map(
                (semester) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SemesterGpaCard(semester: semester),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_curriculums.isNotEmpty) ...[
              _buildSectionTitle(theme, 'Curriculum Details'),
              const SizedBox(height: 12),
              ..._curriculums.map(
                (curriculum) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CurriculumProgressCard(curriculum: curriculum),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  '* Not counted in CGPA',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_baskets.isNotEmpty) ...[
              _buildSectionTitle(theme, 'Basket Details'),
              const SizedBox(height: 12),
              ..._baskets.map(
                (basket) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BasketProgressCard(basket: basket),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(dynamic theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.text,
      ),
    );
  }

  void _showAddCoursesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _AddCoursesPage(
              curriculums: _curriculums,
              baskets: _baskets,
              onSave: _loadData,
            ),
      ),
    );
  }
}

/// Add Courses to Categories Page
class _AddCoursesPage extends StatefulWidget {
  final List<CurriculumWithProgress> curriculums;
  final List<BasketWithProgress> baskets;
  final VoidCallback onSave;

  const _AddCoursesPage({
    required this.curriculums,
    required this.baskets,
    required this.onSave,
  });

  @override
  State<_AddCoursesPage> createState() => _AddCoursesPageState();
}

class _AddCoursesPageState extends State<_AddCoursesPage> {
  final CourseDao _courseDao = CourseDao();
  List<Map<String, dynamic>> _currentSemesterCourses = [];
  List<Map<String, dynamic>> _manualCourses = [];
  bool _isLoading = true;

  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  String? _selectedCurriculum;
  String? _selectedBasket;

  Map<String, Map<String, String?>> _classifications = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _courseTitleController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadCurrentSemesterCourses();
    await _loadManualCourses();
    await _loadClassifications();
  }

  Future<void> _loadCurrentSemesterCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';

      final List<dynamic> semesters = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

      if (semesters.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final currentSemesterName = semesters.first.toString();
      final currentSemesterId =
          semesterMap[currentSemesterName]?.toString() ?? '';

      if (currentSemesterId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      var courses = await _courseDao.getBySemester(currentSemesterId);

      if (courses.isEmpty) {
        final allCoursesMap = await _courseDao.getAllCourses();
        courses = allCoursesMap.map((map) => Course.fromMap(map)).toList();
      }

      setState(() {
        _currentSemesterCourses =
            courses.map((course) {
              return {
                'id': 'course_${course.id}',
                'actualId': course.id,
                'code': course.code ?? 'N/A',
                'title': course.title ?? 'Unknown Course',
                'credits': course.credits ?? 0,
                'type': course.type ?? 'Unknown',
              };
            }).toList();
      });
    } catch (e, stackTrace) {
      Logger.e('AddCourses', 'Failed to load courses', e, stackTrace);
    }
  }

  Future<void> _loadManualCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manualCoursesJson = prefs.getString('manual_courses') ?? '[]';
      final List<dynamic> manualCoursesList = jsonDecode(manualCoursesJson);

      setState(() {
        _manualCourses = manualCoursesList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      Logger.e('AddCourses', 'Failed to load manual courses', e);
    }
  }

  Future<void> _loadClassifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classificationsJson =
          prefs.getString('course_classifications') ?? '{}';
      final Map<String, dynamic> classificationsData = jsonDecode(
        classificationsJson,
      );

      setState(() {
        _classifications = classificationsData.map(
          (key, value) => MapEntry(
            key,
            (value as Map<String, dynamic>).cast<String, String?>(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      Logger.e('AddCourses', 'Failed to load classifications', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveClassifications() async {
    try {
      // Clean up classifications - remove entries where both curriculum and basket are null
      final cleanedClassifications = <String, Map<String, String?>>{};
      for (final entry in _classifications.entries) {
        final curriculum = entry.value['curriculum'];
        final basket = entry.value['basket'];
        // Only keep classifications where at least one category is set
        if (curriculum != null || basket != null) {
          cleanedClassifications[entry.key] = entry.value;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'course_classifications',
        jsonEncode(cleanedClassifications),
      );

      if (mounted) {
        SnackbarUtils.success(
          context,
          'Course classifications saved successfully',
        );
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Logger.e('AddCourses', 'Failed to save classifications', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to save classifications');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Add Courses to Categories',
          style: TextStyle(color: theme.text, fontSize: 18),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
        actions: [
          TextButton(
            onPressed: _saveClassifications,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• Assign courses to curriculum and basket categories',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.text,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '• Credits: earned + added / total (e.g., 79 + 3 / 151)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.text,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '• Percentage: main + added (e.g., 52% + 2.3%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.text,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Current Semester Courses (${_currentSemesterCourses.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentSemesterCourses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No current semester courses found',
                            style: TextStyle(color: theme.muted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._currentSemesterCourses.map(
                        (course) =>
                            _buildCourseClassificationTile(theme, course),
                      ),
                    const SizedBox(height: 24),
                    if (_manualCourses.isNotEmpty) ...[
                      Text(
                        'Saved Manual Courses (${_manualCourses.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._manualCourses.map(
                        (course) => _buildSavedManualCourseTile(theme, course),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Add Manual Course (NPTEL, Certifications, etc.)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManualCourseForm(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildCourseClassificationTile(
    dynamic theme,
    Map<String, dynamic> course,
  ) {
    final courseId = course['id'] as String;
    final classification = _classifications[courseId] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['code'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      course['title'] ?? '',
                      style: TextStyle(fontSize: 11, color: theme.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${course['credits']} cr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown(
                  theme,
                  'Curriculum',
                  classification['curriculum'],
                  widget.curriculums.map((c) => c.distributionType).toList(),
                  (value) {
                    setState(() {
                      _classifications[courseId] = {
                        'curriculum': value,
                        'basket': classification['basket'],
                      };
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown(
                  theme,
                  'Basket',
                  classification['basket'],
                  widget.baskets.map((b) => b.basketTitle).toList(),
                  (value) {
                    setState(() {
                      _classifications[courseId] = {
                        'curriculum': classification['curriculum'],
                        'basket': value,
                      };
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedManualCourseTile(
    dynamic theme,
    Map<String, dynamic> course,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${course['credits']} cr',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.primary,
                        ),
                      ),
                    ),
                    if (course['curriculum'] != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          course['curriculum'],
                          style: TextStyle(fontSize: 10, color: theme.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Course'),
                      content: Text('Delete "${course['title']}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                setState(() {
                  _manualCourses.remove(course);
                });

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'manual_courses',
                  jsonEncode(_manualCourses),
                );

                if (mounted) {
                  SnackbarUtils.info(context, 'Course deleted');
                }

                // Refresh parent page to update totals
                widget.onSave();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown(
    dynamic theme,
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: theme.muted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.border),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              'Select',
              style: TextStyle(fontSize: 11, color: theme.muted),
            ),
            style: TextStyle(fontSize: 11, color: theme.text),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('None', style: TextStyle(fontSize: 11)),
              ),
              ...items.map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildManualCourseForm(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _courseTitleController,
            decoration: InputDecoration(
              labelText: 'Course Title',
              labelStyle: TextStyle(fontSize: 12, color: theme.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            style: TextStyle(fontSize: 13, color: theme.text),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _creditsController,
            decoration: InputDecoration(
              labelText: 'Credits',
              labelStyle: TextStyle(fontSize: 12, color: theme.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 13, color: theme.text),
          ),
          const SizedBox(height: 10),
          _buildCompactDropdown(
            theme,
            'Assign to Curriculum',
            _selectedCurriculum,
            widget.curriculums.map((c) => c.distributionType).toList(),
            (value) => setState(() => _selectedCurriculum = value),
          ),
          const SizedBox(height: 10),
          _buildCompactDropdown(
            theme,
            'Assign to Basket',
            _selectedBasket,
            widget.baskets.map((b) => b.basketTitle).toList(),
            (value) => setState(() => _selectedBasket = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_courseTitleController.text.trim().isEmpty) {
                  SnackbarUtils.warning(context, 'Please enter course title');
                  return;
                }

                if (_creditsController.text.trim().isEmpty) {
                  SnackbarUtils.warning(context, 'Please enter credits');
                  return;
                }

                final credits = double.tryParse(_creditsController.text.trim());
                if (credits == null || credits <= 0) {
                  SnackbarUtils.warning(context, 'Please enter valid credits');
                  return;
                }

                final manualCourse = {
                  'id': 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  'title': _courseTitleController.text.trim(),
                  'credits': credits,
                  'curriculum': _selectedCurriculum,
                  'basket': _selectedBasket,
                };

                _manualCourses.add(manualCourse);

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'manual_courses',
                  jsonEncode(_manualCourses),
                );

                if (mounted) {
                  SnackbarUtils.success(context, 'Course added successfully');
                }

                _courseTitleController.clear();
                _creditsController.clear();
                setState(() {
                  _selectedCurriculum = null;
                  _selectedBasket = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Add Course', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
