import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/logger.dart';

/// Supabase client singleton for Events feature
class SupabaseEventsClient {
  static const String _tag = 'SupabaseEvents';
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase Events not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Initialize Supabase for Events
  static Future<void> initialize() async {
    try {
      if (!EnvConfig.isEventsConfigured) {
        Logger.w(_tag, 'Supabase Events credentials not configured');
        return;
      }

      _client = SupabaseClient(
        EnvConfig.supabaseEventsUrl,
        EnvConfig.supabaseEventsAnonKey,
      );

      Logger.success(_tag, 'Supabase Events initialized');
    } catch (e, stack) {
      Logger.e(_tag, 'Supabase Events initialization failed', e, stack);
      rethrow;
    }
  }

  /// Check if Supabase Events is configured
  static bool get isConfigured => EnvConfig.isEventsConfigured;

  /// Check if Supabase Events is initialized
  static bool get isInitialized => _client != null;
}
