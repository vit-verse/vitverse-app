import 'package:flutter/material.dart';
import '../../../../../core/loading/optimized_lazy_loader.dart';
import 'faculty_rating_page.dart';

class LazyFacultyRatingPage extends StatelessWidget {
  const LazyFacultyRatingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'faculty_rating',
      title: 'Faculty Rating',
      pageBuilder: () => const FacultyRatingPage(),
    );
  }
}
