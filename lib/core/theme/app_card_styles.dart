import 'package:flutter/material.dart';

/// Consistent card styling across the app
/// subtle bright borders highlighting all widgets
class AppCardStyles {
  AppCardStyles._();

  // Border colors - bright but subtle
  static const Color _brightBorderLight = Color(
    0xFFE5E7EB,
  ); // Bright light gray
  static const Color _brightBorderDark = Color(0xFF374151); // Bright dark gray

  /// Main card decoration with bright subtle border
  static BoxDecoration cardDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
    double borderWidth = 1.5,
    double borderRadius = 16.0,
    bool showShadow = true,
  }) {
    return BoxDecoration(
      color:
          customBackgroundColor ??
          (isDark ? const Color(0xFF1F2937) : Colors.white),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color:
            customBorderColor ??
            (isDark ? _brightBorderDark : _brightBorderLight),
        width: borderWidth,
      ),
      boxShadow:
          showShadow
              ? [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
              : null,
    );
  }

  /// Compact card decoration (like in Academic Performance)
  ///
  /// ⚠️ IMPORTANT: Always provide customBackgroundColor parameter!
  /// Use theme.surface for consistent theming across the app.
  /// Example: AppCardStyles.compactCardDecoration(
  ///   isDark: theme.isDark,
  ///   customBackgroundColor: theme.surface,
  /// )
  static BoxDecoration compactCardDecoration({
    bool isDark = false,
    Color? customBorderColor,
    required Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 16.0,
      borderWidth: 1.5,
    );
  }

  /// Large card decoration (like Overall Performance section)
  static BoxDecoration largeCardDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 20.0,
      borderWidth: 1.5,
    );
  }

  /// Extra rounded card decoration (like home page cards)
  static BoxDecoration roundedCardDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 24.0,
      borderWidth: 1.5,
    );
  }

  /// Small widget decoration (buttons, chips, etc.)
  static BoxDecoration smallWidgetDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 12.0,
      borderWidth: 1.2,
      showShadow: false,
    );
  }

  /// List tile decoration (for items in lists)
  static BoxDecoration listTileDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 14.0,
      borderWidth: 1.2,
    );
  }

  /// Dialog/Modal decoration
  static BoxDecoration dialogDecoration({
    bool isDark = false,
    Color? customBorderColor,
    Color? customBackgroundColor,
  }) {
    return cardDecoration(
      isDark: isDark,
      customBorderColor: customBorderColor,
      customBackgroundColor: customBackgroundColor,
      borderRadius: 24.0,
      borderWidth: 1.5,
      showShadow: true,
    );
  }

  /// Container decoration with gradient border effect
  static BoxDecoration gradientBorderCardDecoration({
    bool isDark = false,
    List<Color>? gradientColors,
    Color? backgroundColor,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color:
          backgroundColor ?? (isDark ? const Color(0xFF1F2937) : Colors.white),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color:
            gradientColors?.first ??
            (isDark ? _brightBorderDark : _brightBorderLight),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color:
              isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Card widget builder with consistent styling
  static Widget buildCard({
    required Widget child,
    bool isDark = false,
    Color? borderColor,
    Color? backgroundColor,
    double borderRadius = 16.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    final cardWidget = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: cardDecoration(
        isDark: isDark,
        customBorderColor: borderColor,
        customBackgroundColor: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// Compact card widget (like semester cards in performance page)
  static Widget buildCompactCard({
    required Widget child,
    bool isDark = false,
    Color? borderColor,
    Color? backgroundColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return buildCard(
      child: child,
      isDark: isDark,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      borderRadius: 16.0,
      padding: padding ?? const EdgeInsets.all(14),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      onTap: onTap,
    );
  }

  /// Large card widget (like overall performance section)
  static Widget buildLargeCard({
    required Widget child,
    bool isDark = false,
    Color? borderColor,
    Color? backgroundColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return buildCard(
      child: child,
      isDark: isDark,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      borderRadius: 20.0,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      onTap: onTap,
    );
  }

  /// List item card (for lists like class schedule, exams, etc.)
  static Widget buildListItemCard({
    required Widget child,
    bool isDark = false,
    Color? borderColor,
    Color? backgroundColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return buildCard(
      child: child,
      isDark: isDark,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      borderRadius: 14.0,
      padding: padding ?? const EdgeInsets.all(12),
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      onTap: onTap,
    );
  }

  /// Outline button decoration
  static BoxDecoration outlineButtonDecoration({
    bool isDark = false,
    Color? borderColor,
    bool isSelected = false,
  }) {
    return BoxDecoration(
      color:
          isSelected
              ? (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6))
              : Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: borderColor ?? (isDark ? _brightBorderDark : _brightBorderLight),
        width: 1.5,
      ),
    );
  }

  /// Info box decoration (for information banners)
  static BoxDecoration infoBoxDecoration({
    bool isDark = false,
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFF6366F1);
    return BoxDecoration(
      color: color.withOpacity(isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: color.withOpacity(isDark ? 0.4 : 0.3),
        width: 1.5,
      ),
    );
  }

  /// Warning box decoration
  static BoxDecoration warningBoxDecoration({bool isDark = false}) {
    return infoBoxDecoration(
      isDark: isDark,
      accentColor: const Color(0xFFF59E0B),
    );
  }

  /// Error box decoration
  static BoxDecoration errorBoxDecoration({bool isDark = false}) {
    return infoBoxDecoration(
      isDark: isDark,
      accentColor: const Color(0xFFEF4444),
    );
  }

  /// Success box decoration
  static BoxDecoration successBoxDecoration({bool isDark = false}) {
    return infoBoxDecoration(
      isDark: isDark,
      accentColor: const Color(0xFF10B981),
    );
  }

  /// Bottom sheet decoration
  static BoxDecoration bottomSheetDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: Border(
        top: BorderSide(
          color: isDark ? _brightBorderDark : _brightBorderLight,
          width: 1.5,
        ),
      ),
    );
  }
}
