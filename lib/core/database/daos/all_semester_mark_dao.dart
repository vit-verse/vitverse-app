import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/all_semester_mark.dart';

/// Data Access Object for AllSemesterMark entity
/// Provides CRUD operations for all_semester_marks table
class AllSemesterMarkDao {
  static const String _tableName = 'all_semester_marks';

  /// Get database instance
  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert mark
  Future<int> insert(AllSemesterMark mark) async {
    final db = await _database;
    return await db.insert(_tableName, mark.toMap());
  }

  /// Insert multiple marks
  Future<void> insertAll(List<AllSemesterMark> marks) async {
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
  Future<List<AllSemesterMark>> getAll() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      orderBy: 'semester_name DESC, course_code ASC',
    );
    return maps.map((map) => AllSemesterMark.fromMap(map)).toList();
  }

  /// Get marks by semester ID
  Future<List<AllSemesterMark>> getBySemesterId(String semesterId) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'course_code ASC',
    );
    return maps.map((map) => AllSemesterMark.fromMap(map)).toList();
  }

  /// Get marks by semester name
  Future<List<AllSemesterMark>> getBySemesterName(String semesterName) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'semester_name = ?',
      whereArgs: [semesterName],
      orderBy: 'course_code ASC',
    );
    return maps.map((map) => AllSemesterMark.fromMap(map)).toList();
  }

  /// Get all semesters (distinct)
  Future<List<Map<String, dynamic>>> getAllSemesters() async {
    final db = await _database;
    return await db.rawQuery('''
      SELECT DISTINCT semester_id, semester_name 
      FROM $_tableName 
      ORDER BY semester_name DESC
    ''');
  }

  /// Get marks grouped by semester
  Future<Map<String, List<AllSemesterMark>>> getMarksGroupedBySemester() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      orderBy: 'semester_name DESC, course_code ASC',
    );

    final marks = maps.map((map) => AllSemesterMark.fromMap(map)).toList();
    final grouped = <String, List<AllSemesterMark>>{};

    for (final mark in marks) {
      final semesterName = mark.semesterName ?? 'Unknown';
      if (!grouped.containsKey(semesterName)) {
        grouped[semesterName] = [];
      }
      grouped[semesterName]!.add(mark);
    }

    return grouped;
  }

  /// Get marks grouped by course for a specific semester
  Future<Map<String, List<AllSemesterMark>>> getMarksByCourse(
    String semesterId,
  ) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'course_code ASC, title ASC',
    );

    final marks = maps.map((map) => AllSemesterMark.fromMap(map)).toList();
    final grouped = <String, List<AllSemesterMark>>{};

    for (final mark in marks) {
      final courseKey = '${mark.courseCode} - ${mark.courseTitle}';
      if (!grouped.containsKey(courseKey)) {
        grouped[courseKey] = [];
      }
      grouped[courseKey]!.add(mark);
    }

    return grouped;
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
  Future<AllSemesterMark?> getBySignature(int signature) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'signature = ?',
      whereArgs: [signature],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AllSemesterMark.fromMap(maps.first);
  }

  /// Delete marks by semester ID
  Future<int> deleteBySemesterId(String semesterId) async {
    final db = await _database;
    return await db.delete(
      _tableName,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
  }

  /// Delete all marks
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get total count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get count by semester
  Future<int> getCountBySemester(String semesterId) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE semester_id = ?',
      [semesterId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
