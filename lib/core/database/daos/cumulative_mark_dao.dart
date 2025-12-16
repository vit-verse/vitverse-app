import 'package:sqflite/sqflite.dart';
import '../entities/cumulative_mark.dart';

/// Data Access Object for CumulativeMark entity
/// Handles storage, retrieval, and analytics data related to semester marks
class CumulativeMarkDao {
  final Database database;

  CumulativeMarkDao(this.database);

  /// Insert a single cumulative mark record
  Future<int> insert(CumulativeMark cumulativeMark) async {
    return await database.insert(
      'cumulative_marks',
      cumulativeMark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple cumulative mark records in a batch
  Future<void> insertAll(List<CumulativeMark> cumulativeMarks) async {
    final batch = database.batch();
    for (final mark in cumulativeMarks) {
      batch.insert(
        'cumulative_marks',
        mark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all stored cumulative marks ordered by semester and course
  Future<List<CumulativeMark>> getAll() async {
    final maps = await database.query(
      'cumulative_marks',
      orderBy: 'semester_id DESC, course_code ASC',
    );
    return maps.map((m) => CumulativeMark.fromMap(m)).toList();
  }

  /// Get marks for a specific semester
  Future<List<CumulativeMark>> getBySemester(String semesterId) async {
    final maps = await database.query(
      'cumulative_marks',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'course_code ASC',
    );
    return maps.map((m) => CumulativeMark.fromMap(m)).toList();
  }

  /// Delete all cumulative mark records
  Future<int> deleteAll() async {
    return await database.delete('cumulative_marks');
  }

  /// Get total cumulative mark record count
  Future<int> getCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM cumulative_marks',
    );
    return result.first['count'] as int;
  }
}
