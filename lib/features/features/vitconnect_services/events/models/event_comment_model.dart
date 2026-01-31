class EventComment {
  final String id;
  final String eventId;
  final String eventSource;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  const EventComment({
    required this.id,
    required this.eventId,
    required this.eventSource,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      eventSource: json['event_source'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'event_source': eventSource,
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
