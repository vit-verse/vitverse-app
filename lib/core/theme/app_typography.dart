import 'package:flutter/material.dart';

/// Font Family Constants
class AppFonts {
  static const String inter = 'Inter';
  static const String dmSans = 'DM Sans';
  static const String spaceGrotesk = 'Space Grotesk';
  static const String outfit = 'Outfit';
  static const String sora = 'Sora';
  static const String plusJakartaSans = 'Plus Jakarta Sans';
  static const String rubik = 'Rubik';
  static const String urbanist = 'Urbanist';
  static const String cabin = 'Cabin';
  static const String exo2 = 'Exo 2';

  /// Get all available fonts
  static List<FontOption> get allFonts => [
    const FontOption(
      id: 'inter',
      name: 'Inter',
      family: inter,
      description: 'Default',
    ),
    const FontOption(
      id: 'dm_sans',
      name: 'DM Sans',
      family: dmSans,
      description: 'Clean & Geometric',
    ),
    const FontOption(
      id: 'space_grotesk',
      name: 'Space Grotesk',
      family: spaceGrotesk,
      description: 'Tech & Futuristic',
    ),
    const FontOption(
      id: 'outfit',
      name: 'Outfit',
      family: outfit,
      description: 'Contemporary',
    ),
    const FontOption(
      id: 'sora',
      name: 'Sora',
      family: sora,
      description: 'Modern & Elegant',
    ),
    const FontOption(
      id: 'plus_jakarta_sans',
      name: 'Plus Jakarta Sans',
      family: plusJakartaSans,
      description: 'Friendly & Professional',
    ),
    const FontOption(
      id: 'rubik',
      name: 'Rubik',
      family: rubik,
      description: 'Rounded & Friendly',
    ),
    const FontOption(
      id: 'urbanist',
      name: 'Urbanist',
      family: urbanist,
      description: 'Urban & Stylish',
    ),
    const FontOption(
      id: 'cabin',
      name: 'Cabin',
      family: cabin,
      description: 'Humanist & Clear',
    ),
    const FontOption(
      id: 'exo_2',
      name: 'Exo 2',
      family: exo2,
      description: 'Futuristic & Bold',
    ),
  ];

  /// Get font family by ID
  static String getFontFamilyById(String id) {
    final font = allFonts.firstWhere(
      (f) => f.id == id,
      orElse: () => allFonts.first,
    );
    return font.family;
  }
}

/// Font Option Model
class FontOption {
  final String id;
  final String name;
  final String family;
  final String description;

  const FontOption({
    required this.id,
    required this.name,
    required this.family,
    required this.description,
  });
}

/// Typography Helper
class AppTypography {
  static TextTheme getTextTheme(
    String fontFamily,
    Color textColor,
    Color mutedColor,
  ) {
    return TextTheme(
      // Display styles (largest)
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        letterSpacing: 0.4,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
