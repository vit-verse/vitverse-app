/// Calculator State Model
/// Holds current academic data for calculations
class CalculatorState {
  final double currentCGPA;
  final double completedCredits;
  final double currentSemCredits;
  final double totalProgramCredits;
  final List<CourseGrade> currentCourses;

  const CalculatorState({
    required this.currentCGPA,
    required this.completedCredits,
    required this.currentSemCredits,
    required this.totalProgramCredits,
    this.currentCourses = const [],
  });

  /// Create empty state
  factory CalculatorState.empty() {
    return const CalculatorState(
      currentCGPA: 0.0,
      completedCredits: 0.0,
      currentSemCredits: 0.0,
      totalProgramCredits: 151.0,
      currentCourses: [],
    );
  }

  /// Calculate remaining credits
  double get remainingCredits =>
      (totalProgramCredits - completedCredits).clamp(0.0, totalProgramCredits);

  /// Calculate completion percentage
  double get completionPercentage =>
      totalProgramCredits > 0
          ? (completedCredits / totalProgramCredits * 100).clamp(0.0, 100.0)
          : 0.0;

  /// Check if current semester data is available
  bool get hasCurrentSemesterData =>
      currentSemCredits > 0 && currentCourses.isNotEmpty;

  /// Create copy with updated fields
  CalculatorState copyWith({
    double? currentCGPA,
    double? completedCredits,
    double? currentSemCredits,
    double? totalProgramCredits,
    List<CourseGrade>? currentCourses,
  }) {
    return CalculatorState(
      currentCGPA: currentCGPA ?? this.currentCGPA,
      completedCredits: completedCredits ?? this.completedCredits,
      currentSemCredits: currentSemCredits ?? this.currentSemCredits,
      totalProgramCredits: totalProgramCredits ?? this.totalProgramCredits,
      currentCourses: currentCourses ?? this.currentCourses,
    );
  }

  @override
  String toString() {
    return 'CalculatorState(cgpa: $currentCGPA, completed: $completedCredits, current: $currentSemCredits, total: $totalProgramCredits, courses: ${currentCourses.length})';
  }
}

/// Course with Grade for calculations
class CourseGrade {
  final String courseCode;
  final String courseTitle;
  final double credits;
  final String? grade; // null for ongoing courses

  const CourseGrade({
    required this.courseCode,
    required this.courseTitle,
    required this.credits,
    this.grade,
  });

  /// Check if course has grade assigned
  bool get hasGrade => grade != null && grade!.isNotEmpty;

  /// Create copy with updated grade
  CourseGrade copyWith({
    String? courseCode,
    String? courseTitle,
    double? credits,
    String? grade,
  }) {
    return CourseGrade(
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      credits: credits ?? this.credits,
      grade: grade ?? this.grade,
    );
  }

  @override
  String toString() {
    return 'CourseGrade(code: $courseCode, credits: $credits, grade: ${grade ?? "N/A"})';
  }
}
