import 'package:flutter/material.dart';
import '../../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/grade_history_page.dart';

/// Lazy loading wrapper for Grade History
class LazyGradeHistoryPage extends StatelessWidget {
  const LazyGradeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'grade_history',
      title: 'Grade History',
      pageBuilder: () => const GradeHistoryPage(),
    );
  }
}
