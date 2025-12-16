import 'package:html/parser.dart' as html_parser;
import '../../../../../core/utils/logger.dart';
import '../models/event_model.dart';

class EventHubParser {
  static const String _tag = 'EventHubParser';

  static List<Event> parseEvents(String htmlString) {
    try {
      final document = html_parser.parse(htmlString);
      final eventCards = document.querySelectorAll(
        'form #events .col-lg-4 .card',
      );

      final events = <Event>[];
      for (var card in eventCards) {
        try {
          final event = Event.fromHtmlElement(card);
          if (event.id != '0' && event.title != 'Error Parsing Event') {
            events.add(event);
          }
        } catch (e) {
          Logger.w(_tag, 'Skipped malformed event card');
          continue;
        }
      }

      Logger.i(_tag, 'Parsed ${events.length} events');
      return events;
    } catch (e) {
      Logger.e(_tag, 'HTML parse failed', e);
      return [];
    }
  }

  static bool isValidHtml(String htmlString) {
    try {
      final document = html_parser.parse(htmlString);
      final eventsSection = document.querySelector('form #events');

      if (eventsSection == null) return false;

      final eventCards = document.querySelectorAll(
        'form #events .col-lg-4 .card',
      );
      return eventCards.isNotEmpty;
    } catch (e) {
      Logger.e(_tag, 'HTML validation failed', e);
      return false;
    }
  }
}
