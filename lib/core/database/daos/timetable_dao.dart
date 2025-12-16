import 'package:sqflite/sqflite.dart';
import '../entities/timetable.dart';

/// Data Access Object for Timetable entity
/// Provides methods to interact with the timetable table in the database
class TimetableDao {
  final Database database;

  TimetableDao(this.database);

  /// Insert a single timetable entry
  Future<int> insert(Timetable timetable) async {
    return await database.insert('timetable', timetable.toMap());
  }

  /// Insert multiple timetable entries
  Future<List<int>> insertAll(List<Timetable> timetables) async {
    final List<int> ids = [];
    for (final timetable in timetables) {
      ids.add(await insert(timetable));
    }
    return ids;
  }

  /// Get all timetable entries
  Future<List<Timetable>> getAll() async {
    final List<Map<String, dynamic>> maps = await database.query('timetable');
    return List.generate(maps.length, (i) {
      return Timetable.fromMap(maps[i]);
    });
  }

  /// Get timetable by ID
  Future<Timetable?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'timetable',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Timetable.fromMap(maps.first);
    }
    return null;
  }

  /// Delete all timetable entries
  Future<int> deleteAll() async {
    return await database.delete('timetable');
  }

  /// Get timetable count
  Future<int> getCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM timetable',
    );
    return result.first['count'] as int;
  }
}
