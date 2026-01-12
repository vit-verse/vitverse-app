import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/database/entities/student_profile.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../logic/faculty_rating_provider.dart';
import '../../widgets/faculty_rating_card.dart';
import '../../widgets/faculty_rating_empty_state.dart';
import '../rate_faculty_page.dart';

/// Tab for rating your own faculties
class RateFacultyTab extends StatefulWidget {
  final StudentProfile profile;

  const RateFacultyTab({super.key, required this.profile});

  @override
  State<RateFacultyTab> createState() => _RateFacultyTabState();
}

class _RateFacultyTabState extends State<RateFacultyTab>
    with AutomaticKeepAliveClientMixin {
  static const String _tag = 'RateFacultyTab';

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    final provider = context.read<FacultyRatingProvider>();
    await provider.refresh();
  }

  void _navigateToRatePage(String facultyId) async {
    final provider = context.read<FacultyRatingProvider>();

    try {
      // Find faculty in the list
      final faculty = provider.faculties.firstWhere(
        (f) => f.facultyId == facultyId,
      );

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder:
              (newContext) => ChangeNotifierProvider.value(
                value: provider,
                child: RateFacultyPage(
                  facultyId: faculty.facultyId,
                  studentProfile: widget.profile,
                ),
              ),
        ),
      );

      if (result == true && mounted) {
        await provider.loadFaculties();
      }
    } catch (e) {
      Logger.e(_tag, 'Error navigating to rate page', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Faculty not found');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>().currentTheme;
    final provider = context.watch<FacultyRatingProvider>();

    if (provider.isLoading && provider.faculties.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: theme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.faculties.isEmpty) {
      return const FacultyRatingEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: theme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.faculties.length,
        itemBuilder: (context, index) {
          final facultyWithRating = provider.faculties[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FacultyRatingCard(
              faculty: facultyWithRating,
              onTap: () => _navigateToRatePage(facultyWithRating.facultyId),
            ),
          );
        },
      ),
    );
  }
}
