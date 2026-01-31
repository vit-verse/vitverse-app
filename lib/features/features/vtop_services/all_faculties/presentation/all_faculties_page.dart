import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/faculty_repository.dart';
import '../models/faculty_model.dart';
import '../widgets/faculty_widgets.dart';

class AllFacultiesPage extends StatefulWidget {
  const AllFacultiesPage({super.key});

  @override
  State<AllFacultiesPage> createState() => _AllFacultiesPageState();
}

class _AllFacultiesPageState extends State<AllFacultiesPage> {
  static const String _tag = 'AllFaculties';
  final FacultyRepository _repository = FacultyRepository();
  final TextEditingController _searchController = TextEditingController();

  List<FacultyMember> _allFaculty = [];
  List<FacultyMember> _filteredFaculty = [];
  bool _isLoading = true;
  String? _selectedSchool;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AllFaculities',
      screenClass: 'AllFaculitiesPage',
    );
    _loadFacultyData();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFacultyData({bool forceRefresh = false}) async {
    final hasExistingData = _allFaculty.isNotEmpty;

    if (!hasExistingData) {
      setState(() => _isLoading = true);
    }

    try {
      final facultyList = await _repository.fetchFacultyData(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _allFaculty = facultyList;
          _filteredFaculty = facultyList;
          _isLoading = false;
        });
        _performSearch();
      }
    } catch (e) {
      Logger.e(_tag, 'Load failed', e);
      if (hasExistingData) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarUtils.info(context, 'Using cached data - refresh failed');
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarUtils.error(context, 'Failed to load faculty data');
        }
      }
    }
  }

  void _performSearch() {
    setState(() {
      _filteredFaculty = _repository.applyFilters(
        _allFaculty,
        searchQuery: _searchController.text,
        selectedSchool: _selectedSchool,
      );
    });
  }

  void _filterBySchool(String? school) {
    setState(() {
      _selectedSchool = school;
      _performSearch();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSchool = null;
      _searchController.clear();
      _performSearch();
    });
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to launch URL', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to open profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schools = _repository.getUniqueSchools(_allFaculty);
    final hasActiveFilters = _selectedSchool != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Faculty'),
            if (!_isLoading)
              Text(
                '${_filteredFaculty.length} of ${_allFaculty.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFacultyData(forceRefresh: true),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by ID or name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            if (_showFilters)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (hasActiveFilters)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (schools.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedSchool,
                        decoration: InputDecoration(
                          labelText: 'Department/School',
                          prefixIcon: const Icon(Icons.school, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Departments'),
                          ),
                          ...schools.map(
                            (school) => DropdownMenuItem<String>(
                              value: school,
                              child: Text(
                                school,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: _filterBySchool,
                      ),
                  ],
                ),
              ),

            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredFaculty.isEmpty
                      ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _allFaculty.isEmpty
                                        ? Icons.error_outline
                                        : Icons.search_off,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _allFaculty.isEmpty
                                        ? 'Failed to load faculty data'
                                        : _searchController.text.isEmpty
                                        ? 'No faculty members found'
                                        : 'No results for "${_searchController.text}"',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_allFaculty.isEmpty) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadFacultyData,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _filteredFaculty.length,
                        itemBuilder: (context, index) {
                          final faculty = _filteredFaculty[index];
                          return FacultyCard(
                            faculty: faculty,
                            onTap: () => _showFacultyDetails(faculty),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFacultyDetails(FacultyMember faculty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          child: Text(
                            faculty.getInitial(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          faculty.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          faculty.designation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FacultyDetailRow(
                        icon: Icons.badge,
                        label: 'Employee ID',
                        value: faculty.employeeId,
                      ),
                      FacultyDetailRow(
                        icon: Icons.school,
                        label: 'School',
                        value: faculty.school,
                      ),
                      if (faculty.cabin.isNotEmpty)
                        FacultyDetailRow(
                          icon: Icons.room,
                          label: 'Cabin',
                          value: faculty.cabin,
                        ),
                      const SizedBox(height: 24),
                      if (faculty.profileUrl.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchUrl(faculty.profileUrl),
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('View Profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }
}
