import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../firebase/analytics/analytics_service.dart';
import '../../core/loading/loading_messages.dart';
import 'logic/calendar_provider.dart';
import 'presentation/calendar_page.dart';

class LazyCalendarPage extends StatefulWidget {
  const LazyCalendarPage({super.key});

  @override
  State<LazyCalendarPage> createState() => _LazyCalendarPageState();
}

class _LazyCalendarPageState extends State<LazyCalendarPage> {
  late Future<CalendarProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = _initializeProvider();
  }

  Future<CalendarProvider> _initializeProvider() async {
    final provider = CalendarProvider();
    await provider.initialize();
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CalendarProvider>(
      future: _providerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading message while building page
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    LoadingMessages.getMessage('calendar'),
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
          return ChangeNotifierProvider.value(
            value: snapshot.data!,
            child: const CalendarPageWithAnalytics(),
          );
        }

        // Fallback - should not reach here
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Calendar'),
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
                    'Failed to Load Calendar',
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

class CalendarPageWithAnalytics extends StatefulWidget {
  const CalendarPageWithAnalytics({super.key});

  @override
  State<CalendarPageWithAnalytics> createState() =>
      _CalendarPageWithAnalyticsState();
}

class _CalendarPageWithAnalyticsState extends State<CalendarPageWithAnalytics> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'calendar',
      screenClass: 'calendarPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CalendarPage();
  }
}
