import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/faculty_with_rating.dart';
import '../models/student_faculty_rating.dart';
import '../data/faculty_rating_repository.dart';
import 'package:intl/intl.dart';

/// Faculty Detail Page - Shows all ratings, courses, and reviews
class FacultyDetailPage extends StatefulWidget {
  final FacultyWithRating faculty;

  const FacultyDetailPage({super.key, required this.faculty});

  @override
  State<FacultyDetailPage> createState() => _FacultyDetailPageState();
}

class _FacultyDetailPageState extends State<FacultyDetailPage> {
  static const String _tag = 'FacultyDetailPage';

  List<StudentFacultyRating> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = FacultyRatingRepository();
      await repository.initialize();

      final reviews = await repository.getFacultyReviews(
        facultyId: widget.faculty.facultyId,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }

      Logger.d(_tag, 'Loaded ${reviews.length} reviews');
    } catch (e, stack) {
      Logger.e(_tag, 'Error loading reviews', e, stack);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reviews';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final hasRatings =
        widget.faculty.ratingData != null &&
        widget.faculty.ratingData!.totalRatings > 0;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Faculty Details',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Faculty Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.faculty.facultyName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.faculty.facultyId}',
                      style: TextStyle(fontSize: 12, color: theme.muted),
                    ),
                    if (hasRatings) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            widget.faculty.ratingData!.avgOverall
                                .toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/10',
                            style: TextStyle(fontSize: 16, color: theme.muted),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.faculty.ratingData!.totalRatings} ratings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.muted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No ratings yet',
                          style: TextStyle(fontSize: 12, color: theme.muted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (hasRatings) ...[
                const SizedBox(height: 16),

                // Rating Breakdown
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRatingItem(
                              'Teaching',
                              widget.faculty.ratingData!.avgTeaching,
                              Icons.school,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRatingItem(
                              'Attendance',
                              widget.faculty.ratingData!.avgAttendanceFlex,
                              Icons.event_available,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRatingItem(
                              'Support',
                              widget.faculty.ratingData!.avgSupportiveness,
                              Icons.support_agent,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRatingItem(
                              'Marks',
                              widget.faculty.ratingData!.avgMarks,
                              Icons.grade,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Courses Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, size: 18, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Courses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.faculty.courses.isNotEmpty)
                      ...widget.faculty.courses.map((course) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: theme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${course.code} - ${course.title}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else if (widget.faculty.ratingData?.courses.isNotEmpty ==
                        true)
                      ...widget.faculty.ratingData!.courses.map((course) {
                        final code = course['code'] ?? '';
                        final title = course['title'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: theme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$code - $title',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      Text(
                        'No courses listed',
                        style: TextStyle(fontSize: 13, color: theme.muted),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reviews Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, size: 18, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Review Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                        const Spacer(),
                        if (!_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_reviews.where((r) => r.review != null && r.review!.isNotEmpty).length} comments',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.error),
                          ),
                        ),
                      )
                    else if (_reviews
                        .where((r) => r.review != null && r.review!.isNotEmpty)
                        .isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No review comments yet',
                            style: TextStyle(fontSize: 13, color: theme.muted),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            _reviews
                                .where(
                                  (r) =>
                                      r.review != null && r.review!.isNotEmpty,
                                )
                                .length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 24,
                              color: theme.muted.withValues(alpha: 0.2),
                            ),
                        itemBuilder: (context, index) {
                          final reviewsWithComments =
                              _reviews
                                  .where(
                                    (r) =>
                                        r.review != null &&
                                        r.review!.isNotEmpty,
                                  )
                                  .toList();
                          final review = reviewsWithComments[index];
                          return _buildReviewCard(review, theme);
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(StudentFacultyRating review, theme) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Review Text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
          ),
          child: Text(
            review.review!,
            style: TextStyle(fontSize: 14, color: theme.text, height: 1.4),
          ),
        ),

        const SizedBox(height: 8),

        // Reviewer Info and Date
        Row(
          children: [
            Icon(Icons.person, size: 14, color: theme.muted),
            const SizedBox(width: 6),
            Text(
              review.studentName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.muted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${review.studentRegno})',
              style: TextStyle(fontSize: 11, color: theme.muted),
            ),
            const Spacer(),
            Text(
              dateFormatter.format(review.submittedAt),
              style: TextStyle(fontSize: 11, color: theme.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingItem(
    String label,
    double rating,
    IconData icon,
    dynamic theme,
  ) {
    final color = _getRatingColor(rating);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
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
