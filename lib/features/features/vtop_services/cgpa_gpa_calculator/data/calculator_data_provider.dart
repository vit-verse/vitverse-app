import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/database/entities/cgpa_summary.dart';
import '../../../../../core/database/entities/course.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../../../../../core/utils/logger.dart';
import '../models/calculator_state.dart';

/// Data Provider for CGPA/GPA Calculator
/// Fetches academic data from database and SharedPreferences
class CalculatorDataProvider {
  static const String _tag = 'CalculatorDataProvider';
  final CourseDao _courseDao = CourseDao();

  /// Load calculator state with all required data
  Future<CalculatorState> loadCalculatorState() async {
    try {
      Logger.d(_tag, 'Loading calculator state...');

      // Get CGPA summary from SharedPreferences
      final cgpaSummary = await _getCGPASummary();

      // Get total program credits from SharedPreferences
      final totalCredits = await _getTotalProgramCredits();

      // Get current semester credits and courses
      final currentSemData = await _getCurrentSemesterData();

      final state = CalculatorState(
        currentCGPA: cgpaSummary.cgpa,
        completedCredits: cgpaSummary.creditsEarned,
        currentSemCredits: currentSemData['credits'] as double,
        totalProgramCredits: totalCredits,
        currentCourses: currentSemData['courses'] as List<CourseGrade>,
      );

      Logger.i(
        _tag,
        'Calculator state loaded: CGPA=${state.currentCGPA}, Completed=${state.completedCredits}, Current=${state.currentSemCredits}, Total=${state.totalProgramCredits}',
      );

      return state;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load calculator state', e, stackTrace);
      return CalculatorState.empty();
    }
  }

  /// Get CGPA summary from SharedPreferences
  Future<CGPASummary> _getCGPASummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cgpaJson = prefs.getString('cgpa_summary');

      if (cgpaJson == null || cgpaJson.isEmpty) {
        Logger.w(_tag, 'No CGPA summary found in SharedPreferences');
        return CGPASummary.empty();
      }

      final data = jsonDecode(cgpaJson) as Map<String, dynamic>;
      return CGPASummary.fromJson(data);
    } catch (e) {
      Logger.e(_tag, 'Failed to load CGPA summary', e);
      return CGPASummary.empty();
    }
  }

  /// Get total program credits from SharedPreferences
  Future<double> _getTotalProgramCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalCredits = prefs.getDouble('total_credits_required') ?? 151.0;
      Logger.d(_tag, 'Total program credits: $totalCredits');
      return totalCredits;
    } catch (e) {
      Logger.e(_tag, 'Failed to load total credits', e);
      return 151.0; // Default total
    }
  }

  /// Get current semester data (credits and courses)
  Future<Map<String, dynamic>> _getCurrentSemesterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First, try to get graded courses from current_semester_grades
      final gradedCoursesJson =
          prefs.getString('current_semester_grades') ?? '[]';
      final List<dynamic> gradedCoursesList = jsonDecode(gradedCoursesJson);

      if (gradedCoursesList.isNotEmpty) {
        // User has assigned grades to current semester courses
        final courseGrades =
            gradedCoursesList.map((courseData) {
              return CourseGrade(
                courseCode: courseData['code'] as String? ?? 'N/A',
                courseTitle: courseData['title'] as String? ?? 'Unknown',
                credits: (courseData['credits'] as num?)?.toDouble() ?? 0.0,
                grade: courseData['grade'] as String?,
              );
            }).toList();

        final totalCredits = courseGrades.fold<double>(
          0.0,
          (sum, course) => sum + course.credits,
        );

        Logger.d(
          _tag,
          'Loaded ${courseGrades.length} graded courses with $totalCredits credits',
        );

        return {'credits': totalCredits, 'courses': courseGrades};
      }

      // Fallback: Get courses from database (no grades assigned yet)
      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';
      final List<dynamic> semesters = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

      if (semesters.isEmpty) {
        Logger.w(_tag, 'No current semester found');
        return {'credits': 0.0, 'courses': <CourseGrade>[]};
      }

      final currentSemesterName = semesters.first.toString();
      final currentSemesterId =
          semesterMap[currentSemesterName]?.toString() ?? '';

      if (currentSemesterId.isEmpty) {
        Logger.w(_tag, 'Current semester ID not found');
        return {'credits': 0.0, 'courses': <CourseGrade>[]};
      }

      // Fetch courses from database
      final courses = await _courseDao.getBySemester(currentSemesterId);

      if (courses.isEmpty) {
        Logger.w(_tag, 'No courses found for current semester');
        return {'credits': 0.0, 'courses': <CourseGrade>[]};
      }

      // Convert to CourseGrade objects
      final courseGrades =
          courses.map((course) {
            return CourseGrade(
              courseCode: course.code ?? 'N/A',
              courseTitle: course.title ?? 'Unknown',
              credits: course.credits ?? 0.0,
              grade: null, // Current semester courses don't have grades yet
            );
          }).toList();

      // Calculate total credits
      final totalCredits = courses.fold<double>(
        0.0,
        (sum, course) => sum + (course.credits ?? 0.0),
      );

      Logger.d(
        _tag,
        'Current semester: $currentSemesterName, Courses: ${courses.length}, Credits: $totalCredits',
      );

      return {'credits': totalCredits, 'courses': courseGrades};
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load current semester data', e, stackTrace);
      return {'credits': 0.0, 'courses': <CourseGrade>[]};
    }
  }

  /// Get all semester courses (for summary tab)
  Future<List<Course>> getAllSemesterCourses(String semesterId) async {
    try {
      if (semesterId.isEmpty) return [];

      final courses = await _courseDao.getBySemester(semesterId);
      Logger.d(
        _tag,
        'Loaded ${courses.length} courses for semester: $semesterId',
      );
      return courses;
    } catch (e) {
      Logger.e(_tag, 'Failed to load semester courses', e);
      return [];
    }
  }

  /// Get available semesters
  Future<List<String>> getAvailableSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semestersJson = prefs.getString('available_semesters') ?? '[]';
      final List<dynamic> semesters = jsonDecode(semestersJson);
      final semesterNames = semesters.map((s) => s.toString()).toList();
      Logger.d(_tag, 'Available semesters: $semesterNames');
      return semesterNames;
    } catch (e) {
      Logger.e(_tag, 'Failed to load available semesters', e);
      return [];
    }
  }

  /// Get semester ID for semester name
  Future<String> getSemesterId(String semesterName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semesterMapJson = prefs.getString('semester_map') ?? '{}';
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);
      final semesterId = semesterMap[semesterName]?.toString() ?? '';
      Logger.d(_tag, 'Semester ID for $semesterName: $semesterId');
      return semesterId;
    } catch (e) {
      Logger.e(_tag, 'Failed to get semester ID', e);
      return '';
    }
  }

  /// Check if data is available
  Future<bool> hasData() async {
    final cgpaSummary = await _getCGPASummary();
    return cgpaSummary.cgpa > 0.0;
  }

  /// Get grade distribution from CGPA summary
  Future<Map<String, int>> getGradeDistribution() async {
    try {
      final cgpaSummary = await _getCGPASummary();

      return {
        'S': cgpaSummary.sGrades,
        'A': cgpaSummary.aGrades,
        'B': cgpaSummary.bGrades,
        'C': cgpaSummary.cGrades,
        'D': cgpaSummary.dGrades,
        'E': cgpaSummary.eGrades,
        'F': cgpaSummary.fGrades,
        'N': cgpaSummary.nGrades,
      };
    } catch (e) {
      Logger.e(_tag, 'Failed to get grade distribution', e);
      return {};
    }
  }
}
