import 'package:sqflite/sqflite.dart';
import '../entities/slot.dart';

/// Data Access Object for Slot entity
/// Provides methods to interact with the slots table in the database
class SlotDao {
  final Database database;

  SlotDao(this.database);

  /// Insert a single slot
  Future<int> insert(Slot slot) async {
    return await database.insert('slots', slot.toMap());
  }

  /// Insert multiple slots
  Future<List<int>> insertAll(List<Slot> slots) async {
    final List<int> ids = [];
    for (final slot in slots) {
      ids.add(await insert(slot));
    }
    return ids;
  }

  /// Get all slots
  Future<List<Slot>> getAll() async {
    final List<Map<String, dynamic>> maps = await database.query('slots');
    return List.generate(maps.length, (i) {
      return Slot.fromMap(maps[i]);
    });
  }

  /// Get slot by ID
  Future<Slot?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'slots',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Slot.fromMap(maps.first);
    }
    return null;
  }

  /// Get slots by course ID
  Future<List<Slot>> getByCourseId(int courseId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'slots',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return List.generate(maps.length, (i) {
      return Slot.fromMap(maps[i]);
    });
  }

  /// Delete all slots
  Future<int> deleteAll() async {
    return await database.delete('slots');
  }

  /// Get slot count
  Future<int> getCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM slots',
    );
    return result.first['count'] as int;
  }
}
