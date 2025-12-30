import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/loading/loading_messages.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/themed_lottie_widget.dart';
import '../../firebase/analytics/analytics_service.dart';
import 'logic/performance_logic.dart';
import 'models/performance_models.dart';
import 'presentation/performance_page.dart';

class LazyPerformancePage extends StatefulWidget {
  const LazyPerformancePage({super.key});

  @override
  State<LazyPerformancePage> createState() => _LazyPerformancePageState();
}

class _LazyPerformancePageState extends State<LazyPerformancePage> {
  late Future<List<CoursePerformance>> _performanceFuture;

  @override
  void initState() {
    super.initState();
    _performanceFuture = _initializeData();
  }

  Future<List<CoursePerformance>> _initializeData() async {
    final logic = PerformanceLogic();
    final performances = await logic.getCoursePerformances();
    return performances;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoursePerformance>>(
      future: _performanceFuture,
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
                    LoadingMessages.getMessage('performance'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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
          if (snapshot.data!.isEmpty) {
            return _buildEmptyStateWithAnalytics();
          }
          return PerformancePageWithAnalytics(
            initialPerformances: snapshot.data!,
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
            title: const Text('Academic'),
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
                    'Failed to Load Performance Data',
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
                        _performanceFuture = _initializeData();
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

  Widget _buildEmptyStateWithAnalytics() {
    return _EmptyPerformancePageWithAnalytics(
      onRefresh: () {
        setState(() {
          _performanceFuture = _initializeData();
        });
      },
    );
  }
}

class _EmptyPerformancePageWithAnalytics extends StatefulWidget {
  final VoidCallback onRefresh;

  const _EmptyPerformancePageWithAnalytics({required this.onRefresh});

  @override
  State<_EmptyPerformancePageWithAnalytics> createState() =>
      _EmptyPerformancePageWithAnalyticsState();
}

class _EmptyPerformancePageWithAnalyticsState
    extends State<_EmptyPerformancePageWithAnalytics> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'Performance',
      screenClass: 'PerformancePage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        title: const Text('Academic'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 340,
                height: 340,
                child: ThemedLottieWidget(
                  assetPath: 'assets/lottie/student.lottie',
                  width: 340,
                  height: 340,
                  showContainer: false,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your faculty has not published marks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: themeProvider.currentTheme.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.currentTheme.muted.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PerformancePageWithAnalytics extends StatefulWidget {
  final List<CoursePerformance> initialPerformances;

  const PerformancePageWithAnalytics({
    super.key,
    required this.initialPerformances,
  });

  @override
  State<PerformancePageWithAnalytics> createState() =>
      _PerformancePageWithAnalyticsState();
}

class _PerformancePageWithAnalyticsState
    extends State<PerformancePageWithAnalytics> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'Performance',
      screenClass: 'PerformancePage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PerformancePage(initialPerformances: widget.initialPerformances);
  }
}
