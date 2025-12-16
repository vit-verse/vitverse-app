import '../../../../../core/database/entities/receipt.dart';
import '../../../../../core/utils/logger.dart';
import '../data/fee_data_provider.dart';

/// Business logic for fee management
/// Handles calculations, sorting, and data transformations
class FeeLogic {
  final FeeDataProvider _dataProvider = FeeDataProvider();

  Future<List<Receipt>> loadAllReceipts({bool sortByDateDesc = true}) async {
    try {
      final receipts = await _dataProvider.getAllReceipts();

      if (sortByDateDesc) {
        receipts.sort((a, b) {
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return b.date!.compareTo(a.date!);
        });
      }

      Logger.d('FeeLogic', 'Loaded and sorted ${receipts.length} receipts');
      return receipts;
    } catch (e) {
      Logger.e('FeeLogic', 'Error loading receipts', e);
      rethrow;
    }
  }

  Future<FeeSummary> calculateFeeSummary() async {
    try {
      final receipts = await _dataProvider.getAllReceipts();
      final totalPaid = await _dataProvider.getTotalAmountPaid();

      final totalFees = totalPaid;
      final dueAmount = 0.0;

      final summary = FeeSummary(
        totalFees: totalFees,
        totalPaid: totalPaid,
        dueAmount: dueAmount,
        receiptCount: receipts.length,
      );

      Logger.d('FeeLogic', 'Fee summary: ${summary.toString()}');
      return summary;
    } catch (e) {
      Logger.e('FeeLogic', 'Error calculating fee summary', e);
      rethrow;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return '$day $month $year';
  }

  /// Format currency amount
  String formatAmount(double? amount) {
    if (amount == null) return '₹0.00';

    // Format with Indian numbering system (lakhs, crores)
    final formatter = amount.toStringAsFixed(2);
    final parts = formatter.split('.');
    final intPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for Indian numbering system
    String formatted = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
        formatted = ',$formatted';
      }
      formatted = intPart[i] + formatted;
      count++;
    }

    return '₹$formatted.$decimalPart';
  }
}

/// Model for fee summary
class FeeSummary {
  final double totalFees;
  final double totalPaid;
  final double dueAmount;
  final int receiptCount;

  const FeeSummary({
    required this.totalFees,
    required this.totalPaid,
    required this.dueAmount,
    required this.receiptCount,
  });

  @override
  String toString() {
    return 'FeeSummary(totalFees: $totalFees, totalPaid: $totalPaid, dueAmount: $dueAmount, receipts: $receiptCount)';
  }
}
