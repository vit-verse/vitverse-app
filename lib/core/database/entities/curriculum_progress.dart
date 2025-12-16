/// Curriculum Progress Entity
/// Tracks credit requirements and completion by curriculum category
/// Data source: Step 2 - Student Grade History endpoint (Curriculum Details table)
class CurriculumProgress {
  final int? id;
  final String
  distributionType; // e.g., "Foundation Core - Basic Sciences and Mathematics"
  final double creditsRequired;
  final double creditsEarned;

  CurriculumProgress({
    this.id,
    required this.distributionType,
    required this.creditsRequired,
    required this.creditsEarned,
  });

  /// Check if curriculum category is complete
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

  /// Get status color (for UI)
  String get statusColor {
    if (isComplete) return 'green';
    if (completionPercentage >= 50) return 'orange';
    return 'red';
  }

  /// Convert to Map for SQLite database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'distribution_type': distributionType,
      'credits_required': creditsRequired,
      'credits_earned': creditsEarned,
    };
  }

  /// Create from SQLite Map
  factory CurriculumProgress.fromMap(Map<String, dynamic> map) {
    return CurriculumProgress(
      id: map['id'],
      distributionType: map['distribution_type'] ?? '',
      creditsRequired: (map['credits_required'] ?? 0.0).toDouble(),
      creditsEarned: (map['credits_earned'] ?? 0.0).toDouble(),
    );
  }

  /// Create empty curriculum progress
  factory CurriculumProgress.empty() {
    return CurriculumProgress(
      distributionType: '',
      creditsRequired: 0.0,
      creditsEarned: 0.0,
    );
  }

  @override
  String toString() {
    return 'CurriculumProgress(type: $distributionType, earned: $creditsEarned/$creditsRequired, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }

  /// SQL table creation statement
  static const String createTableSQL = '''
    CREATE TABLE IF NOT EXISTS curriculum_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      distribution_type TEXT NOT NULL UNIQUE,
      credits_required REAL NOT NULL,
      credits_earned REAL NOT NULL
    )
  ''';

  /// SQL index for faster queries
  static const String createIndexSQL = '''
    CREATE INDEX IF NOT EXISTS idx_curriculum_distribution 
    ON curriculum_progress(distribution_type)
  ''';
}
