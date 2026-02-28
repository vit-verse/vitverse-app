// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../core/config/env_config.dart';
// import '../../core/utils/logger.dart';

// /// Supabase client singleton for Events feature
// class SupabaseEventsClient {
//   static const String _tag = 'SupabaseEvents';
//   static SupabaseClient? _client;

//   static SupabaseClient get client {
//     if (_client == null) {
//       throw StateError(
//         'Supabase Events not initialized. Call initialize() first.',
//       );
//     }
//     return _client!;
//   }

//   /// Initialize Supabase for Events
//   static Future<void> initialize() async {
//     try {
//       if (!EnvConfig.isEventsConfigured) {
//         Logger.w(_tag, 'Supabase Events credentials not configured');
//         return;
//       }

//       _client = SupabaseClient(
//         EnvConfig.supabaseEventsUrl,
//         EnvConfig.supabaseEventsAnonKey,
//       );

//       Logger.success(_tag, 'Supabase Events initialized');
//     } catch (e, stack) {
//       Logger.e(_tag, 'Supabase Events initialization failed', e, stack);
//       rethrow;
//     }
//   }

//   /// Check if Supabase Events is configured
//   static bool get isConfigured => EnvConfig.isEventsConfigured;

//   /// Check if Supabase Events is initialized
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
import '../../core/config/env_config.dart';
import '../../core/utils/logger.dart';

class SupabaseEventsClient {
  static const String _tag = 'SupabaseEvents';
  static SupabaseClient? _client;
  static String? _activeUrl;

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase Events not initialized.');
    }
    return _client!;
  }

  static const String _primary = 'https://isonblfadkvfrwekzohx.supabase.co';

  static const String _fallback = 'https://isonblfadkvfrwekzohx.jiobase.com';

  static Future<void> initialize() async {
    try {
      final url = await _resolveEndpoint();

      _client = SupabaseClient(url, EnvConfig.supabaseEventsAnonKey);

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
  static bool get isConfigured => EnvConfig.supabaseEventsAnonKey.isNotEmpty;

  // Check if initialized
  static bool get isInitialized => _client != null;
}
