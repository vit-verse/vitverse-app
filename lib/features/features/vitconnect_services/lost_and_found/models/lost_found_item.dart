/// Lost & Found Item model
class LostFoundItem {
  final String id;
  final String type; // 'lost' or 'found'
  final String itemName;
  final String place;
  final String? description;
  final String contactName;
  final String contactNumber;
  final String postedByName;
  final String postedByRegno;
  final String? imagePath;
  final DateTime createdAt;

  LostFoundItem({
    required this.id,
    required this.type,
    required this.itemName,
    required this.place,
    this.description,
    required this.contactName,
    required this.contactNumber,
    required this.postedByName,
    required this.postedByRegno,
    this.imagePath,
    required this.createdAt,
  });

  /// Create from Supabase response
  factory LostFoundItem.fromMap(Map<String, dynamic> map) {
    return LostFoundItem(
      id: map['id'] as String,
      type: map['type'] as String,
      itemName: map['item_name'] as String,
      place: map['place'] as String,
      description: map['description'] as String?,
      contactName: map['contact_name'] as String,
      contactNumber: map['contact_number'] as String,
      postedByName: map['posted_by_name'] as String,
      postedByRegno: map['posted_by_regno'] as String,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to Map for local cache
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'item_name': itemName,
      'place': place,
      'description': description,
      'contact_name': contactName,
      'contact_number': contactNumber,
      'posted_by_name': postedByName,
      'posted_by_regno': postedByRegno,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if item is lost
  bool get isLost => type == 'lost';

  /// Check if item is found
  bool get isFound => type == 'found';
}
