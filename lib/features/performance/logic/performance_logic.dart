import '../../../core/database/daos/mark_dao.dart';
import '../../../core/utils/logger.dart';
import '../models/performance_models.dart';

/// Business logic for Performance feature
class PerformanceLogic {
  static const String _tag = 'Performance';

  final MarkDao _markDao = MarkDao();

  /// Get all course performances grouped by course
  Future<List<CoursePerformance>> getCoursePerformances() async {
    try {
      Logger.i(_tag, 'Fetching course performances...');

      // Get all marks with course details
      final marksWithCourses = await _markDao.getMarksWithCourses();
      Logger.d(
        _tag,
        'Fetched ${marksWithCourses.length} marks with course details',
      );

      // Group marks by course
      final Map<int, List<Map<String, dynamic>>> groupedMarks = {};
      for (final mark in marksWithCourses) {
        final courseId = mark['course_id'] as int?;
        if (courseId != null) {
          groupedMarks.putIfAbsent(courseId, () => []);
          groupedMarks[courseId]!.add(mark);
        }
      }

      Logger.d(_tag, 'Grouped marks into ${groupedMarks.length} courses');

      // Convert to CoursePerformance objects
      final List<CoursePerformance> performances = [];
      for (final entry in groupedMarks.entries) {
        final courseId = entry.key;
        final marks = entry.value;

        if (marks.isEmpty) continue;

        // Get course details from first mark
        final firstMark = marks.first;
        final assessments =
            marks.map((m) => AssessmentMark.fromMap(m)).toList();

        final unreadCount = assessments.where((a) => !a.isRead).length;

        performances.add(
          CoursePerformance(
            courseId: courseId,
            courseCode: firstMark['course_code'] as String? ?? 'N/A',
            courseTitle: firstMark['course_title'] as String? ?? 'Unknown',
            courseType: firstMark['course_type'] as String? ?? 'theory',
            credits: (firstMark['course_credits'] as num?)?.toDouble() ?? 0.0,
            assessments: assessments,
            unreadCount: unreadCount,
          ),
        );
      }

      Logger.success(
        _tag,
        'Created ${performances.length} course performance objects',
      );
      return performances;
    } catch (e) {
      Logger.e(_tag, 'Error fetching course performances: $e');
      return [];
    }
  }

  /// Update average for a specific mark (Locally)
  Future<bool> updateMarkAverage(int markId, double average) async {
    try {
      Logger.i(_tag, 'Updating average for mark $markId to $average');
      final result = await _markDao.updateAverage(markId, average);
      if (result > 0) {
        Logger.success(_tag, 'Average updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      Logger.e(_tag, 'Error updating average: $e');
      return false;
    }
  }
}
