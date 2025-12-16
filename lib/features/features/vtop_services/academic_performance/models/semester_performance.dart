/// Model representing semester-wise academic performance
class SemesterPerformance {
  final String semesterId; // e.g., "CH20242505"
  final String semesterName; // e.g., "Winter Semester 2024-25"
  final double semesterGpa; // GPA for this semester
  final int courseCount; // Number of courses in this semester
  final double creditsEarned; // Credits earned in this semester
  final List<String> grades; // List of grades obtained

  SemesterPerformance({
    required this.semesterId,
    required this.semesterName,
    required this.semesterGpa,
    required this.courseCount,
    required this.creditsEarned,
    required this.grades,
  });

  /// Check if semester has data
  bool get hasData => courseCount > 0;

  /// Get grade distribution summary
  Map<String, int> get gradeDistribution {
    final distribution = <String, int>{};
    for (final grade in grades) {
      distribution[grade] = (distribution[grade] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get GPA formatted string
  String get gpaFormatted => semesterGpa.toStringAsFixed(2);

  /// Get credits formatted string
  String get creditsFormatted => creditsEarned.toStringAsFixed(1);

  /// Create empty semester
  factory SemesterPerformance.empty() {
    return SemesterPerformance(
      semesterId: '',
      semesterName: '',
      semesterGpa: 0.0,
      courseCount: 0,
      creditsEarned: 0.0,
      grades: [],
    );
  }

  @override
  String toString() {
    return 'SemesterPerformance(name: $semesterName, gpa: $gpaFormatted, courses: $courseCount, credits: $creditsFormatted)';
  }
}
