import 'package:flutter/material.dart';
import '../models/feature_model.dart';
import '../data/feature_repository.dart';
import '../../../core/utils/logger.dart';

class FeatureProvider with ChangeNotifier {
  final FeatureRepository _repository = FeatureRepository();

  List<Feature> _pinnedFeatures = [];
  bool _isLoading = true;
  ViewMode _viewMode = ViewMode.list; // List, 2-col grid, or 3-col grid
  bool _hasCustomizedPins = false; // Track if user has customized pins

  List<Feature> get pinnedFeatures => _pinnedFeatures;
  bool get isLoading => _isLoading;
  ViewMode get viewMode => _viewMode;
  bool get isGridView => _viewMode != ViewMode.list;
  bool get hasCustomizedPins => _hasCustomizedPins;

  /// Initialize provider - load featured and pinned features
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadViewMode();
      await _loadPinnedFeatures();

      Logger.success('FeatureProvider', 'Initialized successfully');
    } catch (e) {
      Logger.e('FeatureProvider', 'Initialization failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pinned features from storage
  Future<void> _loadPinnedFeatures() async {
    try {
      // Check if user has customized pins
      _hasCustomizedPins = await _repository.hasCustomizedPins();

      _pinnedFeatures = await _repository.getPinnedFeatures();

      // Set default pinned features only on first launch (not when user has customized)
      if (_pinnedFeatures.isEmpty && !_hasCustomizedPins) {
        await _setDefaultPinnedFeatures();
        _pinnedFeatures = await _repository.getPinnedFeatures();
      }

      Logger.d(
        'FeatureProvider',
        'Loaded ${_pinnedFeatures.length} pinned features (customized: $_hasCustomizedPins)',
      );
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to load pinned features', e);
      _pinnedFeatures = [];
    }
  }

  /// Set default pinned features on first launch
  Future<void> _setDefaultPinnedFeatures() async {
    try {
      final defaultPinnedIds = [
        'vitconnect:events',
        'vitconnect:friends_schedule',
        'vitconnect:pyq',
        'vitconnect:lost_and_found',
      ];

      for (final id in defaultPinnedIds) {
        await _repository.pinFeature(id);
      }

      Logger.d('FeatureProvider', 'Set default pinned features');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to set default pins', e);
    }
  }

  /// Pin a feature
  Future<void> pinFeature(Feature feature) async {
    try {
      await _repository.pinFeature(feature.id);
      await _repository.markAsCustomized();
      await _loadPinnedFeatures();
      notifyListeners();

      Logger.success('FeatureProvider', 'Pinned: ${feature.title}');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to pin feature', e);
      rethrow;
    }
  }

  /// Unpin a feature
  Future<void> unpinFeature(Feature feature) async {
    try {
      await _repository.unpinFeature(feature.id);
      await _repository.markAsCustomized();
      await _loadPinnedFeatures();
      notifyListeners();

      Logger.success('FeatureProvider', 'Unpinned: ${feature.title}');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to unpin feature', e);
      rethrow;
    }
  }

  /// Check if a feature is pinned
  bool isFeaturePinned(Feature feature) {
    return _pinnedFeatures.any((f) => f.id == feature.id);
  }

  /// Toggle pin status of a feature
  Future<void> togglePin(Feature feature) async {
    if (isFeaturePinned(feature)) {
      await unpinFeature(feature);
    } else {
      await pinFeature(feature);
    }
  }

  /// Reorder pinned features
  Future<void> reorderPinnedFeatures(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = _pinnedFeatures.removeAt(oldIndex);
      _pinnedFeatures.insert(newIndex, item);
      notifyListeners();

      await _repository.reorderPinnedFeatures(oldIndex, newIndex);

      Logger.d('FeatureProvider', 'Reordered pinned features');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to reorder features', e);
      await _loadPinnedFeatures();
      notifyListeners();
    }
  }

  void setViewMode(ViewMode mode) async {
    _viewMode = mode;
    notifyListeners();
    await _saveViewMode(mode);
    Logger.d('FeatureProvider', 'View mode: $mode');
  }

  void toggleViewMode() async {
    switch (_viewMode) {
      case ViewMode.list:
        _viewMode = ViewMode.grid2Column;
        break;
      case ViewMode.grid2Column:
        _viewMode = ViewMode.grid3Column;
        break;
      case ViewMode.grid3Column:
        _viewMode = ViewMode.list;
        break;
    }
    notifyListeners();
    await _saveViewMode(_viewMode);
    Logger.d('FeatureProvider', 'View mode: $_viewMode');
  }

  Future<void> _loadViewMode() async {
    try {
      final mode = await _repository.getViewMode();
      _viewMode = mode;
      Logger.d('FeatureProvider', 'Loaded view mode: $_viewMode');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to load view mode', e);
      _viewMode = ViewMode.grid2Column;
    }
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    try {
      await _repository.saveViewMode(mode);
      Logger.d('FeatureProvider', 'Saved view mode: $mode');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to save view mode', e);
    }
  }

  Future<void> clearAllPins() async {
    try {
      await _repository.clearPinnedFeatures();
      await _loadPinnedFeatures();
      notifyListeners();

      Logger.success('FeatureProvider', 'Cleared all pinned features');
    } catch (e) {
      Logger.e('FeatureProvider', 'Failed to clear pins', e);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
