import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';

class ResultDisplayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String mainValue;
  final String? subValue;
  final IconData icon;
  final Color? customColor;
  final Widget? additionalInfo;

  const ResultDisplayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mainValue,
    this.subValue,
    required this.icon,
    this.customColor,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final displayColor = customColor ?? theme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: displayColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: theme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mainValue,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: displayColor,
                  letterSpacing: -1.0,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(width: 6),
                Text(
                  subValue!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.muted,
                  ),
                ),
              ],
            ],
          ),
          // Additional Info
          if (additionalInfo != null) ...[
            const SizedBox(height: 12),
            additionalInfo!,
          ],
        ],
      ),
    );
  }
}

class ProgressGauge extends StatelessWidget {
  final double percentage; // 0-100
  final String label;
  final Color? color;
  final double size;

  const ProgressGauge({
    super.key,
    required this.percentage,
    required this.label,
    this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final displayColor = color ?? theme.primary;
    final clampedPercentage = percentage.clamp(0.0, 100.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressCirclePainter(
                  progress: 1.0,
                  color: theme.border,
                  strokeWidth: 8,
                ),
              ),
              // Progress circle
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressCirclePainter(
                  progress: clampedPercentage / 100,
                  color: displayColor,
                  strokeWidth: 8,
                ),
              ),
              // Center text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${clampedPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.w900,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.muted,
          ),
        ),
      ],
    );
  }
}

class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressCirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final bool isWarning;
  final bool isSuccess;

  const InfoBanner({
    super.key,
    required this.message,
    required this.icon,
    this.color,
    this.isWarning = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    Color bannerColor;
    if (color != null) {
      bannerColor = color!;
    } else if (isWarning) {
      bannerColor = Colors.orange;
    } else if (isSuccess) {
      bannerColor = Colors.green;
    } else {
      bannerColor = theme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
