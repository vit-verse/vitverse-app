import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_typography.dart';

/// AppTheme - Custom theme data class for VIT Connect
class AppTheme {
  final String id;
  final String name;
  final Color primary;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final bool isDark;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.isDark,
  });

  /// Computed properties for additional colors
  Color get border => isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  Color get error => isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get info => const Color(0xFF3B82F6);

  /// Convert to Flutter ThemeData
  ThemeData toThemeData(String fontFamily) {
    final textTheme = AppTypography.getTextTheme(fontFamily, text, muted);
    final googleFontsTextTheme = _applyGoogleFont(fontFamily, textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: primary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        background: background,
        onBackground: text,
      ),

      // Scaffold
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: googleFontsTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Text theme with Google Fonts
      textTheme: googleFontsTextTheme,

      // Icon theme
      iconTheme: IconThemeData(color: text),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
      ),

      // Page transitions - Android-only predictive back navigation
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Apply Google Font to TextTheme
  TextTheme _applyGoogleFont(String fontFamily, TextTheme baseTextTheme) {
    switch (fontFamily.toLowerCase()) {
      case 'inter':
        return GoogleFonts.interTextTheme(baseTextTheme);
      case 'dm sans':
        return GoogleFonts.dmSansTextTheme(baseTextTheme);
      case 'space grotesk':
        return GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
      case 'outfit':
        return GoogleFonts.outfitTextTheme(baseTextTheme);
      case 'sora':
        return GoogleFonts.soraTextTheme(baseTextTheme);
      case 'plus jakarta sans':
        return GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
      case 'rubik':
        return GoogleFonts.rubikTextTheme(baseTextTheme);
      case 'urbanist':
        return GoogleFonts.urbanistTextTheme(baseTextTheme);
      case 'cabin':
        return GoogleFonts.cabinTextTheme(baseTextTheme);
      case 'exo 2':
        return GoogleFonts.exo2TextTheme(baseTextTheme);
      default:
        return GoogleFonts.interTextTheme(baseTextTheme);
    }
  }

  /// Copy with new values
  AppTheme copyWith({
    String? id,
    String? name,
    Color? primary,
    Color? background,
    Color? surface,
    Color? text,
    Color? muted,
    bool? isDark,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      isDark: isDark ?? this.isDark,
    );
  }
}

/// Available Themes
class AppThemes {
  // LIGHT THEMES (6)
  static const matteIvory = AppTheme(
    id: 'matte_ivory',
    name: 'Matte Ivory',
    primary: Color(0xFF5B5FC7), // Indigo accent
    background: Color(0xFFFAFAF8), // Creamy white
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF737373),
    isDark: false,
  );

  static const fogstone = AppTheme(
    id: 'fogstone',
    name: 'Fogstone',
    primary: Color(0xFF64748B), // Slate blue-gray
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2937),
    muted: Color(0xFF6B7280),
    isDark: false,
  );

  static const matteCopperLight = AppTheme(
    id: 'matte_copper_light',
    name: 'Matte Copper Light',
    primary: Color(0xFFB45309), // Bronze
    background: Color(0xFFFFFBF5),
    surface: Color(0xFFFFF8F0),
    text: Color(0xFF1E1E1E),
    muted: Color(0xFF8B7355),
    isDark: false,
  );

  static const slateMist = AppTheme(
    id: 'slate_mist',
    name: 'Slate Mist',
    primary: Color(0xFF3B82F6), // Cool blue accent
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    isDark: false,
  );

  static const roseLinen = AppTheme(
    id: 'rose_linen',
    name: 'Rose Linen',
    primary: Color(0xFFF472B6),
    background: Color(0xFFFFF1F3),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F1F1F),
    muted: Color(0xFF9D9D9D),
    isDark: false,
  );

  static const peachMist = AppTheme(
    id: 'peach_mist',
    name: 'Peach Mist',
    primary: Color(0xFFFB923C), // Warm coral
    background: Color(0xFFFFF7ED),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1C1917),
    muted: Color(0xFFA16207),
    isDark: false,
  );

  // DARK THEMES (7)
  static const graphite = AppTheme(
    id: 'graphite',
    name: 'Graphite',
    primary: Color(0xFF818CF8),
    background: Color(0xFF1E1E24),
    surface: Color(0xFF2A2A31),
    text: Color(0xFFF5F5F5),
    muted: Color(0xFF9CA3AF),
    isDark: true,
  );

  static const obsidian = AppTheme(
    id: 'obsidian',
    name: 'Obsidian',
    primary: Color(0xFF6366F1),
    background: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    text: Color(0xFFF4F4F5),
    muted: Color(0xFFA1A1AA),
    isDark: true,
  );

  static const midnightAzure = AppTheme(
    id: 'midnight_azure',
    name: 'Midnight Azure',
    primary: Color(0xFF60A5FA),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    text: Color(0xFFE2E8F0),
    muted: Color(0xFF94A3B8),
    isDark: true,
  );

  static const charcoalRose = AppTheme(
    id: 'charcoal_rose',
    name: 'Charcoal Rose',
    primary: Color(0xFFEC4899),
    background: Color(0xFF1F1D22),
    surface: Color(0xFF2B2730),
    text: Color(0xFFF5E9F0),
    muted: Color(0xFFBFA4B6),
    isDark: true,
  );

  static const copperDark = AppTheme(
    id: 'copper_dark',
    name: 'Copper Dark',
    primary: Color(0xFFB45309),
    background: Color(0xFF1B130B),
    surface: Color(0xFF2A1F12),
    text: Color(0xFFFDE68A),
    muted: Color(0xFFBFA074),
    isDark: true,
  );

  static const velvetNoir = AppTheme(
    id: 'velvet_noir',
    name: 'Velvet Noir',
    primary: Color(0xFF8B5CF6),
    background: Color(0xFF130F1A),
    surface: Color(0xFF1C1524),
    text: Color(0xFFEDE9FE),
    muted: Color(0xFFA78BFA),
    isDark: true,
  );

  static const amoledBlack = AppTheme(
    id: 'amoled_black',
    name: 'AMOLED Black',
    primary: Color(0xFFA78BFA),
    background: Color(0xFF000000), // Pure AMOLED
    surface: Color(0xFF0A0A0A),
    text: Color(0xFFF4F4F5),
    muted: Color(0xFF9CA3AF),
    isDark: true,
  );

  static const emeraldNight = AppTheme(
    id: 'emerald_night',
    name: 'Emerald Night',
    primary: Color(0xFF6EE7B7), // Mint emerald
    background: Color(0xFF0A1F1A), // Deep forest black
    surface: Color(0xFF14302A), // Rich jade surface
    text: Color(0xFFE8FAF3), // Soft mint white
    muted: Color(0xFF86EFAC), // Muted mint
    isDark: true,
  );

  /// Get all available themes
  static List<AppTheme> get allThemes => [
    // Light
    matteIvory,
    fogstone,
    matteCopperLight,
    slateMist,
    roseLinen,
    peachMist,
    // Dark
    graphite,
    obsidian,
    midnightAzure,
    charcoalRose,
    copperDark,
    velvetNoir,
    amoledBlack,
    emeraldNight,
  ];

  /// Get theme by ID
  static AppTheme getThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => amoledBlack, // Default to amoledBlack theme
    );
  }
}
