import 'package:flutter/material.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/faculty_data_provider.dart';
import '../models/faculty_with_courses.dart';
import '../widgets/faculty_course_widgets.dart';

class MyCourseFacultiesPage extends StatefulWidget {
  const MyCourseFacultiesPage({super.key});

  @override
  State<MyCourseFacultiesPage> createState() => _MyCourseFacultiesPageState();
}

class _MyCourseFacultiesPageState extends State<MyCourseFacultiesPage> {
  static const String _tag = 'CourseFaculties';
  final FacultyDataProvider _dataProvider = FacultyDataProvider();

  List<FacultyWithCourses> _faculties = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'MyCourseFaculities',
      screenClass: 'MyCourseFaculitiesPage'
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final faculties = await _dataProvider.getFacultiesWithCourses();
      final stats = await _dataProvider.getFacultyStatistics();

      if (mounted) {
        setState(() {
          _faculties = faculties;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to load data', e);
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.error(context, 'Failed to load faculty data');
      }
    }
  }

  List<FacultyWithCourses> get _filteredFaculties {
    if (_searchQuery.isEmpty) return _faculties;

    return _faculties.where((faculty) {
      final nameMatch = faculty.facultyName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final courseMatch = faculty.courses.any((course) {
        final codeMatch =
            course.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false;
        final titleMatch =
            course.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false;
        return codeMatch || titleMatch;
      });
      return nameMatch || courseMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Course Faculties'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _faculties.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Faculties Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No course faculty information available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredFaculties = _filteredFaculties;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          if (_statistics != null)
            FacultyStatisticsCard(statistics: _statistics!),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search faculty or course...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                        : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child:
                filteredFaculties.isEmpty
                    ? _buildNoSearchResults()
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: filteredFaculties.length,
                      itemBuilder: (context, index) {
                        return FacultyExpansionCard(
                          faculty: filteredFaculties[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
