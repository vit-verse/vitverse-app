import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/staff_page.dart';

class LazyStaffPage extends StatelessWidget {
  const LazyStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'staff',
      title: 'Staff Directory',
      pageBuilder: () => const StaffPage(),
    );
  }
}
