import 'package:sqflite/sqflite.dart';
import '../entities/lost_found_cache.dart';
import '../../utils/logger.dart';

/// Data Access Object for Lost & Found cache
class LostFoundDao {
  final Database _database;

  LostFoundDao(this._database);

  /// Get all cached items
  Future<List<LostFoundCacheEntity>> getAllItems() async {
    try {
      final results = await _database.query(
        'lost_found_cache',
        orderBy: 'created_at DESC',
      );

      return results.map((map) => LostFoundCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('LostFoundDao', 'Error getting all items', e);
      return [];
    }
  }

  /// Get items by type
  Future<List<LostFoundCacheEntity>> getItemsByType(String type) async {
    try {
      final results = await _database.query(
        'lost_found_cache',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => LostFoundCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('LostFoundDao', 'Error getting items by type: $type', e);
      return [];
    }
  }

  /// Insert or update item
  Future<void> insertOrUpdate(LostFoundCacheEntity item) async {
    try {
      await _database.insert(
        'lost_found_cache',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.e('LostFoundDao', 'Error inserting/updating item: ${item.id}', e);
    }
  }

  /// Insert multiple items
  Future<void> insertAll(List<LostFoundCacheEntity> items) async {
    try {
      await _database.transaction((txn) async {
        for (final item in items) {
          await txn.insert(
            'lost_found_cache',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      Logger.d('LostFoundDao', 'Cached ${items.length} items');
    } catch (e) {
      Logger.e('LostFoundDao', 'Error inserting all items', e);
    }
  }

  /// Clear all cached items
  Future<void> clearAll() async {
    try {
      await _database.delete('lost_found_cache');
      Logger.d('LostFoundDao', 'Cache cleared');
    } catch (e) {
      Logger.e('LostFoundDao', 'Error clearing cache', e);
    }
  }

  /// Delete items older than days
  Future<void> deleteOlderThan(int days) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

      final deletedCount = await _database.delete(
        'lost_found_cache',
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );

      Logger.d('LostFoundDao', 'Deleted $deletedCount old items');
    } catch (e) {
      Logger.e('LostFoundDao', 'Error deleting old items', e);
    }
  }

  /// Get cache count
  Future<int> getCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM lost_found_cache',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      Logger.e('LostFoundDao', 'Error getting count', e);
      return 0;
    }
  }
}
