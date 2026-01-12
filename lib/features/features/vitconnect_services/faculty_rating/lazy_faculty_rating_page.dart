import 'package:flutter/material.dart';
import 'presentation/faculty_ratings_page.dart';

/// Lazy-loaded Faculty Rating page
class LazyFacultyRatingPage extends StatelessWidget {
  const LazyFacultyRatingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final facultyId = ModalRoute.of(context)?.settings.arguments as String?;

    return FacultyRatingsPage(scrollToFacultyId: facultyId);
  }
}
