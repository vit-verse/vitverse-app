import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../firebase/analytics/analytics_service.dart';
import '../../core/loading/loading_messages.dart';
import 'logic/feature_provider.dart';
import 'presentation/features_page.dart';

class LazyFeaturesPage extends StatefulWidget {
  const LazyFeaturesPage({super.key});

  @override
  State<LazyFeaturesPage> createState() => _LazyFeaturesPageState();
}

class _LazyFeaturesPageState extends State<LazyFeaturesPage> {
  late Future<FeatureProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = _initializeProvider();
  }

  Future<FeatureProvider> _initializeProvider() async {
    final provider = FeatureProvider();
    await provider.initialize();
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeatureProvider>(
      future: _providerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    LoadingMessages.getMessage('features'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.hasData) {
          return ChangeNotifierProvider.value(
            value: snapshot.data!,
            child: const FeaturesPageWithAnalytics(),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Features'),
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Features',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _providerFuture = _initializeProvider();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturesPageWithAnalytics extends StatefulWidget {
  const FeaturesPageWithAnalytics({super.key});

  @override
  State<FeaturesPageWithAnalytics> createState() =>
      _FeaturesPageWithAnalyticsState();
}

class _FeaturesPageWithAnalyticsState extends State<FeaturesPageWithAnalytics> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'Features',
      screenClass: 'FeaturesPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const FeaturesPage();
  }
}
