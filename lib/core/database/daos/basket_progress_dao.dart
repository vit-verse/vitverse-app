import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/basket_progress.dart';

/// Data Access Object for BasketProgress entity
/// Provides CRUD operations for basket_progress table
class BasketProgressDao {
  static const String _tableName = 'basket_progress';

  /// Get database instance
  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert basket progress
  Future<int> insert(BasketProgress basket) async {
    final db = await _database;
    return await db.insert(
      _tableName,
      basket.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple basket progress entries
  Future<void> insertAll(List<BasketProgress> baskets) async {
    final db = await _database;
    final batch = db.batch();
    for (final basket in baskets) {
      batch.insert(
        _tableName,
        basket.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all basket progress entries
  /// Preserves database insertion order (matches VTOP extraction order)
  Future<List<BasketProgress>> getAll() async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
    ); // No ORDER BY - preserve insertion order
    return maps.map((map) => BasketProgress.fromMap(map)).toList();
  }

  /// Get basket progress by basket title
  Future<BasketProgress?> getByBasketTitle(String basketTitle) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'basket_title = ?',
      whereArgs: [basketTitle],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BasketProgress.fromMap(maps.first);
  }

  /// Get basket progress by distribution type
  Future<List<BasketProgress>> getByDistributionType(
    String distributionType,
  ) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'distribution_type = ?',
      whereArgs: [distributionType],
      orderBy: 'basket_title ASC',
    );
    return maps.map((map) => BasketProgress.fromMap(map)).toList();
  }

  /// Update basket progress
  Future<int> update(BasketProgress basket) async {
    final db = await _database;
    return await db.update(
      _tableName,
      basket.toMap(),
      where: 'id = ?',
      whereArgs: [basket.id],
    );
  }

  /// Delete basket progress by ID
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all basket progress entries
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get basket progress count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }

  /// Get total credits required across all baskets
  Future<double> getTotalCreditsRequired() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT SUM(credits_required) as total FROM $_tableName',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total credits earned across all baskets
  Future<double> getTotalCreditsEarned() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT SUM(credits_earned) as total FROM $_tableName',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get completion percentage across all baskets
  Future<double> getCompletionPercentage() async {
    final required = await getTotalCreditsRequired();
    final earned = await getTotalCreditsEarned();
    if (required == 0) return 0.0;
    return (earned / required) * 100;
  }

  /// Get incomplete basket progress entries
  Future<List<BasketProgress>> getIncomplete() async {
    final db = await _database;
    final maps = await db.rawQuery(
      'SELECT * FROM $_tableName WHERE credits_earned < credits_required ORDER BY basket_title ASC',
    );
    return maps.map((map) => BasketProgress.fromMap(map)).toList();
  }

  /// Get complete basket progress entries
  Future<List<BasketProgress>> getComplete() async {
    final db = await _database;
    final maps = await db.rawQuery(
      'SELECT * FROM $_tableName WHERE credits_earned >= credits_required ORDER BY basket_title ASC',
    );
    return maps.map((map) => BasketProgress.fromMap(map)).toList();
  }

  /// Get basket progress with most remaining credits
  Future<BasketProgress?> getMostIncomplete() async {
    final db = await _database;
    final maps = await db.rawQuery(
      'SELECT * FROM $_tableName WHERE credits_earned < credits_required ORDER BY (credits_required - credits_earned) DESC LIMIT 1',
    );
    if (maps.isEmpty) return null;
    return BasketProgress.fromMap(maps.first);
  }
}
