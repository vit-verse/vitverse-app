import '../../../../../core/database/entities/basket_progress.dart';

// model for basket progress with earned/in-progress/required breakdown
class BasketWithProgress {
  final BasketProgress baseData; // Original basket data from database
  final double earnedCredits; // Credits from completed semesters
  final double inProgressCredits; // Credits from current semester courses
  final double requiredCredits; // Total credits required

  BasketWithProgress({
    required this.baseData,
    required this.earnedCredits,
    required this.inProgressCredits,
    required this.requiredCredits,
  });

  /// Basket title
  String get basketTitle => baseData.basketTitle;

  /// Distribution type
  String get distributionType => baseData.distributionType;

  /// Total progress (earned + in-progress)
  double get totalProgress => earnedCredits + inProgressCredits;

  /// Remaining credits needed
  double get remainingCredits {
    final remaining = requiredCredits - totalProgress;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Completion percentage (earned only)
  double get earnedPercentage {
    if (requiredCredits == 0) return 0.0;
    return (earnedCredits / requiredCredits) * 100;
  }

  /// Total progress percentage (earned + in-progress)
  double get totalProgressPercentage {
    if (requiredCredits == 0) return 0.0;
    return (totalProgress / requiredCredits) * 100;
  }

  /// Check if requirement is complete
  bool get isComplete => earnedCredits >= requiredCredits;

  /// Check if there are courses in progress
  bool get hasInProgress => inProgressCredits > 0;

  /// Check if credits exceed required amount (warning condition)
  bool get isExceeding => totalProgress > requiredCredits;

  /// Clamped earned percentage (max 100%)
  double get earnedPercentageClamped => earnedPercentage.clamp(0.0, 100.0);

  /// Clamped total progress percentage (max 100%)
  double get totalProgressPercentageClamped =>
      totalProgressPercentage.clamp(0.0, 100.0);

  /// Status for UI display
  String get status {
    if (isExceeding) return 'Exceeds Requirement';
    if (isComplete) return 'Completed';
    if (hasInProgress) return 'In Progress';
    if (earnedCredits > 0) return 'Ongoing';
    return 'Not Started';
  }

  /// Create from base basket data
  factory BasketWithProgress.fromBase({
    required BasketProgress base,
    required double earned,
    required double inProgress,
  }) {
    return BasketWithProgress(
      baseData: base,
      earnedCredits: earned,
      inProgressCredits: inProgress,
      requiredCredits: base.creditsRequired,
    );
  }

  /// Create empty model
  factory BasketWithProgress.empty() {
    return BasketWithProgress(
      baseData: BasketProgress.empty(),
      earnedCredits: 0.0,
      inProgressCredits: 0.0,
      requiredCredits: 0.0,
    );
  }

  @override
  String toString() {
    return 'BasketWithProgress(title: $basketTitle, earned: $earnedCredits, inProgress: $inProgressCredits, required: $requiredCredits)';
  }
}
