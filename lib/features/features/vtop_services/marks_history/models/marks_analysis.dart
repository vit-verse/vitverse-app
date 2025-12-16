/// Model for marks analysis data
class MarksAnalysis {
  final Map<String, double> semesterAverages;
  final double overallAverage;
  final double highestSemesterAverage;
  final double lowestSemesterAverage;
  final int totalCourses;
  final int totalAssessments;
  final List<String> semesters;

  const MarksAnalysis({
    required this.semesterAverages,
    required this.overallAverage,
    required this.highestSemesterAverage,
    required this.lowestSemesterAverage,
    required this.totalCourses,
    required this.totalAssessments,
    required this.semesters,
  });

  factory MarksAnalysis.empty() {
    return const MarksAnalysis(
      semesterAverages: {},
      overallAverage: 0.0,
      highestSemesterAverage: 0.0,
      lowestSemesterAverage: 0.0,
      totalCourses: 0,
      totalAssessments: 0,
      semesters: [],
    );
  }
}
