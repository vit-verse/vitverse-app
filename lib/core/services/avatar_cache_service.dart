import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../utils/avatar_utils.dart';

/// Service for caching and retrieving selected avatar
class AvatarCacheService {
  static const String _tag = 'AvatarCache';
  static const String _key = 'selected_avatar_id';
  static const String _randomModeKey = 'avatar_random_mode';

  static Future<void> saveAvatar(String avatarId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, avatarId);
      await prefs.setBool(_randomModeKey, false);
      Logger.i(_tag, 'Avatar saved: $avatarId');
    } catch (e) {
      Logger.e(_tag, 'Failed to save avatar', e);
    }
  }

  static Future<void> setRandomMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_randomModeKey, enabled);
      if (enabled) {
        await prefs.remove(_key);
      }
      Logger.i(_tag, 'Random mode: $enabled');
    } catch (e) {
      Logger.e(_tag, 'Failed to set random mode', e);
    }
  }

  static Future<bool> isRandomMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_randomModeKey) ?? false;
    } catch (e) {
      Logger.e(_tag, 'Failed to check random mode', e);
      return false;
    }
  }

  static Future<String?> getAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRandom = prefs.getBool(_randomModeKey) ?? false;

      if (isRandom) {
        return AvatarUtils.generateRandomIds(1).first;
      }

      return prefs.getString(_key);
    } catch (e) {
      Logger.e(_tag, 'Failed to get avatar', e);
      return null;
    }
  }

  static Future<void> clearAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_randomModeKey);
      Logger.i(_tag, 'Avatar cleared');
    } catch (e) {
      Logger.e(_tag, 'Failed to clear avatar', e);
    }
  }
}
