import 'dart:async';
import 'package:flutter/material.dart';

/// Prevents double-tap issues by debouncing tap events
class TapDebouncer {
  static Timer? _debounceTimer;
  static DateTime? _lastTapTime;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// Debounce a function call to prevent rapid repeated calls
  static void debounce(VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, action);
  }

  /// Execute action only if enough time has passed since last tap
  static void throttle(VoidCallback action) {
    final now = DateTime.now();

    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > _debounceDuration) {
      _lastTapTime = now;
      action();
    }
  }

  /// Dispose timers
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastTapTime = null;
  }
}

/// Widget wrapper for debounced taps
class DebouncedInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const DebouncedInkWell({
    Key? key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null ? () => TapDebouncer.throttle(onTap!) : null,
      borderRadius: borderRadius,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Widget wrapper for debounced gesture detection
class DebouncedGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const DebouncedGestureDetector({Key? key, required this.child, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => TapDebouncer.throttle(onTap!) : null,
      child: child,
    );
  }
}
