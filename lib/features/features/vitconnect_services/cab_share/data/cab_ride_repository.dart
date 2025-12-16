import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../../../../../core/utils/logger.dart';
import '../models/cab_ride.dart';
import 'cab_ride_cache_service.dart';

/// Cab Share repository
/// Handles all data operations
class CabRideRepository {
  static const String _tag = 'CabRideRepo';

  final SupabaseClient _supabase = SupabaseClientService.client;
  final _cacheService = CabRideCacheService();

  /// Get rides (cache-first approach)
  Future<List<CabRide>> getRides() async {
    try {
      // Try cache first
      final cached = await _cacheService.getUpcomingRides();
      if (cached.isNotEmpty) {
        Logger.d(_tag, 'Showing ${cached.length} cached rides');
        // Fetch in background
        _refreshInBackground();
        return cached;
      }

      // No cache - fetch from Supabase
      return await _fetchFromSupabase();
    } catch (e, stack) {
      Logger.e(_tag, 'Error getting rides', e, stack);
      return [];
    }
  }

  /// Get user's rides
  Future<List<CabRide>> getMyRides(String regNo) async {
    try {
      Logger.d(_tag, 'Fetching my rides for: $regNo');

      final response = await _supabase
          .from('cab_rides')
          .select()
          .eq('posted_by_regno', regNo)
          .order('travel_date', ascending: false)
          .order('travel_time', ascending: false);

      final rides = (response as List).map((e) => CabRide.fromMap(e)).toList();

      Logger.success(_tag, 'Fetched ${rides.length} my rides');
      return rides;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching my rides', e, stack);
      rethrow;
    }
  }

  /// Fetch rides from Supabase
  Future<List<CabRide>> _fetchFromSupabase() async {
    try {
      Logger.d(_tag, 'Fetching rides from Supabase');

      // Get today's date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String();

      final response = await _supabase
          .from('cab_rides')
          .select()
          .gte('travel_date', todayStr)
          .order('travel_date', ascending: true)
          .order('travel_time', ascending: true)
          .limit(500);

      final rides = (response as List).map((e) => CabRide.fromMap(e)).toList();

      // Cache rides locally for offline access
      Logger.d(_tag, 'Clearing old cache...');
      await _cacheService.clearCache();
      Logger.d(_tag, 'Saving ${rides.length} rides to local cache...');
      await _cacheService.saveRides(rides);
      final cacheCount = await _cacheService.getCacheCount();
      Logger.success(
        _tag,
        'Fetched ${rides.length} rides ($cacheCount cached)',
      );

      return rides;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching from Supabase', e, stack);
      rethrow;
    }
  }

  /// Refresh in background
  void _refreshInBackground() async {
    try {
      final rides = await _fetchFromSupabase();
      Logger.d(_tag, 'Background refresh: ${rides.length} rides');
    } catch (e) {
      Logger.w(_tag, 'Background refresh failed: $e');
    }
  }

  /// Add new ride
  Future<void> addRide({
    required String fromLocation,
    required String toLocation,
    required DateTime travelDate,
    required String travelTime,
    required String cabType,
    required int seatsAvailable,
    required String contactNumber,
    String? description,
    required String postedByName,
    required String postedByRegno,
    required bool notifyAll,
    required Function(double) onProgress,
  }) async {
    try {
      Logger.d(_tag, 'Adding ride: $fromLocation to $toLocation');

      onProgress(0.3);

      // Insert to Supabase DB
      await _supabase.from('cab_rides').insert({
        'from_location': fromLocation,
        'to_location': toLocation,
        'travel_date': travelDate.toIso8601String(),
        'travel_time': travelTime,
        'cab_type': cabType,
        'seats_available': seatsAvailable,
        'contact_number': contactNumber,
        'description': description,
        'posted_by_name': postedByName,
        'posted_by_regno': postedByRegno,
      });

      onProgress(0.7);

      // Send notification if enabled
      if (notifyAll) {
        await _sendNotificationViaFirebase(
          title: 'New Cab Share Available',
          fromLocation: fromLocation,
          toLocation: toLocation,
          travelDate: _formatDate(travelDate),
          travelTime: travelTime,
          cabType: cabType,
          postedByName: postedByName,
        );
      }

      onProgress(0.9);

      // Clear cache to force refresh
      await _cacheService.clearCache();

      onProgress(1.0);
      Logger.success(_tag, 'Ride added successfully');
    } catch (e, stack) {
      Logger.e(_tag, 'Error adding ride', e, stack);
      rethrow;
    }
  }

  /// Delete ride
  Future<void> deleteRide(String rideId, String regNo) async {
    try {
      Logger.d(_tag, 'Deleting ride: $rideId');

      // Delete from Supabase
      await _supabase
          .from('cab_rides')
          .delete()
          .eq('id', rideId)
          .eq('posted_by_regno', regNo);

      // Delete from cache
      await _cacheService.deleteRide(rideId);

      Logger.success(_tag, 'Ride deleted successfully');
    } catch (e, stack) {
      Logger.e(_tag, 'Error deleting ride', e, stack);
      rethrow;
    }
  }

  /// Force refresh (pull-to-refresh)
  Future<List<CabRide>> forceRefresh() async {
    try {
      Logger.d(_tag, 'Force refreshing rides');
      await _cacheService.clearCache();
      return await _fetchFromSupabase();
    } catch (e, stack) {
      Logger.e(_tag, 'Error force refreshing', e, stack);
      rethrow;
    }
  }

  /// Clean old rides from cache
  Future<void> cleanOldRides() async {
    try {
      await _cacheService.cleanOldRides();
    } catch (e) {
      Logger.w(_tag, 'Error cleaning old rides: $e');
    }
  }

  /// Send notification via Firebase Callable Function
  Future<void> _sendNotificationViaFirebase({
    required String title,
    required String fromLocation,
    required String toLocation,
    required String travelDate,
    required String travelTime,
    required String cabType,
    required String postedByName,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions
          .httpsCallable('sendCabShareNotification')
          .call({
            'title': title,
            'fromLocation': fromLocation,
            'toLocation': toLocation,
            'travelDate': travelDate,
            'travelTime': travelTime,
            'cabType': cabType,
            'postedByName': postedByName,
          });

      if (result.data['success'] == true) {
        Logger.success(_tag, 'Notification sent via Firebase');
      } else {
        Logger.w(_tag, 'Notification failed: ${result.data}');
      }
    } catch (e) {
      Logger.w(_tag, 'Notification sending failed: $e');
      // Don't throw - ride was already added
    }
  }

  /// Format date for notification
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
