/// Receipt entity representing fee payment receipts and transaction history
/// Maps to the 'receipts' table in the database
/// Independent entity with natural primary key
// VTOP doesn’t categorize fees clearly into Academic, Hostel, Mess, and Other sections, which makes it confusing for users  -- ;)
class Receipt {
  final int number; // Receipt number (primary key)
  final double? amount;
  final int? date; // Payment timestamp

  const Receipt({required this.number, this.amount, this.date});

  /// Create Receipt from database map
  factory Receipt.fromMap(Map<String, dynamic> map) {
    // Handle date field - can be String (from database TEXT) or int
    int? dateValue;
    final dateField = map['date'];
    if (dateField != null) {
      if (dateField is int) {
        dateValue = dateField;
      } else if (dateField is String) {
        dateValue = int.tryParse(dateField);
      }
    }

    return Receipt(
      number: map['number'] as int,
      amount: map['amount'] as double?,
      date: dateValue,
    );
  }

  /// Convert Receipt to database map
  Map<String, dynamic> toMap() {
    return {'number': number, 'amount': amount, 'date': date};
  }

  /// Get payment date
  DateTime? get paymentDate {
    if (date == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(date!);
  }

  /// Format amount for display
  String get formattedAmount {
    if (amount == null) return 'N/A';
    return '₹${amount!.toStringAsFixed(2)}';
  }

  /// Create copy with updated fields
  Receipt copyWith({int? number, double? amount, int? date}) {
    return Receipt(
      number: number ?? this.number,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Receipt{number: $number, amount: $amount, date: $date}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt &&
        other.number == number &&
        other.amount == amount &&
        other.date == date;
  }

  @override
  int get hashCode {
    return number.hashCode ^ amount.hashCode ^ date.hashCode;
  }
}
