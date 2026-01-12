import 'package:flutter/foundation.dart';
import '../../../../../core/utils/logger.dart';
import '../../../vtop_services/my_course_faculties/data/faculty_data_provider.dart';
import '../models/faculty_with_rating.dart';
import '../models/faculty_rating_aggregate.dart';
import '../models/student_faculty_rating.dart';
import '../data/faculty_rating_repository.dart';

/// Faculty Rating provider
/// State management for Faculty Rating feature
class FacultyRatingProvider extends ChangeNotifier {
  static const String _tag = 'FacultyRatingProvider';

  final _repository = FacultyRatingRepository();
  final _facultyDataProvider = FacultyDataProvider();

  List<FacultyWithRating> _faculties = [];
  List<FacultyWithRating> _allFaculties = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastSyncTime;

  List<FacultyWithRating> get faculties => _faculties;
  List<FacultyWithRating> get allFaculties => _allFaculties;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize provider
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// Load faculties with ratings
  Future<void> loadFaculties() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      Logger.d(_tag, 'Loading faculties from local database');

      // Get faculties from local database (from VTOP courses)
      final facultiesWithCourses =
          await _facultyDataProvider.getFacultiesWithCourses();

      if (facultiesWithCourses.isEmpty) {
        Logger.w(_tag, 'No faculties found in local database');
        _faculties = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Extract faculty IDs (use hash if ERP ID not available)
      final facultyIds =
          facultiesWithCourses.map((f) {
            if (f.facultyErpId != null && f.facultyErpId!.isNotEmpty) {
              return f.facultyErpId!;
            }
            return f.facultyName.hashCode.abs().toString();
          }).toList();
      Logger.d(_tag, 'Found ${facultyIds.length} faculties');

      // Fetch ratings from Supabase (cache-first)
      final ratings = await _repository.getRatings(facultyIds);

      // Create map for quick lookup
      final ratingsMap = <String, FacultyRatingAggregate>{};
      for (final rating in ratings) {
        ratingsMap[rating.facultyId] = rating;
      }

      // Combine faculty info with ratings
      _faculties =
          facultiesWithCourses.map((faculty) {
            // Use hash of name as ID if ERP ID is not available
            final facultyId =
                (faculty.facultyErpId == null || faculty.facultyErpId!.isEmpty)
                    ? faculty.facultyName.hashCode.abs().toString()
                    : faculty.facultyErpId!;

            return FacultyWithRating(
              facultyId: facultyId,
              facultyName: faculty.facultyName,
              courseTitles: faculty.courses.map((c) => c.title ?? '').toList(),
              courses:
                  faculty.courses
                      .map(
                        (c) => SimpleCourseInfo(
                          code: c.code ?? '',
                          title: c.title ?? '',
                        ),
                      )
                      .toList(),
              ratingData: ratingsMap[facultyId],
            );
          }).toList();

      Logger.success(
        _tag,
        'Loaded ${_faculties.length} faculties (${ratingsMap.length} with ratings)',
      );

      _lastSyncTime = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      Logger.e(_tag, 'Error loading faculties', e, stack);
      _errorMessage = 'Failed to load faculties';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh ratings
  Future<void> refresh() async {
    try {
      if (_faculties.isEmpty) {
        await loadFaculties();
        return;
      }

      _isSyncing = true;
      notifyListeners();

      Logger.d(_tag, 'Refreshing ratings');

      final facultyIds = _faculties.map((f) => f.facultyId).toList();
      final ratings = await _repository.forceRefresh(facultyIds);

      // Update ratings
      final ratingsMap = <String, FacultyRatingAggregate>{};
      for (final rating in ratings) {
        ratingsMap[rating.facultyId] = rating;
      }

      _faculties =
          _faculties.map((faculty) {
            return faculty.copyWith(ratingData: ratingsMap[faculty.facultyId]);
          }).toList();

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      Logger.success(_tag, 'Ratings refreshed');
      notifyListeners();
    } catch (e, stack) {
      Logger.e(_tag, 'Error refreshing ratings', e, stack);
      _errorMessage = 'Failed to refresh ratings';
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Submit rating
  Future<bool> submitRating({
    required String studentRegno,
    required String facultyId,
    required String facultyName,
    required double teaching,
    required double attendanceFlex,
    required double supportiveness,
    required double marks,
    List<CourseInfo> courses = const [],
  }) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      Logger.d(_tag, 'Submitting rating for faculty: $facultyId');

      await _repository.submitRating(
        studentRegno: studentRegno,
        facultyId: facultyId,
        facultyName: facultyName,
        teaching: teaching,
        attendanceFlex: attendanceFlex,
        supportiveness: supportiveness,
        marks: marks,
        courses: courses,
      );

      _isSubmitting = false;
      notifyListeners();

      Logger.success(_tag, 'Rating submitted successfully');
      return true;
    } catch (e, stack) {
      Logger.e(_tag, 'Error submitting rating', e, stack);
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Get faculty by ID
  FacultyWithRating? getFacultyById(String facultyId) {
    try {
      return _faculties.firstWhere((f) => f.facultyId == facultyId);
    } catch (e) {
      return null;
    }
  }

  /// Load all faculties from Supabase
  Future<void> loadAllFaculties() async {
    try {
      Logger.d(_tag, 'Loading all faculties from Supabase');

      final ratings = await _repository.getAllFacultyRatings();

      _allFaculties =
          ratings.map((rating) {
            return FacultyWithRating(
              facultyId: rating.facultyId,
              facultyName: rating.facultyName,
              courseTitles: [], // No course info in aggregates table
              courses:
                  rating.courses
                      .map(
                        (c) => SimpleCourseInfo(
                          code: c['code'] ?? '',
                          title: c['title'] ?? '',
                        ),
                      )
                      .toList(),
              ratingData: rating,
            );
          }).toList();

      Logger.success(_tag, 'Loaded ${_allFaculties.length} all faculties');

      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e, stack) {
      Logger.e(_tag, 'Error loading all faculties', e, stack);
      _errorMessage = 'Failed to load all faculties';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    Logger.d(_tag, 'Disposing provider');
    super.dispose();
  }
}
