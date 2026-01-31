import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Database class for VIT Connect app.
class VitConnectDatabase {
  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  static const String _databaseName = 'vit_student.db';
  static const int _databaseVersion = 2;

  static VitConnectDatabase? _instance;
  static Database? _database;

  VitConnectDatabase._();

  static VitConnectDatabase get instance {
    _instance ??= VitConnectDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    try {
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigureSafe,
      );
    } catch (e) {
      Logger.e('DB', 'Database initialization failed', e);

      if (e.toString().contains('journal_mode') ||
          e.toString().contains('WAL') ||
          e.toString().contains('readonly')) {
        await forceResetDatabase();
        return await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigureSafe,
        );
      }

      await deleteDatabase();
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigureSafe,
      );
    }
  }

  Future<void> _onConfigureSafe(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      Logger.e('DB', 'Configuration failed', e);
    }
  }

  // ============================================================================
  // SCHEMA LIFECYCLE
  // ============================================================================

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.i(
      'DB',
      'Upgrading database from version $oldVersion to $newVersion',
    );

    // Migration from version 1 to 2: Add course_type column to attendance table
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE attendance ADD COLUMN course_type TEXT');
        Logger.success('DB', 'Added course_type column to attendance table');
      } catch (e) {
        Logger.e('DB', 'Failed to add course_type column', e);
      }
    }

    // Future database migrations will be handled here
    // Increment version ONLY when:
    // 1. Add/remove tables
    // 2. Add/remove columns
    // 3. Change column types
    // 4. Modify foreign keys
    // 5. Change indexes
  }

  // ============================================================================
  // TABLE DEFINITIONS
  // ============================================================================

  Future<void> _createAllTables(Database db) async {
    // Courses table (parent table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        title TEXT,
        type TEXT,
        credits REAL,
        venue TEXT,
        faculty TEXT,
        faculty_erp_id TEXT,
        semester_id TEXT,
        class_id TEXT,
        category TEXT,
        course_option TEXT
      )
    ''');

    // Slots table (child of courses)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slot TEXT,
        course_id INTEGER,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Timetable table (references slots)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT,
        end_time TEXT,
        sunday INTEGER,
        monday INTEGER,
        tuesday INTEGER,
        wednesday INTEGER,
        thursday INTEGER,
        friday INTEGER,
        saturday INTEGER,
        FOREIGN KEY(sunday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(monday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(tuesday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(wednesday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(thursday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(friday) REFERENCES slots(id) ON DELETE CASCADE,
        FOREIGN KEY(saturday) REFERENCES slots(id) ON DELETE CASCADE
      )
    ''');

    // Attendance table (child of courses)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        course_type TEXT,
        attended INTEGER,
        total INTEGER,
        percentage INTEGER,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Attendance Detail table (child of attendance - day-wise records)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attendance_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        attendance_slot TEXT NOT NULL,
        day_and_timing TEXT NOT NULL,
        attendance_status TEXT NOT NULL,
        is_medical_leave INTEGER DEFAULT 0,
        is_virtual_slot INTEGER DEFAULT 0,
        FOREIGN KEY(attendance_id) REFERENCES attendance(id) ON DELETE CASCADE
      )
    ''');

    // Marks table (child of courses with SET NULL)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        title TEXT,
        score REAL,
        max_score REAL,
        weightage REAL,
        max_weightage REAL,
        average REAL,
        status TEXT,
        is_read INTEGER DEFAULT 0,
        signature INTEGER,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL
      )
    ''');

    // Cumulative marks table (complete academic history across all semesters)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cumulative_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_id TEXT NOT NULL,
        semester_name TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        course_type TEXT NOT NULL,
        credits REAL NOT NULL,
        grading_type TEXT NOT NULL,
        grand_total REAL NOT NULL,
        grade TEXT NOT NULL,
        is_online_course INTEGER DEFAULT 0,
        semester_gpa REAL,
        UNIQUE(semester_id, course_code)
      )
    ''');

    // All semester marks table (comprehensive marks history across all semesters)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS all_semester_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_id TEXT NOT NULL,
        semester_name TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        course_type TEXT NOT NULL,
        slot TEXT,
        title TEXT,
        score REAL,
        max_score REAL,
        weightage REAL,
        max_weightage REAL,
        average REAL,
        status TEXT,
        signature INTEGER,
        UNIQUE(semester_id, course_code, title)
      )
    ''');

    // Staff table (independent)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        key TEXT,
        value TEXT
      )
    ''');

    // Spotlight table (independent with duplicate detection)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS spotlight (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        announcement TEXT,
        category TEXT,
        link TEXT,
        is_read INTEGER DEFAULT 0,
        signature INTEGER
      )
    ''');

    // Receipts table (independent with natural primary key)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        number INTEGER PRIMARY KEY,
        amount REAL,
        date TEXT
      )
    ''');

    // Exams table (child of courses)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        title TEXT,
        start_time INTEGER,
        end_time INTEGER,
        venue TEXT,
        seat_location TEXT,
        seat_number INTEGER,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Curriculum Progress table (Step 2 data)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS curriculum_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distribution_type TEXT NOT NULL UNIQUE,
        credits_required REAL NOT NULL,
        credits_earned REAL NOT NULL
      )
    ''');

    // Basket Progress table (Step 2 data)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS basket_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        basket_title TEXT NOT NULL,
        distribution_type TEXT NOT NULL,
        credits_required REAL NOT NULL,
        credits_earned REAL NOT NULL,
        UNIQUE(basket_title, distribution_type)
      )
    ''');

    await _createIndexes(db);
  }

  // ============================================================================
  // INDEXES
  // ============================================================================

  Future<void> _createIndexes(Database db) async {
    // Course indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_courses_code ON courses(code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_courses_semester ON courses(semester_id)',
    );

    // Attendance indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendance_course ON attendance(course_id)',
    );

    // Attendance Detail indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendance_detail_attendance ON attendance_detail(attendance_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendance_detail_date ON attendance_detail(attendance_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendance_detail_status ON attendance_detail(attendance_status)',
    );

    // Marks indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_course ON marks(course_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_signature ON marks(signature)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_unread ON marks(is_read)',
    );

    // Slots indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_slots_course ON slots(course_id)',
    );

    // Spotlight indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_spotlight_signature ON spotlight(signature)',
    );

    // Exams indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_exams_course ON exams(course_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_exams_start_time ON exams(start_time)',
    );

    // Curriculum Progress indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_curriculum_distribution ON curriculum_progress(distribution_type)',
    );

    // Basket Progress indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_basket_distribution ON basket_progress(distribution_type)',
    );
  }

  // ============================================================================
  // DATABASE OPERATIONS
  // ============================================================================

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      final walFile = File('$path-wal');
      final shmFile = File('$path-shm');

      if (await walFile.exists()) {
        await walFile.delete();
      }

      if (await shmFile.exists()) {
        await shmFile.delete();
      }
    } catch (e) {
      Logger.e('DB', 'Error deleting database files', e);
    }
  }

  Future<void> forceResetDatabase() async {
    try {
      await deleteDatabase();
      _instance = null;
      _database = null;
    } catch (e) {
      Logger.e('DB', 'Force reset failed', e);
    }
  }

  /// Clears all data from database.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear in reverse dependency order (all 14 tables)

      // Independent tables
      await txn.delete('receipts');
      await txn.delete('spotlight');
      await txn.delete('staff');

      // Grade history tables (Step 2, 11, 14)
      await txn.delete('curriculum_progress');
      await txn.delete('basket_progress');
      await txn.delete('cumulative_marks');
      await txn.delete('all_semester_marks');

      // Course-dependent tables
      await txn.delete('marks');
      await txn.delete('exams');
      await txn.delete(
        'attendance_detail',
      ); // Must be deleted before attendance
      await txn.delete('attendance');
      await txn.delete('timetable');
      await txn.delete('slots');
      await txn.delete('courses');
    });
  }

  // ============================================================================
  // DEBUG UTILITIES
  // ============================================================================

  /// Returns row count for each table.
  Future<Map<String, int>> getTableCounts() async {
    final db = await database;
    final counts = <String, int>{};

    final tables = [
      'courses',
      'slots',
      'timetable',
      'attendance',
      'attendance_detail',
      'marks',
      'exams',
      'cumulative_marks',
      'all_semester_marks',
      'curriculum_progress',
      'basket_progress',
      'staff',
      'spotlight',
      'receipts',
    ];

    for (final table in tables) {
      try {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );
        counts[table] = result.first['count'] as int;
      } catch (e) {
        counts[table] = 0;
      }
    }

    return counts;
  }

  Future<void> printAllData() async {
    final db = await database;

    final counts = await getTableCounts();
    counts.forEach((table, count) {
      Logger.i('DB', '$table: $count rows');
    });
    final tables = [
      'courses',
      'slots',
      'timetable',
      'attendance',
      'attendance_detail',
      'marks',
      'exams',
      'cumulative_marks',
      'all_semester_marks',
      'curriculum_progress',
      'basket_progress',
      'staff',
      'spotlight',
      'receipts',
    ];

    for (final table in tables) {
      try {
        // Log first 5 rows of each table for manual verification
        final rows = await db.query(table, limit: 5);
        if (rows.isNotEmpty) {
          for (final row in rows) {
            Logger.i('DB', '$table: $row');
          }
        }
      } catch (e) {
        Logger.e('DB', '$table error', e);
      }
    }
  }
}
