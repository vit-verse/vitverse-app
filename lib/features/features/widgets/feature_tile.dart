import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/tap_debouncer.dart';
import '../models/feature_model.dart';
import '../logic/feature_provider.dart';
import '../constants/feature_colors.dart';

class FeatureTile extends StatelessWidget {
  final Feature feature;
  final ViewMode viewMode;

  const FeatureTile({super.key, required this.feature, required this.viewMode});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeatureProvider>(context);
    final isPinned = provider.pinnedFeatures.any((f) => f.id == feature.id);

    return viewMode == ViewMode.list
        ? _buildListTile(context, isPinned)
        : _buildGridTile(context, isPinned);
  }

  /// List view tile
  Widget _buildListTile(BuildContext context, bool isPinned) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TapDebouncer.throttle(() => _navigateToFeature(context)),
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.primary.withValues(alpha: 0.1),
        highlightColor: theme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Row(
                children: [
                  // Gradient icon - LARGER SIZE
                  _buildGradientIcon(40, 14, 24),
                  const SizedBox(width: 16),

                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description visible in list view
                        Text(
                          feature.description,
                          style: TextStyle(color: theme.muted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grid view tile - REDESIGNED FOR 2-COLUMN
  Widget _buildGridTile(BuildContext context, bool isPinned) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final is2Column = viewMode == ViewMode.grid2Column;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TapDebouncer.throttle(() => _navigateToFeature(context)),
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.primary.withValues(alpha: 0.1),
        highlightColor: theme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content - HORIZONTAL LAYOUT FOR 2-COLUMN
              if (is2Column)
                Row(
                  children: [
                    // Large gradient icon on left
                    _buildGradientIcon(44, 14, 26),
                    const SizedBox(width: 12),

                    // Title on right
                    Expanded(
                      child: Text(
                        feature.title,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                // 3-COLUMN VERTICAL LAYOUT - PERFECTLY CENTERED
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Larger icon - perfectly centered
                      Center(child: _buildGradientIcon(36, 12, 20)),
                      const SizedBox(height: 8),

                      // Title - centered with proper padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          feature.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradient icon container - LARGER SIZES
  Widget _buildGradientIcon(double size, double borderRadius, double iconSize) {
    return FutureBuilder<bool>(
      future: _shouldUseThemeColors(),
      builder: (context, snapshot) {
        final useThemeColors = snapshot.data ?? false;
        final themeProvider = Provider.of<ThemeProvider>(context);

        List<Color> gradientColors;
        if (useThemeColors) {
          // Use theme-based gradient
          gradientColors = [
            themeProvider.currentTheme.primary,
            themeProvider.currentTheme.primary.withValues(alpha: 0.7),
          ];
        } else {
          // Use default feature-specific colors
          gradientColors = FeatureColors.getFeatureGradient(feature.key);
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(feature.icon, size: iconSize, color: Colors.white),
        );
      },
    );
  }

  Future<bool> _shouldUseThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_theme_for_feature_icons') ?? false;
  }

  /// Navigate to feature page
  void _navigateToFeature(BuildContext context) {
    Navigator.pushNamed(context, feature.route);
  }
}
