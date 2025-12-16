/// VIT Official Grade Information
/// Based on Academic Regulations 2024-25
class GradeInfo {
  final String grade;
  final double gradePoint;
  final int marksMin;
  final int marksMax;
  final String remarks;
  final bool countsInCGPA;

  const GradeInfo({
    required this.grade,
    required this.gradePoint,
    required this.marksMin,
    required this.marksMax,
    required this.remarks,
    required this.countsInCGPA,
  });

  /// VIT Official Grading System
  static const List<GradeInfo> vitGrades = [
    GradeInfo(
      grade: 'S',
      gradePoint: 10.0,
      marksMin: 90,
      marksMax: 100,
      remarks: 'Outstanding',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'A',
      gradePoint: 9.0,
      marksMin: 80,
      marksMax: 89,
      remarks: 'Excellent',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'B',
      gradePoint: 8.0,
      marksMin: 70,
      marksMax: 79,
      remarks: 'Very Good',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'C',
      gradePoint: 7.0,
      marksMin: 60,
      marksMax: 69,
      remarks: 'Good',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'D',
      gradePoint: 6.0,
      marksMin: 55,
      marksMax: 59,
      remarks: 'Average',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'E',
      gradePoint: 5.0,
      marksMin: 50,
      marksMax: 54,
      remarks: 'Below Average',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'F',
      gradePoint: 0.0,
      marksMin: 0,
      marksMax: 49,
      remarks: 'Fail',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'N',
      gradePoint: 0.0,
      marksMin: 0,
      marksMax: 0,
      remarks: 'Non-completion',
      countsInCGPA: true,
    ),
    GradeInfo(
      grade: 'W',
      gradePoint: 0.0,
      marksMin: 0,
      marksMax: 0,
      remarks: 'Withdrawn',
      countsInCGPA: false,
    ),
    GradeInfo(
      grade: 'U',
      gradePoint: 0.0,
      marksMin: 0,
      marksMax: 0,
      remarks: 'Audit Completed',
      countsInCGPA: false,
    ),
    GradeInfo(
      grade: 'P',
      gradePoint: 0.0,
      marksMin: 0,
      marksMax: 0,
      remarks: 'Pass',
      countsInCGPA: false,
    ),
  ];

  /// Get grade point for a grade letter
  static double getGradePoint(String grade) {
    final gradeInfo = vitGrades.firstWhere(
      (g) => g.grade == grade.toUpperCase(),
      orElse: () => vitGrades[6], // Default to F
    );
    return gradeInfo.gradePoint;
  }

  /// Get grade info for a grade letter
  static GradeInfo? getGradeInfo(String grade) {
    try {
      return vitGrades.firstWhere((g) => g.grade == grade.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  /// Check if grade counts in CGPA calculation
  static bool countsInCalculation(String grade) {
    final gradeInfo = getGradeInfo(grade);
    return gradeInfo?.countsInCGPA ?? false;
  }

  /// Get valid grades for calculation (S to F, N)
  static List<GradeInfo> get validGrades =>
      vitGrades.where((g) => g.countsInCGPA).toList();

  /// Get passing grades (S to E)
  static List<GradeInfo> get passingGrades =>
      vitGrades.where((g) => g.countsInCGPA && g.gradePoint >= 5.0).toList();

  /// Get failing grades (F, N)
  static List<GradeInfo> get failingGrades =>
      vitGrades.where((g) => g.countsInCGPA && g.gradePoint == 0.0).toList();

  /// Convert CGPA to percentage (VIT Official Formula)
  static double cgpaToPercentage(double cgpa) {
    return cgpa * 10.0;
  }

  /// Convert percentage to approximate CGPA
  static double percentageToCGPA(double percentage) {
    return percentage / 10.0;
  }
}
