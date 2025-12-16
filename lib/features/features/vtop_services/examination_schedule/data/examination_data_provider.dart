import '../../../../../core/database/database.dart';
import '../../../../../core/database/daos/exam_dao.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../../../../../core/utils/logger.dart';

/// Data provider for examination schedule
/// Fetches exam data from local database
class ExaminationDataProvider {
  /// Get all exams with course details
  Future<List<Map<String, dynamic>>> getAllExamsWithCourses() async {
    try {
      final db = VitConnectDatabase.instance;
      final database = await db.database;
      final examDao = ExamDao(database);
      final courseDao = CourseDao();

      // Get all exams
      final exams = await examDao.getAllExams();

      // Get all courses
      final courses = await courseDao.getAllCourses();

      // Get all slots
      final slots = await database.query('slots');

      // Create a map of course IDs to course data
      final courseMap = <int, Map<String, dynamic>>{};
      for (var course in courses) {
        if (course['id'] != null) {
          courseMap[course['id'] as int] = course;
        }
      }

      // Create a map of course IDs to their slots
      final courseSlotsMap = <int, List<String>>{};
      for (var slot in slots) {
        final courseId = slot['course_id'] as int?;
        final slotName = slot['slot']?.toString();
        if (courseId != null && slotName != null) {
          if (!courseSlotsMap.containsKey(courseId)) {
            courseSlotsMap[courseId] = [];
          }
          courseSlotsMap[courseId]!.add(slotName);
        }
      }

      // Combine exam data with course data and slots
      final examsWithCourses = <Map<String, dynamic>>[];
      for (var exam in exams) {
        final courseId = exam['course_id'] as int?;
        final course = courseId != null ? courseMap[courseId] : null;
        final courseSlots =
            courseId != null ? (courseSlotsMap[courseId] ?? []) : <String>[];

        examsWithCourses.add({...exam, 'course': course, 'slots': courseSlots});
      }

      return examsWithCourses;
    } catch (e) {
      Logger.e('ExaminationDataProvider', 'Failed to load exam data', e);
      rethrow;
    }
  }

  /// Get exams by type (grouped by exam title)
  Future<Map<String, List<Map<String, dynamic>>>> getExamsByType() async {
    try {
      final allExams = await getAllExamsWithCourses();
      final examsByType = <String, List<Map<String, dynamic>>>{};

      for (var exam in allExams) {
        final title = exam['title']?.toString() ?? 'Other';

        if (!examsByType.containsKey(title)) {
          examsByType[title] = [];
        }
        examsByType[title]!.add(exam);
      }

      // Sort exams within each type by start time
      examsByType.forEach((key, value) {
        value.sort((a, b) {
          final aTime = a['start_time'] as int? ?? 0;
          final bTime = b['start_time'] as int? ?? 0;
          return aTime.compareTo(bTime);
        });
      });

      return examsByType;
    } catch (e) {
      Logger.e('ExaminationDataProvider', 'Failed to group exams by type', e);
      rethrow;
    }
  }

  /// Get upcoming exams (within next 30 days)
  Future<List<Map<String, dynamic>>> getUpcomingExams() async {
    try {
      final allExams = await getAllExamsWithCourses();
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysLater =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;

      final upcomingExams =
          allExams.where((exam) {
            final startTime = exam['start_time'] as int?;
            if (startTime == null) return false;
            return startTime >= now && startTime <= thirtyDaysLater;
          }).toList();

      // Sort by start time
      upcomingExams.sort((a, b) {
        final aTime = a['start_time'] as int? ?? 0;
        final bTime = b['start_time'] as int? ?? 0;
        return aTime.compareTo(bTime);
      });

      return upcomingExams;
    } catch (e) {
      Logger.e('ExaminationDataProvider', 'Failed to get upcoming exams', e);
      rethrow;
    }
  }

  /// Get next exam
  Future<Map<String, dynamic>?> getNextExam() async {
    try {
      final upcomingExams = await getUpcomingExams();
      return upcomingExams.isNotEmpty ? upcomingExams.first : null;
    } catch (e) {
      Logger.e('ExaminationDataProvider', 'Failed to get next exam', e);
      return null;
    }
  }
}
