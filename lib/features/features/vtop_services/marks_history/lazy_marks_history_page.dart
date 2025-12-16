import 'package:flutter/material.dart';
import '../../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/marks_history_page.dart';

/// Lazy loader wrapper for marks history page
class LazyMarksHistoryPage extends StatelessWidget {
  const LazyMarksHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OptimizedLazyLoader(
      featureKey: 'marks_history',
      pageBuilder: MarksHistoryPage.new,
      title: 'Marks History',
    );
  }
}
