import 'package:flutter/foundation.dart';
import '../models/cab_ride.dart';
import '../data/cab_ride_repository.dart';
import '../../../../../core/utils/logger.dart';

/// Cab Share provider
/// State management for Cab Share feature
class CabRideProvider extends ChangeNotifier {
  static const String _tag = 'CabRideProvider';

  final _repository = CabRideRepository();

  List<CabRide> _allRides = [];
  List<CabRide> _myRides = [];
  bool _isLoading = false;
  bool _isLoadingMyRides = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<CabRide> get allRides => _allRides;
  List<CabRide> get myRides => _myRides;
  bool get isLoading => _isLoading;
  bool get isLoadingMyRides => _isLoadingMyRides;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  /// Get rides grouped by date
  Map<String, List<CabRide>> get ridesGroupedByDate {
    final grouped = <String, List<CabRide>>{};
    for (final ride in _allRides) {
      final dateKey = ride.dateKey;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(ride);
    }
    return grouped;
  }

  /// Load rides
  Future<void> loadRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRides = await _repository.getRides();
      Logger.d(_tag, 'Loaded ${_allRides.length} rides');

      // Clean old rides in background
      _repository.cleanOldRides();
    } catch (e) {
      Logger.e(_tag, 'Error loading rides', e);
      _errorMessage = 'Failed to load rides';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load my rides
  Future<void> loadMyRides(String regNo) async {
    _isLoadingMyRides = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myRides = await _repository.getMyRides(regNo);
      Logger.d(_tag, 'Loaded ${_myRides.length} my rides');
    } catch (e) {
      Logger.e(_tag, 'Error loading my rides', e);
      _errorMessage = 'Failed to load your rides';
    } finally {
      _isLoadingMyRides = false;
      notifyListeners();
    }
  }

  /// Delete ride
  Future<bool> deleteRide(String rideId, String regNo) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.d(_tag, 'Provider: Starting delete for ride: $rideId');

      // Delete from Supabase (this will also clear cache)
      await _repository.deleteRide(rideId, regNo);
      Logger.success(
        _tag,
        'Provider: Successfully deleted from Supabase: $rideId',
      );

      // Remove from local lists ONLY after successful Supabase deletion
      final allRidesCount = _allRides.length;
      final myRidesCount = _myRides.length;

      _allRides.removeWhere((ride) => ride.id == rideId);
      _myRides.removeWhere((ride) => ride.id == rideId);

      Logger.d(
        _tag,
        'Provider: Removed from local lists (all: ${allRidesCount - _allRides.length}, my: ${myRidesCount - _myRides.length})',
      );

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      Logger.e(_tag, 'Provider: Error deleting ride', e, stack);
      _errorMessage = 'Failed to delete ride: ${e.toString()}';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh rides
  Future<void> refresh() async {
    try {
      _allRides = await _repository.forceRefresh();
      Logger.d(_tag, 'Refreshed ${_allRides.length} rides');
      notifyListeners();
    } catch (e) {
      Logger.e(_tag, 'Error refreshing rides', e);
      _errorMessage = 'Failed to refresh rides';
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Filter rides
  List<CabRide> filterRides({
    String? fromLocation,
    String? toLocation,
    DateTime? date,
  }) {
    return _allRides.where((ride) {
      if (fromLocation != null && fromLocation.isNotEmpty) {
        if (!ride.fromLocation.toLowerCase().contains(
          fromLocation.toLowerCase(),
        )) {
          return false;
        }
      }
      if (toLocation != null && toLocation.isNotEmpty) {
        if (!ride.toLocation.toLowerCase().contains(toLocation.toLowerCase())) {
          return false;
        }
      }
      if (date != null) {
        final rideDate = DateTime(
          ride.travelDate.year,
          ride.travelDate.month,
          ride.travelDate.day,
        );
        final filterDate = DateTime(date.year, date.month, date.day);
        if (!rideDate.isAtSameMomentAs(filterDate)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
