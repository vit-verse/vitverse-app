// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Log levels
enum LogLevel { verbose, debug, info, warning, error }

// Dont remove this 4 emojis, its easier for me to review console 📊✅❌⚠️
/// Enhanced logging utility with different log levels
class Logger {
  static const String _prefix = 'VIT_Connect';

  /// Current log level - automatically determined by AppConfig
  static LogLevel get currentLevel => AppConfig.logLevel;

  /// Check if level should be logged
  static bool _shouldLog(LogLevel level) {
    // Quick exit for performance mode
    if (AppConfig.enablePerformanceMode && level.index < LogLevel.error.index) {
      return false;
    }
    return level.index >= currentLevel.index;
  }

  /// Fast check for debug logging (most common case)
  static bool get _debugEnabled => _shouldLog(LogLevel.debug);

  /// Verbose logging (most detailed)
  static void v(String tag, String message) {
    if (_shouldLog(LogLevel.verbose)) {
      print('[$_prefix-V][$tag] $message');
    }
  }

  /// Debug logging (performance optimized)
  static void d(String tag, String message) {
    if (_debugEnabled) {
      print('[$_prefix-D][$tag] $message');
    }
  }

  /// Info logging
  static void i(String tag, String message) {
    if (_shouldLog(LogLevel.info)) {
      print('[$_prefix-I][$tag] $message');
    }
  }

  /// Warning logging
  static void w(String tag, String message) {
    if (_shouldLog(LogLevel.warning)) {
      print('[$_prefix-W][$tag] ⚠️ $message');
    }
  }

  /// Error logging
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_shouldLog(LogLevel.error)) {
      print('[$_prefix-E][$tag] ❌ $message');
      if (error != null) {
        print('[$_prefix-E][$tag] Error: $error');
      }
      if (stackTrace != null && kDebugMode) {
        print('[$_prefix-E][$tag] Stack: $stackTrace');
      }
    }
  }

  /// Progress logging with minimal output
  static void progress(String tag, int current, int total, String step) {
    if (_shouldLog(LogLevel.info)) {
      final percentage = (current / total * 100).toInt();
      print('[$_prefix-P][$tag] ($current/$total - $percentage%) $step');
    }
  }

  /// Success logging
  static void success(String tag, String message) {
    if (_shouldLog(LogLevel.info)) {
      print('[$_prefix-S][$tag] ✅ $message');
    }
  }

  /// Data summary logging (reduced detail)
  static void dataSummary(String tag, Map<String, int> counts) {
    if (_shouldLog(LogLevel.info)) {
      print('[$_prefix-D][$tag] 📊 Data Summary:');
      counts.forEach((table, count) {
        print('[$_prefix-D][$tag]   • $table: $count records');
      });
    }
  }
}

/// Logger extensions for common tags
extension VTOPLogger on Logger {
  static void auth(String message) => Logger.d('Auth', message);
  static void data(String message) => Logger.d('Data', message);
  static void db(String message) => Logger.d('DB', message);
  static void ui(String message) => Logger.d('UI', message);
  static void network(String message) => Logger.d('Network', message);
}
