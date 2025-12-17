import 'package:flutter/material.dart';
import 'dart:async';

enum SnackbarType { success, error, info, warning }

class SnackbarItem {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final SnackBarAction? action;
  late final Timer timer;
  late final AnimationController slideController;
  late final AnimationController progressController;

  SnackbarItem({
    required this.message,
    required this.type,
    required this.duration,
    this.action,
  });
}

class StackedSnackbarManager extends StatefulWidget {
  final Widget child;

  const StackedSnackbarManager({Key? key, required this.child})
    : super(key: key);

  @override
  State<StackedSnackbarManager> createState() => _StackedSnackbarManagerState();

  static _StackedSnackbarManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<_StackedSnackbarManagerState>();
  }
}

class _StackedSnackbarManagerState extends State<StackedSnackbarManager>
    with TickerProviderStateMixin {
  final List<SnackbarItem> _snackbars = [];

  void addSnackbar(SnackbarItem item) {
    setState(() {
      if (_snackbars.length >= 3) {
        final oldest = _snackbars.removeAt(0);
        oldest.slideController.dispose();
        oldest.progressController.dispose();
        oldest.timer.cancel();
      }

      item.slideController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      item.progressController = AnimationController(
        duration: item.duration,
        vsync: this,
      );

      _snackbars.add(item);
      item.slideController.forward();
      item.progressController.forward();

      item.timer = Timer(item.duration, () => _removeSnackbar(item));
    });
  }

  void _removeSnackbar(SnackbarItem item) {
    if (_snackbars.contains(item)) {
      item.slideController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _snackbars.remove(item);
            item.slideController.dispose();
            item.progressController.dispose();
            item.timer.cancel();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final item in _snackbars) {
      item.slideController.dispose();
      item.progressController.dispose();
      item.timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding to account for navigation bar
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;

    // Check if we're on a screen with bottom navigation
    // Look for a Scaffold with bottomNavigationBar in the widget tree
    bool hasBottomNav = false;
    
    // Try to find a Scaffold ancestor with bottomNavigationBar
    context.visitAncestorElements((element) {
      if (element.widget is Scaffold) {
        final scaffold = element.widget as Scaffold;
        if (scaffold.bottomNavigationBar != null) {
          hasBottomNav = true;
          return false; // Stop searching
        }
      }
      return true; // Continue searching
    });

    // Calculate bottom offset:
    // - If keyboard is open: position above keyboard
    // - If bottom nav exists: 70px (nav height) + 16px spacing
    // - Otherwise: just safe area padding + 16px
    final snackbarBottom =
        viewInsets > 0
            ? viewInsets + 16.0
            : (hasBottomNav
                ? 86.0
                : (bottomPadding > 0 ? bottomPadding + 16.0 : 16.0));

    return Stack(
      children: [
        widget.child,
        if (_snackbars.isNotEmpty)
          Positioned(
            bottom: snackbarBottom,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _snackbars.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return AnimatedBuilder(
                      animation: item.slideController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            (1 - item.slideController.value) * 100,
                          ),
                          child: Opacity(
                            opacity: item.slideController.value,
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: index < _snackbars.length - 1 ? 4 : 0,
                              ),
                              child: _SnackbarCard(
                                item: item,
                                index: index,
                                totalCount: _snackbars.length,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SnackbarCard extends StatelessWidget {
  final SnackbarItem item;
  final int index;
  final int totalCount;

  const _SnackbarCard({
    required this.item,
    required this.index,
    required this.totalCount,
  });

  Color _getColor() {
    return switch (item.type) {
      SnackbarType.success => const Color(0xFF10B981),
      SnackbarType.error => const Color(0xFFEF4444),
      SnackbarType.info => const Color(0xFF3B82F6),
      SnackbarType.warning => const Color(0xFFF59E0B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getColor();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLatest = index == totalCount - 1;

    // Latest snackbar gets full width, older ones get progressively smaller
    final width = screenWidth - 32 - ((totalCount - 1 - index) * 20);
    final opacity = isLatest ? 1.0 : 0.7 - ((totalCount - 1 - index) * 0.15);
    final height = 28.0;

    return AnimatedBuilder(
      animation: item.progressController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(opacity * 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Progress fill
              Container(
                width: width * (1 - item.progressController.value),
                height: height,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.message,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.action != null && isLatest)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: item.action!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SnackbarUtils {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final manager = StackedSnackbarManager.of(context);
    if (manager != null) {
      manager.addSnackbar(
        SnackbarItem(
          message: message,
          type: type,
          duration: duration,
          action: action,
        ),
      );
    }
  }

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message: message,
      type: SnackbarType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
