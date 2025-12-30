import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../data/quick_links_repository.dart';
import '../models/quick_links_data.dart';
import '../widgets/link_cards.dart';
import '../../../../../firebase/analytics/analytics_service.dart';

class QuickLinksPage extends StatefulWidget {
  const QuickLinksPage({super.key});

  @override
  State<QuickLinksPage> createState() => _QuickLinksPageState();
}

class _QuickLinksPageState extends State<QuickLinksPage> {
  static const String _tag = 'QuickLinksPage';

  final _repository = QuickLinksRepository();
  bool _isLoading = true;
  QuickLinksData? _data;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'QuickLinks',
      screenClass: 'QuickLinksPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _repository.fetchQuickLinksData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error loading quick links: $e', stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.error(context, 'Failed to load links');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.currentTheme.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quick Links',
          style: TextStyle(
            color: themeProvider.currentTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(themeProvider),
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: themeProvider.currentTheme.primary,
        ),
      );
    }

    if (_data == null || !_data!.hasAnyLinks) {
      return _buildEmptyState(themeProvider);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: themeProvider.currentTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_data!.hasImportantLinks) ...[
              _buildSectionHeader(
                themeProvider,
                'Important Links',
                Icons.star_rounded,
              ),
              const SizedBox(height: 16),
              ...(_data!.importantLinks.map(
                (link) =>
                    ImportantLinkCard(link: link, themeProvider: themeProvider),
              )),
              const SizedBox(height: 24),
            ],
            if (_data!.hasCommunityLinks) ...[
              _buildSectionHeader(
                themeProvider,
                'Community Links',
                Icons.groups_rounded,
              ),
              const SizedBox(height: 16),
              ...(_data!.communityLinks.map(
                (link) =>
                    CommunityLinkCard(link: link, themeProvider: themeProvider),
              )),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeProvider themeProvider,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: themeProvider.currentTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.currentTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 80,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Links Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeProvider.currentTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quick links will appear here once they are added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.currentTheme.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
