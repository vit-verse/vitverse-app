import '../models/calculator_state.dart';
import '../models/calculator_result.dart';
import '../models/grade_info.dart';
import '../../../../../core/utils/logger.dart';

/// Calculator Logic
/// Implements all CGPA/GPA calculation formulas based on VIT Academic Regulations
class CalculatorLogic {
  static const String _tag = 'CalculatorLogic';

  /// Calculate GPA for a list of courses with grades
  /// Formula: GPA = Σ(C_i × GP_i) / ΣC_i
  static double calculateGPA(List<CourseGrade> courses) {
    if (courses.isEmpty) return 0.0;

    double totalWeightedPoints = 0.0;
    double totalCredits = 0.0;

    for (final course in courses) {
      if (course.hasGrade) {
        final gradePoint = GradeInfo.getGradePoint(course.grade!);
        if (GradeInfo.countsInCalculation(course.grade!)) {
          totalWeightedPoints += course.credits * gradePoint;
          totalCredits += course.credits;
        }
      }
    }

    if (totalCredits == 0) return 0.0;

    final gpa = totalWeightedPoints / totalCredits;
    Logger.d(
      _tag,
      'Calculated GPA: $gpa (weighted: $totalWeightedPoints, credits: $totalCredits)',
    );
    return gpa.clamp(0.0, 10.0);
  }

  /// Calculate new CGPA after adding semester GPA
  /// Formula: NewCGPA = ((PrevCGPA × PrevCredits) + (CurrentGPA × CurrentCredits)) / (PrevCredits + CurrentCredits)
  static double calculateNewCGPA({
    required double prevCGPA,
    required double prevCredits,
    required double currentGPA,
    required double currentCredits,
  }) {
    final totalCredits = prevCredits + currentCredits;
    if (totalCredits == 0) return 0.0;

    final numerator = (prevCGPA * prevCredits) + (currentGPA * currentCredits);
    final newCGPA = numerator / totalCredits;

    Logger.d(
      _tag,
      'New CGPA: $newCGPA (prev: $prevCGPA, current GPA: $currentGPA)',
    );
    return newCGPA.clamp(0.0, 10.0);
  }

  /// ESTIMATOR: Calculate required GPA to reach target CGPA
  /// Formula: RequiredGPA = ((TargetCGPA × (PrevCredits + CurrentCredits)) - (PrevCGPA × PrevCredits)) / CurrentCredits
  static EstimatorResult calculateRequiredGPA({
    required double currentCGPA,
    required double completedCredits,
    required double currentSemCredits,
    required double targetCGPA,
  }) {
    if (currentSemCredits <= 0) {
      return EstimatorResult(
        targetCGPA: targetCGPA,
        requiredGPA: 0.0,
        isAchievable: false,
        message: 'No current semester credits available',
        progressPercentage: 0.0,
      );
    }

    final totalCreditsAfter = completedCredits + currentSemCredits;
    final numerator =
        (targetCGPA * totalCreditsAfter) - (currentCGPA * completedCredits);
    final requiredGPA = numerator / currentSemCredits;

    // Calculate progress percentage
    final progressPercentage =
        currentCGPA >= targetCGPA
            ? 100.0
            : ((currentCGPA / targetCGPA) * 100).clamp(0.0, 100.0);

    // Check if achievable
    final isAchievable = requiredGPA >= 0.0 && requiredGPA <= 10.0;

    // Generate message
    String message;
    if (currentCGPA >= targetCGPA) {
      message =
          'Target already achieved! Current CGPA: ${currentCGPA.toStringAsFixed(2)}';
    } else if (requiredGPA > 10.0) {
      message =
          'Target impossible this semester. Required GPA: ${requiredGPA.toStringAsFixed(2)} (max is 10.0)';
    } else if (requiredGPA < 5.0) {
      message =
          'Target already within reach! Minimum passing GPA is sufficient.';
    } else {
      message =
          'You need a GPA of ${requiredGPA.toStringAsFixed(2)} this semester to reach ${targetCGPA.toStringAsFixed(2)} CGPA';
    }

    Logger.d(
      _tag,
      'Estimator: Target=$targetCGPA, Required GPA=$requiredGPA, Achievable=$isAchievable',
    );

    return EstimatorResult(
      targetCGPA: targetCGPA,
      requiredGPA: requiredGPA.clamp(0.0, 10.0),
      isAchievable: isAchievable,
      message: message,
      progressPercentage: progressPercentage,
    );
  }

  /// PREDICTOR: Calculate projected CGPA after semester
  /// Formula: NewCGPA = ((PrevCGPA × PrevCredits) + (ExpectedGPA × CurrentCredits)) / (PrevCredits + CurrentCredits)
  static PredictorResult calculateProjectedCGPA({
    required double currentCGPA,
    required double completedCredits,
    required double expectedGPA,
    required double currentSemCredits,
  }) {
    final projectedCGPA = calculateNewCGPA(
      prevCGPA: currentCGPA,
      prevCredits: completedCredits,
      currentGPA: expectedGPA,
      currentCredits: currentSemCredits,
    );

    final cgpaChange = projectedCGPA - currentCGPA;

    // Determine trend
    String trend;
    if (cgpaChange >= 0.1) {
      trend = 'improving';
    } else if (cgpaChange <= -0.1) {
      trend = 'declining';
    } else {
      trend = 'maintaining';
    }

    Logger.d(
      _tag,
      'Predictor: Current=$currentCGPA, Expected GPA=$expectedGPA, Projected=$projectedCGPA, Change=$cgpaChange',
    );

    return PredictorResult(
      currentCGPA: currentCGPA,
      expectedGPA: expectedGPA,
      projectedCGPA: projectedCGPA,
      cgpaChange: cgpaChange,
      trend: trend,
    );
  }

