import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../../core/theme/theme_provider.dart';
import '../logic/grade_history_logic.dart';

/// Custom radar chart for grade visualization with color-coded grades
class GradeRadarChart extends StatelessWidget {
  final Map<String, double> coursePerformance; // courseCode -> percentage
  final Map<String, String> courseTitles; // courseCode -> title
  final Map<String, String> courseGrades; // courseCode -> grade

  const GradeRadarChart({
    super.key,
    required this.coursePerformance,
    this.courseTitles = const {},
    this.courseGrades = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (coursePerformance.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _GradeRadarChartPainter(
              coursePerformance: coursePerformance,
              courseTitles: courseTitles,
              courseGrades: courseGrades,
              context: context,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeRadarChartPainter extends CustomPainter {
  final Map<String, double> coursePerformance;
  final Map<String, String> courseTitles;
  final Map<String, String> courseGrades;
  final BuildContext context;

  _GradeRadarChartPainter({
    required this.coursePerformance,
    required this.courseTitles,
    required this.courseGrades,
    required this.context,
  });

  Color _getGradeColor(String grade) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final logic = GradeHistoryLogic();
    return logic.getGradeColorFromProvider(themeProvider, grade);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 50;
    final vertexCount = coursePerformance.length;

    if (vertexCount == 0) return;

    _drawBackgroundCircles(canvas, center, radius);
    _drawAxisLines(canvas, center, radius, vertexCount);
    _drawLabels(canvas, center, radius, vertexCount);
    _drawDataPolygon(canvas, center, radius, vertexCount);
  }

  void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), paint);
    }
  }

  void _drawAxisLines(
    Canvas canvas,
    Offset center,
    double radius,
    int vertexCount,
  ) {
    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.2)
          ..strokeWidth = 0.5;

    for (int i = 0; i < vertexCount; i++) {
      final angle = (2 * math.pi * i / vertexCount) - math.pi / 2;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, paint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double radius,
    int vertexCount,
  ) {
    final courses = coursePerformance.keys.toList();
    final labelRadius = radius + 30;

    for (int i = 0; i < vertexCount; i++) {
      final angle = (2 * math.pi * i / vertexCount) - math.pi / 2;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final courseCode = courses[i];
      final grade = courseGrades[courseCode] ?? '';
      final gradeColor = _getGradeColor(grade);

      final labelText = '$courseCode\n$grade';

      final textStyle = TextStyle(
        color: gradeColor,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        height: 1.1,
      );

      _drawText(canvas, labelText, Offset(x, y), textStyle);
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int vertexCount,
  ) {
    final courses = coursePerformance.keys.toList();

    // Draw individual segments with grade colors
    for (int i = 0; i < vertexCount; i++) {
      final percentage = coursePerformance[courses[i]]! / 100;
      final grade = courseGrades[courses[i]] ?? '';
      final gradeColor = _getGradeColor(grade);

      final angle = (2 * math.pi * i / vertexCount) - math.pi / 2;
      final r = radius * percentage;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      // Draw line from center to point
      final linePaint =
          Paint()
            ..color = gradeColor.withValues(alpha: 0.8)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

      canvas.drawLine(center, Offset(x, y), linePaint);

      // Draw point at vertex
      final pointPaint =
          Paint()
            ..color = gradeColor
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);

      // Draw border around point
      final borderPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(x, y), 4.5, borderPaint);
    }

    // Draw connecting lines between points
    final path = Path();
    for (int i = 0; i < vertexCount; i++) {
      final percentage = coursePerformance[courses[i]]! / 100;
      final angle = (2 * math.pi * i / vertexCount) - math.pi / 2;
      final r = radius * percentage;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill polygon with gradient
    final fillPaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final adjustedOffset = Offset(
      offset.dx - textPainter.width / 2,
      offset.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, adjustedOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
