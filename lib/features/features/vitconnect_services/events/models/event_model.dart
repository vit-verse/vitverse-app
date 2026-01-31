class Event {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String category;
  final DateTime eventDate;
  final String source;
  final String? participantType;
  final int entryFee;
  final String teamSize;
  final String? posterUrl;
  final String? contactInfo;
  final String? eventLink;
  final String? userId;
  final String? userNameRegno;
  final String? userEmail;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLikedByMe;
  final int likesCount;
  final int commentsCount;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.category,
    required this.eventDate,
    required this.source,
    this.participantType,
    this.entryFee = 0,
    this.teamSize = '1',
    this.posterUrl,
    this.contactInfo,
    this.eventLink,
    this.userId,
    this.userNameRegno,
    this.userEmail,
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
    this.isLikedByMe = false,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      venue: json['venue'] as String,
      category: json['category'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      source: json['source'] as String,
      participantType: json['participant_type'] as String?,
      entryFee: json['entry_fee'] as int? ?? 0,
      teamSize: json['team_size'] as String? ?? '1',
      posterUrl: json['poster_url'] as String?,
      contactInfo: json['contact_info'] as String?,
      eventLink: json['event_link'] as String?,
      userId: json['user_id'] as String?,
      userNameRegno: json['user_name_regno'] as String?,
      userEmail: json['user_email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      isLikedByMe: false,
      likesCount: 0,
      commentsCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'category': category,
      'event_date': eventDate.toIso8601String(),
      'source': source,
      'participant_type': participantType,
      'entry_fee': entryFee,
      'team_size': teamSize,
      'poster_url': posterUrl,
      'contact_info': contactInfo,
      'event_link': eventLink,
      'user_id': userId,
      'user_name_regno': userNameRegno,
      'user_email': userEmail,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? venue,
    String? category,
    DateTime? eventDate,
    String? source,
    String? participantType,
    int? entryFee,
    String? teamSize,
    String? posterUrl,
    String? contactInfo,
    String? eventLink,
    String? userId,
    String? userNameRegno,
    String? userEmail,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLikedByMe,
    int? likesCount,
    int? commentsCount,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      source: source ?? this.source,
      participantType: participantType ?? this.participantType,
      entryFee: entryFee ?? this.entryFee,
      teamSize: teamSize ?? this.teamSize,
      posterUrl: posterUrl ?? this.posterUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      eventLink: eventLink ?? this.eventLink,
      userId: userId ?? this.userId,
      userNameRegno: userNameRegno ?? this.userNameRegno,
      userEmail: userEmail ?? this.userEmail,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  bool get isOfficial => source == 'official';

  String get formattedEntryFee => entryFee == 0 ? 'FREE' : '$entryFee';

  String get formattedDate {
    final day = eventDate.day;
    final month = _monthNames[eventDate.month - 1];
    final year = eventDate.year;
    return '$day $month $year';
  }

  String get formattedTime {
    final hour = eventDate.hour;
    final minute = eventDate.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static const _monthNames = [
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
}
