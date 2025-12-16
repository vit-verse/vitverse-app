import 'package:flutter/material.dart';
import '../../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/quick_links_page.dart';

class LazyQuickLinksPage extends StatelessWidget {
  const LazyQuickLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'quick_links',
      title: 'Quick Links',
      pageBuilder: () => const QuickLinksPage(),
    );
  }
}
