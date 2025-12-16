import '../../../../../core/database/daos/attendance_dao.dart';
import '../../../../../core/utils/logger.dart';

/// Repository for attendance calculator data
class AttendanceCalculatorRepository {
  final AttendanceDao _attendanceDao = AttendanceDao();

  /// Get all courses with attendance data
  Future<List<Map<String, dynamic>>> getCoursesWithAttendance() async {
    try {
      final data = await _attendanceDao.getAttendanceWithCourses();

      Logger.i(
        'AttendanceCalculatorRepository',
        'Fetched ${data.length} courses with attendance',
      );

      return data;
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorRepository',
        'Failed to fetch courses with attendance',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get attendance data for a specific course
  Future<Map<String, dynamic>?> getCourseAttendance(int courseId) async {
    try {
      final allData = await _attendanceDao.getAttendanceWithCourses();

      final courseData = allData.where((data) => data['course_id'] == courseId);

      if (courseData.isEmpty) {
        Logger.w(
          'AttendanceCalculatorRepository',
          'No attendance data found for course ID: $courseId',
        );
        return null;
      }

      return courseData.first;
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorRepository',
        'Failed to fetch attendance for course ID: $courseId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Check if attendance data exists
  Future<bool> hasAttendanceData() async {
    try {
      final count = await _attendanceDao.getCount();
      return count > 0;
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorRepository',
        'Failed to check attendance data',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Get overall attendance statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    try {
      final allData = await _attendanceDao.getAttendanceWithCourses();

      if (allData.isEmpty) {
        return {
          'total_courses': 0,
          'total_attended': 0,
          'total_classes': 0,
          'average_percentage': 0.0,
        };
      }

      int totalAttended = 0;
      int totalClasses = 0;

      for (final data in allData) {
        totalAttended += (data['attended'] as int? ?? 0);
        totalClasses += (data['total'] as int? ?? 0);
      }

      final averagePercentage =
          totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;

      return {
        'total_courses': allData.length,
        'total_attended': totalAttended,
        'total_classes': totalClasses,
        'average_percentage': averagePercentage,
      };
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorRepository',
        'Failed to calculate overall statistics',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get courses below a certain attendance threshold
  Future<List<Map<String, dynamic>>> getCoursesBelowThreshold(
    double threshold,
  ) async {
    try {
      final allData = await _attendanceDao.getAttendanceWithCourses();

      final belowThreshold =
          allData.where((data) {
            final percentage = data['percentage'] as double? ?? 0.0;
            return percentage < threshold;
          }).toList();

      Logger.i(
        'AttendanceCalculatorRepository',
        'Found ${belowThreshold.length} courses below ${threshold}%',
      );

      return belowThreshold;
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceCalculatorRepository',
        'Failed to fetch courses below threshold',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
