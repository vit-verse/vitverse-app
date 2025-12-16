import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/staff.dart';

/// Data Access Object for Staff entity
/// Provides methods to interact with the staff table in the database
class StaffDao {
  static const String _tableName = 'staff';

  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert a single staff record
  Future<int> insert(Staff staff) async {
    final db = await _database;
    return await db.insert(_tableName, staff.toMap());
  }

  /// Insert multiple staff records
  Future<void> insertAll(List<Staff> staffList) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final staff in staffList) {
        await txn.insert(_tableName, staff.toMap());
      }
    });
  }

  /// Get all staff records
  Future<List<Staff>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName);
    return maps.map((map) => Staff.fromMap(map)).toList();
  }

  /// Get staff by type
  Future<List<Staff>> getByType(String type) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
    );
    return maps.map((map) => Staff.fromMap(map)).toList();
  }

  /// Delete all staff records
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get staff count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }
}
