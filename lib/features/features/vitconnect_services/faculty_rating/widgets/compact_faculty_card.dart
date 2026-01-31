import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../models/faculty_with_rating.dart';
import '../models/faculty_rating_aggregate.dart';
import '../presentation/faculty_detail_page.dart';

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacultyDetailPage(faculty: faculty),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.muted.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.facultyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
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
                hasRatings ? _buildOverallRating(theme) : _buildNoRating(theme),
              ],
            ),

            const SizedBox(height: 8),

            // COURSES
            if (aggregateRating?.courses.isNotEmpty == true) ...[
              ...aggregateRating!.courses.take(3).map(_courseRow),
              if (aggregateRating!.courses.length > 3)
                _moreText(aggregateRating!.courses.length - 3, theme),
            ] else if (faculty.courses.isNotEmpty) ...[
              ...faculty.courses
                  .take(3)
                  .map((c) => _courseRow({'code': c.code, 'title': c.title})),
              if (faculty.courses.length > 3)
                _moreText(faculty.courses.length - 3, theme),
            ] else ...[
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
            ],

            if (hasRatings) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _mini('T', aggregateRating!.avgTeaching, theme),
                  _mini('A', aggregateRating!.avgAttendanceFlex, theme),
                  _mini('S', aggregateRating!.avgSupportiveness, theme),
                  _mini('M', aggregateRating!.avgMarks, theme),
                  _ratingCount(theme),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating(dynamic theme) {
    final rating = aggregateRating!.avgOverall;
    final color = _getRatingColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRating(dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'No ratings',
        style: TextStyle(fontSize: 11, color: theme.muted),
      ),
    );
  }

  Widget _courseRow(Map c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.book_outlined, size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${c['code']} - ${c['title']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreText(int count, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        '+$count more',
        style: TextStyle(fontSize: 10, color: theme.muted),
      ),
    );
  }

  Widget _mini(String label, double rating, dynamic theme) {
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

  Widget _ratingCount(dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.0) return Colors.green;
    if (rating >= 5.0) return Colors.orange;
    return Colors.red;
  }
}
