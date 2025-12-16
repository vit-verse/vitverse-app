/// Number Formatting Utilities
/// Provides precise formatting without rounding
class NumberFormatter {
  /// Truncates a double to specified decimal places WITHOUT rounding
  /// Example: truncateToDecimal(8.876, 2) returns "8.87" (not "8.88")
  static String truncateToDecimal(double value, int decimalPlaces) {
    final multiplier = _pow10(decimalPlaces);
    final truncated = (value * multiplier).truncateToDouble() / multiplier;
    return truncated.toStringAsFixed(decimalPlaces);
  }

  /// Helper: Calculate 10^n
  static double _pow10(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= 10.0;
    }
    return result;
  }

  /// Format CGPA/GPA to 2 decimal places without rounding
  /// Example: 8.876 -> "8.87"
  static String formatCGPA(double value) {
    return truncateToDecimal(value, 2);
  }

  /// Format credits to 1 decimal place
  /// Example: 120.5 -> "120.5", 120.0 -> "120.0"
  static String formatCredits(double value) {
    return value.toStringAsFixed(1);
  }

  /// Format percentage to 1 decimal place without rounding
  /// Example: 88.76% -> "88.7%"
  static String formatPercentage(double value) {
    return '${truncateToDecimal(value, 1)}%';
  }
}
