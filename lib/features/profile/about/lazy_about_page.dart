import 'package:flutter/material.dart';
import '../../../core/loading/optimized_lazy_loader.dart';
import 'about_page.dart';

class LazyAboutPage extends StatelessWidget {
  const LazyAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedLazyLoader(
      featureKey: 'about_page',
      title: 'About VIT Verse',
      pageBuilder: () => const AboutPage(),
      skeletonBuilder: (context) => const AboutSkeletonLoader(),
    );
  }
}

class AboutSkeletonLoader extends StatelessWidget {
  const AboutSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About VIT Verse'), centerTitle: false),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
