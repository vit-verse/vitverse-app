import 'package:flutter/material.dart';
import 'dart:async';

/// Mixin to prevent gesture loss during rebuilds
/// Use this on StatefulWidgets that have frequent rebuilds and tap gestures
mixin GestureFixMixin<T extends StatefulWidget> on State<T> {
  // Track if a gesture is currently active
  bool _isGestureActive = false;
  Timer? _gestureResetTimer;

  /// Call this when a tap/gesture starts
  void startGesture() {
    _isGestureActive = true;
    _gestureResetTimer?.cancel();
    _gestureResetTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isGestureActive = false;
      }
    });
  }

  /// Call this before setState to check if it's safe to rebuild
  bool canRebuild() {
    return !_isGestureActive;
  }

  /// Safe setState that won't interrupt gestures
  void safeSetState(VoidCallback fn) {
    if (mounted && canRebuild()) {
      setState(fn);
    } else if (mounted && _isGestureActive) {
      // Queue the update for after gesture completes
      _gestureResetTimer?.cancel();
      _gestureResetTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isGestureActive = false;
          setState(fn);
        }
      });
    }
  }

  @override
  void dispose() {
    _gestureResetTimer?.cancel();
    super.dispose();
  }
}

/// Safe wrapper for GestureDetector that prevents rebuild conflicts
class SafeGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final HitTestBehavior? behavior;

  const SafeGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Isolate this widget from parent rebuilds
      child: GestureDetector(
        behavior: behavior ?? HitTestBehavior.opaque,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Safe wrapper for InkWell that prevents rebuild conflicts
class SafeInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const SafeInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Isolate this widget from parent rebuilds
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: child,
        ),
      ),
    );
  }
}

/// Debounced rebuild manager - prevents excessive rebuilds
class RebuildThrottler {
  Timer? _timer;
  static const Duration _throttleDuration = Duration(milliseconds: 100);

  void throttleRebuild(VoidCallback rebuild) {
    if (_timer?.isActive ?? false) {
      // Already scheduled, skip this rebuild
      return;
    }

    _timer = Timer(_throttleDuration, rebuild);
  }

  void dispose() {
    _timer?.cancel();
  }
}
