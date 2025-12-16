import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/my_course_faculties_page.dart';

class LazyMyCourseFacultiesPage extends StatelessWidget {
  const LazyMyCourseFacultiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OptimizedLazyLoader(
      featureKey: 'my_course_faculties',
      title: 'My Course Faculties',
      pageBuilder: MyCourseFacultiesPage.new,
    );
  }
}
