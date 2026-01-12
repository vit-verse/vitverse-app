/// Events cache entity for local storage
class EventsCacheEntity {
  final String id;
  final String source;
  final String title;
  final String description;
  final String category;
  final int eventDate;
  final String venue;
  final String? posterUrl;
  final String? contactInfo;
  final String? eventLink;
  final String? participantType;
  final int entryFee;
  final String teamSize;
  final String userNameRegno;
  final String userEmail;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final bool notifyAll;
  final bool isActive;
  final bool isVerified;
  final int createdAt;
  final int cachedAt;

  EventsCacheEntity({
    required this.id,
    required this.source,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.venue,
    this.posterUrl,
    this.contactInfo,
    this.eventLink,
    this.participantType,
    required this.entryFee,
    required this.teamSize,
    required this.userNameRegno,
    required this.userEmail,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    required this.notifyAll,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.cachedAt,
  });

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_source': source,
      'title': title,
      'description': description,
      'category': category,
      'event_date': eventDate,
      'venue': venue,
      'poster_url': posterUrl,
      'contact_info': contactInfo,
      'event_link': eventLink,
      'participant_type': participantType,
      'entry_fee': entryFee,
      'team_size': teamSize,
      'user_name_regno': userNameRegno,
      'user_email': userEmail,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked_by_me': isLikedByMe ? 1 : 0,
      'notify_all': notifyAll ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt,
      'cached_at': cachedAt,
    };
  }

  /// Create from Map
  factory EventsCacheEntity.fromMap(Map<String, dynamic> map) {
    return EventsCacheEntity(
      id: map['id'] as String,
      source: map['event_source'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      eventDate: map['event_date'] as int,
      venue: map['venue'] as String,
      posterUrl: map['poster_url'] as String?,
      contactInfo: map['contact_info'] as String?,
      eventLink: map['event_link'] as String?,
      participantType: map['participant_type'] as String?,
      entryFee: map['entry_fee'] as int? ?? 0,
      teamSize: map['team_size'] as String? ?? '1',
      userNameRegno: map['user_name_regno'] as String,
      userEmail: map['user_email'] as String,
      likesCount: map['likes_count'] as int,
      commentsCount: map['comments_count'] as int,
      isLikedByMe: (map['is_liked_by_me'] as int) == 1,
      notifyAll: (map['notify_all'] as int) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      cachedAt: map['cached_at'] as int,
    );
  }

  /// Copy with
  EventsCacheEntity copyWith({
    String? id,
    String? source,
    String? title,
    String? description,
    String? category,
    int? eventDate,
    String? venue,
    String? posterUrl,
    String? contactInfo,
    String? eventLink,
    String? participantType,
    int? entryFee,
    String? teamSize,
    String? userNameRegno,
    String? userEmail,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    bool? notifyAll,
    bool? isActive,
    bool? isVerified,
    int? createdAt,
    int? cachedAt,
  }) {
    return EventsCacheEntity(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      posterUrl: posterUrl ?? this.posterUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      eventLink: eventLink ?? this.eventLink,
      participantType: participantType ?? this.participantType,
      entryFee: entryFee ?? this.entryFee,
      teamSize: teamSize ?? this.teamSize,
      userNameRegno: userNameRegno ?? this.userNameRegno,
      userEmail: userEmail ?? this.userEmail,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      notifyAll: notifyAll ?? this.notifyAll,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
