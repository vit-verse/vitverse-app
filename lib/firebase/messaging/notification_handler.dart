import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../features/features/vitconnect_services/events/logic/events_provider.dart';
import '../../features/features/vitconnect_services/events/presentation/event_detail_page.dart';
import '../../features/features/vitconnect_services/events/models/event_model.dart';
import '../../features/features/vitconnect_services/events/data/events_repository.dart';
import '../../features/features/vitconnect_services/events/data/events_vitverse_service.dart';
import '../../supabase/core/supabase_events_client.dart';
import '../../core/database_vitverse/database.dart';

/// Handles navigation from FCM notifications
class NotificationHandler {
  static const String _tag = 'NotificationHandler';

  /// Handle notification tap and navigate to appropriate screen
  static Future<void> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.d(_tag, 'Handling notification: $data');

      // Handle link action button
      if (data['action'] == 'open_link') {
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) {
          await _launchURL(url);
        }
        return;
      }

      final type = data['type'] as String?;

      if (type == 'event') {
        await _handleEventNotification(context, data);
      } else {
        Logger.w(_tag, 'Unknown notification type: $type');
      }
    } catch (e, stack) {
      Logger.e(_tag, 'Failed to handle notification', e, stack);
    }
  }

  /// Launch URL in external browser
  static Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.d(_tag, 'Launched URL: $url');
      } else {
        Logger.e(_tag, 'Could not launch URL: $url');
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to launch URL: $url', e);
    }
  }

  /// Handle event notification - navigate to event detail page
  static Future<void> _handleEventNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      final eventId = data['eventId'] as String?;

      if (eventId == null || eventId.isEmpty) {
        Logger.e(_tag, 'Event notification missing eventId');
        return;
      }

      Logger.d(_tag, 'Opening event: $eventId');

      // Create EventsProvider instance
      final eventsProvider = EventsProvider(
        EventsRepository(
          SupabaseEventsClient.client,
          EventsVitverseService(VitVerseDatabase.instance),
        ),
      );

      // Load events
      await eventsProvider.loadEvents();

      // Try to find event in loaded events
      Event? event = eventsProvider.events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => _createPlaceholderEvent(eventId, data),
      );

      // Navigate to event detail page
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    EventDetailPage(event: event, provider: eventsProvider),
          ),
        );
      }
    } catch (e, stack) {
      Logger.e(_tag, 'Failed to handle event notification', e, stack);
    }
  }

  /// Create a placeholder event from notification data
  /// Used when event is not yet loaded in provider
  static Event _createPlaceholderEvent(
    String eventId,
    Map<String, dynamic> data,
  ) {
    return Event(
      id: eventId,
      title: 'Loading Event...',
      description: 'Please wait while we load the event details.',
      venue: data['venue'] as String? ?? 'TBA',
      eventDate: DateTime.now(),
      category: data['category'] as String? ?? 'General',
      posterUrl: null,
      source: 'official',
      isVerified: false,
      likesCount: 0,
      commentsCount: 0,
      isLikedByMe: false,
      eventLink: data['eventLink'] as String?,
    );
  }
}
