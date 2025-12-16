import 'package:flutter/material.dart';

class OverallAttendance {
  final int totalAttended;
  final int totalClasses;
  final double percentage;

  OverallAttendance({required this.totalAttended, required this.totalClasses})
    : percentage =
          totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;

  factory OverallAttendance.fromCourses(List<Map<String, dynamic>> courses) {
    int attended = 0;
    int total = 0;

    for (var course in courses) {
      attended += (course['attended'] as int?) ?? 0;
      total += (course['total'] as int?) ?? 0;
    }

    return OverallAttendance(totalAttended: attended, totalClasses: total);
  }

  @override
  String toString() {
    return 'OverallAttendance(attended: $totalAttended/$totalClasses, '
        'percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}

class CourseAttendance {
  final int courseId;
  final String courseCode;
  final String courseTitle;
  final int attended;
  final int total;
  final double percentage;

  CourseAttendance({
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.attended,
    required this.total,
  }) : percentage = total > 0 ? (attended / total) * 100 : 0.0;

  factory CourseAttendance.fromMap(Map<String, dynamic> map) {
    return CourseAttendance(
      courseId: map['course_id'] as int,
      courseCode: map['course_code'] as String? ?? 'N/A',
      courseTitle: map['course_title'] as String? ?? 'Unknown Course',
      attended: map['attended'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
    );
  }

  String get displayName => '$courseCode - $courseTitle';

  @override
  String toString() {
    return 'CourseAttendance(id: $courseId, code: $courseCode, '
        'attended: $attended/$total, percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}

class AttendanceMatrixCell {
  final double projectedPercentage;
  final int futureAttendances;
  final int futureAbsences;
  final String formattedPercentage;
  final String bufferIndicator;
  final AttendanceStatus status;
  final Color statusColor;
  final int currentAttended;
  final int currentTotal;
  final int totalAfterScenario;
  final int attendedAfterScenario;
  final String interpretation;

  const AttendanceMatrixCell({
    required this.projectedPercentage,
    required this.futureAttendances,
    required this.futureAbsences,
    required this.formattedPercentage,
    required this.bufferIndicator,
    required this.status,
    required this.statusColor,
    required this.currentAttended,
    required this.currentTotal,
    required this.totalAfterScenario,
    required this.attendedAfterScenario,
    required this.interpretation,
  });

  bool get isSafe => projectedPercentage >= 75.0;
  bool get isCaution =>
      projectedPercentage >= 70.0 && projectedPercentage < 75.0;
  bool get isAtRisk => projectedPercentage < 70.0;

  @override
  String toString() {
    return 'AttendanceMatrixCell(percentage: $formattedPercentage%, '
        'futureAttend: +$futureAttendances, futureAbsent: +$futureAbsences, '
        'status: ${status.name}, buffer: $bufferIndicator)';
  }
}

enum AttendanceStatus {
  safe('Safe', Color(0xFF059669)),
  caution('Caution', Color(0xFFEAB308)),
  atRisk('At Risk', Color(0xFFEF4444));

  final String label;
  final Color color;

  const AttendanceStatus(this.label, this.color);
}
