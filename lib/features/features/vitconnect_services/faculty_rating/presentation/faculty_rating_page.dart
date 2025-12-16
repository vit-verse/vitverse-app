import 'package:flutter/material.dart';
import 'faculty_rating_screen.dart';
import '../../../../../../firebase/analytics/analytics_service.dart';

class FacultyRatingPage extends StatelessWidget {
  const FacultyRatingPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreenView(
      screenName: 'FacultyRating',
      screenClass: 'FacultyRatingPage',
    );

    return const FacultyRatingScreen();
  }
}
