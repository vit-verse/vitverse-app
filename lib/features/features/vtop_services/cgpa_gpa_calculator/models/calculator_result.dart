/// Calculator Result Models
/// Contains calculation results for different calculator types
library;

/// CGPA Estimator Result
/// Shows required GPA to reach target CGPA
class EstimatorResult {
  final double targetCGPA;
  final double requiredGPA;
  final bool isAchievable;
  final String message;
  final double progressPercentage; // How close to target (0-100)

  const EstimatorResult({
    required this.targetCGPA,
    required this.requiredGPA,
    required this.isAchievable,
    required this.message,
    required this.progressPercentage,
  });

  /// Check if target already achieved
  bool get alreadyAchieved => requiredGPA < 5.0;

  /// Check if target is impossible
  bool get impossible => requiredGPA > 10.0;

  /// Get difficulty level
  String get difficultyLevel {
    if (alreadyAchieved) return 'Achieved';
    if (impossible) return 'Impossible';
    if (requiredGPA >= 9.5) return 'Very Hard';
    if (requiredGPA >= 9.0) return 'Hard';
    if (requiredGPA >= 8.0) return 'Moderate';
    if (requiredGPA >= 7.0) return 'Easy';
    return 'Very Easy';
  }

  /// Get suggestion for grade distribution
  String getSuggestion() {
    if (alreadyAchieved) {
      return 'You have already achieved your target CGPA! Maintain your performance.';
    }
    if (impossible) {
      return 'This target cannot be achieved this semester. Consider a lower target or focus on long-term improvement.';
    }
    if (requiredGPA >= 9.5) {
      return 'You need to score S grade in most subjects. Aim for 90+ in all courses.';
    }
    if (requiredGPA >= 9.0) {
      return 'Mix of S and A grades required. Focus on scoring 80+ consistently.';
    }
    if (requiredGPA >= 8.0) {
      return 'B grade average should work. Maintain 70+ in all subjects.';
    }
    return 'Maintain consistent performance with C grades or above.';
  }
}

/// CGPA Predictor Result
/// Shows projected CGPA after semester
class PredictorResult {
  final double currentCGPA;
  final double expectedGPA;
  final double projectedCGPA;
  final double cgpaChange;
  final String trend; // 'improving', 'maintaining', 'declining'

  const PredictorResult({
    required this.currentCGPA,
    required this.expectedGPA,
    required this.projectedCGPA,
    required this.cgpaChange,
    required this.trend,
  });

  /// Get trend description
  String get trendDescription {
    if (cgpaChange >= 0.3) return 'Improving Fast!';
    if (cgpaChange >= 0.1) return 'Steady Improvement';
    if (cgpaChange >= -0.1) return 'Maintaining Well';
    if (cgpaChange >= -0.3) return 'Slight Decline';
    return 'Needs Attention';
  }

  /// Get trend icon
  String get trendIcon {
    if (cgpaChange >= 0.3) return '🔥';
    if (cgpaChange >= 0.1) return '📈';
    if (cgpaChange >= -0.1) return '😊';
    if (cgpaChange >= -0.3) return '⚠️';
    return '🚨';
  }

  /// Get percentage representation
  String get projectedPercentage => (projectedCGPA * 10).toStringAsFixed(2);
}

/// Summary & Planner Result
/// Shows max/min possible CGPAs and simulations
class SummaryResult {
  final double currentCGPA;
  final double maxPossibleCGPA;
  final double minPossibleCGPA;
  final Map<String, double> gradeSimulations; // Grade -> Simulated CGPA
  final double completionPercentage;
  final double remainingCredits;

  const SummaryResult({
    required this.currentCGPA,
    required this.maxPossibleCGPA,
    required this.minPossibleCGPA,
    required this.gradeSimulations,
    required this.completionPercentage,
    required this.remainingCredits,
  });

  /// Get CGPA range
  double get cgpaRange => maxPossibleCGPA - minPossibleCGPA;

  /// Check if can reach 9.0+
  bool get canReachNinePoint => maxPossibleCGPA >= 9.0;

  /// Check if at risk of dropping below 7.0
  bool get atRiskOfDropping => minPossibleCGPA < 7.0;

  /// Get motivational message
  String getMotivationalMessage() {
    if (currentCGPA >= 9.0) {
      return 'Outstanding performance! You\'re in the top tier.';
    }
    if (currentCGPA >= 8.0) {
      if (canReachNinePoint) {
        return 'You can still reach 9.0 CGPA with consistent effort!';
      }
      return 'Excellent work! Maintain this momentum.';
    }
    if (currentCGPA >= 7.0) {
      return 'Good progress! Focus on improvement in upcoming semesters.';
    }
    if (atRiskOfDropping) {
      return 'Critical: Focus on scoring at least B grades to improve your standing.';
    }
    return 'Every semester is a new opportunity for improvement!';
  }
}

/// Grade Mix Result
/// Shows CGPA for a specific grade distribution
class GradeMixResult {
  final Map<String, double> gradePercentages; // Grade -> Percentage (0-1)
  final double projectedCGPA;
  final double requiredCredits;
  final Map<String, int> gradeCounts; // Grade -> Number of courses

  const GradeMixResult({
    required this.gradePercentages,
    required this.projectedCGPA,
    required this.requiredCredits,
    required this.gradeCounts,
  });

  /// Get total course count
  int get totalCourses =>
      gradeCounts.values.fold(0, (sum, count) => sum + count);

  /// Get average grade point
  double get averageGradePoint {
    double totalPoints = 0.0;
    int totalCourses = 0;

    gradePercentages.forEach((grade, percentage) {
      final gradePoint = _getGradePoint(grade);
      final count = (gradeCounts[grade] ?? 0);
      totalPoints += gradePoint * count;
      totalCourses += count;
    });

    return totalCourses > 0 ? totalPoints / totalCourses : 0.0;
  }

  double _getGradePoint(String grade) {
    const gradePoints = {
      'S': 10.0,
      'A': 9.0,
      'B': 8.0,
      'C': 7.0,
      'D': 6.0,
      'E': 5.0,
      'F': 0.0,
    };
    return gradePoints[grade] ?? 0.0;
  }
}
