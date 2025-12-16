import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/attendance.dart';

/// Data Access Object for Attendance entity
/// Provides CRUD operations for attendance table
class AttendanceDao {
  static const String _tableName = 'attendance';

  /// Get database instance
  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert attendance record
  Future<int> insert(Attendance attendance) async {
    final db = await _database;
    return await db.insert(_tableName, attendance.toMap());
  }

  /// Insert multiple attendance records
  Future<void> insertAll(List<Attendance> attendanceList) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final attendance in attendanceList) {
        await txn.insert(
          _tableName,
          attendance.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get all attendance records
  Future<List<Attendance>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName, orderBy: 'id DESC');
    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  /// Get attendance by course ID
  Future<Attendance?> getByCourseId(int courseId) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    if (maps.isEmpty) return null;
    return Attendance.fromMap(maps.first);
  }

  /// Get attendance with course details (JOIN query)
  Future<List<Map<String, dynamic>>> getAttendanceWithCourses() async {
    final db = await _database;
    return await db.rawQuery('''
      SELECT a.*, c.code as course_code, c.title as course_title, c.type as course_main_type
      FROM attendance a 
      INNER JOIN courses c ON a.course_id = c.id 
      ORDER BY a.percentage ASC
    ''');
  }

  /// Get average attendance percentage
  Future<double> getAverageAttendance() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT AVG(percentage) as avg_percentage FROM $_tableName',
    );
    final avg = result.first['avg_percentage'];
    return avg != null ? (avg as num).toDouble() : 0.0;
  }

  /// Get attendance below threshold
  Future<List<Attendance>> getBelowThreshold(int threshold) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'percentage < ?',
      whereArgs: [threshold],
      orderBy: 'percentage ASC',
    );
    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  /// Update attendance record
  Future<int> update(Attendance attendance) async {
    final db = await _database;
    return await db.update(
      _tableName,
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  /// Delete attendance record
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all attendance records
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  /// Get attendance count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }
}
