// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../core/config/app_config.dart';
// import '../../core/utils/logger.dart';

// /// Supabase client singleton
// class SupabaseClientService {
//   static const String _tag = 'Supabase';
//   static SupabaseClient? _client;

//   static SupabaseClient get client {
//     if (_client == null) {
//       throw StateError('Supabase not initialized. Call initialize() first.');
//     }
//     return _client!;
//   }

//   /// Initialize Supabase
//   static Future<void> initialize() async {
//     try {
//       if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
//         Logger.w(_tag, 'Supabase credentials not configured');
//         return;
//       }

//       await Supabase.initialize(
//         url: AppConfig.supabaseUrl,
//         anonKey: AppConfig.supabaseAnonKey,
//       );

//       _client = Supabase.instance.client;
//       Logger.success(_tag, 'Supabase initialized');
//     } catch (e, stack) {
//       Logger.e(_tag, 'Supabase initialization failed', e, stack);
//       rethrow;
//     }
//   }

//   /// Check if Supabase is configured
//   static bool get isConfigured {
//     return AppConfig.supabaseUrl.isNotEmpty &&
//         AppConfig.supabaseAnonKey.isNotEmpty;
//   }

//   /// Check if Supabase is initialized
//   static bool get isInitialized => _client != null;
// }

/// ---------------------------------------------------------------------------
/// Date: 28 Feb 2026
/// Issue: Intermittent DNS resolution failures in India for *.supabase.co
///        (ISP-level resolver issues causing random connection failures).
/// Fix: Implemented primary + fallback endpoint logic using Jiobase proxy.
///      App now tries Supabase primary first and switches to proxy on failure.
/// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

class SupabaseClientService {
  static const String _tag = 'Supabase';
  static SupabaseClient? _client;
  static String? _activeUrl;

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static const String _primary = 'https://nptyxmthlvqnoricblhf.supabase.co';

  static const String _fallback = 'https://nptyxmthlvqnoricblhf.jiobase.com';

  static Future<void> initialize() async {
    try {
      final url = await _resolveEndpoint();

      await Supabase.initialize(url: url, anonKey: AppConfig.supabaseAnonKey);

      _client = Supabase.instance.client;
      _activeUrl = url;

      Logger.success(_tag, 'Initialized using: $url');
    } catch (e, stack) {
      Logger.e(_tag, 'Initialization failed', e, stack);
      rethrow;
    }
  }

  static Future<String> _resolveEndpoint() async {
    if (_activeUrl != null) return _activeUrl!;

    try {
      final response = await http
          .head(Uri.parse('$_primary/rest/v1/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 500) {
        return _primary;
      }
    } catch (_) {
      Logger.w(_tag, 'Primary failed, switching to fallback');
    }

    return _fallback;
  }

  // Check if configured
  static bool get isConfigured => AppConfig.supabaseAnonKey.isNotEmpty;

  // Check if initialized
  static bool get isInitialized => _client != null;
}
