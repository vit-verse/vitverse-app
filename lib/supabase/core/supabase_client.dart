import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

/// Supabase client singleton
class SupabaseClientService {
  static const String _tag = 'Supabase';
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
        Logger.w(_tag, 'Supabase credentials not configured');
        return;
      }

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      Logger.success(_tag, 'Supabase initialized');
    } catch (e, stack) {
      Logger.e(_tag, 'Supabase initialization failed', e, stack);
      rethrow;
    }
  }

  /// Check if Supabase is configured
  static bool get isConfigured {
    return AppConfig.supabaseUrl.isNotEmpty &&
        AppConfig.supabaseAnonKey.isNotEmpty;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;
}
