import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'loading_messages.dart';

/// Optimized lazy loader that prevents UI freezing
class OptimizedLazyLoader extends StatefulWidget {
  final String featureKey;
  final Widget Function() pageBuilder;
  final Widget Function(BuildContext context)? skeletonBuilder;
  final String? title;
  final Duration delay;

  const OptimizedLazyLoader({
    super.key,
    required this.featureKey,
    required this.pageBuilder,
    this.skeletonBuilder,
    this.title,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<OptimizedLazyLoader> createState() => _OptimizedLazyLoaderState();
}

class _OptimizedLazyLoaderState extends State<OptimizedLazyLoader> {
  bool _isLoaded = false;
  Widget? _actualPage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPageAsync();
  }

  Future<void> _loadPageAsync() async {
    try {
      // Small delay to ensure skeleton shows first
      await Future.delayed(widget.delay);

      if (!mounted) return;

      // Use scheduler to load on next frame to prevent blocking
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // Load the actual page in a microtask to prevent blocking
          await Future.microtask(() async {
            final page = widget.pageBuilder();

            if (mounted) {
              setState(() {
                _actualPage = page;
                _isLoaded = true;
              });
            }
          });
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = e.toString();
              _isLoaded = true;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (!_isLoaded || _actualPage == null) {
      return widget.skeletonBuilder?.call(context) ?? _buildDefaultSkeleton();
    }

    return _actualPage!;
  }

  Widget _buildDefaultSkeleton() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Loading...'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                LoadingMessages.getMessage(widget.featureKey),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Feature')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load ${widget.title ?? 'feature'}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again or check your connection.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoaded = false;
                    _error = null;
                    _actualPage = null;
                  });
                  _loadPageAsync();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin for creating optimized lazy pages
mixin OptimizedLazyMixin {
  static Widget wrap({
    required String featureKey,
    required Widget Function() pageBuilder,
    Widget Function(BuildContext context)? skeletonBuilder,
    String? title,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return OptimizedLazyLoader(
      featureKey: featureKey,
      pageBuilder: pageBuilder,
      skeletonBuilder: skeletonBuilder,
      title: title,
      delay: delay,
    );
  }
}
