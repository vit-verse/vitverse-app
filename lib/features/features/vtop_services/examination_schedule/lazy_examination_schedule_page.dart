import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/examination_schedule_page.dart';

/// Lazy loading wrapper for Examination Schedule
/// Uses optimized loading to prevent UI freezing
class LazyExaminationSchedulePage extends StatelessWidget {
  const LazyExaminationSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'examination_schedule',
      title: 'Examination Schedule',
      pageBuilder: () => const ExaminationSchedulePage(),
    );
  }
}
