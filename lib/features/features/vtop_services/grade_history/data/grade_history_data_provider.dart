import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/database/database.dart';
import '../../../../../core/database/daos/cumulative_mark_dao.dart';
import '../../../../../core/database/entities/cumulative_mark.dart';
import '../../../../../core/utils/logger.dart';

/// Data provider for grade history
/// Fetches cumulative marks (grades) from local database
/// Uses semester order from SharedPreferences (set during login)
class GradeHistoryDataProvider {
  /// Get all grades grouped by semester
  Future<Map<String, List<CumulativeMark>>> getGradesBySemester() async {
    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final cumulativeMarkDao = CumulativeMarkDao(database);

      // Get all cumulative marks
      final allGrades = await cumulativeMarkDao.getAll();

      if (allGrades.isEmpty) {
        Logger.d('GradeHistoryDataProvider', 'No grades found in database');
        return {};
      }

      // Group grades by semester
      final gradesBySemester = <String, List<CumulativeMark>>{};
      for (var grade in allGrades) {
        final semesterName = grade.semesterName;
        if (!gradesBySemester.containsKey(semesterName)) {
          gradesBySemester[semesterName] = [];
        }
        gradesBySemester[semesterName]!.add(grade);
      }

      // Sort courses within each semester by course code
      gradesBySemester.forEach((key, value) {
        value.sort((a, b) => a.courseCode.compareTo(b.courseCode));
      });

      Logger.success(
        'GradeHistoryDataProvider',
        'Loaded grades for ${gradesBySemester.length} semesters with ${allGrades.length} total courses',
      );

      return gradesBySemester;
    } catch (e) {
      Logger.e('GradeHistoryDataProvider', 'Failed to load grade history', e);
      rethrow;
    }
  }

  /// Get grades for a specific semester
  Future<List<CumulativeMark>> getGradesForSemester(String semesterId) async {
    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final cumulativeMarkDao = CumulativeMarkDao(database);

      final grades = await cumulativeMarkDao.getBySemester(semesterId);

      Logger.d(
        'GradeHistoryDataProvider',
        'Loaded ${grades.length} grades for semester $semesterId',
      );

      return grades;
    } catch (e) {
      Logger.e(
        'GradeHistoryDataProvider',
        'Failed to load grades for semester',
        e,
      );
      rethrow;
    }
  }

  /// Get all semesters with their basic info
  Future<List<Map<String, dynamic>>> getSemesterSummaries() async {
    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final cumulativeMarkDao = CumulativeMarkDao(database);

      // Get all grades from database
      final allGrades = await cumulativeMarkDao.getAll();

      if (allGrades.isEmpty) {
        Logger.d('GradeHistoryDataProvider', 'No grades found in database');
        return [];
      }

      // Get semester order from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final semestersJson = prefs.getString('available_semesters');
      final semesterMapJson = prefs.getString('semester_map');

      if (semestersJson == null || semesterMapJson == null) {
        Logger.w(
          'GradeHistoryDataProvider',
          'Semester list not found in SharedPreferences, using database order',
        );
        // Fallback to grouping by semester
        return _buildSummariesFromGrades(allGrades);
      }

      // Parse semester list
      final List<dynamic> semesterNames = jsonDecode(semestersJson);
      final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

      // Create grade map by semester ID for quick lookup
      final gradesBySemesterId = <String, List<CumulativeMark>>{};
      for (var grade in allGrades) {
        final semesterId = grade.semesterId;
        if (!gradesBySemesterId.containsKey(semesterId)) {
          gradesBySemesterId[semesterId] = [];
        }
        gradesBySemesterId[semesterId]!.add(grade);
      }

      // Build summaries in the correct order from SharedPreferences
      final semesterSummaries = <Map<String, dynamic>>[];

      for (String semesterName in semesterNames) {
        final semesterId = semesterMap[semesterName]?.toString();
        if (semesterId == null) continue;

        // Get grades for this semester
        final semesterGrades = gradesBySemesterId[semesterId];
        if (semesterGrades == null || semesterGrades.isEmpty) {
          Logger.d(
            'GradeHistoryDataProvider',
            'No grades found for semester: $semesterName',
          );
          continue;
        }

        // Sort courses within semester by course code
        semesterGrades.sort((a, b) => a.courseCode.compareTo(b.courseCode));

        // Get stored GPA from first course (all courses in semester have same semesterGpa)
        final storedGpa = semesterGrades.first.semesterGpa;

        int totalCourses = semesterGrades.length;
        int passedCourses = 0;
        double totalCredits = 0;

        for (var g in semesterGrades) {
          totalCredits += g.credits;
          if (g.isPassing) {
            passedCourses++;
          }
        }

        semesterSummaries.add({
          'semester_id': semesterId,
          'semester_name': semesterName,
          'total_courses': totalCourses,
          'passed_courses': passedCourses,
          'total_credits': totalCredits,
          'semester_gpa': storedGpa, // Use stored GPA from VTOP, not calculated
          'grades': semesterGrades,
        });
      }

      Logger.success(
        'GradeHistoryDataProvider',
        'Generated summaries for ${semesterSummaries.length} semesters (SharedPreferences order - most recent first)',
      );

      return semesterSummaries;
    } catch (e) {
      Logger.e(
        'GradeHistoryDataProvider',
        'Failed to generate semester summaries',
        e,
      );
      rethrow;
    }
  }

  /// Fallback method to build summaries from grades when SharedPreferences unavailable
  List<Map<String, dynamic>> _buildSummariesFromGrades(
    List<CumulativeMark> allGrades,
  ) {
    final semesterSummaries = <Map<String, dynamic>>[];
    final seenSemesters = <String>{};

    for (var grade in allGrades) {
      final semesterId = grade.semesterId;

      if (seenSemesters.contains(semesterId)) continue;
      seenSemesters.add(semesterId);

      final semesterGrades =
          allGrades.where((g) => g.semesterId == semesterId).toList();

      if (semesterGrades.isEmpty) continue;

      semesterGrades.sort((a, b) => a.courseCode.compareTo(b.courseCode));

      final storedGpa = semesterGrades.first.semesterGpa;

      int totalCourses = semesterGrades.length;
      int passedCourses = 0;
      double totalCredits = 0;

      for (var g in semesterGrades) {
        totalCredits += g.credits;
        if (g.isPassing) {
          passedCourses++;
        }
      }

      semesterSummaries.add({
        'semester_id': semesterId,
        'semester_name': semesterGrades.first.semesterName,
        'total_courses': totalCourses,
        'passed_courses': passedCourses,
        'total_credits': totalCredits,
        'semester_gpa': storedGpa,
        'grades': semesterGrades,
      });
    }

    return semesterSummaries;
  }

  /// Check if grade history exists
  Future<bool> hasGradeHistory() async {
    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final cumulativeMarkDao = CumulativeMarkDao(database);

      final count = await cumulativeMarkDao.getCount();
      return count > 0;
    } catch (e) {
      Logger.e('GradeHistoryDataProvider', 'Failed to check grade history', e);
      return false;
    }
  }
}
