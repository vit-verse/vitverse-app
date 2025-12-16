import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_preference.dart';

/// Theme Repository - Handles theme persistence
class ThemeRepository {
  static const String _key = 'theme_preference';

  /// Save theme preference
  Future<void> saveThemePreference(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(preference.toJson());
    await prefs.setString(_key, json);
  }

  /// Load theme preference
  Future<ThemePreference> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      return ThemePreference.defaultPreference();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ThemePreference.fromJson(json);
    } catch (e) {
      return ThemePreference.defaultPreference();
    }
  }

  /// Clear theme preference
  Future<void> clearThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