  /// SUMMARY: Calculate max and min possible CGPA
  static SummaryResult calculateSummary({
    required double currentCGPA,
    required double completedCredits,
    required double totalProgramCredits,
  }) {
    final remainingCredits = (totalProgramCredits - completedCredits).clamp(
      0.0,
      totalProgramCredits,
    );

    // Max CGPA (if all remaining credits = S grade = 10.0)
    final maxPossibleCGPA =
        remainingCredits > 0
            ? calculateNewCGPA(
              prevCGPA: currentCGPA,
              prevCredits: completedCredits,
              currentGPA: 10.0,
              currentCredits: remainingCredits,
            )
            : currentCGPA;

    // Min CGPA (if all remaining credits = F grade = 0.0)
    final minPossibleCGPA =
        remainingCredits > 0
            ? calculateNewCGPA(
              prevCGPA: currentCGPA,
              prevCredits: completedCredits,
              currentGPA: 0.0,
              currentCredits: remainingCredits,
            )
            : currentCGPA;

    // Simulated CGPA for different grades
    final gradeSimulations = <String, double>{};
    final validGrades = ['S', 'A', 'B', 'C', 'D', 'E', 'F'];
    for (final grade in validGrades) {
      final gradePoint = GradeInfo.getGradePoint(grade);
      gradeSimulations[grade] =
          remainingCredits > 0
              ? calculateNewCGPA(
                prevCGPA: currentCGPA,
                prevCredits: completedCredits,
                currentGPA: gradePoint,
                currentCredits: remainingCredits,
              )
              : currentCGPA;
    }

    final completionPercentage =
        totalProgramCredits > 0
            ? (completedCredits / totalProgramCredits * 100).clamp(0.0, 100.0)
            : 0.0;

    Logger.d(
      _tag,
      'Summary: Max=$maxPossibleCGPA, Min=$minPossibleCGPA, Remaining=$remainingCredits',
    );

    return SummaryResult(
      currentCGPA: currentCGPA,
      maxPossibleCGPA: maxPossibleCGPA,
      minPossibleCGPA: minPossibleCGPA,
      gradeSimulations: gradeSimulations,
      completionPercentage: completionPercentage,
      remainingCredits: remainingCredits,
    );
  }

  /// GRADE INSIGHTS: Calculate CGPA for custom grade distribution
  /// Formula: ProjectedCGPA = ((PrevCGPA × PrevCredits) + Σ(p_g × GP_g × RemainingCredits)) / TotalCredits
  static GradeMixResult calculateGradeMixCGPA({
    required double currentCGPA,
    required double completedCredits,
    required double remainingCredits,
    required Map<String, double> gradePercentages, // Grade -> percentage (0-1)
  }) {
    // Calculate weighted GPA for grade mix
    double weightedGPA = 0.0;
    final gradeCounts = <String, int>{};

    // Assume equal credit distribution (for simplification)
    gradePercentages.forEach((grade, percentage) {
      final gradePoint = GradeInfo.getGradePoint(grade);
      weightedGPA += gradePoint * percentage;

      // Calculate approximate course count (assuming 3 credits per course)
      final courseCount = (remainingCredits * percentage / 3).round();
      gradeCounts[grade] = courseCount;
    });

    // Calculate projected CGPA
    final projectedCGPA = calculateNewCGPA(
      prevCGPA: currentCGPA,
      prevCredits: completedCredits,
      currentGPA: weightedGPA,
      currentCredits: remainingCredits,
    );

    Logger.d(
      _tag,
      'GradeMix: Weighted GPA=$weightedGPA, Projected CGPA=$projectedCGPA',
    );

    return GradeMixResult(
      gradePercentages: gradePercentages,
      projectedCGPA: projectedCGPA,
      requiredCredits: remainingCredits,
      gradeCounts: gradeCounts,
    );
  }

  /// Calculate CGPA change impact for a single course
  /// Formula: ΔCGPA = ((GP_new - GP_old) × CourseCredits) / TotalCredits
  static double calculateCourseImpact({
    required double oldGradePoint,
    required double newGradePoint,
    required double courseCredits,
    required double totalCredits,
  }) {
    if (totalCredits == 0) return 0.0;

    final deltaCGPA =
        ((newGradePoint - oldGradePoint) * courseCredits) / totalCredits;
    return deltaCGPA;
  }

  /// Format CGPA/GPA for display (2 decimal places)
  static String formatCGPA(double cgpa) {
    return cgpa.toStringAsFixed(2);
  }

  /// Get color based on CGPA value
  static String getCGPACategory(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding';
    if (cgpa >= 8.0) return 'Excellent';
    if (cgpa >= 7.0) return 'Good';
    if (cgpa >= 6.0) return 'Average';
    if (cgpa >= 5.0) return 'Below Average';
    return 'Needs Improvement';
  }

  /// Calculate percentage of courses in each grade
  static Map<String, double> calculateGradeDistribution(
    List<CourseGrade> courses,
  ) {
    if (courses.isEmpty) return {};

    final distribution = <String, int>{};
    int totalCourses = 0;

    for (final course in courses) {
      if (course.hasGrade) {
        distribution[course.grade!] = (distribution[course.grade!] ?? 0) + 1;
        totalCourses++;
      }
    }

    if (totalCourses == 0) return {};

    // Convert to percentages
    final percentages = <String, double>{};
    distribution.forEach((grade, count) {
      percentages[grade] = (count / totalCourses) * 100;
    });

    return percentages;
  }
}
