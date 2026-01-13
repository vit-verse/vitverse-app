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

class _PyqHomePageState extends State<PyqHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AnalyticsService.instance.logScreenView(
      screenName: 'PYQ_Home',
      screenClass: 'PyqHomePage',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          children: [
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [SearchPapersPage(), SubmitPapersPage()],
              ),
            ),
          ],
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
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final animValue = _tabController.animation?.value ?? 0.0;
        final progress = (animValue - index).abs().clamp(0.0, 1.0);
        final colorValue = 1.0 - progress;

        return InkWell(
          onTap: () {
            _tabController.animateTo(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, theme.primary, colorValue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Color.lerp(
                    theme.text.withValues(alpha: 0.6),
                    Colors.white,
                    colorValue,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: Color.lerp(
                      theme.text.withValues(alpha: 0.6),
                      Colors.white,
                      colorValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
