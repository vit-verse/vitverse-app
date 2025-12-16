import 'package:flutter/material.dart';

/// Feature-specific gradient colors for icons
class FeatureColors {
  // Design System Colors
  static const Color primaryBackground = Color(0xFF0f172a);
  static const Color cardBackground = Color(0xFF1e293b);
  static const Color cardHover = Color(0xFF334155);
  static const Color borderColor = Color(0xFF475569);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9ca3af);
  static const Color pinActive = Color(0xFFeab308);
  static const Color pinInactive = Color(0xFF3f3f46);

  // VTOP Services header gradient
  static const List<Color> vtopHeaderGradient = [
    Color(0xFF3b82f6), // Blue-500
    Color(0xFF2563eb), // Blue-600
  ];

  // VIT Connect header gradient
  static const List<Color> vitConnectHeaderGradient = [
    Color(0xFF9333ea), // Purple-500
    Color(0xFFec4899), // Pink-500
  ];

  /// Get gradient colors for a feature by its key
  static List<Color> getFeatureGradient(String featureKey) {
    return _featureGradients[featureKey] ?? _featureGradients['default']!;
  }

  /// All feature-specific gradients
  static const Map<String, List<Color>> _featureGradients = {
    // VTOP Services - Academic
    'attendance_analytics': [Color(0xFF3b82f6), Color(0xFF1d4ed8)], // Blue
    'attendance_calculator': [Color(0xFF6366f1), Color(0xFF4338ca)], // Indigo
    'academic_performance': [Color(0xFF9333ea), Color(0xFF6b21a8)], // Purple
    'attendance_matrix': [Color(0xFF8b5cf6), Color(0xFF6d28d9)], // Violet
    'examination_schedule': [Color(0xFFec4899), Color(0xFFbe185d)], // Pink
    'grade_history': [Color(0xFFf43f5e), Color(0xFFe11d48)], // Rose
    'marks_history': [Color(0xFFf97316), Color(0xFFea580c)], // Orange
    'cgpa_gpa_calculator': [Color(0xFF2563eb), Color(0xFF1e40af)], // Blue-600
    // VTOP Services - Faculty
    'staff': [Color(0xFF10b981), Color(0xFF047857)], // Emerald
    'my_course_faculties': [Color(0xFF14b8a6), Color(0xFF0d9488)], // Teal
    'all_faculties': [Color(0xFF06b6d4), Color(0xFF0891b2)], // Cyan
    // VTOP Services - Finance
    'fee_management': [Color(0xFF22c55e), Color(0xFF15803d)], // Green
    // VIT Connect - Social
    'cab_share': [Color(0xFFef4444), Color(0xFFdc2626)], // Red
    'friends_schedule': [Color(0xFF0ea5e9), Color(0xFF0284c7)], // Sky
    // VIT Connect - Academics
    'faculty_rating': [Color(0xFFf59e0b), Color(0xFFd97706)], // Amber
    // VIT Connect - Utilities
    'lost_and_found': [Color(0xFFd946ef), Color(0xFFa21caf)], // Fuchsia
    'quick_links': [Color(0xFFe11d48), Color(0xFFbe185d)], // Rose-600
    'mess_menu': [Color(0xFFea580c), Color(0xFFc2410c)], // Orange-600
    'laundry': [Color(0xFF0891b2), Color(0xFF0e7490)], // Cyan-600
    // Default gradient
    'default': [Color(0xFF3b82f6), Color(0xFF1d4ed8)], // Blue
  };
}

/// View mode for features page
enum ViewMode { list, grid2Column, grid3Column }
