import '../../../../../core/database_vitverse/database.dart';
import '../../../../../core/database_vitverse/entities/cab_ride_cache.dart';
import '../../../../../core/utils/logger.dart';
import '../config/cab_share_config.dart';
import '../models/cab_ride.dart';

/// Cab Share cache service
/// Manages local storage of rides
class CabRideCacheService {
  static const String _tag = 'CabRideCache';

  final _database = VitVerseDatabase.instance;

  /// Get all cached rides
  Future<List<CabRide>> getCachedRides() async {
    try {
      final dao = _database.cabRideDao;
      final cacheEntities = await dao.getAllRides();

      return cacheEntities.map((entity) {
        return CabRide(
          id: entity.id,
          fromLocation: entity.fromLocation,
          toLocation: entity.toLocation,
          travelDate: DateTime.fromMillisecondsSinceEpoch(entity.travelDate),
          travelTime: entity.travelTime,
          cabType: entity.cabType,
          seatsAvailable: entity.seatsAvailable,
          contactNumber: entity.contactNumber,
          description: entity.description,
          postedByName: entity.postedByName,
          postedByRegno: entity.postedByRegno,
          createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting cached rides', e);
      return [];
    }
  }

  /// Get upcoming rides only (from today onwards)
  Future<List<CabRide>> getUpcomingRides() async {
    try {
      final dao = _database.cabRideDao;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayTimestamp = today.millisecondsSinceEpoch;

      final cacheEntities = await dao.getUpcomingRides(todayTimestamp);

      return cacheEntities.map((entity) {
        return CabRide(
          id: entity.id,
          fromLocation: entity.fromLocation,
          toLocation: entity.toLocation,
          travelDate: DateTime.fromMillisecondsSinceEpoch(entity.travelDate),
          travelTime: entity.travelTime,
          cabType: entity.cabType,
          seatsAvailable: entity.seatsAvailable,
          contactNumber: entity.contactNumber,
          description: entity.description,
          postedByName: entity.postedByName,
          postedByRegno: entity.postedByRegno,
          createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting upcoming rides', e);
      return [];
    }
  }

  /// Get rides by user regno
  Future<List<CabRide>> getRidesByUser(String regno) async {
    try {
      final dao = _database.cabRideDao;
      final cacheEntities = await dao.getRidesByUser(regno);

      return cacheEntities.map((entity) {
        return CabRide(
          id: entity.id,
          fromLocation: entity.fromLocation,
          toLocation: entity.toLocation,
          travelDate: DateTime.fromMillisecondsSinceEpoch(entity.travelDate),
          travelTime: entity.travelTime,
          cabType: entity.cabType,
          seatsAvailable: entity.seatsAvailable,
          contactNumber: entity.contactNumber,
          description: entity.description,
          postedByName: entity.postedByName,
          postedByRegno: entity.postedByRegno,
          createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
        );
      }).toList();
    } catch (e) {
      Logger.e(_tag, 'Error getting rides by user: $regno', e);
      return [];
    }
  }

  /// Save rides to cache
  Future<void> saveRides(List<CabRide> rides) async {
    try {
      final dao = _database.cabRideDao;
      final now = DateTime.now().millisecondsSinceEpoch;

      final cacheEntities =
          rides.map((ride) {
            // Store date as start of day timestamp
            final dateOnly = DateTime(
              ride.travelDate.year,
              ride.travelDate.month,
              ride.travelDate.day,
            );

            return CabRideCacheEntity(
              id: ride.id,
              fromLocation: ride.fromLocation,
              toLocation: ride.toLocation,
              travelDate: dateOnly.millisecondsSinceEpoch,
              travelTime: ride.travelTime,
              cabType: ride.cabType,
              seatsAvailable: ride.seatsAvailable,
              contactNumber: ride.contactNumber,
              description: ride.description,
              postedByName: ride.postedByName,
              postedByRegno: ride.postedByRegno,
              createdAt: ride.createdAt.millisecondsSinceEpoch,
              cachedAt: now,
            );
          }).toList();

      await dao.insertAll(cacheEntities);
      Logger.d(_tag, 'Saved ${rides.length} rides to cache');
    } catch (e) {
      Logger.e(_tag, 'Error saving rides to cache', e);
    }
  }

  /// Delete a specific ride from cache
  Future<void> deleteRide(String rideId) async {
    try {
      final dao = _database.cabRideDao;
      await dao.deleteRide(rideId);
      Logger.d(_tag, 'Deleted ride from cache: $rideId');
    } catch (e) {
      Logger.e(_tag, 'Error deleting ride from cache', e);
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      final dao = _database.cabRideDao;
      await dao.clearAll();
      Logger.d(_tag, 'Cache cleared');
    } catch (e) {
      Logger.e(_tag, 'Error clearing cache', e);
    }
  }

  /// Get cache count
  Future<int> getCacheCount() async {
    try {
      final dao = _database.cabRideDao;
      return await dao.getCount();
    } catch (e) {
      Logger.e(_tag, 'Error getting cache count', e);
      return 0;
    }
  }

  /// Clean old rides (older than configured days in the past)
  Future<void> cleanOldRides() async {
    try {
      final dao = _database.cabRideDao;
      await dao.deleteOlderThan(CabShareConfig.cacheCleanupDays);
    } catch (e) {
      Logger.e(_tag, 'Error cleaning old rides', e);
    }
  }
}
