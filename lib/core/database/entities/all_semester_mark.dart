/// AllSemesterMark entity representing marks across all semesters
/// Maps to the 'all_semester_marks' table in the database
/// Stores comprehensive marks data for complete academic history
class AllSemesterMark {
  final int? id;
  final String? semesterId;
  final String? semesterName;
  final String? courseCode;
  final String? courseTitle;
  final String? courseType;
  final String? slot;
  final String? title; // Assessment title (CAT-1, CAT-2, etc.)
  final double? score;
  final double? maxScore;
  final double? weightage;
  final double? maxWeightage;
  final double? average;
  final String? status;
  final int? signature;

  const AllSemesterMark({
    this.id,
    this.semesterId,
    this.semesterName,
    this.courseCode,
    this.courseTitle,
    this.courseType,
    this.slot,
    this.title,
    this.score,
    this.maxScore,
    this.weightage,
    this.maxWeightage,
    this.average,
    this.status,
    this.signature,
  });

  /// Create AllSemesterMark from database map
  factory AllSemesterMark.fromMap(Map<String, dynamic> map) {
    return AllSemesterMark(
      id: map['id'] as int?,
      semesterId: map['semester_id'] as String?,
      semesterName: map['semester_name'] as String?,
      courseCode: map['course_code'] as String?,
      courseTitle: map['course_title'] as String?,
      courseType: map['course_type'] as String?,
      slot: map['slot'] as String?,
      title: map['title'] as String?,
      score: map['score'] as double?,
      maxScore: map['max_score'] as double?,
      weightage: map['weightage'] as double?,
      maxWeightage: map['max_weightage'] as double?,
      average: map['average'] as double?,
      status: map['status'] as String?,
      signature: map['signature'] as int?,
    );
  }

  /// Convert AllSemesterMark to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_id': semesterId,
      'semester_name': semesterName,
      'course_code': courseCode,
      'course_title': courseTitle,
      'course_type': courseType,
      'slot': slot,
      'title': title,
      'score': score,
      'max_score': maxScore,
      'weightage': weightage,
      'max_weightage': maxWeightage,
      'average': average,
      'status': status,
      'signature': signature,
    };
  }

  /// Generate signature for duplicate detection
  static int generateSignature(List<String> values) {
    final combined = values.join('|');
    return combined.hashCode;
  }

  /// Create copy with updated fields
  AllSemesterMark copyWith({
    int? id,
    String? semesterId,
    String? semesterName,
    String? courseCode,
    String? courseTitle,
    String? courseType,
    String? slot,
    String? title,
    double? score,
    double? maxScore,
    double? weightage,
    double? maxWeightage,
    double? average,
    String? status,
    int? signature,
  }) {
    return AllSemesterMark(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      semesterName: semesterName ?? this.semesterName,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      courseType: courseType ?? this.courseType,
      slot: slot ?? this.slot,
      title: title ?? this.title,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      weightage: weightage ?? this.weightage,
      maxWeightage: maxWeightage ?? this.maxWeightage,
      average: average ?? this.average,
      status: status ?? this.status,
      signature: signature ?? this.signature,
    );
  }

  @override
  String toString() {
    return 'AllSemesterMark{id: $id, semesterName: $semesterName, courseCode: $courseCode, title: $title, score: $score/$maxScore}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllSemesterMark &&
        other.id == id &&
        other.semesterId == semesterId &&
        other.semesterName == semesterName &&
        other.courseCode == courseCode &&
        other.title == title;
  }

  @override
  int get hashCode {
    return Object.hash(id, semesterId, semesterName, courseCode, title);
  }
}
