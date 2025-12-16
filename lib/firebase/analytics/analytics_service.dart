import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'analytics_events.dart';
import '../../core/config/app_version.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  AnalyticsService._();

  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// Initialize Analytics service
  static Future<void> initialize(FirebaseAnalytics analytics) async {
    try {
      _analytics = analytics;
      _observer = FirebaseAnalyticsObserver(analytics: analytics);
      _instance = AnalyticsService._();

      await _setDefaultUserProperties();
      await instance.logAppLifecycle(AppLifecycleEvent.appStartup);
    } catch (e) {
      // Analytics initialization failed
    }
  }

  static Future<void> _setDefaultUserProperties() async {
    try {
      await _analytics?.setUserProperty(
        name: 'app_version',
        value: AppVersion.version,
      );
      await _analytics?.setUserProperty(
        name: 'platform',
        value: defaultTargetPlatform.name,
      );
    } catch (_) {}
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  /// Log screen view - Main tracking method
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (_) {}
  }

  /// Set user ID (when user logs in)
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (_) {}
  }

  /// Log authentication events
  Future<void> logAuth(
    AuthEvent event, {
    Map<String, Object>? parameters,
  }) async {
    await logEvent(name: event.name, parameters: parameters);
  }

  /// Log data sync events
  Future<void> logDataSync(
    DataSyncEvent event, {
    Map<String, Object>? parameters,
  }) async {
    await logEvent(name: event.name, parameters: parameters);
  }

  /// Log error events (lightweight)
  Future<void> logError(
    ErrorEvent event, {
    Map<String, Object>? parameters,
  }) async {
    await logEvent(name: event.name, parameters: parameters);
  }

  /// Log app lifecycle events
  Future<void> logAppLifecycle(
    AppLifecycleEvent event, {
    Map<String, Object>? parameters,
  }) async {
    await logEvent(name: event.name, parameters: parameters);
  }
}
