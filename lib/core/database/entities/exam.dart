/// Exam entity representing exam schedule with dates, venues, and seating
/// Maps to the 'exams' table in the database
/// Child of Course with CASCADE delete
class Exam {
  final int? id;
  final int? courseId;
  final String? title;
  final int? startTime; // Unix timestamp
  final int? endTime; // Unix timestamp
  final String? venue;
  final String? seatLocation;
  final int? seatNumber;

  const Exam({
    this.id,
    this.courseId,
    this.title,
    this.startTime,
    this.endTime,
    this.venue,
    this.seatLocation,
    this.seatNumber,
  });

  /// Create Exam from database map
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      courseId: map['course_id'] as int?,
      title: map['title'] as String?,
      startTime: map['start_time'] as int?,
      endTime: map['end_time'] as int?,
      venue: map['venue'] as String?,
      seatLocation: map['seat_location'] as String?,
      seatNumber: map['seat_number'] as int?,
    );
  }

  /// Convert Exam to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'venue': venue,
      'seat_location': seatLocation,
      'seat_number': seatNumber,
    };
  }

  /// Get exam start date
  DateTime? get startDate {
    if (startTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(startTime!);
  }

  /// Get exam end date
  DateTime? get endDate {
    if (endTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(endTime!);
  }

  /// Check if exam is upcoming (within next 7 days)
  bool get isUpcoming {
    final start = startDate;
    if (start == null) return false;
    final now = DateTime.now();
    final difference = start.difference(now);
    return difference.inDays >= 0 && difference.inDays <= 7;
  }

  /// Create copy with updated fields
  Exam copyWith({
    int? id,
    int? courseId,
    String? title,
    int? startTime,
    int? endTime,
    String? venue,
    String? seatLocation,
    int? seatNumber,
  }) {
    return Exam(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      seatLocation: seatLocation ?? this.seatLocation,
      seatNumber: seatNumber ?? this.seatNumber,
    );
  }

  @override
  String toString() {
    return 'Exam{id: $id, courseId: $courseId, title: $title, startTime: $startTime, endTime: $endTime, venue: $venue, seatLocation: $seatLocation, seatNumber: $seatNumber}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exam &&
        other.id == id &&
        other.courseId == courseId &&
        other.title == title &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.venue == venue &&
        other.seatLocation == seatLocation &&
        other.seatNumber == seatNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        title.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        venue.hashCode ^
        seatLocation.hashCode ^
        seatNumber.hashCode;
  }
}
