import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../logic/faculty_rating_provider.dart';
import '../data/faculty_rating_repository.dart';
import '../widgets/rating_slider.dart';

/// Rate Faculty page
class RateFacultyPage extends StatefulWidget {
  final String facultyId;
  final StudentProfile studentProfile;

  const RateFacultyPage({
    super.key,
    required this.facultyId,
    required this.studentProfile,
  });

  @override
  State<RateFacultyPage> createState() => _RateFacultyPageState();
}

class _RateFacultyPageState extends State<RateFacultyPage> {
  static const String _tag = 'RateFacultyPage';

  double _teaching = 5.0;
  double _attendanceFlex = 5.0;
  double _supportiveness = 5.0;
  double _marks = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    try {
      final repository = FacultyRatingRepository();
      await repository.initialize();

      final rating = await repository.getMyRating(
        studentRegno: widget.studentProfile.registerNumber,
        facultyId: widget.facultyId,
      );

      if (rating != null && mounted) {
        setState(() {
          _teaching = rating.teaching;
          _attendanceFlex = rating.attendanceFlex;
          _supportiveness = rating.supportiveness;
          _marks = rating.marks;
        });
        Logger.d(_tag, 'Loaded existing rating');
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading existing rating', e);
    }
  }

  double get _overallRating {
    return (_teaching + _attendanceFlex + _supportiveness + _marks) / 4.0;
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      final provider = context.read<FacultyRatingProvider>();
      final faculty = provider.getFacultyById(widget.facultyId);

      if (faculty == null) {
        throw Exception('Faculty not found');
      }

      final success = await provider.submitRating(
        studentRegno: widget.studentProfile.registerNumber,
        facultyId: widget.facultyId,
        facultyName: faculty.facultyName,
        teaching: _teaching,
        attendanceFlex: _attendanceFlex,
        supportiveness: _supportiveness,
        marks: _marks,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          Navigator.pop(context, true);
        } else {
          SnackbarUtils.error(
            context,
            provider.errorMessage ?? 'Failed to submit rating',
          );
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error submitting rating', e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        SnackbarUtils.error(context, 'Failed to submit rating');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final provider = context.read<FacultyRatingProvider>();
    final faculty = provider.getFacultyById(widget.facultyId);

    if (faculty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Faculty')),
        body: const Center(child: Text('Faculty not found')),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Rate Faculty',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Faculty Info & Existing Ratings Combined
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Faculty Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faculty.facultyName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              faculty.courseTitles.map((course) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    course,
                                    style: TextStyle(
                                      color: theme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Existing Ratings Display
                  if (faculty.hasRatings) ...[
                    Divider(height: 1, color: theme.muted.withValues(alpha: 0.2)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 16,
                                color: theme.muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Community Ratings (${faculty.ratingData!.totalRatings} reviews)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactStat(
                                  'Teaching',
                                  faculty.ratingData!.avgTeaching,
                                  theme,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactStat(
                                  'Attendance',
                                  faculty.ratingData!.avgAttendanceFlex,
                                  theme,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactStat(
                                  'Support',
                                  faculty.ratingData!.avgSupportiveness,
                                  theme,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactStat(
                                  'Marks',
                                  faculty.ratingData!.avgMarks,
                                  theme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Verified Card - More Compact
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user,
                      size: 16,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentProfile.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.studentProfile.registerNumber,
                          style: TextStyle(fontSize: 11, color: theme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rating Sliders - More Compact
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rating',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RatingSlider(
                    label: 'Teaching Quality',
                    description: 'Clarity, engagement, and effectiveness',
                    value: _teaching,
                    onChanged: (v) => setState(() => _teaching = v),
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  RatingSlider(
                    label: 'Attendance Flexibility',
                    description: 'Understanding towards attendance issues',
                    value: _attendanceFlex,
                    onChanged: (v) => setState(() => _attendanceFlex = v),
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  RatingSlider(
                    label: 'Supportiveness',
                    description: 'Approachability and helpfulness',
                    value: _supportiveness,
                    onChanged: (v) => setState(() => _supportiveness = v),
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  RatingSlider(
                    label: 'Marking Fairness',
                    description: 'Fair evaluation and grading',
                    value: _marks,
                    onChanged: (v) => setState(() => _marks = v),
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // Overall Rating - Inline
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRatingColor(_overallRating).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getRatingColor(_overallRating).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Rating',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          '${_overallRating.toStringAsFixed(1)}/10',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getRatingColor(_overallRating),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, double value, theme) {
    final color = _getRatingColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.text,
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green.shade700;
    if (rating >= 6.0) return Colors.blue.shade700;
    if (rating >= 4.0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
