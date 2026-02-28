import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/logger.dart';

class SupabaseEventsClient {
  static const String _tag = 'SupabaseEvents';
  static const String _cachedEndpointKey = 'supabase_events_cached_endpoint';
  static SupabaseClient? _client;
  static String? _activeUrl;

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase Events not initialized.');
    }
    return _client!;
  }

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

    final primary = EnvConfig.supabaseEventsUrl;
    final fallback = EnvConfig.supabaseEventsFallbackUrl;

    final cached = await _getCachedEndpoint();
    if (cached != null) {
      try {
        final response = await http
            .head(Uri.parse('$cached/rest/v1/'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode < 500) return cached;
      } catch (_) {
        Logger.w(_tag, 'Cached endpoint failed, re-resolving');
      }
    }

    try {
      final response = await http
          .head(Uri.parse('$primary/rest/v1/'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 500) {
        _cacheEndpoint(primary);
        return primary;
      }
    } catch (_) {
      Logger.w(_tag, 'Primary failed, switching to fallback');
    }

    _cacheEndpoint(fallback);
    return fallback;
  }

  static Future<String?> _getCachedEndpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cachedEndpointKey);
    } catch (_) {
      return null;
    }
  }

  static void _cacheEndpoint(String url) {
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString(_cachedEndpointKey, url);
        })
        .catchError((_) {});
  }

  static bool get isConfigured => EnvConfig.supabaseEventsAnonKey.isNotEmpty;

  static bool get isInitialized => _client != null;
}
