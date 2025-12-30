import 'package:flutter/material.dart';
import '../models/faculty_with_rating.dart';

/// Faculty card widget displaying rating information
class FacultyRatingCard extends StatelessWidget {
  final FacultyWithRating faculty;
  final VoidCallback onTap;

  const FacultyRatingCard({
    super.key,
    required this.faculty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRating = faculty.hasRatings;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faculty name and rating badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faculty.facultyName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          faculty.facultyId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRating) _buildRatingBadge(theme),
                ],
              ),

              const SizedBox(height: 12),

              // Courses
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    faculty.courseTitles.take(2).map((course) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
              ),

              if (hasRating) ...[
                const SizedBox(height: 12),
                _buildRatingStats(theme),
              ],

              const SizedBox(height: 8),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(hasRating ? 'Update Rating' : 'Submit Rating'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(ThemeData theme) {
    final rating = faculty.ratingData!;
    final color = _getRatingColor(rating.avgOverall);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            rating.avgOverall.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStats(ThemeData theme) {
    final rating = faculty.ratingData!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Teaching', rating.avgTeaching, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'Attendance',
                  rating.avgAttendanceFlex,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Support',
                  rating.avgSupportiveness,
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('Marks', rating.avgMarks, theme)),
            ],
          ),
          const SizedBox(height: 6),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 6),
          Text(
            'Based on ${rating.totalRatings} rating${rating.totalRatings == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value.toStringAsFixed(1),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _getRatingColor(value),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green.shade700;
    if (rating >= 6.0) return Colors.blue.shade700;
    if (rating >= 4.0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
