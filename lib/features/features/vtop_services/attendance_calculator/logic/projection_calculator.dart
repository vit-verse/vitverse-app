import '../models/course_projection.dart';
import '../models/attendance_day.dart';
import '../models/course_schedule.dart';

/// Calculator for course attendance projections
class ProjectionCalculator {
  /// Calculate projections for multiple courses
  static List<CourseProjection> calculateProjections({
    required List<Map<String, dynamic>> coursesData,
    required List<AttendanceDay> attendanceDays,
    required double targetPercentage,
    required Map<int, CourseSchedule> courseSchedules,
  }) {
    final projections = <CourseProjection>[];

    for (final courseData in coursesData) {
      final courseId = courseData['course_id'] as int? ?? 0;
      final schedule = courseSchedules[courseId];

      if (schedule == null) continue; // Skip if no schedule defined

      final projection = calculateCourseProjection(
        courseData: courseData,
        attendanceDays: attendanceDays,
        targetPercentage: targetPercentage,
        schedule: schedule,
      );

      projections.add(projection);
    }

    // Sort by projected percentage (ascending) - show problematic courses first
    projections.sort(
      (a, b) => a.projectedPercentage.compareTo(b.projectedPercentage),
    );

    return projections;
  }

  /// Calculate projection for a single course
  static CourseProjection calculateCourseProjection({
    required Map<String, dynamic> courseData,
    required List<AttendanceDay> attendanceDays,
    required double targetPercentage,
    required CourseSchedule schedule,
  }) {
    final courseId = courseData['course_id'] as int? ?? 0;
    final courseCode = courseData['course_code'] as String? ?? 'N/A';
    final courseTitle =
        courseData['course_title'] as String? ?? 'Unknown Course';
    final currentAttended = courseData['attended'] as int? ?? 0;
    final currentTotal = courseData['total'] as int? ?? 0;

    return CourseProjection.calculate(
      courseId: courseId,
      courseCode: courseCode,
      courseTitle: courseTitle,
      currentAttended: currentAttended,
      currentTotal: currentTotal,
      attendanceDays: attendanceDays,
      targetPercentage: targetPercentage,
      schedule: schedule,
    );
  }

  /// Calculate overall projection across all courses
  static OverallProjection calculateOverallProjection({
    required List<CourseProjection> courseProjections,
    required double targetPercentage,
  }) {
    if (courseProjections.isEmpty) {
      return OverallProjection(
        totalCourses: 0,
        currentAttended: 0,
        currentTotal: 0,
        currentPercentage: 0.0,
        projectedAttended: 0,
        projectedTotal: 0,
        projectedPercentage: 0.0,
        coursesAboveTarget: 0,
        coursesBelowTarget: 0,
        targetPercentage: targetPercentage,
      );
    }

    int currentAttended = 0;
    int currentTotal = 0;
    int projectedAttended = 0;
    int projectedTotal = 0;
    int coursesAboveTarget = 0;
    int coursesBelowTarget = 0;

    for (final projection in courseProjections) {
      currentAttended += projection.currentAttended;
      currentTotal += projection.currentTotal;
      projectedAttended += projection.projectedAttended;
      projectedTotal += projection.projectedTotal;

      if (projection.projectedPercentage >= targetPercentage) {
        coursesAboveTarget++;
      } else {
        coursesBelowTarget++;
      }
    }

    final currentPercentage =
        currentTotal > 0 ? (currentAttended / currentTotal) * 100 : 0.0;
    final projectedPercentage =
        projectedTotal > 0 ? (projectedAttended / projectedTotal) * 100 : 0.0;

    return OverallProjection(
      totalCourses: courseProjections.length,
      currentAttended: currentAttended,
      currentTotal: currentTotal,
      currentPercentage: currentPercentage,
      projectedAttended: projectedAttended,
      projectedTotal: projectedTotal,
      projectedPercentage: projectedPercentage,
      coursesAboveTarget: coursesAboveTarget,
      coursesBelowTarget: coursesBelowTarget,
      targetPercentage: targetPercentage,
    );
  }

  /// Calculate how many classes needed to reach target
  static int calculateClassesNeeded({
    required int currentAttended,
    required int currentTotal,
    required double targetPercentage,
  }) {
    if (currentTotal == 0) return 0;

    final currentPercentage = (currentAttended / currentTotal) * 100;
    if (currentPercentage >= targetPercentage) return 0;

    int classesNeeded = 0;
    int tempAttended = currentAttended;
    int tempTotal = currentTotal;

    while (true) {
      tempAttended++;
      tempTotal++;
      classesNeeded++;
      final newPercentage = (tempAttended / tempTotal) * 100;
      if (newPercentage >= targetPercentage) break;

      // Safety limit
      if (classesNeeded > 1000) break;
    }

    return classesNeeded;
  }

  /// Calculate how many classes can be missed while maintaining target
  static int calculateClassesCanMiss({
    required int currentAttended,
    required int currentTotal,
    required double targetPercentage,
  }) {
    if (currentTotal == 0) return 0;

    final currentPercentage = (currentAttended / currentTotal) * 100;
    if (currentPercentage < targetPercentage) return 0;

    int canMiss = 0;
    int tempAttended = currentAttended;
    int tempTotal = currentTotal;

    while (true) {
      tempTotal++;
      final newPercentage = (tempAttended / tempTotal) * 100;
      if (newPercentage < targetPercentage) break;
      canMiss++;

      // Safety limit
      if (canMiss > 1000) break;
    }

    return canMiss;
  }
}

/// Overall projection summary
class OverallProjection {
  final int totalCourses;
  final int currentAttended;
  final int currentTotal;
  final double currentPercentage;
  final int projectedAttended;
  final int projectedTotal;
  final double projectedPercentage;
  final int coursesAboveTarget;
  final int coursesBelowTarget;
  final double targetPercentage;

  const OverallProjection({
    required this.totalCourses,
    required this.currentAttended,
    required this.currentTotal,
    required this.currentPercentage,
    required this.projectedAttended,
    required this.projectedTotal,
    required this.projectedPercentage,
    required this.coursesAboveTarget,
    required this.coursesBelowTarget,
    required this.targetPercentage,
  });

  bool get meetsTarget => projectedPercentage >= targetPercentage;

  String get statusText {
    if (coursesBelowTarget == 0) {
      return 'All courses meet target';
    } else if (coursesBelowTarget == totalCourses) {
      return 'All courses below target';
    } else {
      return '$coursesBelowTarget of $totalCourses courses below target';
    }
  }

  @override
  String toString() {
    return 'OverallProjection{courses: $totalCourses, '
        'projected: ${projectedPercentage.toStringAsFixed(1)}%, '
        'above target: $coursesAboveTarget, below: $coursesBelowTarget}';
  }
}
