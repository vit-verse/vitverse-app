/// Theme Preference Model
class ThemePreference {
  final String themeId;
  final String fontFamily;
  final CustomThemeData? customTheme;

  const ThemePreference({
    required this.themeId,
    required this.fontFamily,
    this.customTheme,
  });

  factory ThemePreference.defaultPreference() {
    return const ThemePreference(themeId: 'dark', fontFamily: 'Inter');
  }

  ThemePreference copyWith({
    String? themeId,
    String? fontFamily,
    CustomThemeData? customTheme,
  }) {
    return ThemePreference(
      themeId: themeId ?? this.themeId,
      fontFamily: fontFamily ?? this.fontFamily,
      customTheme: customTheme ?? this.customTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeId': themeId,
      'fontFamily': fontFamily,
      'customTheme': customTheme?.toJson(),
    };
  }

  factory ThemePreference.fromJson(Map<String, dynamic> json) {
    return ThemePreference(
      themeId: json['themeId'] as String,
      fontFamily: json['fontFamily'] as String,
      customTheme:
          json['customTheme'] != null
              ? CustomThemeData.fromJson(
                json['customTheme'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Custom Theme Data Model
class CustomThemeData {
  final String primaryHex;
  final String backgroundHex;
  final String surfaceHex;
  final String textHex;
  final String mutedHex;
  final bool isDark;

  const CustomThemeData({
    required this.primaryHex,
    required this.backgroundHex,
    required this.surfaceHex,
    required this.textHex,
    required this.mutedHex,
    required this.isDark,
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryHex': primaryHex,
      'backgroundHex': backgroundHex,
      'surfaceHex': surfaceHex,
      'textHex': textHex,
      'mutedHex': mutedHex,
      'isDark': isDark,
    };
  }

  factory CustomThemeData.fromJson(Map<String, dynamic> json) {
    return CustomThemeData(
      primaryHex: json['primaryHex'] as String,
      backgroundHex: json['backgroundHex'] as String,
      surfaceHex: json['surfaceHex'] as String,
      textHex: json['textHex'] as String,
      mutedHex: json['mutedHex'] as String,
      isDark: json['isDark'] as bool,
    );
  }
}
