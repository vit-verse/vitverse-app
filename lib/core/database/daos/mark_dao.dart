import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/mark.dart';

class MarkDao {
  static const String _tableName = 'marks';

  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert mark
  Future<int> insert(Mark mark) async {
    final db = await _database;
    return await db.insert(_tableName, mark.toMap());
  }

  /// Insert multiple marks
  Future<void> insertAll(List<Mark> marks) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final mark in marks) {
        await txn.insert(
          _tableName,
          mark.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get all marks
  Future<List<Mark>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName, orderBy: 'id DESC');
    return maps.map((map) => Mark.fromMap(map)).toList();
  }

  /// Get marks by course ID
  Future<List<Mark>> getByCourseId(int courseId) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'id DESC',
    );
    return maps.map((map) => Mark.fromMap(map)).toList();
  }

  /// Get unread marks
  Future<List<Mark>> getUnreadMarks() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );
    return maps.map((map) => Mark.fromMap(map)).toList();
  }

  /// Get marks with course details (JOIN query)
  Future<List<Map<String, dynamic>>> getMarksWithCourses() async {
    final db = await _database;
    return await db.rawQuery('''
      SELECT m.*, 
             c.code as course_code, 
             c.title as course_title,
             c.type as course_type,
             c.credits as course_credits
      FROM marks m 
      LEFT JOIN courses c ON m.course_id = c.id 
      ORDER BY m.id DESC
    ''');
  }

  /// Check if mark exists by signature (duplicate detection)
  Future<bool> existsBySignature(int signature) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE signature = ?',
      [signature],
    );
    return (result.first['count'] as int) > 0;
  }

  /// Get mark by signature (for duplicate detection)
  Future<Mark?> getBySignature(int signature) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'signature = ?',
      whereArgs: [signature],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Mark.fromMap(maps.first);
  }

  /// Mark as read
  Future<int> markAsRead(int markId) async {
    final db = await _database;
    return await db.update(
      _tableName,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [markId],
    );
  }

  /// Update average for a mark
  Future<int> updateAverage(int markId, double average) async {
    final db = await _database;
    return await db.update(
      _tableName,
      {'average': average},
      where: 'id = ?',
      whereArgs: [markId],
    );
  }

  /// Mark all as read
  Future<int> markAllAsRead() async {
    final db = await _database;
    return await db.update(_tableName, {'is_read': 1});
  }

  /// Update mark
  Future<int> update(Mark mark) async {
    final db = await _database;
    return await db.update(
      _tableName,
      mark.toMap(),
      where: 'id = ?',
      whereArgs: [mark.id],
    );
  }

  /// Delete mark
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all marks
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  /// Get mark count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }

  Future<int> getUnreadCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_read = 0',
    );
    return result.first['count'] as int;
  }

  Future<Mark?> getById(int id) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Mark.fromMap(maps.first);
  }

  Future<Map<String, dynamic>?> getMarkWithCourse(int markId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT m.signature, m.title, c.code AS course_code
      FROM $_tableName m
      LEFT JOIN courses c ON m.course_id = c.id
      WHERE m.id = ?
    ''',
      [markId],
    );
    return rows.isEmpty ? null : rows.first;
  }
}
