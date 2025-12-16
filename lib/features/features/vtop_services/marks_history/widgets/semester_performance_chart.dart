import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom dual-axis chart for semester performance
/// Left Y-axis: Percentage, Right Y-axis: Course count
class SemesterPerformanceChart extends StatelessWidget {
  final List<MapEntry<String, double>> semesterData; // semester -> percentage
  final Map<String, int> courseCounts; // semester -> course count
  final Color primaryColor;

  const SemesterPerformanceChart({
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
  final Map<String, int> courseCounts;
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

    // Calculate max values
    final maxPercentage = 100.0;
    final maxCourses =
        courseCounts.values.isEmpty
            ? 10.0
            : courseCounts.values.reduce(math.max).toDouble();

    // Draw grid lines
    _drawGrid(canvas, leftPadding, topPadding, chartWidth, chartHeight);

    // Draw axes labels
    _drawLabels(
      canvas,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      maxCourses,
    );

    // Draw bar chart (courses)
    _drawBars(
      canvas,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      maxCourses,
    );

    // Draw line chart (percentage)
    _drawLine(
      canvas,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      maxPercentage,
    );

    // Draw X-axis labels
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

    // Left Y-axis (percentage)
    for (int i = 0; i <= 4; i++) {
      final value = 100 - (i * 25);
      final y = top + (height / 4) * i;
      _drawText(canvas, '$value%', Offset(5, y - 6), textStyle);
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
    final paint =
        Paint()
          ..color = primaryColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < semesterData.length; i++) {
      final semester = semesterData[i].key;
      final courseCount = courseCounts[semester]?.toDouble() ?? 0;
      final barHeight = (courseCount / maxCourses) * height;
      final x = left + (barWidth * i) + barWidth * 0.2;
      final barWidthActual = barWidth * 0.6;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top + height - barHeight, barWidthActual, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    double maxPercentage,
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
      final percentage = semesterData[i].value;
      final x = left + (barWidth * i) + barWidth * 0.5;
      final y = top + height - (percentage / maxPercentage) * height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
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
