import 'package:flutter/material.dart';

class CapsuleProgress extends StatelessWidget {
  final double percentage;
  final Color? color;
  final double width;
  final double height;
  final String? label;
  final double borderWidth;

  const CapsuleProgress({
    super.key,
    required this.percentage,
    this.color,
    this.width = 100,
    this.height = 40,
    this.label,
    this.borderWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Theme.of(context).primaryColor;
    final clampedPercentage = percentage.clamp(0.0, 100.0);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CapsuleBorderPainter(
          progress: clampedPercentage / 100.0,
          color: color,
          borderWidth: borderWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clampedPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: height * 0.4,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              if (label != null) ...[
                SizedBox(height: height * 0.06),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: height * 0.25,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleBorderPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double borderWidth;

  _CapsuleBorderPainter({
    required this.progress,
    required this.color,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;

    // Background border (grey)
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Progress border (colored)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Create capsule path
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    // Draw full grey border
    canvas.drawPath(path, trackPaint);

    // Draw progress border
    if (progress > 0) {
      final metric = path.computeMetrics().first;
      final length = metric.length;
      final trimmedPath = metric.extractPath(0, length * progress);
      canvas.drawPath(trimmedPath, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_CapsuleBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}