/// Model representing performance data for a single course
/// Groups all marks/assessments for a course with calculated overall score
class CoursePerformance {
  final int courseId;
  final String courseCode;
  final String courseTitle;
  final String courseType;
  final double credits;
  final List<AssessmentMark> assessments;
  final int unreadCount;

  CoursePerformance({
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.courseType,
    required this.credits,
    required this.assessments,
    required this.unreadCount,
  });

  /// Calculate overall score percentage
  double get overallScore {
    if (assessments.isEmpty) return 0.0;

    double totalWeightage = 0.0;
    double obtainedWeightage = 0.0;

    for (final assessment in assessments) {
      if (assessment.maxWeightage != null && assessment.weightage != null) {
        totalWeightage += assessment.maxWeightage!;
        obtainedWeightage += assessment.weightage!;
      }
    }

    if (totalWeightage == 0) return 0.0;
    return (obtainedWeightage / totalWeightage) * 100;
  }

  /// Get total possible weightage
  double get totalWeightage {
    return assessments.fold(
      0.0,
      (sum, mark) => sum + (mark.maxWeightage ?? 0.0),
    );
  }

  /// Get obtained weightage
  double get obtainedWeightage {
    return assessments.fold(0.0, (sum, mark) => sum + (mark.weightage ?? 0.0));
  }
}

/// Model representing a single assessment mark
class AssessmentMark {
  final int id;
  final String title;
  final double? score;
  final double? maxScore;
  final double? weightage;
  final double? maxWeightage;
  final double? average;
  final String? status;
  final bool isRead;

  AssessmentMark({
    required this.id,
    required this.title,
    this.score,
    this.maxScore,
    this.weightage,
    this.maxWeightage,
    this.average,
    this.status,
    required this.isRead,
  });

  /// Create from database map
  factory AssessmentMark.fromMap(Map<String, dynamic> map) {
    return AssessmentMark(
      id: map['id'] as int,
      title: map['title'] as String? ?? 'Unknown',
      score: map['score'] as double?,
      maxScore: map['max_score'] as double?,
      weightage: map['weightage'] as double?,
      maxWeightage: map['max_weightage'] as double?,
      average: map['average'] as double?,
      status: map['status'] as String?,
      isRead: (map['is_read'] as int?) == 1,
    );
  }

  /// Get score percentage
  double? get scorePercentage {
    if (score == null || maxScore == null || maxScore == 0) return null;
    return (score! / maxScore!) * 100;
  }

  /// Get weightage percentage
  double? get weightagePercentage {
    if (weightage == null || maxWeightage == null || maxWeightage == 0) {
      return null;
    }
    return (weightage! / maxWeightage!) * 100;
  }

  /// Check if assessment is present
  bool get isPresent {
    return status?.toLowerCase() == 'present';
  }

  /// Check if assessment is absent
  bool get isAbsent {
    return status?.toLowerCase() == 'absent';
  }
}
