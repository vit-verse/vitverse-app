import 'package:flutter/material.dart';
import '../data/widget_preferences_service.dart';
import '../../../../core/utils/logger.dart';

/// Provider for managing widget customization state
class WidgetCustomizationProvider extends ChangeNotifier {
  static const String _tag = 'WidgetCustomizationProvider';

  final WidgetPreferencesService _prefsService =
      WidgetPreferencesService.instance;

  ClassCardDisplayType _classCardDisplayType = ClassCardDisplayType.attendance;
  HomeSecondaryWidgetType _homeSecondaryWidgetType =
      HomeSecondaryWidgetType.todayClasses;
  List<HomeSecondaryWidgetType> _homeSecondaryWidgets =
      HomeSecondaryWidgetType.values;

  ClassCardDisplayType get classCardDisplayType => _classCardDisplayType;
  HomeSecondaryWidgetType get homeSecondaryWidgetType =>
      _homeSecondaryWidgetType;
  List<HomeSecondaryWidgetType> get homeSecondaryWidgets =>
      _homeSecondaryWidgets;

  WidgetCustomizationProvider() {
    _loadPreferences();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      _classCardDisplayType = _prefsService.getClassCardDisplayType();
      _homeSecondaryWidgetType = _prefsService.getHomeSecondaryWidgetType();
      _homeSecondaryWidgets = _prefsService.getHomeSecondaryWidgets();
      Logger.i(
        _tag,
        'Loaded preferences: classCard=${_classCardDisplayType.name}, homeWidgets=${_homeSecondaryWidgets.length}',
      );
      notifyListeners();
    } catch (e) {
      Logger.e(_tag, 'Error loading preferences', e);
    }
  }

  /// Set class card display type
  Future<void> setClassCardDisplayType(ClassCardDisplayType type) async {
    if (_classCardDisplayType == type) return;

    try {
      final success = await _prefsService.setClassCardDisplayType(type);
      if (success) {
        _classCardDisplayType = type;
        Logger.i(_tag, 'Class card display type updated to: ${type.name}');
        notifyListeners();
      }
    } catch (e) {
      Logger.e(_tag, 'Error setting class card display type', e);
    }
  }

  /// Set home secondary widget type
  Future<void> setHomeSecondaryWidgetType(HomeSecondaryWidgetType type) async {
    if (_homeSecondaryWidgetType == type) return;

    try {
      final success = await _prefsService.setHomeSecondaryWidgetType(type);
      if (success) {
        _homeSecondaryWidgetType = type;
        Logger.i(_tag, 'Home secondary widget type updated to: ${type.name}');
        notifyListeners();
      }
    } catch (e) {
      Logger.e(_tag, 'Error setting home secondary widget type', e);
    }
  }

  /// Toggle home secondary widget selection (multi-select)
  Future<void> toggleHomeSecondaryWidget(HomeSecondaryWidgetType type) async {
    try {
      final newList = List<HomeSecondaryWidgetType>.from(_homeSecondaryWidgets);

      if (newList.contains(type)) {
        // Don't allow removing if it's the last one
        if (newList.length <= 1) {
          Logger.w(_tag, 'Cannot remove last widget');
          return;
        }
        newList.remove(type);
      } else {
        newList.add(type);
      }

      final success = await _prefsService.setHomeSecondaryWidgets(newList);
      if (success) {
        _homeSecondaryWidgets = newList;
        Logger.i(
          _tag,
          'Home secondary widgets updated: ${newList.map((w) => w.name).toList()}',
        );
        notifyListeners();
      }
    } catch (e) {
      Logger.e(_tag, 'Error toggling home secondary widget', e);
    }
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      await _prefsService.resetToDefaults();
      _classCardDisplayType = ClassCardDisplayType.attendance;
      _homeSecondaryWidgetType = HomeSecondaryWidgetType.todayClasses;
      _homeSecondaryWidgets = HomeSecondaryWidgetType.values;
      Logger.i(_tag, 'Widget preferences reset to defaults');
      notifyListeners();
    } catch (e) {
      Logger.e(_tag, 'Error resetting to defaults', e);
    }
  }

  /// Get display name for class card display type
  static String getClassCardDisplayName(ClassCardDisplayType type) {
    switch (type) {
      case ClassCardDisplayType.none:
        return 'None';
      case ClassCardDisplayType.attendance:
        return 'Attendance %';
      case ClassCardDisplayType.venue:
        return 'Venue';
      case ClassCardDisplayType.slot:
        return 'Slot';
      case ClassCardDisplayType.buffer:
        return 'Buffer (±75%)';
    }
  }

  /// Get display name for home secondary widget type
  static String getHomeSecondaryWidgetName(HomeSecondaryWidgetType type) {
    switch (type) {
      case HomeSecondaryWidgetType.todayClasses:
        return 'Today\'s Classes';
      case HomeSecondaryWidgetType.ongoingClass:
        return 'Ongoing Class';
      case HomeSecondaryWidgetType.nextClass:
        return 'Next Class';
      case HomeSecondaryWidgetType.nextExam:
        return 'Next Exam';
      case HomeSecondaryWidgetType.totalODs:
        return 'Total ODs';
    }
  }

  /// Get icon for class card display type
  static IconData getClassCardDisplayIcon(ClassCardDisplayType type) {
    switch (type) {
      case ClassCardDisplayType.none:
        return Icons.visibility_off;
      case ClassCardDisplayType.attendance:
        return Icons.check_circle_outline;
      case ClassCardDisplayType.venue:
        return Icons.location_on_outlined;
      case ClassCardDisplayType.slot:
        return Icons.schedule_outlined;
      case ClassCardDisplayType.buffer:
        return Icons.calculate_outlined;
    }
  }

  /// Get icon for home secondary widget type
  static IconData getHomeSecondaryWidgetIcon(HomeSecondaryWidgetType type) {
    switch (type) {
      case HomeSecondaryWidgetType.todayClasses:
        return Icons.today_outlined;
      case HomeSecondaryWidgetType.ongoingClass:
        return Icons.play_circle_outline;
      case HomeSecondaryWidgetType.nextClass:
        return Icons.skip_next_outlined;
      case HomeSecondaryWidgetType.nextExam:
        return Icons.assignment_outlined;
      case HomeSecondaryWidgetType.totalODs:
        return Icons.event_busy_outlined;
    }
  }
}
