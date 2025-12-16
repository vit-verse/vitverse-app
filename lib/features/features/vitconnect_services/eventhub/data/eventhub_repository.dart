import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../authentication/core/user_agent_service.dart';
import '../../../../../core/utils/logger.dart';
import '../models/event_model.dart';
import '../eventhub_constants.dart';
import 'eventhub_parser.dart';

class EventHubRepository {
  static const String _tag = 'EventHubRepository';

  static Future<List<Event>> fetchEventsFromNetwork() async {
    try {
      Logger.d(_tag, 'Fetching events from network');

      final userAgent =
          await UserAgentService.instance.getAuthorizedUserAgent();

      final httpClient =
          HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) =>
                    host == 'eventhubcc.vit.ac.in';
      final ioClient = IOClient(httpClient);

      final response = await ioClient
          .get(
            Uri.parse(
              '${EventHubConstants.baseUrl}${EventHubConstants.eventsEndpoint}',
            ),
            headers: {'User-Agent': userAgent},
          )
          .timeout(Duration(seconds: EventHubConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final htmlString = response.body;
        ioClient.close();

        if (!EventHubParser.isValidHtml(htmlString)) {
          Logger.w(_tag, 'Invalid HTML response');
          throw Exception('Invalid HTML response from EventHub');
        }

        final events = EventHubParser.parseEvents(htmlString);
        Logger.i(_tag, 'Fetched ${events.length} events');
        return events;
      } else {
        ioClient.close();
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      Logger.e(_tag, 'Network fetch failed', e);
      rethrow;
    }
  }

  static Future<void> cacheEvents(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = events.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(EventHubConstants.cacheKey, jsonString);
      await prefs.setString(
        EventHubConstants.timestampKey,
        DateTime.now().toIso8601String(),
      );

      Logger.d(_tag, 'Cached ${events.length} events');
    } catch (e) {
      Logger.e(_tag, 'Cache save failed', e);
    }
  }

  static Future<List<Event>?> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(EventHubConstants.cacheKey);

      if (jsonString == null) {
        Logger.d(_tag, 'No cached events found');
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List;
      final events =
          jsonList
              .map((json) => Event.fromJson(json as Map<String, dynamic>))
              .toList();

      Logger.d(_tag, 'Retrieved ${events.length} cached events');
      return events;
    } catch (e) {
      Logger.e(_tag, 'Cache retrieval failed', e);
      return null;
    }
  }

  static Future<bool> isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(EventHubConstants.timestampKey);

      if (timestampStr == null) return true;

      final lastRefresh = DateTime.parse(timestampStr);
      final expiry = lastRefresh.add(
        Duration(hours: EventHubConstants.cacheExpiryHours),
      );
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      Logger.e(_tag, 'Cache expiry check failed', e);
      return true;
    }
  }

  static Future<DateTime?> getLastRefreshTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(EventHubConstants.timestampKey);
      return timestampStr != null ? DateTime.parse(timestampStr) : null;
    } catch (e) {
      Logger.e(_tag, 'Failed to get refresh time', e);
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(EventHubConstants.cacheKey);
      await prefs.remove(EventHubConstants.timestampKey);
      Logger.i(_tag, 'Cache cleared');
    } catch (e) {
      Logger.e(_tag, 'Cache clear failed', e);
    }
  }

  static Future<List<Event>> loadEvents({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final isCacheExpired = await EventHubRepository.isCacheExpired();

        if (!isCacheExpired) {
          final cachedEvents = await getCachedEvents();
          if (cachedEvents != null && cachedEvents.isNotEmpty) {
            Logger.d(_tag, 'Using cached events');
            return cachedEvents;
          }
        }
      }

      Logger.d(_tag, 'Fetching fresh events');
      final events = await fetchEventsFromNetwork();

      if (events.isNotEmpty) {
        await cacheEvents(events);
      }

      return events;
    } catch (e) {
      Logger.e(_tag, 'Load failed, trying cache fallback', e);

      final cachedEvents = await getCachedEvents();
      if (cachedEvents != null && cachedEvents.isNotEmpty) {
        Logger.i(_tag, 'Using cached fallback');
        return cachedEvents;
      }

      rethrow;
    }
  }
}
