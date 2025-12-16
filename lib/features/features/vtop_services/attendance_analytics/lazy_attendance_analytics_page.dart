import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/attendance_analytics_page.dart';

/// Lazy loader for Attendance Analytics feature
class LazyAttendanceAnalyticsPage extends StatelessWidget {
  const LazyAttendanceAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'attendance_analytics',
      title: 'Attendance Analytics',
      pageBuilder: () => const AttendanceAnalyticsPage(),
    );
  }
}
