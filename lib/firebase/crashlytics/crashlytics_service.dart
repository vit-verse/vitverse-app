import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_version.dart';

class CrashlyticsService {
  static CrashlyticsService? _instance;
  static FirebaseCrashlytics? _crashlytics;

  CrashlyticsService._();

  static CrashlyticsService get instance =>
      _instance ??= CrashlyticsService._();

  /// Initialize Crashlytics service
  static Future<void> initialize(FirebaseCrashlytics crashlytics) async {
    try {
      _crashlytics = crashlytics;
      _instance = CrashlyticsService._();
      await _setDefaultCustomKeys();
    } catch (e) {
      // Crashlytics initialization failed
    }
  }

  static Future<void> _setDefaultCustomKeys() async {
    try {
      await _crashlytics?.setCustomKey('app_version', AppVersion.version);
      await _crashlytics?.setCustomKey('platform', defaultTargetPlatform.name);
    } catch (_) {}
  }

  /// Record a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(exception, stackTrace, fatal: fatal);
    } catch (_) {}
  }

  /// Record Flutter framework errors
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics?.recordFlutterFatalError(details);
    } catch (_) {}
  }

  /// Set user identifier
  static Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics?.setUserIdentifier(identifier);
    } catch (_) {}
  }

  /// Set custom key
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (_) {}
  }

  /// Log a breadcrumb message
  static Future<void> log(String message) async {
    try {
      await _crashlytics?.log(message);
    } catch (_) {}
  }
}
