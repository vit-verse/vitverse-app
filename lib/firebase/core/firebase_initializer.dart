import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';
import '../analytics/analytics_service.dart';
import '../crashlytics/crashlytics_service.dart';
import '../messaging/fcm_service.dart';
import '../../core/utils/logger.dart';

class FirebaseInitializer {
  static const String _tag = 'FirebaseInit';
  static bool _isInitialized = false;
  static bool _coreInitialized = false;

  /// Initialize only Firebase Core (lightweight, required for App Check)
  static Future<void> initializeCore() async {
    if (_coreInitialized) {
      Logger.d(_tag, 'Core already initialized');
      return;
    }

    try {
      await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
      _coreInitialized = true;
      Logger.success(_tag, 'Core initialized');
    } catch (e, stack) {
      Logger.e(_tag, 'Core initialization failed', e, stack);
      rethrow;
    }
  }

  /// Initialize Firebase and all services (full initialization)
  static Future<void> initialize() async {
    if (_isInitialized) {
      Logger.w(_tag, 'Already initialized');
      return;
    }

    try {
      Logger.i(_tag, 'Initializing Firebase services...');
      final startTime = DateTime.now();

      // Initialize core if not already done
      if (!_coreInitialized) {
        await initializeCore();
      }

      // Initialize services (heavyweight)
      await _initializeServices();
      await _setupErrorHandling();

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success(_tag, 'Initialized in ${duration}ms');

      _isInitialized = true;
      FirebaseConfig.printConfig();
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Initialization failed', e, stackTrace);
      Logger.w(_tag, 'App will continue without Firebase');
    }
  }

  /// Initialize Firebase services
  static Future<void> _initializeServices() async {
    final futures = <Future>[];

    if (FirebaseConfig.enableAnalytics) futures.add(_initializeAnalytics());
    if (FirebaseConfig.enableCrashlytics) futures.add(_initializeCrashlytics());
    if (FirebaseConfig.enableMessaging) futures.add(_initializeMessaging());

    await Future.wait(futures);
  }

  /// Initialize Firebase Analytics
  static Future<void> _initializeAnalytics() async {
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(
        FirebaseConfig.enableDataCollection,
      );
      await AnalyticsService.initialize(analytics);
      Logger.success(_tag, 'Analytics initialized');
    } catch (e) {
      Logger.e(_tag, 'Analytics failed', e);
    }
  }

  /// Initialize Firebase Crashlytics
  static Future<void> _initializeCrashlytics() async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(
        FirebaseConfig.enableDataCollection,
      );
      await CrashlyticsService.initialize(crashlytics);
      Logger.success(_tag, 'Crashlytics initialized');
    } catch (e) {
      Logger.e(_tag, 'Crashlytics failed', e);
    }
  }

  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await FCMService.initialize(messaging);
      Logger.success(_tag, 'Messaging initialized');
    } catch (e) {
      Logger.e(_tag, 'Messaging failed', e);
    }
  }

  /// Setup global error handling
  static Future<void> _setupErrorHandling() async {
    try {
      // Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        Logger.e(_tag, 'Flutter Error', details.exception, details.stack);
        if (FirebaseConfig.enableCrashlytics) {
          CrashlyticsService.recordFlutterError(details);
        }
      };

      // Async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        Logger.e(_tag, 'Platform Error', error, stack);
        if (FirebaseConfig.enableCrashlytics) {
          CrashlyticsService.recordError(error, stack, fatal: false);
        }
        return true;
      };

      Logger.success(_tag, 'Error handling configured');
    } catch (e) {
      Logger.e(_tag, 'Error handling setup failed', e);
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
}
