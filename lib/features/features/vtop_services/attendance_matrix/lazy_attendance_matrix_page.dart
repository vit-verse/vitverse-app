import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/attendance_matrix_page.dart';

class LazyAttendanceMatrixPage extends StatelessWidget {
  const LazyAttendanceMatrixPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'attendance_matrix',
      title: 'Attendance Matrix',
      pageBuilder: () => const AttendanceMatrixPage(),
    );
  }
}
