import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/attendance_detail.dart';

/// Data Access Object for AttendanceDetail entity
/// Provides database operations for day-wise attendance details
class AttendanceDetailDao {
  /// Get database instance
  Future<Database> get _database async {
    return await VitConnectDatabase.instance.database;
  }

  /// Insert a single attendance detail record
  Future<int> insert(AttendanceDetail detail) async {
    final db = await _database;
    return await db.insert(
      'attendance_detail',
      detail.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple attendance detail records in a batch
  Future<void> insertBatch(List<AttendanceDetail> details) async {
    if (details.isEmpty) return;

    final db = await _database;
    final batch = db.batch();

    for (final detail in details) {
      batch.insert(
        'attendance_detail',
        detail.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get all attendance details for a specific attendance record
  Future<List<AttendanceDetail>> getByAttendanceId(int attendanceId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
      orderBy: 'attendance_date DESC', // Most recent first
    );

    return maps.map((map) => AttendanceDetail.fromMap(map)).toList();
  }

  /// Get all attendance details
  Future<List<AttendanceDetail>> getAll() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      orderBy: 'attendance_date DESC',
    );

    return maps.map((map) => AttendanceDetail.fromMap(map)).toList();
  }

  /// Get attendance details by date range
  Future<List<AttendanceDetail>> getByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      where: 'attendance_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'attendance_date DESC',
    );

    return maps.map((map) => AttendanceDetail.fromMap(map)).toList();
  }

  /// Get attendance details by status (Present, Absent, On Duty, etc.)
  Future<List<AttendanceDetail>> getByStatus(String status) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      where: 'attendance_status = ?',
      whereArgs: [status],
      orderBy: 'attendance_date DESC',
    );

    return maps.map((map) => AttendanceDetail.fromMap(map)).toList();
  }

  /// Get attendance details for a specific slot
  Future<List<AttendanceDetail>> getBySlot(String slot) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      where: 'attendance_slot = ?',
      whereArgs: [slot],
      orderBy: 'attendance_date DESC',
    );

    return maps.map((map) => AttendanceDetail.fromMap(map)).toList();
  }

  /// Get count of attendance details by status for a specific attendance record
  /// Useful for analytics (e.g., "You were present 25 times, absent 3 times")
  Future<Map<String, int>> getStatusCounts(int attendanceId) async {
    final db = await _database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT attendance_status, COUNT(*) as count
      FROM attendance_detail
      WHERE attendance_id = ?
      GROUP BY attendance_status
    ''',
      [attendanceId],
    );

    final counts = <String, int>{};
    for (final row in result) {
      counts[row['attendance_status'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// Get total count of attendance details
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_detail',
    );
    return result.first['count'] as int;
  }

  /// Get count of attendance details for a specific attendance record
  Future<int> getCountByAttendanceId(int attendanceId) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_detail WHERE attendance_id = ?',
      [attendanceId],
    );
    return result.first['count'] as int;
  }

  /// Update an attendance detail record
  Future<int> update(AttendanceDetail detail) async {
    if (detail.id == null) {
      throw ArgumentError('Cannot update attendance detail without an id');
    }

    final db = await _database;
    return await db.update(
      'attendance_detail',
      detail.toMap(),
      where: 'id = ?',
      whereArgs: [detail.id],
    );
  }

  /// Delete an attendance detail by ID
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(
      'attendance_detail',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all attendance details for a specific attendance record
  /// Note: This will happen automatically via CASCADE DELETE when attendance is deleted
  Future<int> deleteByAttendanceId(int attendanceId) async {
    final db = await _database;
    return await db.delete(
      'attendance_detail',
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
    );
  }

  /// Delete all attendance details
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete('attendance_detail');
  }

  /// Get absent count for a specific attendance record
  Future<int> getAbsentCount(int attendanceId) async {
    final db = await _database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM attendance_detail
      WHERE attendance_id = ? AND attendance_status = 'Absent'
    ''',
      [attendanceId],
    );
    return result.first['count'] as int;
  }

  /// Get present count for a specific attendance record
  Future<int> getPresentCount(int attendanceId) async {
    final db = await _database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM attendance_detail
      WHERE attendance_id = ? AND attendance_status = 'Present'
    ''',
      [attendanceId],
    );
    return result.first['count'] as int;
  }

  /// Get on duty count for a specific attendance record
  /// Counts each slot separately if slots are combined with '+'
  /// For example: "L45+L46" counts as 2, not 1
  Future<int> getOnDutyCount(int attendanceId) async {
    final db = await _database;
    final result = await db.rawQuery(
      '''
      SELECT attendance_slot
      FROM attendance_detail
      WHERE attendance_id = ? AND attendance_status = 'On Duty'
    ''',
      [attendanceId],
    );

    // Count slots, splitting by '+' if present (This line is just a hack)
    int totalOdCount = 0;
    for (final row in result) {
      final slot = row['attendance_slot'] as String?;
      if (slot != null && slot.isNotEmpty) {
        // Count number of slots (split by '+')
        final slotCount = slot.split('+').length;
        totalOdCount += slotCount;
      }
    }

    return totalOdCount;
  }

  /// Get most recent attendance detail for an attendance record
  Future<AttendanceDetail?> getMostRecent(int attendanceId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_detail',
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
      orderBy: 'attendance_date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AttendanceDetail.fromMap(maps.first);
  }
}
