import '../../../../../core/database_vitverse/database.dart';
import '../../../../../core/database_vitverse/entities/lost_found_cache.dart';
import '../../../../../core/utils/logger.dart';
import '../models/lost_found_item.dart';

/// Lost & Found cache service
/// Manages local storage of items
class LostFoundCacheService {
  static const String _tag = 'LostFoundCache';

  final _database = VitVerseDatabase.instance;

  /// Get all cached items
  Future<List<LostFoundItem>> getCachedItems() async {
    try {
      final dao = _database.lostFoundDao;
      final cacheEntities = await dao.getAllItems();

      return cacheEntities.map((entity) {
        return LostFoundItem(
          id: entity.id,
          type: entity.type,
          itemName: entity.itemName,
          place: entity.place,
          description: entity.description,
          contactName: entity.contactName,
          contactNumber: entity.contactNumber,
          postedByName: entity.postedByName,
          postedByRegno: entity.postedByRegno,
          imagePath: entity.imagePath,
          createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting cached items', e);
      return [];
    }
  }

  /// Get cached items by type
  Future<List<LostFoundItem>> getCachedItemsByType(String type) async {
    try {
      final dao = _database.lostFoundDao;
      final cacheEntities = await dao.getItemsByType(type);

      return cacheEntities.map((entity) {
        return LostFoundItem(
          id: entity.id,
          type: entity.type,
          itemName: entity.itemName,
          place: entity.place,
          description: entity.description,
          contactName: entity.contactName,
          contactNumber: entity.contactNumber,
          postedByName: entity.postedByName,
          postedByRegno: entity.postedByRegno,
          imagePath: entity.imagePath,
          createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting cached items by type: $type', e);
      return [];
    }
  }

  /// Save items to cache
  Future<void> saveItems(List<LostFoundItem> items) async {
    try {
      final dao = _database.lostFoundDao;
      final now = DateTime.now().millisecondsSinceEpoch;

      final cacheEntities =
          items.map((item) {
            return LostFoundCacheEntity(
              id: item.id,
              type: item.type,
              itemName: item.itemName,
              place: item.place,
              description: item.description,
              contactName: item.contactName,
              contactNumber: item.contactNumber,
              postedByName: item.postedByName,
              postedByRegno: item.postedByRegno,
              imagePath: item.imagePath,
              createdAt: item.createdAt.millisecondsSinceEpoch,
              cachedAt: now,
            );
          }).toList();

      await dao.insertAll(cacheEntities);
      Logger.d(_tag, 'Saved ${items.length} items to cache');
    } catch (e) {
      Logger.e(_tag, 'Error saving items to cache', e);
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      final dao = _database.lostFoundDao;
      await dao.clearAll();
      Logger.d(_tag, 'Cache cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing cache', e);
    }
  }

  /// Get cache count
  Future<int> getCacheCount() async {
    try {
      final dao = _database.lostFoundDao;
      return await dao.getCount();
    } catch (e) {
      Logger.e(_tag, 'Error getting cache count', e);
      return 0;
    }
  }
}
