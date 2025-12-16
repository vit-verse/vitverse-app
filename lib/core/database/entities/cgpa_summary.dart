/// CGPA Summary Entity
/// Stores overall CGPA and grade distribution from VTOP
/// Data source: Step 2 - Student Grade History endpoint
/// Saved in SharedPreferences for fast access on home screen
class CGPASummary {
  final double creditsRegistered;
  final double creditsEarned;
  final double cgpa;
  final int sGrades; // S grade count
  final int aGrades; // A grade count
  final int bGrades; // B grade count
  final int cGrades; // C grade count
  final int dGrades; // D grade count
  final int eGrades; // E grade count
  final int fGrades; // F grade count
  final int nGrades; // N grade count (failed subjects ---, not in life!)

  CGPASummary({
    required this.creditsRegistered,
    required this.creditsEarned,
    required this.cgpa,
    required this.sGrades,
    required this.aGrades,
    required this.bGrades,
    required this.cGrades,
    required this.dGrades,
    required this.eGrades,
    required this.fGrades,
    required this.nGrades,
  });

  /// Convert to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'creditsRegistered': creditsRegistered,
      'creditsEarned': creditsEarned,
      'cgpa': cgpa,
      'sGrades': sGrades,
      'aGrades': aGrades,
      'bGrades': bGrades,
      'cGrades': cGrades,
      'dGrades': dGrades,
      'eGrades': eGrades,
      'fGrades': fGrades,
      'nGrades': nGrades,
    };
  }

  /// Create from JSON (from SharedPreferences)
  factory CGPASummary.fromJson(Map<String, dynamic> json) {
    return CGPASummary(
      creditsRegistered: (json['creditsRegistered'] ?? 0.0).toDouble(),
      creditsEarned: (json['creditsEarned'] ?? 0.0).toDouble(),
      cgpa: (json['cgpa'] ?? 0.0).toDouble(),
      sGrades: json['sGrades'] ?? 0,
      aGrades: json['aGrades'] ?? 0,
      bGrades: json['bGrades'] ?? 0,
      cGrades: json['cGrades'] ?? 0,
      dGrades: json['dGrades'] ?? 0,
      eGrades: json['eGrades'] ?? 0,
      fGrades: json['fGrades'] ?? 0,
      nGrades: json['nGrades'] ?? 0,
    );
  }

  /// Create empty summary
  factory CGPASummary.empty() {
    return CGPASummary(
      creditsRegistered: 0.0,
      creditsEarned: 0.0,
      cgpa: 0.0,
      sGrades: 0,
      aGrades: 0,
      bGrades: 0,
      cGrades: 0,
      dGrades: 0,
      eGrades: 0,
      fGrades: 0,
      nGrades: 0,
    );
  }

  /// Calculate total courses
  int get totalCourses =>
      sGrades +
      aGrades +
      bGrades +
      cGrades +
      dGrades +
      eGrades +
      fGrades +
      nGrades;

  /// Calculate pass percentage
  double get passPercentage {
    if (totalCourses == 0) return 0.0;
    final passed = totalCourses - fGrades - nGrades;
    return (passed / totalCourses) * 100;
  }

  @override
  String toString() {
    return 'CGPASummary(cgpa: $cgpa, creditsEarned: $creditsEarned/$creditsRegistered, totalCourses: $totalCourses)';
  }
}
