import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_constants.dart';
import '../../../firebase/analytics/analytics_service.dart';
import '../constants/feature_colors.dart';
import '../logic/feature_provider.dart';
import '../models/feature_model.dart';
import '../data/feature_catalogue.dart';

class FeaturesSettingsPage extends StatefulWidget {
  const FeaturesSettingsPage({super.key});

  @override
  State<FeaturesSettingsPage> createState() => _FeaturesSettingsPageState();
}

class _FeaturesSettingsPageState extends State<FeaturesSettingsPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'FeaturesSettings',
      screenClass: 'FeaturesSettingsPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Features Settings'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Layout Grid Section
            _buildSectionHeader('Layout Grid', theme),
            const SizedBox(height: ThemeConstants.spacingSm),
            _buildLayoutGridSelector(theme),

            const SizedBox(height: ThemeConstants.spacingXl),

            // Pin Management Section
            _buildSectionHeader('Quick Access Pins', theme),
            const SizedBox(height: ThemeConstants.spacingXs),
            Text(
              'Select features to pin for quick access',
              style: TextStyle(color: theme.muted, fontSize: 14),
            ),
            const SizedBox(height: ThemeConstants.spacingMd),
            _buildPinManagement(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic theme) {
    return Text(
      title,
      style: TextStyle(
        color: theme.text,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLayoutGridSelector(dynamic theme) {
    return Consumer<FeatureProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.muted.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildGridOption(
                context,
                viewMode: ViewMode.list,
                icon: Icons.format_list_bulleted,
                title: 'List View',
                description: 'Detailed cards with descriptions',
                isSelected: provider.viewMode == ViewMode.list,
                theme: theme,
              ),
              Divider(height: 1, color: theme.muted.withOpacity(0.1)),
              _buildGridOption(
                context,
                viewMode: ViewMode.grid2Column,
                icon: Icons.grid_view,
                title: '2 Column Grid',
                description: 'Balanced layout with icons and titles',
                isSelected: provider.viewMode == ViewMode.grid2Column,
                theme: theme,
              ),
              Divider(height: 1, color: theme.muted.withOpacity(0.1)),
              _buildGridOption(
                context,
                viewMode: ViewMode.grid3Column,
                icon: Icons.grid_3x3,
                title: '3 Column Grid',
                description: 'Compact grid for maximum features',
                isSelected: provider.viewMode == ViewMode.grid3Column,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridOption(
    BuildContext context, {
    required ViewMode viewMode,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required dynamic theme,
  }) {
    final provider = Provider.of<FeatureProvider>(context, listen: false);

    return InkWell(
      onTap: () => provider.setViewMode(viewMode),
      child: Container(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.primary.withOpacity(0.15)
                        : theme.muted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? theme.primary.withOpacity(0.3)
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.primary : theme.muted,
                size: 24,
              ),
            ),
            const SizedBox(width: ThemeConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: theme.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primary, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: theme.muted.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinManagement(dynamic theme) {
    return Consumer<FeatureProvider>(
      builder: (context, provider, _) {
        // Get all available features
        final allFeatures = [
          ...FeatureCatalogue.getVtopFeaturesByCategory().values.expand(
            (f) => f,
          ),
          ...FeatureCatalogue.getVitConnectFeatures(),
        ];

        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.muted.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allFeatures.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: theme.muted.withOpacity(0.1)),
            itemBuilder: (context, index) {
              final feature = allFeatures[index];
              final isPinned = provider.pinnedFeatures.any(
                (f) => f.id == feature.id,
              );

              return _buildPinTile(
                context,
                feature: feature,
                isPinned: isPinned,
                theme: theme,
                provider: provider,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPinTile(
    BuildContext context, {
    required Feature feature,
    required bool isPinned,
    required dynamic theme,
    required FeatureProvider provider,
  }) {
    return InkWell(
      onTap: () => provider.togglePin(feature),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingMd,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Feature icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(feature.icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: ThemeConstants.spacingMd),

            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.description,
                    style: TextStyle(color: theme.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Pin toggle
            Switch(
              value: isPinned,
              onChanged: (value) => provider.togglePin(feature),
              activeColor: theme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
