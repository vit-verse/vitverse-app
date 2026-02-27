import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

enum SnackbarType { success, error, info, warning }

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class SnackbarItem {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final SnackBarAction? action;
  late AnimationController slideController;
  late AnimationController countdownController;
  late Timer timer;

  SnackbarItem({
    required this.message,
    required this.type,
    required this.duration,
    this.action,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Manager widget (wrap your app root with this)
// ─────────────────────────────────────────────────────────────────────────────

class StackedSnackbarManager extends StatefulWidget {
  final Widget child;

  const StackedSnackbarManager({super.key, required this.child});

  @override
  State<StackedSnackbarManager> createState() => _StackedSnackbarManagerState();

  // ignore: library_private_types_in_public_api
  static _StackedSnackbarManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<_StackedSnackbarManagerState>();
  }
}

class _StackedSnackbarManagerState extends State<StackedSnackbarManager>
    with TickerProviderStateMixin {
  SnackbarItem? _current;

  void addSnackbar(SnackbarItem item) {
    // Instantly dismiss any existing snackbar
    if (_current != null) {
      _disposeItem(_current!);
      _current = null;
    }

    item.slideController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    item.countdownController = AnimationController(
      duration: item.duration,
      vsync: this,
    );

    setState(() => _current = item);

    item.slideController.forward();
    item.countdownController.forward();

    item.timer = Timer(item.duration, () => _removeSnackbar(item));
  }

  void _removeSnackbar(SnackbarItem item) {
    if (_current == item) {
      item.slideController.reverse().then((_) {
        if (mounted && _current == item) {
          _disposeItem(item);
          setState(() => _current = null);
        }
      });
    }
  }

  void _disposeItem(SnackbarItem item) {
    item.timer.cancel();
    if (item.slideController.isAnimating || !item.slideController.isDismissed) {
      item.slideController.stop();
    }
    item.slideController.dispose();
    item.countdownController.dispose();
  }

  @override
  void dispose() {
    if (_current != null) _disposeItem(_current!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;

    bool hasBottomNav = false;
    context.visitAncestorElements((element) {
      if (element.widget is Scaffold) {
        final scaffold = element.widget as Scaffold;
        if (scaffold.bottomNavigationBar != null) {
          hasBottomNav = true;
          return false;
        }
      }
      return true;
    });

    final snackbarBottom =
        viewInsets > 0
            ? viewInsets + 12.0
            : (hasBottomNav
                ? 100.0
                : (bottomPadding > 0 ? bottomPadding + 12.0 : 12.0));

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            bottom: snackbarBottom,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _current!.slideController,
              builder: (context, child) {
                final slide = CurvedAnimation(
                  parent: _current!.slideController,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return Transform.translate(
                  offset: Offset(0, (1 - slide.value) * 60),
                  child: Opacity(opacity: slide.value, child: child),
                );
              },
              child: _SnackbarCard(
                item: _current!,
                onDismiss: () => _removeSnackbar(_current!),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snackbar card widget
// ─────────────────────────────────────────────────────────────────────────────

class _SnackbarCard extends StatelessWidget {
  final SnackbarItem item;
  final VoidCallback onDismiss;

  const _SnackbarCard({required this.item, required this.onDismiss});

  Color _typeColor() => switch (item.type) {
    SnackbarType.success => const Color(0xFF22C55E),
    SnackbarType.error => const Color(0xFFEF4444),
    SnackbarType.info => const Color(0xFF3B82F6),
    SnackbarType.warning => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final appTheme = themeProvider.currentTheme;
    final typeColor = _typeColor();

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: appTheme.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: appTheme.isDark ? 0.40 : 0.14,
              ),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular countdown ring with center dot
            AnimatedBuilder(
              animation: item.countdownController,
              builder: (context, _) {
                final remaining = 1.0 - item.countdownController.value;
                return SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(
                    painter: _CountdownRingPainter(
                      progress: remaining,
                      color: typeColor,
                      trackColor: typeColor.withValues(alpha: 0.18),
                      strokeWidth: 2.4,
                      dotRadius: 4.2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            // Message text
            Flexible(
              child: Text(
                item.message,
                style: TextStyle(
                  color: appTheme.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Optional action
            if (item.action != null) ...[
              const SizedBox(width: 8),
              item.action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter: countdown ring + center dot
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownRingPainter extends CustomPainter {
  final double progress; // 1.0 → full ring, 0.0 → empty
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double dotRadius;

  const _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background ring)
    final trackPaint =
        Paint()
          ..color = trackColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (countdown)
    if (progress > 0.01) {
      final progressPaint =
          Paint()
            ..color = color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start from 12 o'clock
        2 * math.pi * progress, // sweep angle
        false,
        progressPaint,
      );
    }

    // Center dot
    canvas.drawCircle(center, dotRadius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

class SnackbarUtils {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final manager = StackedSnackbarManager.of(context);
    manager?.addSnackbar(
      SnackbarItem(
        message: message,
        type: type,
        duration: duration,
        action: action,
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: SnackbarType.success,
    duration: duration ?? const Duration(seconds: 3),
  );

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message: message,
    type: SnackbarType.error,
    duration: duration ?? const Duration(seconds: 3),
    action: action,
  );

  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: SnackbarType.info,
    duration: duration ?? const Duration(seconds: 3),
  );

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: SnackbarType.warning,
    duration: duration ?? const Duration(seconds: 3),
  );
}
