import 'package:flutter/material.dart';

/// Calendar event model for VIT academic calendar
class CalendarData {
  final String lastUpdated;
  final String lastUpdatedISO;
  final String semester;
  final String classGroup;
  final Map<String, MonthData> months;

  const CalendarData({
    required this.lastUpdated,
    required this.lastUpdatedISO,
    required this.semester,
    required this.classGroup,
    required this.months,
  });

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    final monthsMap = <String, MonthData>{};
    final months = json['months'] as Map<String, dynamic>? ?? {};

    for (final entry in months.entries) {
      monthsMap[entry.key] = MonthData.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return CalendarData(
      lastUpdated: json['lastUpdated'] ?? '',
      lastUpdatedISO: json['lastUpdatedISO'] ?? '',
      semester: json['semester'] ?? '',
      classGroup: json['classGroup'] ?? '',
      months: monthsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated,
      'lastUpdatedISO': lastUpdatedISO,
      'semester': semester,
      'classGroup': classGroup,
      'months': months.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class MonthData {
  final String date;
  final EventsData events;

  const MonthData({required this.date, required this.events});

  factory MonthData.fromJson(Map<String, dynamic> json) {
    return MonthData(
      date: json['date'] ?? '',
      events: EventsData.fromJson(
        json['events'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'events': events.toJson()};
  }
}

class EventsData {
  final List<DayEvent> days;

  const EventsData({required this.days});

  factory EventsData.fromJson(Map<String, dynamic> json) {
    return EventsData(
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => DayEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'days': days.map((e) => e.toJson()).toList()};
  }
}

class DayEvent {
  final int date;
  final List<Event> events;

  const DayEvent({required this.date, required this.events});

  factory DayEvent.fromJson(Map<String, dynamic> json) {
    return DayEvent(
      date: json['date'] ?? 0,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'events': events.map((e) => e.toJson()).toList()};
  }
}

class Event {
  final String category;
  final String description;
  final String text;

  const Event({
    required this.category,
    required this.description,
    required this.text,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'description': description, 'text': text};
  }

  /// Get color based on event text
  bool get isInstructionalDay =>
      text.toLowerCase().contains('instructional day') &&
      !text.toLowerCase().contains('no instructional day');
  bool get isHoliday =>
      text.toLowerCase().contains('no instructional day') ||
      text.toLowerCase().contains('holiday');
}

/// Personal ICS calendar model
class PersonalCalendar {
  final String id;
  final String name;
  final String url;
  final DateTime lastSynced;
  final bool isEnabled;

  const PersonalCalendar({
    required this.id,
    required this.name,
    required this.url,
    required this.lastSynced,
    required this.isEnabled,
  });

  factory PersonalCalendar.fromJson(Map<String, dynamic> json) {
    return PersonalCalendar(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      lastSynced: DateTime.parse(
        json['lastSynced'] ?? DateTime.now().toIso8601String(),
      ),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'lastSynced': lastSynced.toIso8601String(),
      'isEnabled': isEnabled,
    };
  }
}

/// Personal calendar event model
class PersonalEvent {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final TimeOfDay? time;
  final bool hasNotification;
  final int? notificationMinutes;
  final DateTime createdAt;

  const PersonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    this.time,
    required this.hasNotification,
    this.notificationMinutes,
    required this.createdAt,
  });

  factory PersonalEvent.fromJson(Map<String, dynamic> json) {
    return PersonalEvent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time:
          json['time'] != null
              ? TimeOfDay(
                hour: json['time']['hour'] ?? 0,
                minute: json['time']['minute'] ?? 0,
              )
              : null,
      hasNotification: json['hasNotification'] ?? false,
      notificationMinutes: json['notificationMinutes'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'time':
          time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'hasNotification': hasNotification,
      'notificationMinutes': notificationMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Event for display
  Event toEvent() {
    return Event(category: 'Personal', description: description, text: name);
  }

  /// Get notification time
  DateTime? get notificationTime {
    if (!hasNotification || notificationMinutes == null) {
      return null;
    }

    // If no time is set, use the date at 9 AM
    final eventDateTime =
        time != null
            ? DateTime(
              date.year,
              date.month,
              date.day,
              time!.hour,
              time!.minute,
            )
            : DateTime(
              date.year,
              date.month,
              date.day,
              9, // Default to 9 AM if no time is set
              0,
            );

    return eventDateTime.subtract(Duration(minutes: notificationMinutes!));
  }
}
