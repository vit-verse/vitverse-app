import '../models/curriculum_with_progress.dart';
import '../models/basket_with_progress.dart';
import '../models/semester_performance.dart';
import '../../../../../core/database/entities/cgpa_summary.dart';

/// Business logic for Academic Performance calculations
class AcademicPerformanceLogic {
  /// Format CGPA for display (e.g., "8.48")
  static String formatCGPA(double cgpa) {
    return cgpa.toStringAsFixed(2);
  }

  /// Format credits for display (e.g., "86.5/120.0")
  static String formatCredits(double earned, double total) {
    return '${earned.toStringAsFixed(1)}/${total.toStringAsFixed(1)}';
  }

  /// Calculate overall degree progress percentage
  static double calculateDegreeProgress(double earned, double required) {
    if (required == 0) return 0.0;
    return (earned / required) * 100;
  }

  /// Get progress status text
  static String getProgressStatus(double percentage) {
    if (percentage >= 100) return 'Completed';
    if (percentage >= 75) return 'Excellent Progress';
    if (percentage >= 50) return 'Good Progress';
    if (percentage >= 25) return 'In Progress';
    return 'Just Started';
  }

  /// Calculate total curriculum credits
  static Map<String, double> calculateCurriculumTotals(
    List<CurriculumWithProgress> curriculums,
  ) {
    double totalEarned = 0.0;
    double totalInProgress = 0.0;
    double totalRequired = 0.0;

    for (final curriculum in curriculums) {
      totalEarned += curriculum.earnedCredits;
      totalInProgress += curriculum.inProgressCredits;
      totalRequired += curriculum.requiredCredits;
    }

    return {
      'earned': totalEarned,
      'inProgress': totalInProgress,
      'required': totalRequired,
    };
  }

  /// Calculate total basket credits
  static Map<String, double> calculateBasketTotals(
    List<BasketWithProgress> baskets,
  ) {
    double totalEarned = 0.0;
    double totalInProgress = 0.0;
    double totalRequired = 0.0;

    for (final basket in baskets) {
      totalEarned += basket.earnedCredits;
      totalInProgress += basket.inProgressCredits;
      totalRequired += basket.requiredCredits;
    }

    return {
      'earned': totalEarned,
      'inProgress': totalInProgress,
      'required': totalRequired,
    };
  }

  /// Get grade color based on grade letter (returns opacity for theme color)
  static double getGradeOpacity(String grade) {
    switch (grade.toUpperCase()) {
      case 'S':
        return 1.0;
      case 'A':
        return 0.9;
      case 'B':
        return 0.75;
      case 'C':
        return 0.6;
      case 'D':
        return 0.45;
      case 'E':
        return 0.3;
      case 'F':
      case 'N':
        return 0.15;
      default:
        return 0.5;
    }
  }

  /// Sort semesters by ID (descending - newest first)
  static List<SemesterPerformance> sortSemestersByDate(
    List<SemesterPerformance> semesters,
  ) {
    final sorted = List<SemesterPerformance>.from(semesters);
    sorted.sort((a, b) => b.semesterId.compareTo(a.semesterId));
    return sorted;
  }

  /// Get grade distribution from CGPA summary
  static Map<String, int> getGradeDistribution(CGPASummary cgpa) {
    return {
      'S': cgpa.sGrades,
      'A': cgpa.aGrades,
      'B': cgpa.bGrades,
      'C': cgpa.cGrades,
      'D': cgpa.dGrades,
      'E': cgpa.eGrades,
      'F': cgpa.fGrades,
      'N': cgpa.nGrades,
    };
  }

  /// Get grade distribution as list for charts
  static List<MapEntry<String, int>> getGradeDistributionList(
    CGPASummary cgpa,
  ) {
    final distribution = getGradeDistribution(cgpa);
    // Filter out zero counts
    return distribution.entries.where((e) => e.value > 0).toList();
  }

  /// Calculate pass percentage
  static double calculatePassPercentage(CGPASummary cgpa) {
    final totalCourses = cgpa.totalCourses;
    if (totalCourses == 0) return 0.0;
    final failed = cgpa.fGrades + cgpa.nGrades;
    final passed = totalCourses - failed;
    return (passed / totalCourses) * 100;
  }

  /// Format percentage for display
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}
