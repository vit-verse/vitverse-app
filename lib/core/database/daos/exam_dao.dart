import 'package:sqflite/sqflite.dart';
import '../entities/exam.dart';

/// Data Access Object for Exam entity
/// Provides methods to interact with the exams table in the database
class ExamDao {
  final Database database;

  ExamDao(this.database);

  /// Insert a single exam
  Future<int> insert(Exam exam) async {
    return await database.insert('exams', exam.toMap());
  }

  /// Insert multiple exams
  Future<List<int>> insertAll(List<Exam> exams) async {
    final List<int> ids = [];
    for (final exam in exams) {
      ids.add(await insert(exam));
    }
    return ids;
  }

  /// Get all exams
  Future<List<Exam>> getAll() async {
    final List<Map<String, dynamic>> maps = await database.query('exams');
    return List.generate(maps.length, (i) {
      return Exam.fromMap(maps[i]);
    });
  }

  /// Get all exams as maps (for home screen)
  Future<List<Map<String, dynamic>>> getAllExams() async {
    return await database.query('exams');
  }

  /// Get exams by course ID
  Future<List<Exam>> getByCourseId(int courseId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'exams',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return List.generate(maps.length, (i) {
      return Exam.fromMap(maps[i]);
    });
  }

  /// Delete all exams
  Future<int> deleteAll() async {
    return await database.delete('exams');
  }

  /// Get exam count
  Future<int> getCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM exams',
    );
    return result.first['count'] as int;
  }
}
