import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/tap_debouncer.dart';
import '../models/feature_model.dart';
import '../logic/feature_provider.dart';
import '../constants/feature_colors.dart';
import '../data/feature_repository.dart';

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
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.primary.withValues(alpha: 0.1),
        highlightColor: theme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient icon
              _buildGradientIcon(40, 12, 22),
              const SizedBox(width: 14),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Description visible in list view
                    Text(
                      feature.description,
                      style: TextStyle(
                        color: theme.muted,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  /// Grid view tile - REDESIGNED FOR 2-COLUMN AND 3-COLUMN
  Widget _buildGridTile(BuildContext context, bool isPinned) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final is2Column = viewMode == ViewMode.grid2Column;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TapDebouncer.throttle(() => _navigateToFeature(context)),
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.primary.withValues(alpha: 0.1),
        highlightColor: theme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: is2Column ? 12 : 8,
            vertical: is2Column ? 10 : 10,
          ),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child:
              is2Column
                  ? Row(
                    children: [
                      // Large gradient icon on left
                      _buildGradientIcon(44, 12, 24),
                      const SizedBox(width: 12),
                      // Title on right
                      Expanded(
                        child: Text(
                          feature.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon - compact size for 3-column
                      _buildGradientIcon(34, 10, 18),
                      const SizedBox(height: 6),
                      // Title - centered, compact
                      Flexible(
                        child: Text(
                          feature.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
