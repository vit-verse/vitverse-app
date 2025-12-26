import 'package:flutter/foundation.dart';
import '../../../../../core/utils/logger.dart';
import '../data/pyq_api.dart';
import '../data/pyq_models.dart';

/// PYQ Controller - manages state and business logic for PYQ feature
class PyqController extends ChangeNotifier {
  static const _tag = 'PyqController';

  // Loading states
  bool _isLoadingGlobal = false;
  bool _isLoadingCourse = false;

  // Data
  GlobalPyqMeta? _globalMeta;
  final Map<String, List<PyqPaper>> _coursePapersCache = {};
  String? _selectedCourse;
  List<PyqPaper> _currentPapers = [];

  // Error states
  String? _globalError;
  String? _courseError;
  String? _uploadError;

  // Search
  String _searchQuery = '';
  List<MapEntry<String, String>> _filteredCourses = [];

  // Getters
  bool get isLoadingGlobal => _isLoadingGlobal;
  bool get isLoadingCourse => _isLoadingCourse;
  GlobalPyqMeta? get globalMeta => _globalMeta;
  String? get selectedCourse => _selectedCourse;
  List<PyqPaper> get currentPapers => _currentPapers;
  String? get globalError => _globalError;
  String? get courseError => _courseError;
  String? get uploadError => _uploadError;
  String get searchQuery => _searchQuery;
  List<MapEntry<String, String>> get filteredCourses => _filteredCourses;
  int get totalCourses => _globalMeta?.totalCourses ?? 0;
  int get totalPapers => _globalMeta?.totalPapers ?? 0;
  bool get hasGlobalData => _globalMeta != null;

  /// Load global metadata
  Future<void> loadGlobal() async {
    try {
      _isLoadingGlobal = true;
      _globalError = null;
      notifyListeners();

      _globalMeta = null;
      _coursePapersCache.clear();

      _globalMeta = await PyqApi.fetchGlobal();
      _filteredCourses = _globalMeta!.courses.entries.toList();

      Logger.i(_tag, 'Global metadata loaded successfully');
      _isLoadingGlobal = false;
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load global metadata', e, stackTrace);
      _globalError = 'Failed to load courses. Please try again.';
      _isLoadingGlobal = false;
      notifyListeners();
    }
  }

  /// Load papers for a specific course
  Future<void> loadCourse(String courseCode) async {
    try {
      _isLoadingCourse = true;
      _courseError = null;
      _selectedCourse = courseCode;
      notifyListeners();

      if (_coursePapersCache.containsKey(courseCode)) {
        _currentPapers = _coursePapersCache[courseCode]!;
      } else {
        final papers = await PyqApi.fetchCoursePapers(courseCode);
        _coursePapersCache[courseCode] = papers;
        _currentPapers = papers;
        Logger.i(_tag, 'Loaded ${papers.length} papers for $courseCode');
      }

      _isLoadingCourse = false;
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load course papers', e, stackTrace);
      _courseError = 'Failed to load papers. Please try again.';
      _currentPapers = [];
      _isLoadingCourse = false;
      notifyListeners();
    }
  }

  /// Search courses by code or title
  void searchCourses(String query) {
    _searchQuery = query.trim().toUpperCase();

    if (_searchQuery.isEmpty) {
      _filteredCourses = _globalMeta?.courses.entries.toList() ?? [];
    } else {
      _filteredCourses =
          (_globalMeta?.courses.entries ?? [])
              .where(
                (entry) =>
                    entry.key.toUpperCase().contains(_searchQuery) ||
                    entry.value.toUpperCase().contains(_searchQuery),
              )
              .toList();
    }

    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredCourses = _globalMeta?.courses.entries.toList() ?? [];
    notifyListeners();
  }

  /// Get paper count for a course
  int getPaperCount(String courseCode) {
    if (_coursePapersCache.containsKey(courseCode)) {
      return _coursePapersCache[courseCode]!.length;
    }
    return 0;
  }

  /// Get exams for current course
  List<String> getCurrentExams() {
    final examSet = <String>{};
    for (var paper in _currentPapers) {
      examSet.add(paper.exam);
    }
    return examSet.toList()..sort();
  }

  /// Get papers by exam type
  List<PyqPaper> getPapersByExam(String examType) {
    return _currentPapers.where((p) => p.exam == examType).toList();
  }

  /// Reset selected course
  void resetCourse() {
    _selectedCourse = null;
    _currentPapers = [];
    _courseError = null;
    notifyListeners();
  }

  /// Clear all cache
  void clearCache() {
    _coursePapersCache.clear();
    Logger.i(_tag, 'Cache cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
