import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/database/daos/course_dao.dart';
import '../controller/pyq_controller.dart';
import 'course_detail_page.dart';

/// Search Papers Page - shows all available courses with papers
class SearchPapersPage extends StatefulWidget {
  const SearchPapersPage({super.key});

  @override
  State<SearchPapersPage> createState() => _SearchPapersPageState();
}

class _SearchPapersPageState extends State<SearchPapersPage> {
  static const _tag = 'SearchPapersPage';
  final TextEditingController _searchController = TextEditingController();
  final CourseDao _courseDao = CourseDao();
  String _searchQuery = '';
  bool _showMyCoursesOnly = false;
  List<String> _userCourseCodes = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoadingCourses = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _updateFilteredCourses();
    });
    _loadUserCourses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PyqController>(context, listen: false);
      if (!controller.hasGlobalData) {
        controller.loadGlobal().then((_) => _updateFilteredCourses());
      } else {
        _updateFilteredCourses();
      }
    });
  }

  Future<void> _loadUserCourses() async {
    try {
      final courses = await _courseDao.getAllCourses();
      setState(() {
        _userCourseCodes =
            courses
                .map((c) => c['code']?.toString() ?? '')
                .where((code) => code.isNotEmpty)
                .toList();
      });
      _updateFilteredCourses();
    } catch (e) {
      Logger.e(_tag, 'Failed to load user courses', e);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateFilteredCourses() async {
    final controller = Provider.of<PyqController>(context, listen: false);
    if (controller.globalMeta == null) {
      setState(() {
        _filteredCourses = [];
        _isLoadingCourses = false;
      });
      return;
    }

    setState(() => _isLoadingCourses = true);

    try {
      // Fetch all courses from local DB
      final allCourses = await _courseDao.getAllCourses();

      // Build course list with metadata
      List<Map<String, dynamic>> courseList = [];

      // Get courses from GitHub metadata (now a Map<String, String>)
      final coursesMap = controller.globalMeta!.courses;

      for (final entry in coursesMap.entries) {
        final courseCode = entry.key;
        final courseTitle = entry.value;

        // Find matching course in local DB to check if user is enrolled
        final dbCourse = allCourses.firstWhere(
          (c) => c['code']?.toString() == courseCode,
          orElse: () => {},
        );

        final isEnrolled = dbCourse.isNotEmpty;

        // Add to list based on filter
        if (!_showMyCoursesOnly || isEnrolled) {
          courseList.add({
            'course_code': courseCode,
            'course_title': courseTitle,
            'paper_count': 1, // Will be fetched when user clicks the card
          });
        }
      }

      // Add enrolled courses with 0 papers when "My Courses" is selected
      if (_showMyCoursesOnly) {
        for (final dbCourse in allCourses) {
          final courseCode = dbCourse['code']?.toString() ?? '';
          if (courseCode.isNotEmpty &&
              !courseList.any((c) => c['course_code'] == courseCode)) {
            courseList.add({
              'course_code': courseCode,
              'course_title': dbCourse['title'] ?? courseCode,
              'paper_count': 0,
            });
          }
        }
      }

      // Filter by search query
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        courseList =
            courseList.where((course) {
              final code =
                  (course['course_code']?.toString() ?? '').toLowerCase();
              final title =
                  (course['course_title']?.toString() ?? '').toLowerCase();
              return code.contains(searchQuery) || title.contains(searchQuery);
            }).toList();
      }

      setState(() {
        _filteredCourses = courseList;
        _isLoadingCourses = false;
      });
    } catch (e) {
      Logger.e(_tag, 'Error building course list', e);
      setState(() {
        _filteredCourses = [];
        _isLoadingCourses = false;
      });
    }
  }

  void _openCourseDetail(String code, String title, int paperCount) {
    final controller = Provider.of<PyqController>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: controller,
              child: CourseDetailPage(
                courseCode: code,
                courseTitle: title,
                totalPapers: paperCount,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Consumer<PyqController>(
      builder: (context, controller, _) {
        if (controller.isLoadingGlobal) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }

        if (controller.globalError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.error),
                const SizedBox(height: 16),
                Text(
                  controller.globalError!,
                  style: TextStyle(color: theme.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadGlobal,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredCourses = _filteredCourses;
        final isLoading = _isLoadingCourses;

        return Column(
          children: [
            // Statistics and Toggle Row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  // Statistics
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: AppCardStyles.compactCardDecoration(
                        isDark: theme.isDark,
                        customBackgroundColor: theme.surface,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${controller.totalCourses} courses',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${controller.totalPapers} papers',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Toggle
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton('All', !_showMyCoursesOnly, () {
                          setState(() => _showMyCoursesOnly = false);
                          _updateFilteredCourses();
                        }, theme),
                        _buildToggleButton(
                          'My Courses',
                          _showMyCoursesOnly,
                          () {
                            setState(() => _showMyCoursesOnly = true);
                            _updateFilteredCourses();
                          },
                          theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by code or title...',
                    hintStyle: TextStyle(color: theme.muted, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: theme.muted,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: theme.muted,
                              ),
                              onPressed: _searchController.clear,
                              padding: EdgeInsets.zero,
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ),

            // Course List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final controller = Provider.of<PyqController>(
                    context,
                    listen: false,
                  );
                  await controller.loadGlobal();
                  await _updateFilteredCourses();
                },
                child:
                    filteredCourses.isEmpty
                        ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _showMyCoursesOnly
                                        ? Icons.school_outlined
                                        : Icons.search_off,
                                    size: 48,
                                    color: theme.muted,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _showMyCoursesOnly
                                        ? 'You are not enrolled in any courses'
                                        : _searchQuery.isNotEmpty
                                        ? 'No courses found'
                                        : 'No courses available',
                                    style: TextStyle(
                                      color: theme.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return _buildCourseCard(course, theme);
                          },
                        ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    dynamic theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : theme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(dynamic course, dynamic theme) {
    try {
      // Defensive type checking
      if (course is! Map<String, dynamic>) {
        Logger.w(_tag, 'Invalid course data type: ${course.runtimeType}');
        return const SizedBox.shrink();
      }

      final courseMap = course;
      final code = courseMap['course_code']?.toString() ?? '';
      final title = courseMap['course_title']?.toString() ?? 'Unknown';
      final paperCount = (courseMap['paper_count'] as num?)?.toInt() ?? 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _openCourseDetail(code, title, paperCount),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AppCardStyles.compactCardDecoration(
              isDark: theme.isDark,
              customBackgroundColor: theme.surface,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: theme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(color: theme.muted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 12,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paperCount.toString(),
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: theme.muted, size: 18),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error building course card', e, stackTrace);
      return const SizedBox.shrink();
    }
  }
}
