import 'package:sqflite/sqflite.dart';
import '../entities/cab_ride_cache.dart';
import '../../utils/logger.dart';

/// Data Access Object for Cab Share cache
class CabRideDao {
  final Database _database;

  CabRideDao(this._database);

  /// Get all cached rides
  Future<List<CabRideCacheEntity>> getAllRides() async {
    try {
      final results = await _database.query(
        'cab_ride_cache',
        orderBy: 'travel_date ASC, travel_time ASC',
      );

      return results.map((map) => CabRideCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CabRideDao', 'Error getting all rides', e);
      return [];
    }
  }

  /// Get rides from a specific date onwards
  Future<List<CabRideCacheEntity>> getUpcomingRides(int fromDate) async {
    try {
      final results = await _database.query(
        'cab_ride_cache',
        where: 'travel_date >= ?',
        whereArgs: [fromDate],
        orderBy: 'travel_date ASC, travel_time ASC',
      );

      return results.map((map) => CabRideCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CabRideDao', 'Error getting upcoming rides', e);
      return [];
    }
  }

  /// Get rides by user regno
  Future<List<CabRideCacheEntity>> getRidesByUser(String regno) async {
    try {
      final results = await _database.query(
        'cab_ride_cache',
        where: 'posted_by_regno = ?',
        whereArgs: [regno],
        orderBy: 'travel_date DESC',
      );

      return results.map((map) => CabRideCacheEntity.fromMap(map)).toList();
    } catch (e) {
      Logger.e('CabRideDao', 'Error getting rides by user: $regno', e);
      return [];
    }
  }

  /// Insert or update ride
  Future<void> insertOrUpdate(CabRideCacheEntity ride) async {
    try {
      await _database.insert(
        'cab_ride_cache',
        ride.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.e('CabRideDao', 'Error inserting/updating ride: ${ride.id}', e);
    }
  }

  /// Insert multiple rides
  Future<void> insertAll(List<CabRideCacheEntity> rides) async {
    try {
      await _database.transaction((txn) async {
        for (final ride in rides) {
          await txn.insert(
            'cab_ride_cache',
            ride.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      Logger.d('CabRideDao', 'Cached ${rides.length} rides');
    } catch (e) {
      Logger.e('CabRideDao', 'Error inserting all rides', e);
    }
  }

  /// Delete a specific ride
  Future<void> deleteRide(String rideId) async {
    try {
      await _database.delete(
        'cab_ride_cache',
        where: 'id = ?',
        whereArgs: [rideId],
      );
      Logger.d('CabRideDao', 'Deleted ride: $rideId');
    } catch (e) {
      Logger.e('CabRideDao', 'Error deleting ride: $rideId', e);
    }
  }

  /// Clear all cached rides
  Future<void> clearAll() async {
    try {
      await _database.delete('cab_ride_cache');
      Logger.d('CabRideDao', 'Cache cleared');
    } catch (e) {
      Logger.e('CabRideDao', 'Error clearing cache', e);
    }
  }

  /// Delete rides older than days
  Future<void> deleteOlderThan(int days) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

      final deletedCount = await _database.delete(
        'cab_ride_cache',
        where: 'travel_date < ?',
        whereArgs: [cutoffTime],
      );

      Logger.d('CabRideDao', 'Deleted $deletedCount old rides');
    } catch (e) {
      Logger.e('CabRideDao', 'Error deleting old rides', e);
    }
  }

  /// Get cache count
  Future<int> getCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM cab_ride_cache',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      Logger.e('CabRideDao', 'Error getting count', e);
      return 0;
    }
  }
}
