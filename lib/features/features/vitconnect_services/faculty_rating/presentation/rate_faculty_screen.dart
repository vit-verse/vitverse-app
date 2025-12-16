import 'package:flutter/material.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../bloc/faculty_rating_bloc.dart';
import '../models/faculty_model.dart';
import '../models/rating_model.dart';
import '../widgets/faculty_rating_widgets.dart';

class RateFacultyScreen extends StatefulWidget {
  final Faculty faculty;
  final FacultyRatingBloc bloc;

  const RateFacultyScreen({
    super.key,
    required this.faculty,
    required this.bloc,
  });

  @override
  State<RateFacultyScreen> createState() => _RateFacultyScreenState();
}

class _RateFacultyScreenState extends State<RateFacultyScreen> {
  static const String _tag = 'RateFacultyScreen';

  final Map<String, double> _ratings = {
    'teaching': 5.0,
    'attendance_flex': 5.0,
    'supportiveness': 5.0,
    'marks': 5.0,
  };

  bool _isSubmitting = false;

  double get _overallRating {
    final sum = _ratings.values.reduce((a, b) => a + b);
    return sum / _ratings.length;
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submission = RatingSubmission(
        facultyId: widget.faculty.facultyId,
        facultyName: widget.faculty.name,
        teaching: _ratings['teaching']!,
        attendanceFlex: _ratings['attendance_flex']!,
        supportiveness: _ratings['supportiveness']!,
        marks: _ratings['marks']!,
      );

      await widget.bloc.submitRating(submission);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Logger.e(_tag, 'Error submitting rating', e);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        SnackbarUtils.error(context, 'Failed to submit rating');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async => !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rate Faculty'),
          centerTitle: false,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FacultyDetailsCard(faculty: widget.faculty),
                    const SizedBox(height: 24),
                    const PrivacyNoticeCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Rate on following parameters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...RatingParameters.all.map((param) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RatingSliderWidget(
                          label: param.title,
                          description: param.description,
                          icon: _getIconForParameter(param.id),
                          initialValue: _ratings[param.id]!,
                          onChanged: (value) {
                            setState(() {
                              _ratings[param.id] = value;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    OverallRatingCard(overallRating: _overallRating),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child:
                        _isSubmitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                            : const Text('Submit Rating'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForParameter(String parameterId) {
    switch (parameterId) {
      case 'teaching':
        return Icons.school;
      case 'attendance_flex':
        return Icons.calendar_today;
      case 'supportiveness':
        return Icons.support_agent;
      case 'marks':
        return Icons.assessment;
      default:
        return Icons.star;
    }
  }
}
