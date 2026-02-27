import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';
import 'daos/calendar_dao.dart';
import 'daos/lost_found_dao.dart';
import 'daos/cab_ride_dao.dart';
import 'daos/custom_theme_dao.dart';
import 'daos/events_dao.dart';
import 'daos/marks_meta_dao.dart';

class VitVerseDatabase {
  static const String _databaseName = 'vit_verse.db';
  static const int _databaseVersion = 6;

  static VitVerseDatabase? _instance;
  static Database? _database;
  static CalendarDao? _calendarDao;
  static LostFoundDao? _lostFoundDao;
  static CabRideDao? _cabRideDao;
  static CustomThemeDao? _customThemeDao;
  static EventsDao? _eventsDao;
  static MarksMetaDao? _marksMetaDao;

  VitVerseDatabase._();

  static VitVerseDatabase get instance {
    _instance ??= VitVerseDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  CalendarDao get calendarDao {
    if (_calendarDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _calendarDao!;
  }

  LostFoundDao get lostFoundDao {
    if (_lostFoundDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _lostFoundDao!;
  }

  CabRideDao get cabRideDao {
    if (_cabRideDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _cabRideDao!;
  }

  CustomThemeDao get customThemeDao {
    if (_customThemeDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _customThemeDao!;
  }

  EventsDao get eventsDao {
    if (_eventsDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _eventsDao!;
  }

  MarksMetaDao get marksMetaDao {
    if (_marksMetaDao == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _marksMetaDao!;
  }

  Future<void> initialize() async {
    try {
      _database = await _initDatabase();
      _calendarDao = CalendarDao(_database!);
      _lostFoundDao = LostFoundDao(_database!);
      _cabRideDao = CabRideDao(_database!);
      _customThemeDao = CustomThemeDao(_database!);
      _eventsDao = EventsDao(_database!);
      _marksMetaDao = MarksMetaDao(_database!);
      Logger.i('VitVerseDB', 'Database initialized');
    } catch (e) {
      Logger.e('VitVerseDB', 'Database initialization failed', e);
      rethrow;
    }
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
      Logger.e('VitVerseDB', 'Database initialization failed', e);

      // Handle common database issues
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

      // If other errors, delete and recreate
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
      Logger.d('VitVerseDB', 'Foreign keys enabled');
    } catch (e) {
      Logger.e('VitVerseDB', 'Failed to enable foreign keys', e);
    }

    try {
      await db.execute('PRAGMA synchronous = NORMAL');
      Logger.d('VitVerseDB', 'Synchronous mode set to NORMAL');
    } catch (e) {
      Logger.e('VitVerseDB', 'Failed to set synchronous mode', e);
    }

    try {
      await db.execute('PRAGMA cache_size = 10000');
      Logger.d('VitVerseDB', 'Cache size set to 10000');
    } catch (e) {
      Logger.e('VitVerseDB', 'Failed to set cache size', e);
    }

    try {
      await db.execute('PRAGMA temp_store = MEMORY');
      Logger.d('VitVerseDB', 'Temp store set to MEMORY');
    } catch (e) {
      Logger.e('VitVerseDB', 'Failed to set temp store', e);
    }

    // Skip WAL mode as it may not be supported in all environments
    Logger.d('VitVerseDB', 'Database configuration completed');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    Logger.i('VitVerseDB', 'VIT Verse database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.i('VitVerseDB', 'Upgrading from v$oldVersion to v$newVersion');
    if (oldVersion < 6) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS marks_read (signature INTEGER PRIMARY KEY, updated_at INTEGER NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS marks_avg (identity_key INTEGER PRIMARY KEY, average REAL NOT NULL, updated_at INTEGER NOT NULL)',
      );
    }
  }

  Future<void> _createAllTables(Database db) async {
    // Calendar cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS calendar_cache (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        cache_type TEXT NOT NULL
      )
    ''');

    // Personal events table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personal_events (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        date INTEGER NOT NULL,
        time_hour INTEGER,
        time_minute INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Selected calendars table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS selected_calendars (
        id TEXT PRIMARY KEY,
        semester_name TEXT NOT NULL,
        class_group TEXT NOT NULL,
        file_path TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        added_at INTEGER NOT NULL
      )
    ''');

    // App preferences table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Lost & Found cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lost_found_cache (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        item_name TEXT NOT NULL,
        place TEXT NOT NULL,
        description TEXT,
        contact_name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        posted_by_name TEXT NOT NULL,
        posted_by_regno TEXT NOT NULL,
        image_path TEXT,
        created_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    // Cab Ride cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cab_ride_cache (
        id TEXT PRIMARY KEY,
        from_location TEXT NOT NULL,
        to_location TEXT NOT NULL,
        travel_date INTEGER NOT NULL,
        travel_time TEXT NOT NULL,
        cab_type TEXT NOT NULL,
        seats_available INTEGER NOT NULL,
        contact_number TEXT NOT NULL,
        description TEXT,
        posted_by_name TEXT NOT NULL,
        posted_by_regno TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Custom themes table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_themes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        primary_color TEXT NOT NULL,
        background_color TEXT NOT NULL,
        surface_color TEXT NOT NULL,
        text_color TEXT NOT NULL,
        muted_color TEXT NOT NULL,
        is_dark INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // Events cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events_cache (
        id TEXT PRIMARY KEY,
        event_source TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        event_date INTEGER NOT NULL,
        venue TEXT NOT NULL,
        poster_url TEXT,
        contact_info TEXT,
        event_link TEXT,
        participant_type TEXT,
        entry_fee INTEGER NOT NULL DEFAULT 0,
        team_size TEXT NOT NULL,
        user_name_regno TEXT NOT NULL,
        user_email TEXT NOT NULL,
        likes_count INTEGER NOT NULL DEFAULT 0,
        comments_count INTEGER NOT NULL DEFAULT 0,
        is_liked_by_me INTEGER NOT NULL DEFAULT 0,
        notify_all INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_verified INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS marks_read (signature INTEGER PRIMARY KEY, updated_at INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS marks_avg (identity_key INTEGER PRIMARY KEY, average REAL NOT NULL, updated_at INTEGER NOT NULL)',
    );
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Calendar cache indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_calendar_cache_type ON calendar_cache(cache_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_calendar_cache_expires ON calendar_cache(expires_at)',
    );

    // Lost & Found cache indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lost_found_type ON lost_found_cache(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lost_found_created ON lost_found_cache(created_at)',
    );

    // Cab Ride cache indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cab_ride_date ON cab_ride_cache(travel_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cab_ride_regno ON cab_ride_cache(posted_by_regno)',
    );

    // Events cache indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_cache_date ON events_cache(event_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_cache_source ON events_cache(event_source)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_cache_category ON events_cache(category)',
    );

    // Personal events indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_personal_events_date ON personal_events(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_personal_events_time ON personal_events(date, time_hour, time_minute)',
    );

    // Selected calendars indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_selected_calendars_active ON selected_calendars(is_active)',
    );

