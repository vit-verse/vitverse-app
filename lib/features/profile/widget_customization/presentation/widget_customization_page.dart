import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../firebase/analytics/analytics_service.dart';
import '../provider/widget_customization_provider.dart';
import '../data/widget_preferences_service.dart';
import '../widgets/calendar_integration_card_simple.dart';

class WidgetCustomizationPage extends StatelessWidget {
  const WidgetCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreenView(
      screenName: 'WidgetCustomization',
      screenClass: 'WidgetCustomizationPage',
    );
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: Text('Widget Customization'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        children: [
          // Section 0: Calendar Integration
          _buildSectionHeader(
            context,
            'Calendar Integration',
            'Automatically mark holidays and day orders on home screen',
            theme,
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          const CalendarIntegrationCard(),

          const SizedBox(height: ThemeConstants.spacingXl),

          // Section 1: Class Card Display
          _buildSectionHeader(
            context,
            'Class Card Display',
            'Choose what to display on class cards in timetable',
            theme,
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          _ClassCardDisplaySection(themeProvider: themeProvider),

          const SizedBox(height: ThemeConstants.spacingXl),

          // Section 2: Home Screen Secondary Widget
          _buildSectionHeader(
            context,
            'Home Screen Widgets (Multi-Select)',
            'Select which widgets to display (will auto-swipe)',
            theme,
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          _HomeSecondaryWidgetSection(themeProvider: themeProvider),

          const SizedBox(height: ThemeConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: theme.muted),
        ),
      ],
    );
  }
}

/// Section for class card display options
class _ClassCardDisplaySection extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _ClassCardDisplaySection({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WidgetCustomizationProvider>();
    final theme = themeProvider.currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(color: theme.primary.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            ClassCardDisplayType.values.map((type) {
              final isSelected = provider.classCardDisplayType == type;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ToggleOptionTile(
                  icon: WidgetCustomizationProvider.getClassCardDisplayIcon(
                    type,
                  ),
                  title: WidgetCustomizationProvider.getClassCardDisplayName(
                    type,
                  ),
                  isEnabled: isSelected,
                  onToggle: (value) {
                    if (value) {
                      provider.setClassCardDisplayType(type);
                    }
                  },
                  themeProvider: themeProvider,
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Section for home secondary widget options (multi-select)
class _HomeSecondaryWidgetSection extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _HomeSecondaryWidgetSection({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WidgetCustomizationProvider>();
    final theme = themeProvider.currentTheme;
    final selectedWidgets = provider.homeSecondaryWidgets;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(color: theme.primary.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info text
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select multiple widgets (at least one required)',
                    style: TextStyle(fontSize: 12, color: theme.text),
                  ),
                ),
              ],
            ),
          ),
          ...HomeSecondaryWidgetType.values.map((type) {
            final isSelected = selectedWidgets.contains(type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ToggleOptionTile(
                icon: WidgetCustomizationProvider.getHomeSecondaryWidgetIcon(
                  type,
                ),
                title: WidgetCustomizationProvider.getHomeSecondaryWidgetName(
                  type,
                ),
                isEnabled: isSelected,
                onToggle: (value) => provider.toggleHomeSecondaryWidget(type),
                themeProvider: themeProvider,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Toggle option tile widget
class _ToggleOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final ThemeProvider themeProvider;

  const _ToggleOptionTile({
    required this.icon,
    required this.title,
    required this.isEnabled,
    required this.onToggle,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMd,
        vertical: ThemeConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        border: Border.all(color: theme.muted.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.text),
          ),
          const SizedBox(width: ThemeConstants.spacingMd),

          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.text,
              ),
            ),
          ),

          // Toggle Switch
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }
}
