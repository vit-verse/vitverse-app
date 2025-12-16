import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/logger.dart';
import '../models/hostel_preferences.dart';

/// Service to manage hostel preferences (gender, block, mess type, etc.)
class HostelPreferencesService {
  static const String _tag = 'HostelPreferencesService';
  static const String _prefsKey = 'hostel_preferences';

  /// Save hostel preferences to local storage
  static Future<void> savePreferences(HostelPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(_prefsKey, jsonString);
      Logger.i(_tag, 'Preferences saved successfully');
      Logger.d(_tag, 'Saved preferences: ${preferences.toJson()}');
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error saving preferences: $e', stackTrace);
      rethrow;
    }
  }

  /// Load hostel preferences from local storage
  static Future<HostelPreferences?> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString == null || jsonString.isEmpty) {
        Logger.d(_tag, 'No preferences found in storage');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final preferences = HostelPreferences.fromJson(json);
      Logger.i(_tag, 'Preferences loaded successfully');
      Logger.d(_tag, 'Loaded preferences: ${preferences.toJson()}');
      return preferences;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error loading preferences: $e', stackTrace);
      return null;
    }
  }

  /// Clear saved preferences
  static Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      Logger.i(_tag, 'Preferences cleared successfully');
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error clearing preferences: $e', stackTrace);
      rethrow;
    }
  }

  /// Check if preferences are saved
  static Future<bool> hasPreferences() async {
    try {
      final preferences = await loadPreferences();
      return preferences != null && preferences.isComplete;
    } catch (e) {
      Logger.e(_tag, 'Error checking preferences: $e');
      return false;
    }
  }

  /// Update specific preference field
  static Future<void> updatePreference({
    String? gender,
    String? block,
    String? messType,
    String? caterer,
    int? roomNumber,
  }) async {
    try {
      final current = await loadPreferences();

      final updated = HostelPreferences(
        gender: gender ?? current?.gender ?? '',
        block: block ?? current?.block ?? '',
        messType: messType ?? current?.messType ?? '',
        caterer: caterer ?? current?.caterer,
        roomNumber: roomNumber ?? current?.roomNumber,
      );

      await savePreferences(updated);
      Logger.d(
        _tag,
        'Preference updated: gender=$gender, block=$block, messType=$messType',
      );
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error updating preference: $e', stackTrace);
      rethrow;
    }
  }

  /// Get mess menu file name from saved preferences
  static Future<String?> getMessMenuFileName() async {
    final preferences = await loadPreferences();
    if (preferences == null || !preferences.isComplete) {
      return null;
    }
    return preferences.getMessMenuFileName();
  }

  /// Get laundry schedule file name from saved preferences
  static Future<String?> getLaundryFileName() async {
    final preferences = await loadPreferences();
    if (preferences == null || !preferences.isComplete) {
      return null;
    }
    return preferences.getLaundryFileName();
  }
}
