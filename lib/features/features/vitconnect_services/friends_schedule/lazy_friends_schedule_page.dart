import 'package:flutter/material.dart';
import '../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/friends_timetable_page.dart';

class LazyFriendsSchedulePage extends StatelessWidget {
  const LazyFriendsSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'friends_schedule',
      title: 'Friends Schedule',
      pageBuilder: () => const FriendsSchedulePage(),
    );
  }
}
