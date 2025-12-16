import 'package:flutter/material.dart';

/// Custom dual-axis chart for grade performance (bar + line)
/// Bars show total/passed courses, line shows GPA trend
class GradePerformanceChart extends StatelessWidget {
  final List<MapEntry<String, double>> semesterData; // semester -> GPA
  final Map<String, Map<String, int>>
  courseCounts; // semester -> {total, passed}
  final Color primaryColor;

  const GradePerformanceChart({
    super.key,
    required this.semesterData,
    required this.courseCounts,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (semesterData.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = 180.0;
        return SizedBox(
          height: height + 60,
          child: CustomPaint(
            size: Size(width, height),
            painter: _DualAxisChartPainter(
              semesterData: semesterData,
              courseCounts: courseCounts,
              primaryColor: primaryColor,
            ),
          ),
        );
      },
    );
  }
}

class _DualAxisChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> semesterData;
  final Map<String, Map<String, int>> courseCounts;
  final Color primaryColor;

  _DualAxisChartPainter({
    required this.semesterData,
    required this.courseCounts,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 35.0;
    const rightPadding = 35.0;
    const topPadding = 15.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxGPA = 10.0;

    int maxCourses = 10;
    for (final counts in courseCounts.values) {
      final total = counts['total'] ?? 0;
      if (total > maxCourses) maxCourses = total;
    }

    _drawGrid(canvas, leftPadding, topPadding, chartWidth, chartHeight);
    _drawLabels(
      canvas,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      maxCourses.toDouble(),
    );
    _drawBars(
      canvas,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      maxCourses.toDouble(),
    );
    _drawLine(canvas, leftPadding, topPadding, chartWidth, chartHeight, maxGPA);
    _drawXAxisLabels(canvas, leftPadding, topPadding, chartWidth, chartHeight);
  }

  void _drawGrid(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
  ) {
    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.1)
          ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = top + (height / 4) * i;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), paint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    double maxCourses,
  ) {
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 9);

    // Left Y-axis (GPA)
    for (int i = 0; i <= 4; i++) {
      final value = 10.0 - (i * 2.5);
      final y = top + (height / 4) * i;
      _drawText(canvas, value.toStringAsFixed(1), Offset(5, y - 6), textStyle);
    }

    // Right Y-axis (courses)
    for (int i = 0; i <= 4; i++) {
      final value = (maxCourses - (maxCourses / 4) * i).round();
      final y = top + (height / 4) * i;
      _drawText(
        canvas,
        '$value',
        Offset(left + width + 5, y - 6),
        textStyle.copyWith(color: primaryColor.withValues(alpha: 0.7)),
      );
    }
  }

  void _drawBars(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    double maxCourses,
  ) {
    if (semesterData.isEmpty) return;

    final barWidth = width / semesterData.length;

    for (int i = 0; i < semesterData.length; i++) {
      final semester = semesterData[i].key;
      final counts = courseCounts[semester];
      final totalCourses = counts?['total']?.toDouble() ?? 0;
      final passedCourses = counts?['passed']?.toDouble() ?? 0;

      final totalBarHeight = (totalCourses / maxCourses) * height;
      final passedBarHeight = (passedCourses / maxCourses) * height;

      final x = left + (barWidth * i) + barWidth * 0.2;
      final barWidthActual = barWidth * 0.6;

      // Total courses bar (lighter)
      final totalPaint =
          Paint()
            ..color = primaryColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            top + height - totalBarHeight,
            barWidthActual,
            totalBarHeight,
          ),
          const Radius.circular(4),
        ),
        totalPaint,
      );

      // Passed courses bar (darker, overlaid)
      final passedPaint =
          Paint()
            ..color = primaryColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            top + height - passedBarHeight,
            barWidthActual,
            passedBarHeight,
          ),
          const Radius.circular(4),
        ),
        passedPaint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    double maxGPA,
  ) {
    if (semesterData.isEmpty) return;

    final paint =
        Paint()
          ..color = primaryColor.withValues(alpha: 0.9)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    final path = Path();
    final barWidth = width / semesterData.length;

    for (int i = 0; i < semesterData.length; i++) {
      final gpa = semesterData[i].value;
      final x = left + (barWidth * i) + barWidth * 0.5;
      final y = top + height - (gpa / maxGPA) * height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  void _drawXAxisLabels(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
  ) {
    if (semesterData.isEmpty) return;

    final textStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final barWidth = width / semesterData.length;

    for (int i = 0; i < semesterData.length; i++) {
      final label = 'S${i + 1}';
      final x = left + (barWidth * i) + barWidth * 0.5;
      _drawText(canvas, label, Offset(x - 8, top + height + 8), textStyle);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
