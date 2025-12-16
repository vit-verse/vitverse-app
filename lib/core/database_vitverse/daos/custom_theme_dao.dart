import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../utils/logger.dart';
import '../../theme/app_theme.dart';

/// DAO for managing custom user-created themes
class CustomThemeDao {
  final Database _db;
  static const String _tag = 'CustomThemeDao';
  static const String _tableName = 'custom_themes';

  CustomThemeDao(this._db);

  /// Get all custom themes
  Future<List<AppTheme>> getAllCustomThemes() async {
    try {
      final result = await _db.query(_tableName, orderBy: 'created_at DESC');

      return result.map((map) => _mapToTheme(map)).toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to get custom themes', e);
      return [];
    }
  }

  /// Save a custom theme
  Future<bool> saveCustomTheme(AppTheme theme) async {
    try {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      await _db.insert(_tableName, {
        'id': id,
        'name': theme.name,
        'primary_color': _colorToHex(theme.primary),
        'background_color': _colorToHex(theme.background),
        'surface_color': _colorToHex(theme.surface),
        'text_color': _colorToHex(theme.text),
        'muted_color': _colorToHex(theme.muted),
        'is_dark': theme.isDark ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      Logger.i(_tag, 'Custom theme "${theme.name}" saved with ID: $id');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Failed to save custom theme', e);
      return false;
    }
  }

  /// Delete a custom theme
  Future<bool> deleteCustomTheme(String themeId) async {
    try {
      final result = await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [themeId],
      );

      if (result > 0) {
        Logger.i(_tag, 'Custom theme deleted: $themeId');
        return true;
      }
      return false;
    } catch (e) {
      Logger.e(_tag, 'Failed to delete custom theme', e);
      return false;
    }
  }

  /// Get count of custom themes
  Future<int> getCustomThemeCount() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      Logger.e(_tag, 'Failed to get custom theme count', e);
      return 0;
    }
  }

  /// Clear all custom themes
  Future<void> clearAllCustomThemes() async {
    try {
      await _db.delete(_tableName);
      Logger.i(_tag, 'All custom themes cleared');
    } catch (e) {
      Logger.e(_tag, 'Failed to clear custom themes', e);
    }
  }

  /// Helper: Map database row to AppTheme
  AppTheme _mapToTheme(Map<String, dynamic> map) {
    return AppTheme(
      id: map['id'] as String,
      name: map['name'] as String,
      primary: Color(_hexToColorInt(map['primary_color'] as String)),
      background: Color(_hexToColorInt(map['background_color'] as String)),
      surface: Color(_hexToColorInt(map['surface_color'] as String)),
      text: Color(_hexToColorInt(map['text_color'] as String)),
      muted: Color(_hexToColorInt(map['muted_color'] as String)),
      isDark: (map['is_dark'] as int) == 1,
    );
  }

  /// Helper: Convert Color to Hex
  String _colorToHex(dynamic color) {
    if (color is int) {
      return '#${color.toRadixString(16).substring(2).toUpperCase()}';
    }
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Helper: Convert Hex to Color int
  int _hexToColorInt(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return int.parse('FF$hexCode', radix: 16);
  }
}
