import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_provider.dart';

/// Business logic for grade history
class GradeHistoryLogic {
  /// Get color for grade directly from provider
  Color getGradeColorFromProvider(ThemeProvider provider, String grade) {
    return provider.marksColorScheme.getColor(_getGradePercentage(grade));
  }

  /// Get color for GPA display using provider
  Color getGPAColorFromProvider(ThemeProvider provider, double gpa) {
    final percentage = gpa * 10;
    return provider.marksColorScheme.getColor(percentage);
  }

  /// Convert grade to percentage for color calculation
  double _getGradePercentage(String grade) {
    switch (grade.toUpperCase()) {
      case 'S':
        return 95.0;
      case 'A':
        return 85.0;
      case 'B':
        return 75.0;
      case 'C':
        return 65.0;
      case 'D':
        return 55.0;
      case 'E':
        return 45.0;
      case 'F':
        return 30.0;
      case 'N':
        return 30.0;
      case 'P':
        return 95.0; // passed: treat as s grade color,
      default:
        return 50.0;
    }
  }

  String formatGPA(double? gpa) {
    if (gpa == null || gpa == 0.0) return 'N/A';
    return gpa.toStringAsFixed(2);
  }

  String formatCredits(double credits) {
    if (credits == credits.toInt()) {
      return credits.toInt().toString();
    }
    return credits.toStringAsFixed(1);
  }
}
