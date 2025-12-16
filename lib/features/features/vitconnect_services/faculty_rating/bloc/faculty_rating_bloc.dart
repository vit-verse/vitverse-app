import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../../core/utils/logger.dart';
import '../models/rating_model.dart';
import '../repositories/faculty_repository.dart';
import '../repositories/rating_repository.dart';
import '../utils/rating_constants.dart';
import 'faculty_rating_state.dart';

/// Controller for managing faculty rating feature state
class FacultyRatingBloc extends ChangeNotifier {
  static const String _tag = 'FacultyRatingBloc';

  final FacultyRepository _facultyRepository;
  final RatingRepository _ratingRepository;

  DateTime? _lastFetchTime;
  FacultyRatingState _state = const FacultyRatingInitial();

  // Cache for last successful loaded state
  static FacultyRatingLoaded? _cachedState;
  static DateTime? _cachedStateTime;

  FacultyRatingBloc({
    FacultyRepository? facultyRepository,
    RatingRepository? ratingRepository,
  }) : _facultyRepository = facultyRepository ?? FacultyRepository(),
       _ratingRepository = ratingRepository ?? RatingRepository() {
    // Restore from cache if available and recent
    if (_cachedState != null && _cachedStateTime != null) {
      final cacheAge = DateTime.now().difference(_cachedStateTime!);
      if (cacheAge < FacultyRatingConstants.cacheDuration) {
        Logger.i(
          _tag,
          'Restoring from cached state (age: ${cacheAge.inSeconds}s)',
        );
        _state = _cachedState!.copyWith(isRefreshing: false);
        _lastFetchTime = _cachedStateTime;
      }
    }
  }

  FacultyRatingState get state => _state;

  void _emit(FacultyRatingState newState) {
    // Check if bloc is disposed before emitting
    if (!hasListeners) {
      Logger.w(_tag, 'Attempted to emit state after disposal, skipping');
      return;
    }
    _state = newState;

    // Cache successful loaded states
    if (newState is FacultyRatingLoaded) {
      _cachedState = newState;
      _cachedStateTime = DateTime.now();
      Logger.d(
        _tag,
        'Cached state updated with ${newState.faculties.length} faculties',
      );
    }

    notifyListeners();
  }

