/// Represents a single class slot for a friend's timetable
/// Contains course info, timing, and venue details
class FriendClassSlot {
  final String day; // Monday, Tuesday, etc.
  final String timeSlot; // e.g., "08:00-08:50"
  final String courseCode;
  final String courseTitle;
  final String venue;
  final String slotId; // e.g., "A1", "B1", etc.

  const FriendClassSlot({
    required this.day,
    required this.timeSlot,
    required this.courseCode,
    required this.courseTitle,
    required this.venue,
    required this.slotId,
  });

  /// Create cell ID for matrix positioning (day + timeSlot)
  String get cellId => '${day}_$timeSlot';

  /// Create FriendClassSlot from JSON
  factory FriendClassSlot.fromJson(Map<String, dynamic> json) {
    return FriendClassSlot(
      day: json['day'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      slotId: json['slotId'] as String? ?? '',
    );
  }

  /// Convert FriendClassSlot to JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'timeSlot': timeSlot,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'venue': venue,
      'slotId': slotId,
    };
  }

  /// Create compact string for QR code
  String toCompactString() {
    return '$day|$timeSlot|$courseCode|$courseTitle|$venue|$slotId';
  }

  /// Parse from compact string
  factory FriendClassSlot.fromCompactString(String str) {
    final parts = str.split('|');
    if (parts.length != 6) {
      throw FormatException('Invalid compact string format');
    }
    return FriendClassSlot(
      day: parts[0],
      timeSlot: parts[1],
      courseCode: parts[2],
      courseTitle: parts[3],
      venue: parts[4],
      slotId: parts[5],
    );
  }

  @override
  String toString() {
    return 'FriendClassSlot{$courseCode at $timeSlot on $day in $venue}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendClassSlot &&
        other.day == day &&
        other.timeSlot == timeSlot &&
        other.courseCode == courseCode &&
        other.venue == venue;
  }

  @override
  int get hashCode {
    return day.hashCode ^
        timeSlot.hashCode ^
        courseCode.hashCode ^
        venue.hashCode;
  }
}
