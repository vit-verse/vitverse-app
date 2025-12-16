import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

/// Utility class for getting consistent colors throughout the app
class ColorUtils {
  /// Get attendance color based on percentage
  static Color getAttendanceColor(BuildContext context, double percentage) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.attendanceColorScheme.getColor(
      percentage,
      themeProvider.currentTheme.primary,
    );
  }

  /// Get marks color based on percentage
  static Color getMarksColor(BuildContext context, double percentage) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.marksColorScheme.getColor(
      percentage,
      themeProvider.currentTheme.primary,
    );
  }

  /// Get attendance color directly from provider
  static Color getAttendanceColorFromProvider(
    ThemeProvider provider,
    double percentage,
  ) {
    return provider.attendanceColorScheme.getColor(
      percentage,
      provider.currentTheme.primary,
    );
  }

  /// Get marks color directly from provider
  static Color getMarksColorFromProvider(
    ThemeProvider provider,
    double percentage,
  ) {
    return provider.marksColorScheme.getColor(
      percentage,
      provider.currentTheme.primary,
    );
  }
}
