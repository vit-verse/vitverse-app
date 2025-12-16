/// Basket Progress Entity
/// Tracks elective basket requirements and completion
/// Data source: Step 2 - Student Grade History endpoint (Basket Details table)
class BasketProgress {
  final int? id;
  final String
  basketTitle; // e.g., "Foreign Language", "Extra curricular activities"
  final String distributionType; // e.g., "FCHSSM", "NGCR"
  final double creditsRequired;
  final double creditsEarned;

  BasketProgress({
    this.id,
    required this.basketTitle,
    required this.distributionType,
    required this.creditsRequired,
    required this.creditsEarned,
  });

  /// Check if basket requirement is complete
  bool get isComplete => creditsEarned >= creditsRequired;

  /// Calculate completion percentage
  double get completionPercentage {
    if (creditsRequired == 0) return 0.0;
    return (creditsEarned / creditsRequired) * 100;
  }

  /// Get remaining credits needed
  double get creditsRemaining {
    final remaining = creditsRequired - creditsEarned;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Get status for UI display
  String get status {
    if (isComplete) return 'Completed';
    if (creditsEarned > 0) return 'In Progress';
    return 'Not Started';
  }

  /// Convert to Map for SQLite database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'basket_title': basketTitle,
      'distribution_type': distributionType,
      'credits_required': creditsRequired,
      'credits_earned': creditsEarned,
    };
  }

  /// Create from SQLite Map
  factory BasketProgress.fromMap(Map<String, dynamic> map) {
    return BasketProgress(
      id: map['id'],
      basketTitle: map['basket_title'] ?? '',
      distributionType: map['distribution_type'] ?? '',
      creditsRequired: (map['credits_required'] ?? 0.0).toDouble(),
      creditsEarned: (map['credits_earned'] ?? 0.0).toDouble(),
    );
  }

  /// Create empty basket progress
  factory BasketProgress.empty() {
    return BasketProgress(
      basketTitle: '',
      distributionType: '',
      creditsRequired: 0.0,
      creditsEarned: 0.0,
    );
  }

  @override
  String toString() {
    return 'BasketProgress(title: $basketTitle, type: $distributionType, earned: $creditsEarned/$creditsRequired, status: $status)';
  }

  /// SQL table creation statement
  static const String createTableSQL = '''
    CREATE TABLE IF NOT EXISTS basket_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      basket_title TEXT NOT NULL,
      distribution_type TEXT NOT NULL,
      credits_required REAL NOT NULL,
      credits_earned REAL NOT NULL,
      UNIQUE(basket_title, distribution_type)
    )
  ''';

  /// SQL index for faster queries
  static const String createIndexSQL = '''
    CREATE INDEX IF NOT EXISTS idx_basket_distribution 
    ON basket_progress(distribution_type)
  ''';
}
