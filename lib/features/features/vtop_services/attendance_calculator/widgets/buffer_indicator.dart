import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';

/// Widget to display buffer classes indicator
class BufferIndicator extends StatelessWidget {
  final int bufferClasses;
  final bool meetsTarget;

  const BufferIndicator({
    super.key,
    required this.bufferClasses,
    required this.meetsTarget,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final isPositive = bufferClasses > 0;
    final isNeutral = bufferClasses == 0;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (isNeutral) {
      backgroundColor = theme.primary.withOpacity(0.1);
      textColor = theme.primary;
      icon = Icons.check_circle_outline;
      message = 'At target';
    } else if (isPositive) {
      backgroundColor = (theme.isDark
              ? const Color(0xFF66BB6A)
              : const Color(0xFF43A047))
          .withOpacity(0.1);
      textColor =
          theme.isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
      icon = Icons.trending_up;
      message =
          'Can miss $bufferClasses ${bufferClasses == 1 ? 'class' : 'classes'}';
    } else {
      backgroundColor = (theme.isDark
              ? const Color(0xFFEF5350)
              : const Color(0xFFE53935))
          .withOpacity(0.1);
      textColor =
          theme.isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935);
      icon = Icons.trending_down;
      final needed = bufferClasses.abs();
      message = 'Need $needed ${needed == 1 ? 'class' : 'classes'}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMd,
        vertical: ThemeConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: ThemeConstants.spacingXs),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
