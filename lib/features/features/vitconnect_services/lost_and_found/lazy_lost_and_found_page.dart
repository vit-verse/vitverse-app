import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/lost_found_home_page.dart';

/// Lazy loader for Lost & Found feature
class LazyLostAndFoundPage extends StatelessWidget {
  const LazyLostAndFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'lost_and_found',
      pageBuilder: () => const LostFoundHomePage(),
    );
  }
}
