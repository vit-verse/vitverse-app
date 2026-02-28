import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'app_typography.dart';
import 'color_schemes.dart';

/// Theme Provider - Manages app theme and font
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _fontKey = 'selected_font';
  static const String _customThemeKey = 'custom_theme';

  // Color scheme keys
  static const String _attendanceColorSchemeKey = 'attendance_color_scheme';
  static const String _marksColorSchemeKey = 'marks_color_scheme';

  AppTheme _currentTheme = AppThemes.amoledBlack;
  String _currentFont = AppFonts.exo2;
  AppTheme? _customTheme;

  // Color schemes
  AttendanceColorScheme _attendanceColorScheme =
      AttendanceColorScheme.defaultScheme;
  MarksColorScheme _marksColorScheme = MarksColorScheme.defaultScheme;

  AppTheme get currentTheme => _currentTheme;
  String get currentFont => _currentFont;
  AppTheme? get customTheme => _customTheme;

  // Color scheme getters
  AttendanceColorScheme get attendanceColorScheme => _attendanceColorScheme;
  MarksColorScheme get marksColorScheme => _marksColorScheme;

  bool get isDarkMode => _currentTheme.isDark;

  /// Get SystemUiOverlayStyle for current theme
  SystemUiOverlayStyle get systemOverlayStyle {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// Initialize theme from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final themeId = prefs.getString(_themeKey) ?? 'amoled_black';
    if (themeId == 'custom') {
      _loadCustomTheme(prefs);
    } else {
      _currentTheme = AppThemes.getThemeById(themeId);
    }

    // Load font
    _currentFont = prefs.getString(_fontKey) ?? AppFonts.exo2;

    // Load color schemes
    _loadColorSchemes(prefs);

    notifyListeners();
  }

  /// Load custom theme from preferences
  void _loadCustomTheme(SharedPreferences prefs) {
    try {
      final name = prefs.getString('${_customThemeKey}_name');
      final primaryHex = prefs.getString('${_customThemeKey}_primary');
      final backgroundHex = prefs.getString('${_customThemeKey}_background');
      final surfaceHex = prefs.getString('${_customThemeKey}_surface');
      final textHex = prefs.getString('${_customThemeKey}_text');
      final mutedHex = prefs.getString('${_customThemeKey}_muted');
      final isDark = prefs.getBool('${_customThemeKey}_isDark') ?? true;

      if (primaryHex != null &&
          backgroundHex != null &&
          surfaceHex != null &&
          textHex != null &&
          mutedHex != null) {
        _customTheme = AppTheme(
          id: 'custom',
          name: name ?? 'Custom', // Load saved name or default to 'Custom'
          primary: _hexToColor(primaryHex),
          background: _hexToColor(backgroundHex),
          surface: _hexToColor(surfaceHex),
          text: _hexToColor(textHex),
          muted: _hexToColor(mutedHex),
          isDark: isDark,
        );
        _currentTheme = _customTheme!;
      } else {
        // Custom theme data missing, fallback to amoled_black and clear invalid theme key
        _currentTheme = AppThemes.amoledBlack;
        prefs.setString(_themeKey, 'amoled_black');
      }
    } catch (e) {
      // Error loading custom theme, fallback to amoled_black
      _currentTheme = AppThemes.amoledBlack;
      prefs.setString(_themeKey, 'amoled_black');
      // Clear corrupted custom theme data
      prefs.remove('${_customThemeKey}_name');
      prefs.remove('${_customThemeKey}_primary');
      prefs.remove('${_customThemeKey}_background');
      prefs.remove('${_customThemeKey}_surface');
      prefs.remove('${_customThemeKey}_text');
      prefs.remove('${_customThemeKey}_muted');
      prefs.remove('${_customThemeKey}_isDark');
    }
  }

  /// Load color schemes from preferences
  void _loadColorSchemes(SharedPreferences prefs) {
    // Load attendance color scheme
    final attendanceUseRanges =
        prefs.getBool('${_attendanceColorSchemeKey}_useRanges') ?? true;
    final attendanceAutoMatch =
        prefs.getBool('${_attendanceColorSchemeKey}_autoMatch') ?? false;
    final attendancePrimaryHex = prefs.getString(
      '${_attendanceColorSchemeKey}_primary',
    );

    if (attendanceUseRanges) {
      _attendanceColorScheme = AttendanceColorScheme.defaultScheme;
    } else if (attendanceAutoMatch) {
      _attendanceColorScheme = AttendanceColorScheme.autoThemeScheme();
    } else if (attendancePrimaryHex != null) {
      _attendanceColorScheme = AttendanceColorScheme.primaryColorScheme(
        _hexToColor(attendancePrimaryHex),
      );
    } else {
      _attendanceColorScheme = AttendanceColorScheme.defaultScheme;
    }

    // Load marks color scheme
    final marksUseRanges =
        prefs.getBool('${_marksColorSchemeKey}_useRanges') ?? true;
    final marksAutoMatch =
        prefs.getBool('${_marksColorSchemeKey}_autoMatch') ?? false;
    final marksPrimaryHex = prefs.getString('${_marksColorSchemeKey}_primary');

    if (marksUseRanges) {
      _marksColorScheme = MarksColorScheme.defaultScheme;
    } else if (marksAutoMatch) {
      _marksColorScheme = MarksColorScheme.autoThemeScheme();
    } else if (marksPrimaryHex != null) {
      _marksColorScheme = MarksColorScheme.primaryColorScheme(
        _hexToColor(marksPrimaryHex),
      );
    } else {
      _marksColorScheme = MarksColorScheme.defaultScheme;
    }
  }

  /// Set a built-in theme (NOT for custom themes)
  /// Use [setCustomTheme] for custom themes to ensure proper persistence
  Future<void> setTheme(AppTheme theme) async {
    assert(
      !theme.id.startsWith('custom_'),
      'Use setCustomTheme() for custom themes',
    );

    _currentTheme = theme;
    _customTheme = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.id);
  }

  /// Set font
  Future<void> setFont(String fontFamily) async {
    _currentFont = fontFamily;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, fontFamily);
  }

  /// Set a custom theme with full data persistence
  /// Saves all theme colors to SharedPreferences for reliable startup loading
  Future<void> setCustomTheme(AppTheme theme) async {
    _customTheme = theme;
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, 'custom');
    await prefs.setString('${_customThemeKey}_name', theme.name);
    await prefs.setString(
      '${_customThemeKey}_primary',
      _colorToHex(theme.primary),
    );
    await prefs.setString(
      '${_customThemeKey}_background',
      _colorToHex(theme.background),
    );
    await prefs.setString(
      '${_customThemeKey}_surface',
      _colorToHex(theme.surface),
    );
    await prefs.setString('${_customThemeKey}_text', _colorToHex(theme.text));
    await prefs.setString('${_customThemeKey}_muted', _colorToHex(theme.muted));
    await prefs.setBool('${_customThemeKey}_isDark', theme.isDark);
  }

  /// Set attendance color scheme
  Future<void> setAttendanceColorScheme(AttendanceColorScheme scheme) async {
    _attendanceColorScheme = scheme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      '${_attendanceColorSchemeKey}_useRanges',
      scheme.useRanges,
    );
    await prefs.setBool(
      '${_attendanceColorSchemeKey}_autoMatch',
      scheme.autoMatchTheme,
    );
    if (scheme.primaryColor != null) {
      await prefs.setString(
        '${_attendanceColorSchemeKey}_primary',
        _colorToHex(scheme.primaryColor!),
      );
    }
  }

  /// Set marks color scheme
  Future<void> setMarksColorScheme(MarksColorScheme scheme) async {
    _marksColorScheme = scheme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_marksColorSchemeKey}_useRanges', scheme.useRanges);
    await prefs.setBool(
      '${_marksColorSchemeKey}_autoMatch',
      scheme.autoMatchTheme,
    );
    if (scheme.primaryColor != null) {
      await prefs.setString(
        '${_marksColorSchemeKey}_primary',
        _colorToHex(scheme.primaryColor!),
      );
    }
  }

  /// Get current ThemeData
  ThemeData getThemeData() {
    return _currentTheme.toThemeData(_currentFont);
  }

  /// Helper: Convert Color to Hex
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Helper: Convert Hex to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
