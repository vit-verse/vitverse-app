/// Mark entity representing individual assessment marks and scores
/// Maps to the 'marks' table in the database
/// Child of Course with SET_NULL delete to preserve marks
class Mark {
  final int? id;
  final int? courseId;
  final String? title;
  final double? score;
  final double? maxScore;
  final double? weightage;
  final double? maxWeightage;
  final double? average;
  final String? status;
  final bool? isRead;
  final int? signature;

  const Mark({
    this.id,
    this.courseId,
    this.title,
    this.score,
    this.maxScore,
    this.weightage,
    this.maxWeightage,
    this.average,
    this.status,
    this.isRead,
    this.signature,
  });

  /// Create Mark from database map
  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      id: map['id'] as int?,
      courseId: map['course_id'] as int?,
      title: map['title'] as String?,
      score: map['score'] as double?,
      maxScore: map['max_score'] as double?,
      weightage: map['weightage'] as double?,
      maxWeightage: map['max_weightage'] as double?,
      average: map['average'] as double?,
      status: map['status'] as String?,
      isRead: map['is_read'] == 1,
      signature: map['signature'] as int?,
    );
  }

  /// Convert Mark to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'score': score,
      'max_score': maxScore,
      'weightage': weightage,
      'max_weightage': maxWeightage,
      'average': average,
      'status': status,
      'is_read': isRead == true ? 1 : 0,
      'signature': signature,
    };
  }

  /// Generate signature for duplicate detection
  static int generateSignature(List<String> values) {
    final combined = values.join('|');
    return combined.hashCode;
  }

  /// Create copy with updated fields
  Mark copyWith({
    int? id,
    int? courseId,
    String? title,
    double? score,
    double? maxScore,
    double? weightage,
    double? maxWeightage,
    double? average,
    String? status,
    bool? isRead,
    int? signature,
  }) {
    return Mark(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      weightage: weightage ?? this.weightage,
      maxWeightage: maxWeightage ?? this.maxWeightage,
      average: average ?? this.average,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      signature: signature ?? this.signature,
    );
  }

  @override
  String toString() {
    return 'Mark{id: $id, courseId: $courseId, title: $title, score: $score, maxScore: $maxScore, weightage: $weightage, maxWeightage: $maxWeightage, average: $average, status: $status, isRead: $isRead, signature: $signature}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mark &&
        other.id == id &&
        other.courseId == courseId &&
        other.title == title &&
        other.score == score &&
        other.maxScore == maxScore &&
        other.weightage == weightage &&
        other.maxWeightage == maxWeightage &&
        other.average == average &&
        other.status == status &&
        other.isRead == isRead &&
        other.signature == signature;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        title.hashCode ^
        score.hashCode ^
        maxScore.hashCode ^
        weightage.hashCode ^
        maxWeightage.hashCode ^
        average.hashCode ^
        status.hashCode ^
        isRead.hashCode ^
        signature.hashCode;
  }
}
