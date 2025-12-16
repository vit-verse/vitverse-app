import 'package:flutter/material.dart';
import '../models/models.dart';

class AttendanceMatrixLogic {
  static const double targetPercentage = 75.0;

  static double calculateProjectedPercentage({
    required int attended,
    required int total,
    required int addAttend,
    required int addAbsent,
  }) {
    if (total + addAttend + addAbsent == 0) return 0.0;
    return ((attended + addAttend) / (total + addAttend + addAbsent)) * 100;
  }

  static int calculateBuffer({required int attended, required int total}) {
    if (total == 0) return 0;
    final currentPercentage = (attended / total) * 100;
    if (currentPercentage < targetPercentage) return 0;

    final buffer = ((attended - 0.75 * total) / 0.75).floor();
    return buffer >= 0 ? buffer : 0;
  }

  static int calculateRecovery({required int attended, required int total}) {
    if (total == 0) return 0;
    final currentPercentage = (attended / total) * 100;
    if (currentPercentage >= targetPercentage) return 0;

    final recovery = ((0.75 * total - attended) / 0.25).ceil();
    return recovery > 0 ? recovery : 0;
  }

  static String formatPercentage(double percentage) {
    final floored = (percentage * 10).floor() / 10;
    return floored.toStringAsFixed(1);
  }

  static String getBufferIndicator({
    required int attended,
    required int total,
  }) {
    if (total == 0) return '(±0)';

    final percentage = (attended / total) * 100;

    if (percentage >= targetPercentage) {
      final buffer = calculateBuffer(attended: attended, total: total);
      return buffer == 0 ? '(±0)' : '(+$buffer)';
    } else {
      final recovery = calculateRecovery(attended: attended, total: total);
      return '(−$recovery)';
    }
  }

  static AttendanceStatus getStatus(double percentage) {
    if (percentage >= 80.0) return AttendanceStatus.safe;
    if (percentage >= 75.0) return AttendanceStatus.caution;
    return AttendanceStatus.atRisk;
  }

  static Color getStatusColor(AttendanceStatus status, {double opacity = 1.0}) {
    return status.color.withOpacity(opacity);
  }

  static String generateInterpretation({
    required int futureAttendances,
    required int futureAbsences,
    required double projectedPercentage,
    required AttendanceStatus status,
    bool isOverall = false,
  }) {
    final formattedPercentage = formatPercentage(projectedPercentage);
    final contextText = isOverall ? 'overall attendance' : 'attendance';

    if (futureAttendances == 0 && futureAbsences == 0) {
      if (projectedPercentage >= 80.0) {
        return 'Your current $contextText is $formattedPercentage%, which is excellent (≥80%).';
      } else if (projectedPercentage >= 75.0) {
        return 'Your current $contextText is $formattedPercentage%, which is safe (≥75%) but could be improved.';
      } else {
        return 'Your current $contextText is $formattedPercentage%, which is below the 75% requirement.';
      }
    }

    final totalFutureClasses = futureAttendances + futureAbsences;
    final attendText = futureAttendances == 1 ? 'class' : 'classes';
    final missText = futureAbsences == 1 ? 'class' : 'classes';
    final totalText = totalFutureClasses == 1 ? 'class' : 'classes';

    String scenarioText = '';

    if (totalFutureClasses > 0) {
      scenarioText = 'In the next $totalFutureClasses $totalText, if you ';

      if (futureAttendances > 0 && futureAbsences > 0) {
        scenarioText +=
            'attend $futureAttendances $attendText and miss $futureAbsences $missText';
      } else if (futureAttendances > 0) {
        scenarioText += 'attend all $futureAttendances $attendText';
      } else {
        scenarioText += 'miss all $futureAbsences $missText';
      }

      scenarioText += ', then your $contextText will be $formattedPercentage%';
    }

    if (status == AttendanceStatus.safe) {
      scenarioText += ', which is excellent (≥80%).';
    } else if (status == AttendanceStatus.caution) {
      scenarioText += ', which is safe (≥75%) but could be improved.';
    } else {
      scenarioText += ', which falls below the 75% requirement.';
    }

    return scenarioText;
  }

  static AttendanceMatrixCell generateCell({
    required int currentAttended,
    required int currentTotal,
    required int futureAttendances,
    required int futureAbsences,
    bool isOverall = false,
  }) {
    final projectedPercentage = calculateProjectedPercentage(
      attended: currentAttended,
      total: currentTotal,
      addAttend: futureAttendances,
      addAbsent: futureAbsences,
    );

    final attendedAfterScenario = currentAttended + futureAttendances;
    final totalAfterScenario =
        currentTotal + futureAttendances + futureAbsences;

    final status = getStatus(projectedPercentage);
    final bufferIndicator = getBufferIndicator(
      attended: attendedAfterScenario,
      total: totalAfterScenario,
    );
    final interpretation = generateInterpretation(
      futureAttendances: futureAttendances,
      futureAbsences: futureAbsences,
      projectedPercentage: projectedPercentage,
      status: status,
      isOverall: isOverall,
    );

    return AttendanceMatrixCell(
      projectedPercentage: projectedPercentage,
      futureAttendances: futureAttendances,
      futureAbsences: futureAbsences,
      formattedPercentage: formatPercentage(projectedPercentage),
      bufferIndicator: bufferIndicator,
      status: status,
      statusColor: status.color,
      currentAttended: currentAttended,
      currentTotal: currentTotal,
      totalAfterScenario: totalAfterScenario,
      attendedAfterScenario: attendedAfterScenario,
      interpretation: interpretation,
    );
  }

  static List<List<AttendanceMatrixCell>> generateMatrix({
    required int currentAttended,
    required int currentTotal,
    bool isOverall = false,
  }) {
    const matrixSize = 6;
    List<List<AttendanceMatrixCell>> matrix = [];

    for (int absences = 0; absences < matrixSize; absences++) {
      List<AttendanceMatrixCell> row = [];

      for (int attendances = 0; attendances < matrixSize; attendances++) {
        final cell = generateCell(
          currentAttended: currentAttended,
          currentTotal: currentTotal,
          futureAttendances: attendances,
          futureAbsences: absences,
          isOverall: isOverall,
        );
        row.add(cell);
      }

      matrix.add(row);
    }

    return matrix;
  }

  static Color getCellBackgroundColor(AttendanceStatus status, bool isDark) {
    final baseColor = status.color;
    return isDark ? baseColor.withOpacity(0.2) : baseColor.withOpacity(0.15);
  }

  static Color getCellTextColor(AttendanceStatus status, bool isDark) {
    if (isDark) {
      return status.color.withOpacity(0.9);
    } else {
      return Color.lerp(status.color, Colors.black, 0.3)!;
    }
  }
}
