import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

/// Pill widget for displaying credits
class CreditPill extends StatelessWidget {
  final double credits;

  const CreditPill({super.key, required this.credits});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final creditsText =
        credits % 1 == 0
            ? credits.toInt().toString()
            : credits.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$creditsText CR',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: themeProvider.currentTheme.primary,
        ),
      ),
    );
  }
}
