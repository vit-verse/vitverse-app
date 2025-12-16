import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/app_card_styles.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../models/faculty_model.dart';
import '../utils/rating_constants.dart';

/// Card widget to display faculty information with rating
class FacultyCard extends StatelessWidget {
  final Faculty faculty;
  final VoidCallback onRatePressed;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  const FacultyCard({
    super.key,
    required this.faculty,
    required this.onRatePressed,
    this.isRefreshing = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: FacultyRatingConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          FacultyRatingConstants.cardBorderRadius,
        ),
      ),
      child: InkWell(
        onTap: onRatePressed,
        borderRadius: BorderRadius.circular(
          FacultyRatingConstants.cardBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faculty name and ERP
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faculty.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          faculty.facultyId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  if (faculty.ratingStats != null &&
                      faculty.ratingStats!.hasRatings)
                    _buildRatingBadge(context, faculty.ratingStats!),
                ],
              ),

              const SizedBox(height: 12),

              // Courses
              _buildCoursesSection(context),

              const SizedBox(height: 12),

              // Rating stats or Rate button
              if (faculty.ratingStats != null &&
                  faculty.ratingStats!.hasRatings)
                _buildRatingStats(context)
              else
                _buildNoRatingSection(context),

              const SizedBox(height: 8),

              // Rate button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isRefreshing ? null : onRatePressed,
                  icon: const Icon(Icons.star_outline, size: 20),
                  label: const Text('Rate Faculty'),
                  style: OutlinedButton.styleFrom(
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

  Widget _buildRatingBadge(BuildContext context, FacultyRatingStats stats) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    Color badgeColor;
    if (stats.overallRating >= 8.0) {
      badgeColor = Colors.green;
    } else if (stats.overallRating >= 6.0) {
      badgeColor = Colors.blue;
    } else if (stats.overallRating >= 4.0) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppCardStyles.smallWidgetDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: badgeColor.withOpacity(0.1),
      ),
      child: Text(
        stats.overallRating.toStringAsFixed(1),
        style: theme.textTheme.titleSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCoursesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Courses (${faculty.courseTitles.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...faculty.courseTitles.take(2).map((course) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
        if (faculty.courseTitles.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              '+${faculty.courseTitles.length - 2} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = faculty.ratingStats!;

    if (isRefreshing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppCardStyles.infoBoxDecoration(
        isDark: Provider.of<ThemeProvider>(context).currentTheme.isDark,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                Icons.school,
                'Teaching',
                stats.teachingRating,
              ),
              _buildStatItem(
                context,
                Icons.calendar_today,
                'Attendance',
                stats.attendanceFlexRating,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                Icons.support_agent,
                'Support',
                stats.supportivenessRating,
              ),
              _buildStatItem(
                context,
                Icons.assessment,
                'Marks',
                stats.marksRating,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${stats.totalRatings} rating${stats.totalRatings != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    double rating,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoRatingSection(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppCardStyles.infoBoxDecoration(
        isDark: themeProvider.currentTheme.isDark,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'No ratings yet. Be the first to rate!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
