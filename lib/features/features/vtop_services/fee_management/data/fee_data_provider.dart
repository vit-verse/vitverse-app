import '../../../../../core/database/database.dart';
import '../../../../../core/database/entities/receipt.dart';
import '../../../../../core/utils/logger.dart';

class FeeDataProvider {
  final VitConnectDatabase _database = VitConnectDatabase.instance;

  Future<List<Receipt>> getAllReceipts() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'receipts',
        orderBy: 'date DESC',
      );

      Logger.d(
        'FeeDataProvider',
        'Loaded ${maps.length} receipts from database',
      );

      return List.generate(maps.length, (i) {
        return Receipt.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.e('FeeDataProvider', 'Error loading receipts', e);
      rethrow;
    }
  }

  Future<double> getTotalAmountPaid() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM receipts WHERE amount IS NOT NULL',
      );

      final total = result.first['total'] as double? ?? 0.0;
      Logger.d('FeeDataProvider', 'Total amount paid: ₹$total');

      return total;
    } catch (e) {
      Logger.e('FeeDataProvider', 'Error calculating total amount', e);
      return 0.0;
    }
  }
}
