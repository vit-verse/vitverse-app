/// Model for Laundry Schedule
class LaundrySchedule {
  final int id;
  final String date;
  final String? roomNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  LaundrySchedule({
    required this.id,
    required this.date,
    this.roomNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LaundrySchedule.fromJson(Map<String, dynamic> json) {
    return LaundrySchedule(
      id: json['Id'] as int? ?? 0,
      date: json['Date'] as String? ?? '',
      roomNumber: json['RoomNumber'] as String?,
      createdAt: _parseDateTime(json['CreatedAt']),
      updatedAt: _parseDateTime(json['UpdatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) {
        // Handle format: "2025-10-04 01:32:17+05:30"
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
      'Date': date,
      'RoomNumber': roomNumber,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parse room number range (e.g., "112 - 322" or "323 - 509")
  (int?, int?)? getRoomRange() {
    if (roomNumber == null || roomNumber!.isEmpty) return null;

    final parts = roomNumber!.split('-').map((s) => s.trim()).toList();
    if (parts.length != 2) return null;

    try {
      final start = int.parse(parts[0]);
      final end = int.parse(parts[1]);
      return (start, end);
    } catch (e) {
      return null;
    }
  }

  /// Check if a room number falls within this schedule's range
  bool containsRoom(int roomNum) {
    final range = getRoomRange();
    if (range == null) return false;
    final (start, end) = range;
    if (start == null || end == null) return false;
    return roomNum >= start && roomNum <= end;
  }

  /// Get date as integer for current month calculation
  int get dateNumber {
    try {
      return int.parse(date);
    } catch (e) {
      return 0;
    }
  }

  /// Get display text for room range
  String get roomRangeDisplay {
    if (roomNumber == null || roomNumber!.isEmpty) {
      return 'No laundry scheduled';
    }
    return 'Rooms: $roomNumber';
  }
}

/// Container for laundry schedule response
class LaundryScheduleResponse {
  final List<LaundrySchedule> items;

  LaundryScheduleResponse({required this.items});

  factory LaundryScheduleResponse.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? [];
    return LaundryScheduleResponse(
      items:
          list
              .map(
                (item) =>
                    LaundrySchedule.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'list': items.map((item) => item.toJson()).toList()};
  }
}
