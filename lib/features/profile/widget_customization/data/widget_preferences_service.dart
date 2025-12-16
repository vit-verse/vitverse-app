import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/logger.dart';

enum ClassCardDisplayType { none, attendance, venue, slot, buffer }

enum HomeSecondaryWidgetType {
  todayClasses,
  ongoingClass,
  nextClass,
  nextExam,
  totalODs,
}

/// Service for managing widget customization preferences
class WidgetPreferencesService {
  static const String _tag = 'WidgetPreferencesService';

  // Preference keys
  static const String _keyClassCardDisplay = 'class_card_display_type';
  static const String _keyHomeSecondaryWidget = 'home_secondary_widget_type';
  static const String _keyHomeSecondaryWidgets =
      'home_secondary_widgets_list'; // Multi-select

  static WidgetPreferencesService? _instance;
  static WidgetPreferencesService get instance {
    _instance ??= WidgetPreferencesService._();
    return _instance!;
  }

  WidgetPreferencesService._();

  SharedPreferences? _prefs;

  /// Initialize preferences
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Logger.i(_tag, 'Widget preferences initialized');
    } catch (e) {
      Logger.e(_tag, 'Error initializing widget preferences', e);
    }
  }

  /// Get class card display type
  ClassCardDisplayType getClassCardDisplayType() {
    try {
      final value = _prefs?.getString(_keyClassCardDisplay);
      if (value == null) {
        return ClassCardDisplayType.attendance; // Default
      }
      return ClassCardDisplayType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ClassCardDisplayType.attendance,
      );
    } catch (e) {
      Logger.e(_tag, 'Error getting class card display type', e);
      return ClassCardDisplayType.attendance;
    }
  }

  /// Set class card display type
  Future<bool> setClassCardDisplayType(ClassCardDisplayType type) async {
    try {
      final success =
          await _prefs?.setString(_keyClassCardDisplay, type.name) ?? false;
      if (success) {
        Logger.i(_tag, 'Class card display type set to: ${type.name}');
      }
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error setting class card display type', e);
      return false;
    }
  }

  /// Get home secondary widget type
  HomeSecondaryWidgetType getHomeSecondaryWidgetType() {
    try {
      final value = _prefs?.getString(_keyHomeSecondaryWidget);
      if (value == null) {
        return HomeSecondaryWidgetType.todayClasses; // Default
      }
      return HomeSecondaryWidgetType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => HomeSecondaryWidgetType.todayClasses,
      );
    } catch (e) {
      Logger.e(_tag, 'Error getting home secondary widget type', e);
      return HomeSecondaryWidgetType.todayClasses;
    }
  }

  /// Set home secondary widget type
  Future<bool> setHomeSecondaryWidgetType(HomeSecondaryWidgetType type) async {
    try {
      final success =
          await _prefs?.setString(_keyHomeSecondaryWidget, type.name) ?? false;
      if (success) {
        Logger.i(_tag, 'Home secondary widget type set to: ${type.name}');
      }
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error setting home secondary widget type', e);
      return false;
    }
  }

  /// Get selected home secondary widgets (multi-select)
  List<HomeSecondaryWidgetType> getHomeSecondaryWidgets() {
    try {
      final value = _prefs?.getStringList(_keyHomeSecondaryWidgets);
      if (value == null || value.isEmpty) {
        // Default: All widgets selected
        return HomeSecondaryWidgetType.values;
      }
      return value.map((name) {
        return HomeSecondaryWidgetType.values.firstWhere(
          (e) => e.name == name,
          orElse: () => HomeSecondaryWidgetType.todayClasses,
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting home secondary widgets', e);
      return HomeSecondaryWidgetType.values;
    }
  }

  /// Set selected home secondary widgets (multi-select)
  Future<bool> setHomeSecondaryWidgets(
    List<HomeSecondaryWidgetType> widgets,
  ) async {
    try {
      if (widgets.isEmpty) {
        // Don't allow empty selection, keep at least one
        return false;
      }
      final names = widgets.map((w) => w.name).toList();
      final success =
          await _prefs?.setStringList(_keyHomeSecondaryWidgets, names) ?? false;
      if (success) {
        Logger.i(_tag, 'Home secondary widgets set to: $names');
      }
      return success;
    } catch (e) {
      Logger.e(_tag, 'Error setting home secondary widgets', e);
      return false;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    try {
      await _prefs?.remove(_keyClassCardDisplay);
      await _prefs?.remove(_keyHomeSecondaryWidget);
      await _prefs?.remove(_keyHomeSecondaryWidgets);
      Logger.i(_tag, 'Widget preferences reset to defaults');
    } catch (e) {
      Logger.e(_tag, 'Error resetting widget preferences', e);
    }
  }
}
