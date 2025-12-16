import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';
import 'student_profile.dart';

/// Helper class for managing student profile updates
class StudentProfileHelper {
  static const String _tag = 'StudentProfileHelper';

  /// Update nickname in student profile
  static Future<bool> updateNickname(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        Logger.e(_tag, 'No student profile found');
        return false;
      }

      // Parse existing profile
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;

      // Update nickname
      profileMap['nickname'] = nickname.trim().isEmpty ? null : nickname.trim();

      // Save back to SharedPreferences
      await prefs.setString('student_profile', jsonEncode(profileMap));

      Logger.i(
        _tag,
        'Nickname updated: ${profileMap['nickname'] ?? '(cleared)'}',
      );
      return true;
    } catch (e) {
      Logger.e(_tag, 'Error updating nickname', e);
      return false;
    }
  }

  /// Get current student profile
  static Future<StudentProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson != null && profileJson.isNotEmpty) {
        return StudentProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      Logger.e(_tag, 'Error getting profile', e);
      return null;
    }
  }
}
