import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../models/faculty_with_rating.dart';
import '../models/faculty_rating_aggregate.dart';

/// Compact card for displaying faculty in All Faculties tab
class CompactFacultyCard extends StatelessWidget {
  final FacultyWithRating faculty;
  final FacultyRatingAggregate? aggregateRating;

  const CompactFacultyCard({
    super.key,
    required this.faculty,
    this.aggregateRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final hasRatings =
        aggregateRating != null && aggregateRating!.totalRatings > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.muted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name and Overall Rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.facultyName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (faculty.facultyId.isNotEmpty)
                      Text(
                        '(${faculty.facultyId})',
                        style: TextStyle(fontSize: 10, color: theme.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasRatings) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(
                      aggregateRating!.avgOverall,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: _getRatingColor(aggregateRating!.avgOverall),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aggregateRating!.avgOverall.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(aggregateRating!.avgOverall),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.muted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'No ratings',
                    style: TextStyle(fontSize: 11, color: theme.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Course Info - One course per line
          if (aggregateRating?.courses.isNotEmpty == true) ...[
            ...aggregateRating!.courses.take(3).map((c) {
              final code = c['code'] ?? '';
              final title = c['title'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.book_outlined, size: 12, color: theme.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$code - $title',
                        style: TextStyle(fontSize: 11, color: theme.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (aggregateRating!.courses.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '+${aggregateRating!.courses.length - 3} more',
                  style: TextStyle(fontSize: 10, color: theme.muted),
                ),
              ),
          ] else if (faculty.courses.isNotEmpty) ...[
            ...faculty.courses.take(3).map((course) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.book_outlined, size: 12, color: theme.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${course.code} - ${course.title}',
                        style: TextStyle(fontSize: 11, color: theme.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (faculty.courses.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '+${faculty.courses.length - 3} more',
                  style: TextStyle(fontSize: 10, color: theme.muted),
                ),
              ),
          ] else
            Row(
              children: [
                Icon(Icons.book_outlined, size: 12, color: theme.muted),
                const SizedBox(width: 4),
                Text(
                  'No courses',
                  style: TextStyle(fontSize: 11, color: theme.muted),
                ),
              ],
            ),

          if (hasRatings) ...[
            const SizedBox(height: 8),
            // Rating Details Row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMiniRating('T', aggregateRating!.avgTeaching, theme),
                _buildMiniRating(
                  'A',
                  aggregateRating!.avgAttendanceFlex,
                  theme,
                ),
                _buildMiniRating(
                  'S',
                  aggregateRating!.avgSupportiveness,
                  theme,
                ),
                _buildMiniRating('M', aggregateRating!.avgMarks, theme),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${aggregateRating!.totalRatings} ratings',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniRating(String label, double rating, dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.muted,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              color: _getRatingColor(rating),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.0) return Colors.green;
    if (rating >= 5.0) return Colors.orange;
    return Colors.red;
  }
}
