import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/laundry_page.dart';

/// Lazy loading wrapper for Laundry
/// Uses optimized loading to prevent UI freezing
class LazyLaundryPage extends StatelessWidget {
  const LazyLaundryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'laundry',
      title: 'Laundry',
      pageBuilder: () => const LaundryPage(),
    );
  }
}
