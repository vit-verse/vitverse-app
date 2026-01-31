import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_card_styles.dart';

/// Reusable card widget with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 24.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: margin,
            decoration: AppCardStyles.cardDecoration(
              isDark: themeProvider.currentTheme.isDark,
              customBorderColor:
                  borderColor ??
                  themeProvider.currentTheme.muted.withValues(alpha: 0.2),
              customBackgroundColor:
                  backgroundColor ?? themeProvider.currentTheme.surface,
              borderRadius: borderRadius,
              showShadow: showShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