    // App preferences indexes (key is already primary key)
  }

  // ignore: unused_element
  Future<void> _dropAllTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS calendar_cache');
    await db.execute('DROP TABLE IF EXISTS personal_events');
    await db.execute('DROP TABLE IF EXISTS selected_calendars');
    await db.execute('DROP TABLE IF EXISTS app_preferences');
    await db.execute('DROP TABLE IF EXISTS lost_found_cache');
    await db.execute('DROP TABLE IF EXISTS cab_ride_cache');
    await db.execute('DROP TABLE IF EXISTS custom_themes');
    await db.execute('DROP TABLE IF EXISTS marks_read');
    await db.execute('DROP TABLE IF EXISTS marks_avg');
  }

  /// Check if database exists
  Future<bool> databaseExists() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);
      return await file.exists();
    } catch (e) {
      Logger.e('VitVerseDB', 'Error checking database existence', e);
      return false;
    }
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      Logger.e('VitVerseDB', 'Error getting database size', e);
      return 0;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _calendarDao = null;
      Logger.i('VitVerseDB', 'Database connection closed');
    }
  }

  /// Delete database files
  Future<void> deleteDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        _calendarDao = null;
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      // Delete WAL and SHM files
      final walFile = File('$path-wal');
      final shmFile = File('$path-shm');

      if (await walFile.exists()) {
        await walFile.delete();
      }

      if (await shmFile.exists()) {
        await shmFile.delete();
      }

      Logger.i('VitVerseDB', 'Database files deleted');
    } catch (e) {
      Logger.e('VitVerseDB', 'Error deleting database files', e);
    }
  }

  /// Force reset database
  Future<void> forceResetDatabase() async {
    try {
      await deleteDatabase();
      _instance = null;
      _database = null;
      _calendarDao = null;
      Logger.i('VitVerseDB', 'Database force reset completed');
    } catch (e) {
      Logger.e('VitVerseDB', 'Force reset failed', e);
    }
  }

  /// Clear all data (for app reset/uninstall only - NOT for logout)
  /// WARNING: This clears ALL VitVerse data including user preferences
  Future<void> clearAllData() async {
    try {
      if (_calendarDao != null) {
        await _calendarDao!.clearAllData();
      } else {
        final db = await database;
        await db.transaction((txn) async {
          await txn.delete('calendar_cache');
          await txn.delete('personal_events');
          await txn.delete('selected_calendars');
          await txn.delete('app_preferences');
          await txn.delete('lost_found_cache');
          await txn.delete('cab_ride_cache');
          await txn.delete('custom_themes');
          await txn.delete('events_cache');
        });
      }
      Logger.i('VitVerseDB', 'All VIT Verse data cleared');
    } catch (e) {
      Logger.e('VitVerseDB', 'Error clearing all data', e);
    }
  }

  Future<void> clearStudentData() async {
    try {
      final db = await database;
      await db.delete('marks_read');
      await db.delete('marks_avg');
      Logger.i('VitVerseDB', 'Student marks meta cleared');
    } catch (e) {
      Logger.e('VitVerseDB', 'Error in clearStudentData', e);
    }
  }

  /// Get table counts for debugging
  Future<Map<String, int>> getTableCounts() async {
    try {
      if (_calendarDao != null) {
        return await _calendarDao!.getTableCounts();
      }

      final db = await database;
      final counts = <String, int>{};
      final tables = [
        'calendar_cache',
        'personal_events',
        'selected_calendars',
        'app_preferences',
        'lost_found_cache',
        'cab_ride_cache',
        'custom_themes',
        'events_cache',
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
    } catch (e) {
      Logger.e('VitVerseDB', 'Error getting table counts', e);
      return {};
    }
  }

  /// Print database info for debugging
  Future<void> printDatabaseInfo() async {
    try {
      final exists = await databaseExists();
      final size = await getDatabaseSize();
      final counts = await getTableCounts();

      Logger.i('VitVerseDB', 'Database exists: $exists');
      Logger.i(
        'VitVerseDB',
        'Database size: ${(size / 1024).toStringAsFixed(2)} KB',
      );

      counts.forEach((table, count) {
        Logger.i('VitVerseDB', '$table: $count rows');
      });
    } catch (e) {
      Logger.e('VitVerseDB', 'Error printing database info', e);
    }
  }

  /// Vacuum database to optimize storage
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      Logger.i('VitVerseDB', 'Database vacuumed successfully');
    } catch (e) {
      Logger.e('VitVerseDB', 'Error vacuuming database', e);
    }
  }

  /// Analyze database for query optimization
  Future<void> analyze() async {
    try {
      final db = await database;
      await db.execute('ANALYZE');
      Logger.i('VitVerseDB', 'Database analyzed successfully');
    } catch (e) {
      Logger.e('VitVerseDB', 'Error analyzing database', e);
    }
  }
}
