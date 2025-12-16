import '../../../../../../core/database/daos/all_semester_mark_dao.dart';
import '../../../../../../core/database/entities/all_semester_mark.dart';
import '../../../../../../core/utils/logger.dart';
import '../models/marks_analysis.dart';
import '../models/course_type.dart';

/// Service for managing marks history with analytics
class MarksHistoryService {
  static final MarksHistoryService _instance = MarksHistoryService._internal();
  factory MarksHistoryService() => _instance;
  MarksHistoryService._internal();

  final AllSemesterMarkDao _dao = AllSemesterMarkDao();

  /// Get all marks grouped by semester
  Future<Map<String, List<AllSemesterMark>>>
  getAllMarksGroupedBySemester() async {
    try {
      return await _dao.getMarksGroupedBySemester();
    } catch (e) {
      Logger.e('MarksHistory', 'Error fetching marks by semester', e);
      return {};
    }
  }

  /// Calculate marks analysis for graphs
  Future<MarksAnalysis> calculateMarksAnalysis() async {
    try {
      final marksData = await getAllMarksGroupedBySemester();

      if (marksData.isEmpty) {
        return MarksAnalysis.empty();
      }

      final semesterAverages = <String, double>{};
      int totalCourses = 0;
      int totalAssessments = 0;
      double sumOfAverages = 0.0;
      double highestAvg = 0.0;
      double lowestAvg = 100.0;

      for (final entry in marksData.entries) {
        final semester = entry.key;
        final marks = entry.value;

        // Group by course
        final courseGroups = <String, List<AllSemesterMark>>{};
        for (final mark in marks) {
          final key = '${mark.courseCode}_${mark.courseTitle}';
          courseGroups.putIfAbsent(key, () => []).add(mark);
        }

        totalCourses += courseGroups.length;
        totalAssessments += marks.length;

        // Calculate semester average
        double semesterTotal = 0.0;
        double semesterMaxTotal = 0.0;

        for (final mark in marks) {
          semesterTotal += mark.score ?? 0.0;
          semesterMaxTotal += mark.maxScore ?? 0.0;
        }

        final semesterAvg =
            semesterMaxTotal > 0
                ? (semesterTotal / semesterMaxTotal) * 100
                : 0.0;

        semesterAverages[semester] = semesterAvg;
        sumOfAverages += semesterAvg;

        if (semesterAvg > highestAvg) highestAvg = semesterAvg;
        if (semesterAvg < lowestAvg) lowestAvg = semesterAvg;
      }

      final overallAvg =
          marksData.isNotEmpty ? sumOfAverages / marksData.length : 0.0;

      return MarksAnalysis(
        semesterAverages: semesterAverages,
        overallAverage: overallAvg,
        highestSemesterAverage: highestAvg,
        lowestSemesterAverage: lowestAvg,
        totalCourses: totalCourses,
        totalAssessments: totalAssessments,
        semesters: marksData.keys.toList(),
      );
    } catch (e) {
      Logger.e('MarksHistory', 'Error calculating marks analysis', e);
      return MarksAnalysis.empty();
    }
  }

  /// Detect course type from course code
  CourseType getCourseType(String? courseCode) {
    return CourseType.fromCourseCode(courseCode);
  }

  /// Check if marks data is available
  Future<bool> hasMarksData() async {
    final count = await _dao.getCount();
    return count > 0;
  }
}
