import 'package:sqflite/sqflite.dart'; // <-- ADDED: provides Database type
import '../../authentication/core/auth_service.dart';
import '../../../core/database/database.dart';
import '../../../core/database/daos/attendance_dao.dart';
import '../../../core/database/daos/course_dao.dart';
import '../../../core/database/daos/exam_dao.dart';
import '../../../core/database/daos/slot_dao.dart';
import '../../../core/utils/logger.dart';

class HomeDataProvider {
  final _auth = VTOPAuthService.instance;
  final _attendanceDao = AttendanceDao();
  final _courseDao = CourseDao();

  Future<Database> get _db async => await VitConnectDatabase.instance.database;

  /// Generic helper to reduce try/catch duplication
  Future<T> _safeCall<T>(String tag, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      // include stacktrace to make debugging easier
      Logger.e('HomeDataProvider', '$tag failed', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserData() =>
      _safeCall('User data load', () => _auth.getUserData());

  Future<List<Map<String, dynamic>>> getAttendanceData() => _safeCall(
    'Attendance load',
    () => _attendanceDao.getAttendanceWithCourses(),
  );

  Future<List<Map<String, dynamic>>> getTimetableData() =>
      _safeCall('Timetable load', () async {
        final database = await _db;
        final result = await database.query('timetable');

        Logger.d('HomeDataProvider', 'Timetable rows: ${result.length}');
        if (result.isNotEmpty) {
          Logger.d('HomeDataProvider', 'Sample keys: ${result.first.keys}');
          Logger.d('HomeDataProvider', 'Sample row: ${result.first}');
        }

        return result;
      });

  Future<List<Map<String, dynamic>>> getExamData() =>
      _safeCall('Exam load', () async {
        final database = await _db;
        return ExamDao(database).getAllExams();
      });

  Future<List<Map<String, dynamic>>> getCoursesData() =>
      _safeCall('Courses load', () => _courseDao.getAllCourses());

  Future<List<Map<String, dynamic>>> getSlotsData() =>
      _safeCall('Slots load', () async {
        final database = await _db;
        return await database.query('slots');
      });
}