  /// Load faculties with ratings
  /// If [forceRefresh] is true, will skip cache check
  Future<void> loadFaculties({bool forceRefresh = false}) async {
    try {
      // Check if already disposed
      if (!hasListeners) {
        Logger.w(_tag, 'Bloc disposed, skipping loadFaculties');
        return;
      }

      // If we have cached state and it's recent, show it immediately
      if (!forceRefresh && _state is FacultyRatingLoaded) {
        Logger.i(_tag, 'Already have loaded state, checking if refresh needed');

        // Check if cache needs refresh
        final isCacheFresh = await _facultyRepository.isCacheFresh();
        if (isCacheFresh && _lastFetchTime != null) {
          final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
          Logger.i(
            _tag,
            'Cache is still fresh (${timeSinceLastFetch.inSeconds}s old), skipping load',
          );
          return;
        }
      }

      Logger.i(
        _tag,
        'Loading faculties with ratings (forceRefresh: $forceRefresh)',
      );

      // First, load faculties from local database immediately
      final faculties = await _facultyRepository.getFaculties();

      if (faculties.isEmpty) {
        Logger.w(_tag, 'No faculties found in local database');
        _emit(
          const FacultyRatingError(
            message: 'No faculties found',
            error: 'Make sure you have courses in your timetable',
          ),
        );
        return;
      }

      Logger.i(
        _tag,
        'Loaded ${faculties.length} faculties from local database',
      );

      // Try to load cached ratings first for immediate display
      final cachedRatingsMap = await _facultyRepository.refreshRatings([]);

      if (cachedRatingsMap.isNotEmpty) {
        Logger.i(_tag, 'Showing cached ratings immediately');
        final facultiesWithCachedRatings =
            faculties.map((faculty) {
              final cachedStats = cachedRatingsMap[faculty.facultyId];
              if (cachedStats != null) {
                return faculty.copyWith(ratingStats: cachedStats);
              }
              return faculty;
            }).toList();

        // Show cached data immediately
        _emit(
          FacultyRatingLoaded(
            faculties: facultiesWithCachedRatings,
            lastUpdated: DateTime.now(),
            isRefreshing: true, // Show that we're refreshing in background
          ),
        );
      } else if (_state is! FacultyRatingLoaded) {
        // No cache, show loading
        _emit(
          FacultyRatingLoaded(
            faculties: faculties,
            lastUpdated: DateTime.now(),
            isRefreshing: true,
          ),
        );
      } else {
        // We have cached state, show refresh indicator
        final currentState = _state as FacultyRatingLoaded;
        _emit(currentState.copyWith(isRefreshing: true));
      }

      // Then fetch fresh ratings in background
      final facultyIds = faculties.map((f) => f.facultyId).toList();
      final ratingsMap = await _facultyRepository.refreshRatings(facultyIds);

      // Update faculties with fresh ratings
      final updatedFaculties =
          faculties.map((faculty) {
            final updatedStats = ratingsMap[faculty.facultyId];
            if (updatedStats != null) {
              return faculty.copyWith(ratingStats: updatedStats);
            }
            return faculty;
          }).toList();

      _lastFetchTime = DateTime.now();

      Logger.i(_tag, 'Updated ${ratingsMap.length} faculties with ratings');
      _emit(
        FacultyRatingLoaded(
          faculties: updatedFaculties,
          lastUpdated: _lastFetchTime!,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      Logger.e(_tag, 'Error loading faculties', e);

      // If we already have cached data showing, keep it
      if (_state is FacultyRatingLoaded) {
        final currentState = _state as FacultyRatingLoaded;
        _emit(currentState.copyWith(isRefreshing: false));
        Logger.i(_tag, 'Keeping cached data due to error');
      } else {
        _emit(
          FacultyRatingError(
            message: 'Failed to load faculties',
            error: e.toString(),
          ),
        );
      }
    }
  }

  /// Refresh ratings for all faculties
  /// Always forces refresh regardless of cache time (used for pull-to-refresh)
  Future<void> refreshRatings({bool forceRefresh = true}) async {
    try {
      // Check if already disposed
      if (!hasListeners) {
        Logger.w(_tag, 'Bloc disposed, skipping refreshRatings');
        return;
      }

      if (_state is! FacultyRatingLoaded) return;

      final currentState = _state as FacultyRatingLoaded;

      // Check cache only if not forcing refresh
      if (!forceRefresh && _lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch < FacultyRatingConstants.cacheDuration) {
          Logger.i(
            _tag,
            'Skipping refresh - last fetch was ${timeSinceLastFetch.inSeconds}s ago',
          );
          return;
        }
      }

      Logger.i(
        _tag,
        'Refreshing ratings for all faculties (forceRefresh: $forceRefresh)',
      );

      // Keep showing current faculties while refreshing
      _emit(currentState.copyWith(isRefreshing: true));

      final facultyIds =
          currentState.faculties.map((f) => f.facultyId).toList();
      final ratingsMap = await _facultyRepository.refreshRatings(facultyIds);

      // Update faculties with new ratings
      final updatedFaculties =
          currentState.faculties.map((faculty) {
            final updatedStats = ratingsMap[faculty.facultyId];
            if (updatedStats != null) {
              return faculty.copyWith(ratingStats: updatedStats);
            }
            return faculty;
          }).toList();

      _lastFetchTime = DateTime.now();

      Logger.i(_tag, 'Ratings refreshed successfully');
      _emit(
        FacultyRatingLoaded(
          faculties: updatedFaculties,
          lastUpdated: _lastFetchTime!,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      Logger.e(_tag, 'Error refreshing ratings', e);

      // Keep current state but stop refreshing indicator
      if (_state is FacultyRatingLoaded) {
        final currentState = _state as FacultyRatingLoaded;
        _emit(currentState.copyWith(isRefreshing: false));
      }
    }
  }

  /// Refresh rating for a single faculty
  Future<void> refreshSingleFacultyRating(String facultyId) async {
    try {
      // Check if already disposed
      if (!hasListeners) {
        Logger.w(_tag, 'Bloc disposed, skipping refreshSingleFacultyRating');
        return;
      }

      if (_state is! FacultyRatingLoaded) return;

      final currentState = _state as FacultyRatingLoaded;
      Logger.i(_tag, 'Refreshing rating for faculty: $facultyId');

      // Show refreshing indicator for this faculty
      _emit(currentState.copyWith(refreshingFacultyId: facultyId));

      // Fetch updated rating
      final ratingsMap = await _facultyRepository.refreshRatings([facultyId]);
      final updatedStats = ratingsMap[facultyId];

      if (updatedStats != null) {
        // Find and update the faculty
        final updatedFaculties =
            currentState.faculties.map((faculty) {
              if (faculty.facultyId == facultyId) {
                return faculty.copyWith(ratingStats: updatedStats);
              }
              return faculty;
            }).toList();

        _emit(
          FacultyRatingLoaded(
            faculties: updatedFaculties,
            lastUpdated: DateTime.now(),
            isRefreshing: false,
          ),
        );

        Logger.i(_tag, 'Faculty rating refreshed successfully');
      } else {
        // Clear refreshing indicator
        _emit(currentState.copyWith(clearRefreshingId: true));
      }
    } catch (e) {
      Logger.e(_tag, 'Error refreshing faculty rating', e);

      // Clear refreshing indicator on error
      if (_state is FacultyRatingLoaded) {
        final currentState = _state as FacultyRatingLoaded;
        _emit(currentState.copyWith(clearRefreshingId: true));
      }
    }
  }

  /// Submit a rating
  Future<void> submitRating(RatingSubmission rating) async {
    try {
      // Check if already disposed
      if (!hasListeners) {
        Logger.w(_tag, 'Bloc disposed, skipping submitRating');
        return;
      }

      Logger.i(_tag, 'Submitting rating for faculty: ${rating.facultyId}');
      _emit(RatingSubmissionInProgress(rating.facultyId));

      final response = await _ratingRepository.submitRating(rating);

      if (response.success) {
        Logger.i(_tag, 'Rating submitted successfully');
        _emit(
          RatingSubmissionSuccess(
            message: response.message,
            facultyId: rating.facultyId,
          ),
        );

        // Refresh the specific faculty's rating after submission
        await refreshSingleFacultyRating(rating.facultyId);
      } else {
        Logger.w(_tag, 'Rating submission failed: ${response.message}');
        _emit(
          RatingSubmissionFailure(
            message: response.message,
            error: response.error,
          ),
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Error submitting rating', e);
      _emit(
        RatingSubmissionFailure(
          message: 'Failed to submit rating. Please try again.',
          error: e.toString(),
        ),
      );
    }
  }

  /// Check service availability
  Future<void> checkServiceAvailability() async {
    try {
      Logger.i(_tag, 'Checking service availability');

      final isAvailable = await _ratingRepository.isServiceAvailable();

      if (!isAvailable) {
        _emit(
          const ServiceUnavailable(
            'Faculty rating service is currently unavailable. Please try again later.',
          ),
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Error checking service availability', e);
    }
  }

  /// Check if data needs refresh
  bool get needsRefresh {
    if (_lastFetchTime == null) return true;
    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    return timeSinceLastFetch >= FacultyRatingConstants.cacheDuration;
  }
}
