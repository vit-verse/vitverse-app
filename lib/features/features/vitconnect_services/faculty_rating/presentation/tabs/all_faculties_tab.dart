import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../logic/faculty_rating_provider.dart';
import '../../widgets/compact_faculty_card.dart';

enum SortOption { highestRating, lowestRating, mostRated, leastRated }

enum SortAttribute { overall, knowledge, teaching, approachability, grading }

/// Tab for viewing all faculties with ratings
class AllFacultiesTab extends StatefulWidget {
  const AllFacultiesTab({super.key});

  @override
  State<AllFacultiesTab> createState() => _AllFacultiesTabState();
}

class _AllFacultiesTabState extends State<AllFacultiesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _searchQuery = '';
  SortOption _sortOption = SortOption.highestRating;
  SortAttribute _sortAttribute = SortAttribute.overall;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load all faculties from Supabase when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FacultyRatingProvider>().loadAllFaculties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredAndSortedFaculties(FacultyRatingProvider provider) {
    var faculties =
        provider.allFaculties.where((f) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          // Search by faculty name, faculty ID, course code, or course title
          return f.facultyName.toLowerCase().contains(query) ||
              f.facultyId.toLowerCase().contains(query) ||
              f.courses.any(
                (c) =>
                    (c.code.toLowerCase().contains(query) ||
                        c.title.toLowerCase().contains(query)),
              );
        }).toList();

    // Get rating value based on selected attribute
    double getRatingValue(dynamic fw) {
      if (fw.ratingData == null) return 0.0;
      switch (_sortAttribute) {
        case SortAttribute.overall:
          return fw.ratingData!.avgOverall;
        case SortAttribute.knowledge:
          return fw.ratingData!.avgTeaching;
        case SortAttribute.teaching:
          return fw.ratingData!.avgTeaching;
        case SortAttribute.approachability:
          return fw.ratingData!.avgSupportiveness;
        case SortAttribute.grading:
          return fw.ratingData!.avgMarks;
      }
    }

    // Sort based on selected option
    switch (_sortOption) {
      case SortOption.highestRating:
        faculties.sort(
          (a, b) => getRatingValue(b).compareTo(getRatingValue(a)),
        );
        break;
      case SortOption.lowestRating:
        faculties.sort(
          (a, b) => getRatingValue(a).compareTo(getRatingValue(b)),
        );
        break;
      case SortOption.mostRated:
        faculties.sort((a, b) {
          final aCount = a.ratingData?.totalRatings ?? 0;
          final bCount = b.ratingData?.totalRatings ?? 0;
          return bCount.compareTo(aCount);
        });
        break;
      case SortOption.leastRated:
        faculties.sort((a, b) {
          final aCount = a.ratingData?.totalRatings ?? 0;
          final bCount = b.ratingData?.totalRatings ?? 0;
          return aCount.compareTo(bCount);
        });
        break;
    }

    return faculties;
  }

  int _getTotalRatings(FacultyRatingProvider provider) {
    return provider.allFaculties.fold<int>(
      0,
      (sum, fw) => sum + (fw.ratingData?.totalRatings ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>().currentTheme;
    final provider = context.watch<FacultyRatingProvider>();

    final filteredFaculties = _getFilteredAndSortedFaculties(provider);
    final totalFaculties = provider.allFaculties.length;
    final totalRatings = _getTotalRatings(provider);

    return Stack(
      children: [
        Column(
          children: [
            // Compact Search and Sort Row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: theme.muted, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: theme.text, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Search by name, ID, or course...',
                                hintStyle: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onChanged:
                                  (value) =>
                                      setState(() => _searchQuery = value),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.clear,
                                color: theme.muted,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sort By Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.muted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: DropdownButton<SortOption>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _sortOption,
                          isDense: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: theme.muted,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: SortOption.highestRating,
                              child: Text(
                                'Highest',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortOption.lowestRating,
                              child: Text(
                                'Lowest',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortOption.mostRated,
                              child: Text(
                                'Most Rated',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortOption.leastRated,
                              child: Text(
                                'Least Rated',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) => setState(() => _sortOption = value!),
                          style: TextStyle(fontSize: 10, color: theme.text),
                          dropdownColor: theme.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Attribute Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.muted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: DropdownButton<SortAttribute>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _sortAttribute,
                          isDense: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: theme.muted,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: SortAttribute.overall,
                              child: Text(
                                'Overall',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortAttribute.teaching,
                              child: Text(
                                'Teaching',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortAttribute.approachability,
                              child: Text(
                                'Support',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            DropdownMenuItem(
                              value: SortAttribute.grading,
                              child: Text(
                                'Marks',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) =>
                                  setState(() => _sortAttribute = value!),
                          style: TextStyle(fontSize: 10, color: theme.text),
                          dropdownColor: theme.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Compact Stats Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 12, color: theme.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Total: $totalFaculties faculties • $totalRatings ratings',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Faculty List
            Expanded(
              child:
                  provider.isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: theme.primary),
                      )
                      : filteredFaculties.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.muted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No faculties found'
                                  : 'No results for "$_searchQuery"',
                              style: TextStyle(color: theme.muted),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadAllFaculties();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                          itemCount: filteredFaculties.length,
                          itemBuilder: (context, index) {
                            final fw = filteredFaculties[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: CompactFacultyCard(
                                faculty: fw,
                                aggregateRating: fw.ratingData,
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
        // Floating Legend Bar
        Positioned(
          bottom: 8,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('T', 'Teaching', theme),
                _buildDivider(theme),
                _buildLegendItem('A', 'Attendance', theme),
                _buildDivider(theme),
                _buildLegendItem('S', 'Supportiveness', theme),
                _buildDivider(theme),
                _buildLegendItem('M', 'Marks', theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String letter, String label, dynamic theme) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(dynamic theme) {
    return Container(
      width: 1,
      height: 16,
      color: theme.muted.withValues(alpha: 0.3),
    );
  }
}
