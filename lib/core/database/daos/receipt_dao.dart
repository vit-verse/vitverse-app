import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../entities/receipt.dart';

/// Data Access Object for Receipt entity
/// Provides methods to interact with the receipts table in the database
class ReceiptDao {
  static const String _tableName = 'receipts';

  Future<Database> get _database async => VitConnectDatabase.instance.database;

  /// Insert a single receipt
  Future<int> insert(Receipt receipt) async {
    final db = await _database;
    return await db.insert(_tableName, receipt.toMap());
  }

  /// Insert multiple receipts
  Future<void> insertAll(List<Receipt> receipts) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final receipt in receipts) {
        await txn.insert(_tableName, receipt.toMap());
      }
    });
  }

  /// Get all receipts
  Future<List<Receipt>> getAll() async {
    final db = await _database;
    final maps = await db.query(_tableName);
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  /// Get receipt by number
  Future<Receipt?> getByNumber(int number) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'number = ?',
      whereArgs: [number],
    );
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  /// Delete all receipts
  Future<int> deleteAll() async {
    final db = await _database;
    return await db.delete(_tableName);
  }

  /// Get receipt count
  Future<int> getCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }
}
