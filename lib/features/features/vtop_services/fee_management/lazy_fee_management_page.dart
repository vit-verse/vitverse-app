import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/fee_management_page.dart';

class LazyFeeManagementPage extends StatelessWidget {
  const LazyFeeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'fees',
      title: 'Fee Management',
      pageBuilder: () => const FeeManagementPage(),
    );
  }
}
