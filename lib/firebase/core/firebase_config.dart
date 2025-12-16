import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../firebase_options.dart';

/// Firebase feature configuration
class FirebaseConfig {
  static const String _tag = 'FirebaseConfig';

  // Project metadata
  static const String projectId = 'vit-connect-app';
  static const String appName = 'VIT Connect';

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enableMessaging = true;

  // Environment detection
  static bool get isDebugMode => kDebugMode;
  static bool get enableDebugLogging => kDebugMode;
  static bool get enableDataCollection => !kDebugMode;

  static FirebaseOptions get currentPlatform {
    return DefaultFirebaseOptions.currentPlatform;
  }

  static void printConfig() {
    if (!enableDebugLogging) return;

    Logger.i(
      _tag,
      'Project: $projectId | Debug: $isDebugMode | Analytics: $enableAnalytics | Crashlytics: $enableCrashlytics | Messaging: $enableMessaging',
    );
  }
}
