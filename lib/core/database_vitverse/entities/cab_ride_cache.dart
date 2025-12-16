/// Cab Share cache entity for local storage
class CabRideCacheEntity {
  final String id;
  final String fromLocation;
  final String toLocation;
  final int travelDate; // Unix timestamp (date only)
  final String travelTime;
  final String cabType;
  final int seatsAvailable;
  final String contactNumber;
  final String? description;
  final String postedByName;
  final String postedByRegno;
  final int createdAt; // Unix timestamp
  final int cachedAt; // Unix timestamp

  CabRideCacheEntity({
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
    required this.cachedAt,
  });

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_location': fromLocation,
      'to_location': toLocation,
      'travel_date': travelDate,
      'travel_time': travelTime,
      'cab_type': cabType,
      'seats_available': seatsAvailable,
      'contact_number': contactNumber,
      'description': description,
      'posted_by_name': postedByName,
      'posted_by_regno': postedByRegno,
      'created_at': createdAt,
      'cached_at': cachedAt,
    };
  }

  /// Create from SQLite Map
  factory CabRideCacheEntity.fromMap(Map<String, dynamic> map) {
    return CabRideCacheEntity(
      id: map['id'] as String,
      fromLocation: map['from_location'] as String,
      toLocation: map['to_location'] as String,
      travelDate: map['travel_date'] as int,
      travelTime: map['travel_time'] as String,
      cabType: map['cab_type'] as String,
      seatsAvailable: map['seats_available'] as int,
      contactNumber: map['contact_number'] as String,
      description: map['description'] as String?,
      postedByName: map['posted_by_name'] as String,
      postedByRegno: map['posted_by_regno'] as String,
      createdAt: map['created_at'] as int,
      cachedAt: map['cached_at'] as int,
    );
  }
}
