/// Model for Mess Menu Items
class MessMenuItem {
  final int id;
  final String day;
  final String breakfast;
  final String lunch;
  final String snacks;
  final String dinner;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessMenuItem({
    required this.id,
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessMenuItem.fromJson(Map<String, dynamic> json) {
    return MessMenuItem(
      id: json['Id'] as int? ?? 0,
      day: json['Day'] as String? ?? '',
      breakfast: json['Breakfast'] as String? ?? '',
      lunch: json['Lunch'] as String? ?? '',
      snacks: json['Snacks'] as String? ?? '',
      dinner: json['Dinner'] as String? ?? '',
      createdAt: _parseDateTime(json['CreatedAt']),
      updatedAt: _parseDateTime(json['UpdatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) {
        // Handle format: "2025-09-11 20:25:53+05:30"
        final cleanValue = value.replaceAll(RegExp(r'[+\-]\d{2}:\d{2}$'), '');
        return DateTime.parse(cleanValue);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Day': day,
      'Breakfast': breakfast,
      'Lunch': lunch,
      'Snacks': snacks,
      'Dinner': dinner,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get the day number (0 = Monday, 6 = Sunday)
  int get dayNumber {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days.indexOf(day);
  }

  /// Get first letter of day for circle display
  String get dayInitial {
    return day.isNotEmpty ? day[0].toUpperCase() : '';
  }
}

/// Container for mess menu response
class MessMenuResponse {
  final List<MessMenuItem> items;

  MessMenuResponse({required this.items});

  factory MessMenuResponse.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? [];
    return MessMenuResponse(
      items:
          list
              .map(
                (item) => MessMenuItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'list': items.map((item) => item.toJson()).toList()};
  }
}
