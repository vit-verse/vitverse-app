import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../../../../../core/database/entities/course.dart';
import '../models/grade_info.dart';

class AddCoursesPage extends StatefulWidget {
  final VoidCallback onCoursesUpdated;

  const AddCoursesPage({super.key, required this.onCoursesUpdated});

  @override
  State<AddCoursesPage> createState() => _AddCoursesPageState();
}

class _AddCoursesPageState extends State<AddCoursesPage>
    with SingleTickerProviderStateMixin {
  final CourseDao _courseDao = CourseDao();
  final TextEditingController _manualCourseNameController =
      TextEditingController();
  final TextEditingController _manualCreditsController =
      TextEditingController();

  List<Course> _currentSemesterCourses = [];
  List<Map<String, dynamic>> _manualCourses = [];
  Map<String, String> _courseGrades = {}; // courseId -> grade
  Map<String, String> _manualGrades = {}; // index -> grade
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedManualGrade = 'S'; // Default grade for manual entry

  final List<String> _availableGrades = ['S', 'A', 'B', 'C', 'D', 'E', 'F'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCourseNameController.dispose();
    _manualCreditsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadCurrentSemesterCourses();
    await _loadSavedGrades();
    await _loadManualCourses();
  }

  Future<void> _loadCurrentSemesterCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';
      final List<dynamic> semesters = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

      if (semesters.isNotEmpty) {
        final currentSemesterName = semesters.first.toString();
        final currentSemesterId =
            semesterMap[currentSemesterName]?.toString() ?? '';

        if (currentSemesterId.isNotEmpty) {
          // Try to get courses by semester first
          var courses = await _courseDao.getBySemester(currentSemesterId);

          // If no courses found for semester, get all courses (fallback like Academic Performance)
          if (courses.isEmpty) {
            Logger.d(
              'AddCourses',
              'No courses found for semester ID, loading all courses',
            );
            final allCoursesMap = await _courseDao.getAllCourses();
            courses = allCoursesMap.map((map) => Course.fromMap(map)).toList();
          }

          setState(() {
            _currentSemesterCourses = courses;
          });
          Logger.d(
            'AddCourses',
            'Loaded ${courses.length} courses for semester: $currentSemesterName',
          );
        }
      }
    } catch (e) {
      Logger.e('AddCourses', 'Failed to load current semester courses', e);
    }
  }

  Future<void> _loadSavedGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gradesJson = prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> savedGrades = jsonDecode(gradesJson);

      final Map<String, String> grades = {};
      for (var gradeData in savedGrades) {
        if (gradeData['isManual'] != true) {
          final courseId = gradeData['courseId']?.toString();
          final grade = gradeData['grade']?.toString();
          if (courseId != null && grade != null) {
            grades[courseId] = grade;
          }
        }
      }

      setState(() {
        _courseGrades = grades;
      });

      Logger.d('AddCourses', 'Loaded ${grades.length} saved grade assignments');
    } catch (e) {
      Logger.e('AddCourses', 'Failed to load saved grades', e);
    }
  }

  Future<void> _loadManualCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gradesJson = prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> savedGrades = jsonDecode(gradesJson);

      final List<Map<String, dynamic>> manualCourses = [];
      final Map<String, String> manualGrades = {};

      for (var gradeData in savedGrades) {
        if (gradeData['isManual'] == true) {
          manualCourses.add({
            'title': gradeData['title'],
            'credits': gradeData['credits'],
          });
          manualGrades[manualCourses.length.toString()] =
              gradeData['grade']?.toString() ?? 'S';
        }
      }

      setState(() {
        _manualCourses = manualCourses;
        _manualGrades = manualGrades;
        _isLoading = false;
      });

      Logger.d('AddCourses', 'Loaded ${manualCourses.length} manual courses');
    } catch (e) {
      Logger.e('AddCourses', 'Failed to load manual courses', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> allGrades = [];

      // Add semester courses with grades
      for (var course in _currentSemesterCourses) {
        final grade = _courseGrades[course.id.toString()];
        if (grade != null) {
          allGrades.add({
            'courseId': course.id,
            'code': course.code ?? 'N/A',
            'title': course.title ?? 'Unknown',
            'credits': course.credits ?? 0.0,
            'grade': grade,
            'isManual': false,
          });
        }
      }

      // Add manual courses with grades
      for (int i = 0; i < _manualCourses.length; i++) {
        final course = _manualCourses[i];
        final grade = _manualGrades[(i + 1).toString()] ?? 'S';
        allGrades.add({
          'title': course['title'],
          'credits': course['credits'],
          'grade': grade,
          'isManual': true,
        });
      }

      await prefs.setString('current_semester_grades', jsonEncode(allGrades));

      Logger.i('AddCourses', 'Saved ${allGrades.length} course grades');

      if (mounted) {
        SnackbarUtils.success(
          context,
          'Updated ${allGrades.length} courses successfully!',
        );

        // Notify parent to refresh
        widget.onCoursesUpdated();

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.e('AddCourses', 'Failed to save grades', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to save courses');
      }
    }
  }

  void _addManualCourse() {
    if (_manualCourseNameController.text.isEmpty ||
        _manualCreditsController.text.isEmpty) {
      SnackbarUtils.warning(context, 'Please fill all fields');
      return;
    }

    final credits = double.tryParse(_manualCreditsController.text);
    if (credits == null || credits <= 0) {
      SnackbarUtils.error(context, 'Invalid credits');
      return;
    }

    setState(() {
      _manualCourses.add({
        'title': _manualCourseNameController.text,
        'credits': credits,
      });
      _manualGrades[_manualCourses.length.toString()] = _selectedManualGrade;
      _manualCourseNameController.clear();
      _manualCreditsController.clear();
      _selectedManualGrade = 'S'; // Reset to default
    });
  }

  void _removeManualCourse(int index) {
    setState(() {
      _manualCourses.removeAt(index);
      // Rebuild manual grades map
      final newManualGrades = <String, String>{};
      for (int i = 0; i < _manualCourses.length; i++) {
        final oldKey = (i + 1).toString();
        if (i < index) {
          newManualGrades[oldKey] = _manualGrades[oldKey] ?? 'S';
        } else {
          final nextKey = (i + 2).toString();
          newManualGrades[oldKey] = _manualGrades[nextKey] ?? 'S';
        }
      }
      _manualGrades = newManualGrades;
    });
  }

  int get _totalSelectedCourses {
    return _courseGrades.length + _manualCourses.length;
  }

  double get _totalSelectedCredits {
    double credits = 0.0;
    for (var course in _currentSemesterCourses) {
      if (_courseGrades.containsKey(course.id.toString())) {
        credits += course.credits ?? 0.0;
      }
    }
    for (var course in _manualCourses) {
      credits += course['credits'] as double;
    }
    return credits;
  }

  // Calculate expected GPA based on selected courses and grades
  double get _calculatedExpectedGPA {
    double totalWeightedPoints = 0.0;
    double totalCredits = 0.0;

    // Add semester courses
    for (var course in _currentSemesterCourses) {
      final courseId = course.id.toString();
      if (_courseGrades.containsKey(courseId)) {
        final grade = _courseGrades[courseId]!;
        final gradePoint = GradeInfo.getGradePoint(grade);
        final credits = course.credits ?? 0.0;
        totalWeightedPoints += credits * gradePoint;
        totalCredits += credits;
      }
    }

    // Add manual courses
    for (int i = 0; i < _manualCourses.length; i++) {
      final course = _manualCourses[i];
      final gradeKey = (i + 1).toString();
      final grade = _manualGrades[gradeKey] ?? 'S';
      final gradePoint = GradeInfo.getGradePoint(grade);
      final credits = course['credits'] as double;
      totalWeightedPoints += credits * gradePoint;
      totalCredits += credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedPoints / totalCredits;
  }

  // Get detailed breakdown of credit points
  List<Map<String, dynamic>> get _detailedBreakdown {
    List<Map<String, dynamic>> breakdown = [];

    // Add semester courses
    for (var course in _currentSemesterCourses) {
      final courseId = course.id.toString();
      if (_courseGrades.containsKey(courseId)) {
        final grade = _courseGrades[courseId]!;
        final gradePoint = GradeInfo.getGradePoint(grade);
        final credits = course.credits ?? 0.0;
        breakdown.add({
          'title': course.title ?? 'Unknown',
          'code': course.code ?? 'N/A',
          'credits': credits,
          'grade': grade,
          'gradePoint': gradePoint,
          'creditPoints': credits * gradePoint,
        });
      }
    }

    // Add manual courses
    for (int i = 0; i < _manualCourses.length; i++) {
      final course = _manualCourses[i];
      final gradeKey = (i + 1).toString();
      final grade = _manualGrades[gradeKey] ?? 'S';
      final gradePoint = GradeInfo.getGradePoint(grade);
      final credits = course['credits'] as double;
      breakdown.add({
        'title': course['title'],
        'code': 'Manual',
        'credits': credits,
        'grade': grade,
        'gradePoint': gradePoint,
        'creditPoints': credits * gradePoint,
      });
    }

    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Courses',
              style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_totalSelectedCourses > 0)
              Text(
                '$_totalSelectedCourses courses • ${_totalSelectedCredits.toStringAsFixed(1)} credits',
                style: TextStyle(fontSize: 12, color: theme.muted),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primary,
          labelColor: theme.primary,
          unselectedLabelColor: theme.muted,
          tabs: const [
            Tab(text: 'Current Semester'),
            Tab(text: 'Manual Entry'),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrentSemesterTab(theme),
                  _buildManualEntryTab(theme),
                ],
              ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildCurrentSemesterTab(dynamic theme) {
    if (_currentSemesterCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: theme.muted),
            const SizedBox(height: 16),
            Text(
              'No courses found for current semester',
              style: TextStyle(color: theme.muted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentSemesterCourses.length,
      itemBuilder: (context, index) {
        final course = _currentSemesterCourses[index];
        final courseId = course.id.toString();
        final isSelected = _courseGrades.containsKey(courseId);
        final selectedGrade = _courseGrades[courseId];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary.withValues(alpha: 0.1) : theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primary : theme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _courseGrades[courseId] = 'S';
                          } else {
                            _courseGrades.remove(courseId);
                          }
                        });
                      },
                      activeColor: theme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title ?? 'Unknown Course',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 14,
                                color: theme.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.code ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.school, size: 14, color: theme.muted),
                              const SizedBox(width: 4),
                              Text(
                                '${course.credits ?? 0} credits',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selectedGrade ?? 'S',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGrade ?? 'S',
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: theme.text),
                        style: TextStyle(color: theme.text, fontSize: 14),
                        dropdownColor: theme.surface,
                        items:
                            _availableGrades.map((grade) {
                              final gradePoint = GradeInfo.getGradePoint(grade);
                              return DropdownMenuItem(
                                value: grade,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Grade $grade',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${gradePoint.toStringAsFixed(0)} points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _courseGrades[courseId] = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualEntryTab(dynamic theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manual Entry Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Manual Course',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _manualCourseNameController,
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    labelText: 'Course Name',
                    labelStyle: TextStyle(color: theme.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _manualCreditsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: theme.text),
                        decoration: InputDecoration(
                          labelText: 'Credits',
                          labelStyle: TextStyle(color: theme.muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedManualGrade,
                        style: TextStyle(color: theme.text),
                        dropdownColor: theme.surface,
                        decoration: InputDecoration(
                          labelText: 'Grade',
                          labelStyle: TextStyle(color: theme.muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.primary),
                          ),
                        ),
                        items:
                            _availableGrades.map((grade) {
                              final gradePoint = GradeInfo.getGradePoint(grade);
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(
                                  '$grade (${gradePoint.toStringAsFixed(0)})',
                                  style: TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedManualGrade = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addManualCourse,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manual Courses List
          if (_manualCourses.isNotEmpty) ...[
            Text(
              'Manual Courses (${_manualCourses.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 12),
            ..._manualCourses.asMap().entries.map((entry) {
              final index = entry.key;
              final course = entry.value;
              final gradeKey = (index + 1).toString();
              final selectedGrade = _manualGrades[gradeKey] ?? 'S';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primary, width: 2),
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
                                course['title'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${course['credits']} credits',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.muted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Grade: $selectedGrade',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeManualCourse(index),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGrade,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: theme.text),
                          style: TextStyle(color: theme.text, fontSize: 14),
                          dropdownColor: theme.surface,
                          items:
                              _availableGrades.map((grade) {
                                final gradePoint = GradeInfo.getGradePoint(
                                  grade,
                                );
                                return DropdownMenuItem(
                                  value: grade,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$grade (${gradePoint.toStringAsFixed(0)})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withOpacity(
                                            0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          gradePoint.toStringAsFixed(0),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _manualGrades[gradeKey] = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(dynamic theme) {
    final expectedGPA = _calculatedExpectedGPA;
    final hasSelectedCourses = _totalSelectedCourses > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expected GPA Display (if courses selected)
            if (hasSelectedCourses) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expected GPA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          expectedGPA.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                          '$_totalSelectedCourses courses • ${_totalSelectedCredits.toStringAsFixed(1)} credits',
                          style: TextStyle(fontSize: 12, color: theme.muted),
                        ),
                        TextButton.icon(
                          onPressed: _showDetailedBreakdown,
                          icon: Icon(Icons.info_outline, size: 16),
                          label: Text('Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.primary,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Bottom Action Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_totalSelectedCourses courses selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        '${_totalSelectedCredits.toStringAsFixed(1)} total credits',
                        style: TextStyle(fontSize: 12, color: theme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _totalSelectedCourses > 0 ? _saveGrades : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: theme.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedBreakdown() {
    final breakdown = _detailedBreakdown;
    final expectedGPA = _calculatedExpectedGPA;
    final totalCredits = _totalSelectedCredits;
    final totalCreditPoints = breakdown.fold<double>(
      0.0,
      (sum, item) => sum + (item['creditPoints'] as double),
    );

    showDialog(
      context: context,
      builder: (context) {
        final theme = Provider.of<ThemeProvider>(context).currentTheme;
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Row(
            children: [
              Icon(Icons.calculate, color: theme.primary),
              const SizedBox(width: 12),
              Text(
                'GPA Calculation Details',
                style: TextStyle(color: theme.text, fontSize: 18),
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
                    border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Total Courses',
                        breakdown.length.toString(),
                        theme,
                      ),
                      const SizedBox(height: 4),
                      _buildSummaryRow(
                        'Total Credits',
                        totalCredits.toStringAsFixed(1),
                        theme,
                      ),
                      const SizedBox(height: 4),
                      _buildSummaryRow(
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
                            expectedGPA.toStringAsFixed(2),
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
                // Formula Explanation
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
                          Icon(Icons.functions, size: 16, color: theme.muted),
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
                        'GPA = $totalCreditPoints / $totalCredits = ${expectedGPA.toStringAsFixed(2)}',
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
                // Course-wise breakdown
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
                          style: TextStyle(fontSize: 11, color: theme.muted),
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
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, dynamic theme) {
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
}
