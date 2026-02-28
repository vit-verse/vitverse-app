import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'env_config.dart';

/// Application configuration for development and production
class AppConfig {
  static const bool enableDetailedLogs = false; // production: false
  static const bool enablePerformanceMode = true; // production: true
  static const bool enableDatabaseDebug = false; // production: false
  static const bool enableNetworkLogs = false; // production: false

  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  static String get githubVitconnectToken => EnvConfig.githubVitconnectToken;
  static String get pyqSecretHeader => EnvConfig.pyqSecretHeader;

  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  static bool get isProfile => kProfileMode;

  // Log level calculation
  static LogLevel get logLevel {
    if (enablePerformanceMode) return LogLevel.error;
    if (!enableDetailedLogs) {
      return isProduction ? LogLevel.error : LogLevel.warning;
    }
    return isDevelopment ? LogLevel.debug : LogLevel.error;
  }

  // Feature flags
  static bool get enableDatabaseOptimizations => true;
  static bool get enableLazyLoading => true;
  static bool get enableProgressiveLoading => true;
  static bool get enableKiroAnimations => true;

  // Performance settings
  static int get databaseCacheSize => 10000;
  static int get maxLogEntries => enableDetailedLogs ? 1000 : 100;
  static int get lazyLoadingTimeout => 10;

  // Debug helpers
  static void printConfig() {
    if (isDevelopment) {
      Logger.i('AppConfig', 'Environment: ${isDevelopment ? 'Dev' : 'Prod'}');
      Logger.i('AppConfig', 'Logs: $enableDetailedLogs');
      Logger.i('AppConfig', 'Performance: $enablePerformanceMode');
      Logger.i('AppConfig', 'Log Level: $logLevel');
    }
  }
}
