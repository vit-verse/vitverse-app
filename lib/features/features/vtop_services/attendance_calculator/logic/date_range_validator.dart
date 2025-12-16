import '../models/date_range.dart';

/// Validator for date range selections
class DateRangeValidator {
  static const int maxAllowedDays = 180;
  static const int minAllowedDays = 1;

  /// Validate a date range
  static ValidationResult validate(DateRange dateRange) {
    // Check if end date is before start date
    if (dateRange.endDate.isBefore(dateRange.startDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'End date cannot be before start date',
      );
    }

    // Check if dates are the same
    if (dateRange.startDate.isAtSameMomentAs(dateRange.endDate)) {
      // Allow same date selection
      return ValidationResult(isValid: true);
    }

    // Check minimum days
    if (dateRange.dayCount < minAllowedDays) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Date range must be at least $minAllowedDays day',
      );
    }

    // Check maximum days
    if (dateRange.dayCount > maxAllowedDays) {
      return ValidationResult(
        isValid: false,
        errorMessage:
            'Date range cannot exceed $maxAllowedDays days. Selected: ${dateRange.dayCount} days',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate start date
  static ValidationResult validateStartDate(
    DateTime startDate,
    DateTime? endDate,
  ) {
    // Start date should not be in far future
    final maxFutureDate = DateTime.now().add(const Duration(days: 365));
    if (startDate.isAfter(maxFutureDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Start date is too far in the future',
      );
    }

    // If end date exists, start should not be after end
    if (endDate != null && startDate.isAfter(endDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Start date cannot be after end date',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate end date
  static ValidationResult validateEndDate(
    DateTime? startDate,
    DateTime endDate,
  ) {
    // End date should not be in far future
    final maxFutureDate = DateTime.now().add(const Duration(days: 365));
    if (endDate.isAfter(maxFutureDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'End date is too far in the future',
      );
    }

    // If start date exists, end should not be before start
    if (startDate != null && endDate.isBefore(startDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'End date cannot be before start date',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Check if date range is within reasonable limits
  static bool isReasonableRange(DateRange dateRange) {
    return dateRange.dayCount <= maxAllowedDays &&
        dateRange.dayCount >= minAllowedDays &&
        dateRange.isValid;
  }

  /// Get suggested end date based on start date
  static DateTime getSuggestedEndDate(DateTime startDate) {
    // Suggest 30 days from start as default
    return startDate.add(const Duration(days: 30));
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  @override
  String toString() {
    if (isValid) return 'ValidationResult{valid}';
    return 'ValidationResult{invalid: $errorMessage}';
  }
}
