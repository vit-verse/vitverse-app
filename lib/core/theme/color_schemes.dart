import 'package:flutter/material.dart';

/// Color scheme for attendance representation
class AttendanceColorScheme {
  final String name;
  final bool useRanges;
  final List<AttendanceColorRange> ranges;
  final Color? primaryColor;
  final bool autoMatchTheme;

  AttendanceColorScheme({
    required this.name,
    required this.useRanges,
    required this.ranges,
    this.primaryColor,
    this.autoMatchTheme = false,
  });

  /// Create default scheme
  static AttendanceColorScheme get defaultScheme => AttendanceColorScheme(
    name: 'Default',
    useRanges: true,
    ranges: [
      AttendanceColorRange(
        min: 85,
        max: 101,
        color: const Color(0xFF4CAF7C),
      ), // Matte Emerald (success)
      AttendanceColorRange(
        min: 80,
        max: 85,
        color: const Color(0xFF81C784),
      ), // Soft Sage (mild success)
      AttendanceColorRange(
        min: 75,
        max: 80,
        color: const Color(0xFFE6B980),
      ), // Muted Amber (warning)
      AttendanceColorRange(
        min: 0,
        max: 75,
        color: const Color(0xFFD67C7C),
      ), // Dusty Rose (low)
    ],
  );

  /// Create simple primary color scheme
  static AttendanceColorScheme primaryColorScheme(Color color) =>
      AttendanceColorScheme(
        name: 'Primary Color',
        useRanges: false,
        ranges: [],
        primaryColor: color,
        autoMatchTheme: false,
      );

  /// Create auto theme matching scheme
  static AttendanceColorScheme autoThemeScheme() => AttendanceColorScheme(
    name: 'Auto Theme',
    useRanges: false,
    ranges: [],
    primaryColor: null,
    autoMatchTheme: true,
  );

  /// Get color for attendance percentage
  Color getColor(double percentage, [Color? themeColor]) {
    if (!useRanges) {
      // When ranges are disabled, use a light shade of the primary color
      Color baseColor;
      if (autoMatchTheme && themeColor != null) {
        baseColor = themeColor;
      } else {
        baseColor = primaryColor ?? const Color(0xFF6366F1);
      }
      return Color.lerp(baseColor, Colors.white, 0.3) ??
          baseColor.withValues(alpha: 0.8);
    }

    for (final range in ranges) {
      if (percentage >= range.min && percentage < range.max) {
        return range.color;
      }
    }

    // Handle edge case for 100%
    if (percentage >= 100 && ranges.isNotEmpty) {
      return ranges.first.color;
    }

    // Fallback to last range color for values below minimum
    return ranges.isNotEmpty ? ranges.last.color : const Color(0xFF059669);
  }

  /// Copy with new values
  AttendanceColorScheme copyWith({
    String? name,
    bool? useRanges,
    List<AttendanceColorRange>? ranges,
    Color? primaryColor,
    bool? autoMatchTheme,
  }) {
    return AttendanceColorScheme(
      name: name ?? this.name,
      useRanges: useRanges ?? this.useRanges,
      ranges: ranges ?? this.ranges,
      primaryColor: primaryColor ?? this.primaryColor,
      autoMatchTheme: autoMatchTheme ?? this.autoMatchTheme,
    );
  }
}

/// Color range for attendance
class AttendanceColorRange {
  final double min;
  final double max;
  final Color color;

  AttendanceColorRange({
    required this.min,
    required this.max,
    required this.color,
  });

  /// Copy with new values
  AttendanceColorRange copyWith({double? min, double? max, Color? color}) {
    return AttendanceColorRange(
      min: min ?? this.min,
      max: max ?? this.max,
      color: color ?? this.color,
    );
  }
}

/// Color scheme for marks representation
class MarksColorScheme {
  final String name;
  final bool useRanges;
  final List<MarksColorRange> ranges;
  final Color? primaryColor;
  final bool autoMatchTheme;

  MarksColorScheme({
    required this.name,
    required this.useRanges,
    required this.ranges,
    this.primaryColor,
    this.autoMatchTheme = false,
  });

  /// Create default scheme 
  static MarksColorScheme get defaultScheme => MarksColorScheme(
    name: 'Default',
    useRanges: true,
    ranges: [
      MarksColorRange(
        min: 85,
        max: 101,
        color: const Color(0xFF4F9D69),
      ), // Matte Green (excellent)
      MarksColorRange(
        min: 70,
        max: 85,
        color: const Color(0xFF88B888),
      ), // Soft Olive (good)
      MarksColorRange(
        min: 50,
        max: 70,
        color: const Color(0xFFE8B97C),
      ), // Warm Sand (average)
      MarksColorRange(
        min: 0,
        max: 50,
        color: const Color(0xFFC87171),
      ), // Muted Coral (poor)
    ],
  );

  /// Create simple primary color scheme
  static MarksColorScheme primaryColorScheme(Color color) => MarksColorScheme(
    name: 'Primary Color',
    useRanges: false,
    ranges: [],
    primaryColor: color,
    autoMatchTheme: false,
  );

  /// Create auto theme matching scheme
  static MarksColorScheme autoThemeScheme() => MarksColorScheme(
    name: 'Auto Theme',
    useRanges: false,
    ranges: [],
    primaryColor: null,
    autoMatchTheme: true,
  );

  /// Get color for marks percentage
  Color getColor(double percentage, [Color? themeColor]) {
    if (!useRanges) {
      // When ranges are disabled, use a light shade of the primary color
      Color baseColor;
      if (autoMatchTheme && themeColor != null) {
        baseColor = themeColor;
      } else {
        baseColor = primaryColor ?? const Color(0xFF6366F1);
      }
      return Color.lerp(baseColor, Colors.white, 0.3) ??
          baseColor.withValues(alpha: 0.8);
    }

    for (final range in ranges) {
      if (percentage >= range.min && percentage < range.max) {
        return range.color;
      }
    }

    // Handle edge case for 100%
    if (percentage >= 100 && ranges.isNotEmpty) {
      return ranges.first.color;
    }

    // Fallback to last range color for values below minimum
    return ranges.isNotEmpty ? ranges.last.color : const Color(0xFF059669);
  }

  /// Copy with new values
  MarksColorScheme copyWith({
    String? name,
    bool? useRanges,
    List<MarksColorRange>? ranges,
    Color? primaryColor,
    bool? autoMatchTheme,
  }) {
    return MarksColorScheme(
      name: name ?? this.name,
      useRanges: useRanges ?? this.useRanges,
      ranges: ranges ?? this.ranges,
      primaryColor: primaryColor ?? this.primaryColor,
      autoMatchTheme: autoMatchTheme ?? this.autoMatchTheme,
    );
  }
}

/// Color range for marks
class MarksColorRange {
  final double min;
  final double max;
  final Color color;

  MarksColorRange({required this.min, required this.max, required this.color});

  /// Copy with new values
  MarksColorRange copyWith({double? min, double? max, Color? color}) {
    return MarksColorRange(
      min: min ?? this.min,
      max: max ?? this.max,
      color: color ?? this.color,
    );
  }
}
