import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/pyq_home_page.dart';

/// Lazy loader for PYQ feature
class LazyPyqPage extends StatelessWidget {
  const LazyPyqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'pyq',
      title: 'PYQs',
      pageBuilder: () => const PyqHomePage(),
    );
  }
}
