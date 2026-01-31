/// PYQ (Previous Year Question Papers) Models
class GlobalPyqMeta {
  final int totalCourses;
  final int totalPapers;
  final Map<String, String> courses; // courseCode -> courseTitle

  GlobalPyqMeta({
    required this.totalCourses,
    required this.totalPapers,
    required this.courses,
  });

  factory GlobalPyqMeta.fromJson(Map<String, dynamic> json) {
    // Handle courses as a Map
    final coursesData = json['courses'];
    Map<String, String> coursesMap = {};

    if (coursesData is Map) {
      coursesMap = Map<String, String>.from(coursesData);
    }

    return GlobalPyqMeta(
      totalCourses: json['total_courses'] ?? 0,
      totalPapers: json['total_papers'] ?? 0,
      courses: coursesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_courses': totalCourses,
      'total_papers': totalPapers,
      'courses': courses,
    };
  }
}

/// Represents a single PYQ paper
class PyqPaper {
  final String paperId;
  final String exam;
  final String fileUrl;

  PyqPaper({required this.paperId, required this.exam, required this.fileUrl});

  factory PyqPaper.fromJson(Map<String, dynamic> json) {
    return PyqPaper(
      paperId: json['paper_id'] ?? '',
      exam: json['exam'] ?? '',
      fileUrl: json['file_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'paper_id': paperId, 'exam': exam, 'file_url': fileUrl};
  }
}

/// Represents a course with paper count
class CoursePyqInfo {
  final String courseCode;
  final int paperCount;
  final List<String> exams;

  CoursePyqInfo({
    required this.courseCode,
    required this.paperCount,
    required this.exams,
  });

  factory CoursePyqInfo.fromPapers(String courseCode, List<PyqPaper> papers) {
    final examSet = papers.map((p) => p.exam).toSet();
    return CoursePyqInfo(
      courseCode: courseCode,
      paperCount: papers.length,
      exams: examSet.toList(),
    );
  }
}
