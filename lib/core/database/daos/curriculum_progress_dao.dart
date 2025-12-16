import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/curriculum_progress.dart';

/// Data Access Object for CurriculumProgress entity
/// Provides CRUD operations for curriculum_progress table
class CurriculumProgressDao {
  static const String _tableName = 'curriculum_progress';

  /// Get database instance
  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert curriculum progress
  Future<int> insert(CurriculumProgress curriculum) async {
    final db = await _database;
    return await db.insert(
      _tableName,
      curriculum.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple curriculum progress entries
  Future<void> insertAll(List<CurriculumProgress> curriculums) async {
    final db = await _database;
    final batch = db.batch();
    for (final curriculum in curriculums) {
      batch.insert(
        _tableName,
        curriculum.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all curriculum progress entries
  /// Preserves database insertion order (matches VTOP extraction order)
  Future<List<CurriculumProgress>> getAll() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
    ); // No ORDER BY - preserve insertion order
    return maps.map((map) => CurriculumProgress.fromMap(map)).toList();
  }

  /// Get curriculum progress by distribution type
  Future<CurriculumProgress?> getByDistributionType(
    String distributionType,
  ) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'distribution_type = ?',
      whereArgs: [distributionType],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CurriculumProgress.fromMap(maps.first);
  }

  /// Update curriculum progress
  Future<int> update(CurriculumProgress curriculum) async {
    final db = await _database;
    return await db.update(
      _tableName,
      curriculum.toMap(),
      where: 'id = ?',
      whereArgs: [curriculum.id],
    );
  }

  /// Delete curriculum progress by ID
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all curriculum progress entries
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get curriculum progress count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }

  /// Get total credits required
  Future<double> getTotalCreditsRequired() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT SUM(credits_required) as total FROM $_tableName',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total credits earned
  Future<double> getTotalCreditsEarned() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT SUM(credits_earned) as total FROM $_tableName',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage() async {
    final required = await getTotalCreditsRequired();
    final earned = await getTotalCreditsEarned();
    if (required == 0) return 0.0;
    return (earned / required) * 100;
  }

  /// Get incomplete curriculum progress entries
  Future<List<CurriculumProgress>> getIncomplete() async {
    final db = await _database;
    final maps = await db.rawQuery(
      'SELECT * FROM $_tableName WHERE credits_earned < credits_required ORDER BY distribution_type ASC',
    );
    return maps.map((map) => CurriculumProgress.fromMap(map)).toList();
  }

  /// Get complete curriculum progress entries
  Future<List<CurriculumProgress>> getComplete() async {
    final db = await _database;
    final maps = await db.rawQuery(
      'SELECT * FROM $_tableName WHERE credits_earned >= credits_required ORDER BY distribution_type ASC',
    );
    return maps.map((map) => CurriculumProgress.fromMap(map)).toList();
  }
}
