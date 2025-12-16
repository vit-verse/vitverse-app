import 'package:flutter/material.dart';
import '../../../../../core/loading/optimized_lazy_loader.dart';
import 'presentation/eventhub_page.dart';

class LazyEventHubPage extends StatelessWidget {
  const LazyEventHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'eventhub',
      title: 'EventHub',
      pageBuilder: () => const EventHubPage(),
    );
  }
}
