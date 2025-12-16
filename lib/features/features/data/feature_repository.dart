import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feature_model.dart';
import 'feature_catalogue.dart';
import '../../../core/utils/logger.dart';

/// Feature Repository - Manages featured features and pinned features
class FeatureRepository {
  static const String _pinnedFeaturesKey = 'pinned_feature_ids';
  static const String _featureOrderKey = 'feature_order';
  static const String _customizedPinsKey = 'has_customized_pins';

  /// Get pinned feature IDs from local storage
  Future<List<String>> getPinnedFeatureIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pinnedFeaturesKey);

      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      final pinnedIds = decoded.cast<String>();

      Logger.d(
        'FeatureRepository',
        'Loaded ${pinnedIds.length} pinned features',
      );
      return pinnedIds;
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to load pinned features', e);
      return [];
    }
  }

  /// Save pinned feature IDs to local storage
  Future<void> savePinnedFeatureIds(List<String> featureIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(featureIds);
      await prefs.setString(_pinnedFeaturesKey, jsonString);

      Logger.d(
        'FeatureRepository',
        'Saved ${featureIds.length} pinned features',
      );
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to save pinned features', e);
      rethrow;
    }
  }

  /// Pin a feature
  Future<void> pinFeature(String featureId) async {
    final pinnedIds = await getPinnedFeatureIds();
    if (!pinnedIds.contains(featureId)) {
      pinnedIds.add(featureId);
      await savePinnedFeatureIds(pinnedIds);
      Logger.d('FeatureRepository', 'Pinned feature: $featureId');
    }
  }

  /// Unpin a feature
  Future<void> unpinFeature(String featureId) async {
    final pinnedIds = await getPinnedFeatureIds();
    if (pinnedIds.contains(featureId)) {
      pinnedIds.remove(featureId);
      await savePinnedFeatureIds(pinnedIds);
      Logger.d('FeatureRepository', 'Unpinned feature: $featureId');
    }
  }

  /// Check if a feature is pinned
  Future<bool> isFeaturePinned(String featureId) async {
    final pinnedIds = await getPinnedFeatureIds();
    return pinnedIds.contains(featureId);
  }

  /// Get pinned features as Feature objects
  Future<List<Feature>> getPinnedFeatures() async {
    final pinnedIds = await getPinnedFeatureIds();
    final features = <Feature>[];

    for (final id in pinnedIds) {
      final feature = FeatureCatalogue.getFeatureById(id);
      if (feature != null) {
        features.add(feature);
      }
    }

    return features;
  }

  /// Reorder pinned features
  Future<void> reorderPinnedFeatures(int oldIndex, int newIndex) async {
    final pinnedIds = await getPinnedFeatureIds();

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = pinnedIds.removeAt(oldIndex);
    pinnedIds.insert(newIndex, item);

    await savePinnedFeatureIds(pinnedIds);
    Logger.d('FeatureRepository', 'Reordered pinned features');
  }

  /// Save feature order for a section (VTOP or VIT Connect)
  Future<void> saveFeatureOrder(
    String sectionKey,
    List<String> featureIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_featureOrderKey}_$sectionKey';
      final jsonString = jsonEncode(featureIds);
      await prefs.setString(key, jsonString);

      Logger.d(
        'FeatureRepository',
        'Saved order for $sectionKey: ${featureIds.length} features',
      );
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to save feature order', e);
    }
  }

  /// Get feature order for a section
  Future<List<String>?> getFeatureOrder(String sectionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_featureOrderKey}_$sectionKey';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to load feature order', e);
      return null;
    }
  }

  /// Apply custom order to features
  Future<List<Feature>> applyCustomOrder(
    String sectionKey,
    List<Feature> features,
  ) async {
    final customOrder = await getFeatureOrder(sectionKey);
    if (customOrder == null) return features;

    final orderedFeatures = <Feature>[];
    final remainingFeatures = List<Feature>.from(features);

    // Add features in custom order
    for (final id in customOrder) {
      final feature = remainingFeatures.firstWhere(
        (f) => f.id == id,
        orElse: () => features.first, // Dummy fallback
      );
      if (remainingFeatures.contains(feature)) {
        orderedFeatures.add(feature);
        remainingFeatures.remove(feature);
      }
    }

    // Add any remaining features that weren't in the custom order
    orderedFeatures.addAll(remainingFeatures);

    return orderedFeatures;
  }

  /// Clear all pinned features
  Future<void> clearPinnedFeatures() async {
    await savePinnedFeatureIds([]);
    Logger.d('FeatureRepository', 'Cleared all pinned features');
  }

  /// Check if user has customized pins
  Future<bool> hasCustomizedPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_customizedPinsKey) ?? false;
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to check customized pins', e);
      return false;
    }
  }

  /// Mark pins as customized by user
  Future<void> markAsCustomized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_customizedPinsKey, true);
      Logger.d('FeatureRepository', 'Marked pins as customized');
    } catch (e) {
      Logger.e('FeatureRepository', 'Failed to mark as customized', e);
    }
  }
}
