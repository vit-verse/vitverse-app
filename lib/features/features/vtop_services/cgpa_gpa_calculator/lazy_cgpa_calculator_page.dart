import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/cgpa_gpa_calculator_page.dart';

class LazyCgpaCalculatorPage extends StatelessWidget {
  const LazyCgpaCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OptimizedLazyLoader(
      featureKey: 'cgpa_calculator',
      title: 'CGPA Calculator',
      pageBuilder: CgpaGpaCalculatorPage.new,
    );
  }
}
