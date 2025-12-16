import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class CalendarAppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  const CalendarAppBar({
    super.key,
    required this.onRefresh,
    required this.onSettings,
  });

  /// Reusable action button for AppBar
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeProvider.currentTheme.muted.withOpacity(0.2),
          ),
        ),
        child: Icon(icon, size: 20, color: themeProvider.currentTheme.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SliverAppBar(
      title: const Text('Calendar'),

      // 🔥 Make app bar STICK to top
      pinned: true,
      floating: false,
      snap: false,

      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _buildActionButton(
            icon: Icons.refresh,
            onPressed: onRefresh,
            tooltip: 'Refresh calendars',
            themeProvider: themeProvider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: _buildActionButton(
            icon: Icons.settings,
            onPressed: onSettings,
            tooltip: 'Calendar settings',
            themeProvider: themeProvider,
          ),
        ),
      ],
    );
  }
}
