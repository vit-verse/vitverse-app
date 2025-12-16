import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/all_faculties_page.dart';

class LazyAllFacultiesPage extends StatelessWidget {
  const LazyAllFacultiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OptimizedLazyLoader(
      featureKey: 'all_faculties',
      title: 'All Faculties',
      pageBuilder: AllFacultiesPage.new,
    );
  }
}
