import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../controller/pyq_controller.dart';
import 'submit_papers_page.dart';
import 'search_papers_page.dart';

/// PYQ Home Page - main entry point with tabs
class PyqHomePage extends StatefulWidget {
  const PyqHomePage({super.key});

  @override
  State<PyqHomePage> createState() => _PyqHomePageState();
}

class _PyqHomePageState extends State<PyqHomePage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'PYQ_Home',
      screenClass: 'PyqHomePage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return ChangeNotifierProvider(
      create: (_) => PyqController(),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'PYQs',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text),
        ),
        body: Column(
          children: [_buildTabBar(theme), Expanded(child: _buildCurrentTab())],
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Search Papers',
              icon: Icons.search,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Submit Papers',
              icon: Icons.upload_file,
              index: 1,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
    required dynamic theme,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : theme.text.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : theme.text.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        return const SearchPapersPage();
      case 1:
        return const SubmitPapersPage();
      default:
        return const SearchPapersPage();
    }
  }
}
