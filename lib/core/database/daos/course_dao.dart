import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/course.dart';

/// Data Access Object for Course entity
/// Provides CRUD operations for courses table
class CourseDao {
  static const String _tableName = 'courses';

  /// Get database instance
  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert a course
  Future<int> insert(Course course) async {
    final db = await _database;
    return await db.insert(_tableName, course.toMap());
  }

  /// Insert multiple courses
  Future<void> insertAll(List<Course> courses) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final course in courses) {
        await txn.insert(
          _tableName,
          course.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get all courses
  Future<List<Course>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName, orderBy: 'code ASC');
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  /// Get all courses as maps (for home screen)
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final db = await _database;
    return await db.query(_tableName, orderBy: 'code ASC');
  }

  /// Get course by ID
  Future<Course?> getById(int id) async {
    final db = await _database;
    final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// Get courses by semester
  Future<List<Course>> getBySemester(String semesterId) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'code ASC',
    );
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  /// Update a course
  Future<int> update(Course course) async {
    final db = await _database;
    return await db.update(
      _tableName,
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// Delete a course
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all courses
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  /// Get course count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }

  /// Get courses with their attendance (JOIN query)
  Future<List<Map<String, dynamic>>> getCoursesWithAttendance() async {
    final db = await _database;
    return await db.rawQuery('''
      SELECT c.*, a.percentage as attendance_percentage 
      FROM courses c 
      LEFT JOIN attendance a ON c.id = a.course_id 
      ORDER BY c.code
    ''');
  }

  /// Get course by slot
  Future<Course?> getCourseBySlot(String slot) async {
    final db = await _database;
    final maps = await db.rawQuery(
      '''
      SELECT c.* FROM courses c 
      INNER JOIN slots s ON c.id = s.course_id 
      WHERE s.slot = ?
    ''',
      [slot],
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// Insert a slot
  Future<int> insertSlot(dynamic slot) async {
    final db = await _database;
    final slotMap = {'slot': slot.slot, 'course_id': slot.courseId};
    return await db.insert('slots', slotMap);
  }

  /// Insert multiple slots
  Future<void> insertSlots(List<dynamic> slots) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final slot in slots) {
        final slotMap = {'slot': slot.slot, 'course_id': slot.courseId};
        await txn.insert(
          'slots',
          slotMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
