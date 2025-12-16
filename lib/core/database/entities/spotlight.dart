/// Spotlight entity representing university announcements and notices
/// Maps to the 'spotlight' table in the database
/// Independent entity with duplicate detection
/// TODO: VTOP changed endpoint for spotlight, need to fix that (Priority LOW)
class Spotlight {
  final int? id;
  final String? announcement;
  final String? category;
  final String? link;
  final bool? isRead;
  final int? signature;

  const Spotlight({
    this.id,
    this.announcement,
    this.category,
    this.link,
    this.isRead,
    this.signature,
  });

  /// Create Spotlight from database map
  factory Spotlight.fromMap(Map<String, dynamic> map) {
    return Spotlight(
      id: map['id'] as int?,
      announcement: map['announcement'] as String?,
      category: map['category'] as String?,
      link: map['link'] as String?,
      isRead: map['is_read'] == 1,
      signature: map['signature'] as int?,
    );
  }

  /// Convert Spotlight to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'announcement': announcement,
      'category': category,
      'link': link,
      'is_read': isRead == true ? 1 : 0,
      'signature': signature,
    };
  }

  /// Generate signature for duplicate detection
  static int generateSignature(List<String> values) {
    final combined = values.join('|');
    return combined.hashCode;
  }

  /// Check if announcement has a link
  bool get hasLink {
    return link != null && link!.isNotEmpty;
  }

  /// Create copy with updated fields
  Spotlight copyWith({
    int? id,
    String? announcement,
    String? category,
    String? link,
    bool? isRead,
    int? signature,
  }) {
    return Spotlight(
      id: id ?? this.id,
      announcement: announcement ?? this.announcement,
      category: category ?? this.category,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      signature: signature ?? this.signature,
    );
  }

  @override
  String toString() {
    return 'Spotlight{id: $id, announcement: $announcement, category: $category, link: $link, isRead: $isRead, signature: $signature}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spotlight &&
        other.id == id &&
        other.announcement == announcement &&
        other.category == category &&
        other.link == link &&
        other.isRead == isRead &&
        other.signature == signature;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        announcement.hashCode ^
        category.hashCode ^
        link.hashCode ^
        isRead.hashCode ^
        signature.hashCode;
  }
}
