import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/mess_menu_page.dart';

/// Lazy loading wrapper for Mess Menu
/// Uses optimized loading to prevent UI freezing
class LazyMessMenuPage extends StatelessWidget {
  const LazyMessMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'mess_menu',
      title: 'Mess Menu',
      pageBuilder: () => const MessMenuPage(),
    );
  }
}
