import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/academic_performance_page.dart';

/// Lazy loading wrapper for Academic Performance
class LazyAcademicPerformancePage extends StatelessWidget {
  const LazyAcademicPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'academic_performance',
      title: 'Academic Performance',
      pageBuilder: () => const AcademicPerformancePage(),
    );
  }
}
