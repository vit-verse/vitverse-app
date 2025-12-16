import 'package:html/dom.dart' as dom;
import '../eventhub_constants.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String venue;
  final String participantType;
  final String category;
  final int fee;
  final String teamSize;
  final String clubId;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.venue,
    required this.participantType,
    required this.category,
    required this.fee,
    required this.teamSize,
    required this.clubId,
  });

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    return !eventDay.isBefore(today);
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    final eventDay = DateTime(date.year, date.month, date.day);
    return !eventDay.isBefore(today) && eventDay.isBefore(nextWeek);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  String get formattedDate {
    return '${EventHubConstants.monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get formattedDateWithDay {
    final dayName = EventHubConstants.dayNames[date.weekday - 1];
    return '${EventHubConstants.monthNames[date.month - 1]} ${date.day}, ${date.year} ($dayName)';
  }

  bool get isTeamEvent {
    return teamSize.contains('-') || teamSize.contains('team');
  }

  String get teamSizeDisplay {
    if (teamSize.contains('-')) {
      return '$teamSize members';
    }
    return teamSize == '1' ? 'Individual' : '$teamSize members';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'venue': venue,
      'participantType': participantType,
      'category': category,
      'fee': fee,
      'teamSize': teamSize,
      'clubId': clubId,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      venue: json['venue'] as String,
      participantType: json['participantType'] as String,
      category: json['category'] as String,
      fee: json['fee'] as int,
      teamSize: json['teamSize'] as String,
      clubId: json['clubId'] as String,
    );
  }

  factory Event.fromHtmlElement(dom.Element cardElement) {
    try {
      final titleElement = cardElement.querySelector('.card-title span');
      final title = titleElement?.text.trim() ?? 'Unknown Event';

      String participantType = 'Unknown';
      final participantIcon = cardElement.querySelector(
        '.fa-user-check, .fa-people-carry-box',
      );
      if (participantIcon != null && participantIcon.parent != null) {
        final participantSpan = participantIcon.parent!.querySelector('span');
        if (participantSpan != null) {
          participantType = participantSpan.text.trim();
        }
      }

      String category = 'General';
      final allDivs = cardElement.querySelectorAll('div');
      for (var div in allDivs) {
        final divText = div.text.trim();
        if (divText.startsWith('(') && divText.endsWith(')')) {
          final spanInDiv = div.querySelector('span');
          if (spanInDiv != null) {
            category = spanInDiv.text.trim();
            break;
          } else {
            category = divText.substring(1, divText.length - 1);
            break;
          }
        }
      }

      final dateSpan =
          cardElement.querySelector('.fa-calendar-days')?.nextElementSibling;
      final dateStr = dateSpan?.text.trim() ?? '';
      DateTime eventDate = DateTime.now();
      try {
        eventDate = DateTime.parse(dateStr);
      } catch (e) {
        eventDate = DateTime.now();
      }

      final venueSpan =
          cardElement.querySelector('.fa-map-location-dot')?.nextElementSibling;
      final venue = venueSpan?.text.trim() ?? 'TBA';

      final feeSpan =
          cardElement
              .querySelector('.fa-indian-rupee-sign')
              ?.nextElementSibling;
      final feeStr = feeSpan?.text.trim() ?? '0';
      int fee = 0;
      try {
        fee = int.parse(feeStr);
      } catch (e) {
        fee = 0;
      }

      final teamIcon = cardElement.querySelector('.fa-street-view, .fa-users');
      String teamSize = '1';
      if (teamIcon != null && teamIcon.parent != null) {
        final teamSpans = teamIcon.parent!.querySelectorAll('span');
        if (teamSpans.isNotEmpty) {
          if (teamSpans.length > 1) {
            final min = teamSpans[0].text.trim();
            final max = teamSpans[1].text.trim();
            teamSize = '$min-$max';
          } else {
            teamSize = teamSpans[0].text.trim();
          }
        }
      }

      final buttonElement = cardElement.querySelector('button[name="eid"]');
      final eventId = buttonElement?.attributes['value'] ?? '0';
      final clubId = category;

      return Event(
        id: eventId,
        title: title,
        date: eventDate,
        venue: venue,
        participantType: participantType,
        category: category,
        fee: fee,
        teamSize: teamSize,
        clubId: clubId,
      );
    } catch (e) {
      return Event(
        id: '0',
        title: 'Error Parsing Event',
        date: DateTime.now(),
        venue: 'Unknown',
        participantType: 'Unknown',
        category: 'Unknown',
        fee: 0,
        teamSize: '1',
        clubId: 'unknown',
      );
    }
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, date: $date, venue: $venue}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
