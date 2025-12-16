/// Calendar metadata model for VIT academic calendar
class CalendarMetadata {
  final String lastUpdated;
  final String lastUpdatedISO;
  final int totalSemesters;
  final int totalCalendars;
  final List<Semester> semesters;

  const CalendarMetadata({
    required this.lastUpdated,
    required this.lastUpdatedISO,
    required this.totalSemesters,
    required this.totalCalendars,
    required this.semesters,
  });

  factory CalendarMetadata.fromJson(Map<String, dynamic> json) {
    return CalendarMetadata(
      lastUpdated: json['lastUpdated'] ?? '',
      lastUpdatedISO: json['lastUpdatedISO'] ?? '',
      totalSemesters: json['totalSemesters'] ?? 0,
      totalCalendars: json['totalCalendars'] ?? 0,
      semesters:
          (json['semesters'] as List<dynamic>?)
              ?.map((e) => Semester.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated,
      'lastUpdatedISO': lastUpdatedISO,
      'totalSemesters': totalSemesters,
      'totalCalendars': totalCalendars,
      'semesters': semesters.map((e) => e.toJson()).toList(),
    };
  }
}

class Semester {
  final String semesterFolder;
  final String semesterName;
  final int classGroupCount;
  final List<ClassGroup> classGroups;

  const Semester({
    required this.semesterFolder,
    required this.semesterName,
    required this.classGroupCount,
    required this.classGroups,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      semesterFolder: json['semesterFolder'] ?? '',
      semesterName: json['semesterName'] ?? '',
      classGroupCount: json['classGroupCount'] ?? 0,
      classGroups:
          (json['classGroups'] as List<dynamic>?)
              ?.map((e) => ClassGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterFolder': semesterFolder,
      'semesterName': semesterName,
      'classGroupCount': classGroupCount,
      'classGroups': classGroups.map((e) => e.toJson()).toList(),
    };
  }
}

class ClassGroup {
  final String classGroup;
  final String fileName;
  final String filePath;
  final String lastUpdated;
  final String lastUpdatedISO;
  final int monthCount;
  final String months;
  final int totalEventDays;
  final int totalEvents;

  const ClassGroup({
    required this.classGroup,
    required this.fileName,
    required this.filePath,
    required this.lastUpdated,
    required this.lastUpdatedISO,
    required this.monthCount,
    required this.months,
    required this.totalEventDays,
    required this.totalEvents,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      classGroup: json['classGroup'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
      lastUpdatedISO: json['lastUpdatedISO'] ?? '',
      monthCount: json['monthCount'] ?? 0,
      months: json['months'] ?? '',
      totalEventDays: json['totalEventDays'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classGroup': classGroup,
      'fileName': fileName,
      'filePath': filePath,
      'lastUpdated': lastUpdated,
      'lastUpdatedISO': lastUpdatedISO,
      'monthCount': monthCount,
      'months': months,
      'totalEventDays': totalEventDays,
      'totalEvents': totalEvents,
    };
  }
}
