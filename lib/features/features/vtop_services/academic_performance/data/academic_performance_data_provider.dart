import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/database/database.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../../../../../core/database/entities/course.dart';
import '../../../../../core/database/daos/curriculum_progress_dao.dart';
import '../../../../../core/database/daos/basket_progress_dao.dart';
import '../../../../../core/database/entities/cgpa_summary.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../models/curriculum_with_progress.dart';
import '../models/basket_with_progress.dart';
import '../models/semester_performance.dart';

/// Data provider for Academic Performance feature
/// Fetches academic data from database and SharedPreferences
class AcademicPerformanceDataProvider {
  final CurriculumProgressDao _curriculumDao;
  final BasketProgressDao _basketDao;

  AcademicPerformanceDataProvider()
    : _curriculumDao = CurriculumProgressDao(),
      _basketDao = BasketProgressDao();

  /// Get CGPA summary from SharedPreferences
  Future<CGPASummary> getCGPASummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cgpaJson = prefs.getString('cgpa_summary');

      if (cgpaJson == null || cgpaJson.isEmpty) {
        Logger.w(
          'AcademicPerformance',
          'No CGPA summary found in SharedPreferences',
        );
        return CGPASummary.empty();
      }

      final data = jsonDecode(cgpaJson) as Map<String, dynamic>;
      return CGPASummary.fromJson(data);
    } catch (e) {
      Logger.e('AcademicPerformance', 'Failed to load CGPA summary', e);
      return CGPASummary.empty();
    }
  }

  /// Get student profile from SharedPreferences
  Future<StudentProfile> getStudentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        Logger.w(
          'AcademicPerformance',
          'No student profile found in SharedPreferences',
        );
        return StudentProfile.empty();
      }

      final data = jsonDecode(profileJson) as Map<String, dynamic>;
      return StudentProfile.fromJson(data);
    } catch (e) {
      Logger.e('AcademicPerformance', 'Failed to load student profile', e);
      return StudentProfile.empty();
    }
  }

  /// Get curriculum progress
  /// Preserves database insertion order (matches VTOP official order)
  Future<List<CurriculumWithProgress>> getCurriculumWithProgress() async {
    try {
      // Get base curriculum data - NO SORTING, preserves database order
      final curriculums = await _curriculumDao.getAll();

      if (curriculums.isEmpty) {
        Logger.w('AcademicPerformance', 'No curriculum progress data found');
        return [];
      }

      // Load manual courses and course classifications from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final manualCoursesJson = prefs.getString('manual_courses') ?? '[]';
      final List<dynamic> manualCourses = jsonDecode(manualCoursesJson);
      final classificationsJson =
          prefs.getString('course_classifications') ?? '{}';
      final Map<String, dynamic> classifications = jsonDecode(
        classificationsJson,
      );

      // Get all current semester courses from DB
      final courseDao = CourseDao();
      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';
      final List<dynamic> semesters = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);
      String currentSemesterId = '';
      if (semesters.isNotEmpty) {
        final currentSemesterName = semesters.first.toString();
        currentSemesterId = semesterMap[currentSemesterName]?.toString() ?? '';
      }
      List<Course> currentSemesterCourses = [];
      if (currentSemesterId.isNotEmpty) {
        currentSemesterCourses = await courseDao.getBySemester(
          currentSemesterId,
        );
      }

      // Calculate added credits per curriculum (manual + classified current semester)
      final Map<String, double> addedCreditsMap = {};
      // Manual courses
      for (final course in manualCourses) {
        final curriculum = course['curriculum'] as String?;
        if (curriculum != null) {
          addedCreditsMap[curriculum] =
              (addedCreditsMap[curriculum] ?? 0.0) +
              ((course['credits'] as num?)?.toDouble() ?? 0.0);
        }
      }
      // Classified current semester courses (fetch credits from DB for each classified course)
      for (final entry in classifications.entries) {
        final key = entry.key;
        final classification = entry.value;
        if (key.startsWith('course_') && classification['curriculum'] != null) {
          final courseIdStr = key.replaceFirst('course_', '');
          final courseId = int.tryParse(courseIdStr);
          if (courseId != null) {
            final course = await courseDao.getById(courseId);
            if (course != null) {
              final curriculum = classification['curriculum'];
              addedCreditsMap[curriculum] =
                  (addedCreditsMap[curriculum] ?? 0.0) +
                  (course.credits ?? 0.0);
            }
          }
        }
      }

      // Convert with manual + classified course credits
      final result =
          curriculums
              .map(
                (curriculum) => CurriculumWithProgress.fromBase(
                  base: curriculum,
                  earned: curriculum.creditsEarned,
                  inProgress:
                      addedCreditsMap[curriculum.distributionType] ?? 0.0,
                ),
              )
              .toList();

      return result;
    } catch (e) {
      Logger.e('AcademicPerformance', 'Failed to load curriculum progress', e);
      return [];
    }
  }

  /// Get basket progress
  /// Preserves database insertion order (matches VTOP official order)
  Future<List<BasketWithProgress>> getBasketWithProgress() async {
    try {
      // Get base basket data - NO SORTING, preserves database order
      final baskets = await _basketDao.getAll();

      if (baskets.isEmpty) {
        Logger.w('AcademicPerformance', 'No basket progress data found');
        return [];
      }

      // Load manual courses and course classifications from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final manualCoursesJson = prefs.getString('manual_courses') ?? '[]';
      final List<dynamic> manualCourses = jsonDecode(manualCoursesJson);
      final classificationsJson =
          prefs.getString('course_classifications') ?? '{}';
      final Map<String, dynamic> classifications = jsonDecode(
        classificationsJson,
      );

      // Get all current semester courses from DB
      final courseDao = CourseDao();
      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';
      final List<dynamic> semesters = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);
      String currentSemesterId = '';
      if (semesters.isNotEmpty) {
        final currentSemesterName = semesters.first.toString();
        currentSemesterId = semesterMap[currentSemesterName]?.toString() ?? '';
      }
      List<Course> currentSemesterCourses = [];
      if (currentSemesterId.isNotEmpty) {
        currentSemesterCourses = await courseDao.getBySemester(
          currentSemesterId,
        );
      }

      // Calculate added credits per basket (manual + classified current semester)
      final Map<String, double> addedCreditsMap = {};
      // Manual courses
      for (final course in manualCourses) {
        final basket = course['basket'] as String?;
        if (basket != null) {
          addedCreditsMap[basket] =
              (addedCreditsMap[basket] ?? 0.0) +
              ((course['credits'] as num?)?.toDouble() ?? 0.0);
        }
      }
      // Classified current semester courses (fetch credits from DB for each classified course)
      for (final entry in classifications.entries) {
        final key = entry.key;
        final classification = entry.value;
        if (key.startsWith('course_') && classification['basket'] != null) {
          final courseIdStr = key.replaceFirst('course_', '');
          final courseId = int.tryParse(courseIdStr);
          if (courseId != null) {
            final course = await courseDao.getById(courseId);
            if (course != null) {
              final basket = classification['basket'];
              addedCreditsMap[basket] =
                  (addedCreditsMap[basket] ?? 0.0) + (course.credits ?? 0.0);
            }
          }
        }
      }

      // Convert with manual + classified course credits
      final result =
          baskets
              .map(
                (basket) => BasketWithProgress.fromBase(
                  base: basket,
                  earned: basket.creditsEarned,
                  inProgress: addedCreditsMap[basket.basketTitle] ?? 0.0,
                ),
              )
              .toList();

      return result;
    } catch (e) {
      Logger.e('AcademicPerformance', 'Failed to load basket progress', e);
      return [];
    }
  }

  /// Get semester-wise performance
  /// Uses semester order from SharedPreferences (preserved from Auth login)
  Future<List<SemesterPerformance>> getSemesterPerformances() async {
    try {
      // Get semester order from SharedPreferences (saved during login)
      final prefs = await SharedPreferences.getInstance();
      final semesterListJson = prefs.getString(
        'available_semesters',
      ); // Correct key from auth_service

      List<String> semesterOrder = [];
      if (semesterListJson != null && semesterListJson.isNotEmpty) {
        try {
          final List<dynamic> semesterList = jsonDecode(semesterListJson);
          semesterOrder = semesterList.cast<String>();
        } catch (e) {
          Logger.w('AcademicPerformance', 'Failed to parse semester list');
        }
      }

      final db = await VitConnectDatabase.instance.database;

      // Group cumulative marks by semester (no ORDER BY to preserve DB order)
      final result = await db.rawQuery('''
        SELECT 
          semester_id,
          semester_name,
          semester_gpa,
          COUNT(*) as course_count,
          SUM(credits) as total_credits,
          GROUP_CONCAT(grade) as grades
        FROM cumulative_marks
        GROUP BY semester_id
      ''');

      final performanceMap = <String, SemesterPerformance>{};

      for (final row in result) {
        final semesterId = row['semester_id'] as String? ?? '';
        final semesterName = row['semester_name'] as String? ?? '';
        final gradesString = row['grades'] as String? ?? '';
        final grades = gradesString.split(',');

        performanceMap[semesterName] = SemesterPerformance(
          semesterId: semesterId,
          semesterName: semesterName,
          semesterGpa: (row['semester_gpa'] as num?)?.toDouble() ?? 0.0,
          courseCount: row['course_count'] as int? ?? 0,
          creditsEarned: (row['total_credits'] as num?)?.toDouble() ?? 0.0,
          grades: grades,
        );
      }

      // Sort by semester order from SharedPreferences (preserves auth extraction order)
      final performances = <SemesterPerformance>[];
      if (semesterOrder.isNotEmpty) {
        for (final semesterName in semesterOrder) {
          if (performanceMap.containsKey(semesterName)) {
            performances.add(performanceMap[semesterName]!);
          }
        }
      } else {
        // Fallback: use DB order
        performances.addAll(performanceMap.values);
      }

      return performances;
    } catch (e) {
      Logger.e('AcademicPerformance', 'Failed to load semester data', e);
      return [];
    }
  }

  /// Get overall degree completion percentage
  Future<double> getDegreeCompletionPercentage() async {
    try {
      final cgpa = await getCGPASummary();
      if (cgpa.creditsRegistered == 0) return 0.0;
      return (cgpa.creditsEarned / cgpa.creditsRegistered) * 100;
    } catch (e) {
      Logger.e(
        'AcademicPerformance',
        'Failed to calculate degree completion',
        e,
      );
      return 0.0;
    }
  }
}
