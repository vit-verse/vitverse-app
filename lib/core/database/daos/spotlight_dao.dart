import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/spotlight.dart';

/// Data Access Object for Spotlight entity
/// Provides methods to interact with the spotlight table in the database
class SpotlightDao {
  static const String _tableName = 'spotlight';

  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert a single spotlight announcement
  Future<int> insert(Spotlight spotlight) async {
    final db = await _database;
    return await db.insert(_tableName, spotlight.toMap());
  }

  /// Insert multiple spotlight announcements
  Future<void> insertAll(List<Spotlight> spotlights) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final spotlight in spotlights) {
        await txn.insert(_tableName, spotlight.toMap());
      }
    });
  }

  /// Get all spotlight announcements
  Future<List<Spotlight>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName);
    return maps.map((map) => Spotlight.fromMap(map)).toList();
  }

  /// Get unread spotlight announcements
  Future<List<Spotlight>> getUnread() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'is_read = ?',
      whereArgs: [0],
    );
    return maps.map((map) => Spotlight.fromMap(map)).toList();
  }

  /// Mark spotlight as read by signature
  Future<int> markAsRead(int signature) async {
    final db = await _database;
    return await db.update(
      _tableName,
      {'is_read': 1},
      where: 'signature = ?',
      whereArgs: [signature],
    );
  }

  /// Delete all spotlight announcements
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get spotlight count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }
}
