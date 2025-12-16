import 'package:flutter/material.dart';

/// Enum representing the status of a day in the attendance calculator
enum DayStatus {
  absent,
  present,
  holiday;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case DayStatus.absent:
        return 'Absent';
      case DayStatus.present:
        return 'Present';
      case DayStatus.holiday:
        return 'Holiday';
    }
  }

  /// Get icon for the status
  IconData get icon {
    switch (this) {
      case DayStatus.absent:
        return Icons.cancel;
      case DayStatus.present:
        return Icons.check_circle;
      case DayStatus.holiday:
        return Icons.event_busy;
    }
  }

  /// Get next status in cycle (for toggling)
  DayStatus get next {
    switch (this) {
      case DayStatus.absent:
        return DayStatus.present;
      case DayStatus.present:
        return DayStatus.holiday;
      case DayStatus.holiday:
        return DayStatus.absent;
    }
  }

  /// Get color based on theme (lighter versions for professional look)
  Color getColor(Color primary, bool isDark) {
    switch (this) {
      case DayStatus.absent:
        // Red tone
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935);
      case DayStatus.present:
        // Green tone
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
      case DayStatus.holiday:
        // Amber tone
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFFFA000);
    }
  }
}
