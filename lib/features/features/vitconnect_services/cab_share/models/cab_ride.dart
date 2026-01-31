/// Cab Share Ride model
class CabRide {
  final String id;
  final String fromLocation;
  final String toLocation;
  final DateTime travelDate;
  final String travelTime; // e.g., "10:30 AM"
  final String cabType; // e.g., "Sedan", "SUV", "Mini", "Auto"
  final int seatsAvailable;
  final String contactNumber;
  final String? description;
  final String postedByName;
  final String postedByRegno;
  final DateTime createdAt;

  CabRide({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.travelDate,
    required this.travelTime,
    required this.cabType,
    required this.seatsAvailable,
    required this.contactNumber,
    this.description,
    required this.postedByName,
    required this.postedByRegno,
    required this.createdAt,
  });

  /// Create from Supabase response
  factory CabRide.fromMap(Map<String, dynamic> map) {
    return CabRide(
      id: map['id'] as String,
      fromLocation: map['from_location'] as String,
      toLocation: map['to_location'] as String,
      travelDate: DateTime.parse(map['travel_date'] as String),
      travelTime: map['travel_time'] as String,
      cabType: map['cab_type'] as String,
      seatsAvailable: map['seats_available'] as int,
      contactNumber: map['contact_number'] as String,
      description: map['description'] as String?,
      postedByName: map['posted_by_name'] as String,
      postedByRegno: map['posted_by_regno'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to Map for local cache
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_location': fromLocation,
      'to_location': toLocation,
      'travel_date': travelDate.toIso8601String(),
      'travel_time': travelTime,
      'cab_type': cabType,
      'seats_available': seatsAvailable,
      'contact_number': contactNumber,
      'description': description,
      'posted_by_name': postedByName,
      'posted_by_regno': postedByRegno,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get formatted date string
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${travelDate.day} ${months[travelDate.month - 1]} ${travelDate.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    return travelTime;
  }

  /// Get date key for grouping (YYYY-MM-DD)
  String get dateKey {
    return '${travelDate.year}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}';
  }

  /// Check if ride is in the past
  bool get isPastRide {
    final now = DateTime.now();
    final rideDateTime = DateTime(
      travelDate.year,
      travelDate.month,
      travelDate.day,
    );
    return rideDateTime.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Copy with method
  CabRide copyWith({
    String? id,
    String? fromLocation,
    String? toLocation,
    DateTime? travelDate,
    String? travelTime,
    String? cabType,
    int? seatsAvailable,
    String? contactNumber,
    String? description,
    String? postedByName,
    String? postedByRegno,
    DateTime? createdAt,
  }) {
    return CabRide(
      id: id ?? this.id,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      travelDate: travelDate ?? this.travelDate,
      travelTime: travelTime ?? this.travelTime,
      cabType: cabType ?? this.cabType,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      contactNumber: contactNumber ?? this.contactNumber,
      description: description ?? this.description,
      postedByName: postedByName ?? this.postedByName,
      postedByRegno: postedByRegno ?? this.postedByRegno,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
