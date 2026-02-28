import '../../../core/database/daos/mark_dao.dart';
import '../../../core/database_vitverse/database.dart';
import '../../../core/utils/logger.dart';
import '../models/performance_models.dart';

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

  Future<bool> updateMarkAverage(int markId, double average) async {
    try {
      final result = await _markDao.updateAverage(markId, average);
      if (result > 0) {
        final meta = await _markDao.getMarkWithCourse(markId);
        if (meta != null) {
          final courseCode = meta['course_code'] as String? ?? '';
          final title = meta['title'] as String? ?? '';
          final identityKey = '${courseCode}_$title'.hashCode;
          await VitVerseDatabase.instance.marksMetaDao.saveAverage(
            identityKey,
            average,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.e(_tag, 'Error updating average: $e');
      return false;
    }
  }

  Future<void> markAsRead(int markId) async {
    try {
      await _markDao.markAsRead(markId);
      final meta = await _markDao.getMarkWithCourse(markId);
      if (meta != null) {
        final sig = meta['signature'] as int?;
        if (sig != null) {
          await VitVerseDatabase.instance.marksMetaDao.saveReadSignature(sig);
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error marking as read: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      final marksWithCourses = await _markDao.getMarksWithCourses();
      final signatures = <int>[];
      for (final m in marksWithCourses) {
        final sig = m['signature'] as int?;
        if (sig != null) signatures.add(sig);
      }
      await _markDao.markAllAsRead();
      if (signatures.isNotEmpty) {
        await VitVerseDatabase.instance.marksMetaDao.saveReadSignatures(
          signatures,
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Error marking all as read: $e');
    }
  }
}
