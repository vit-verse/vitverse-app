import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../logic/lost_found_provider.dart';
import 'tabs/lost_tab.dart';
import 'tabs/found_tab.dart';
import 'tabs/me_tab.dart';
import 'add_lost_found_page.dart';

/// Lost & Found home page with 3 tabs
class LostFoundHomePage extends StatefulWidget {
  const LostFoundHomePage({super.key});

  @override
  State<LostFoundHomePage> createState() => _LostFoundHomePageState();
}

class _LostFoundHomePageState extends State<LostFoundHomePage> {
  LostFoundProvider? _provider;
  bool _isSupabaseConfigured = false;
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _checkSupabaseAndInit();

    AnalyticsService.instance.logScreenView(
      screenName: 'LostAndFound',
      screenClass: 'LostFoundHomePage',
    );
  }

  void _checkSupabaseAndInit() {
    if (!SupabaseClientService.isInitialized) {
      setState(() => _isSupabaseConfigured = false);
      return;
    }

    setState(() => _isSupabaseConfigured = true);
    _provider = LostFoundProvider();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_provider == null) return;
    await _provider!.loadItems();
    if (mounted && _provider!.errorMessage != null) {
      SnackbarUtils.error(context, _provider!.errorMessage!);
    }
  }

  Future<void> _onRefresh() async {
    if (_provider == null) return;
    await _provider!.refresh();
    if (mounted && _provider!.errorMessage != null) {
      SnackbarUtils.error(context, _provider!.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (!_isSupabaseConfigured) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Lost & Found',
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
        body: _buildSupabaseNotConfiguredUI(theme),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Lost & Found',
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
            _buildSearchBar(theme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: theme.primary,
                child: _buildCurrentTab(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddPage,
          backgroundColor: theme.primary,
          child: const Icon(Icons.add, color: Colors.white),
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
              label: 'Lost',
              icon: Icons.help_outline,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Found',
              icon: Icons.check_circle_outline,
              index: 1,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Me',
              icon: Icons.person_outline,
              index: 2,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.text, fontSize: 14),
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: theme.muted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: theme.muted, size: 18),
              onPressed: () => _searchController.clear(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
              color: isSelected ? Colors.white : theme.text.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : theme.text.withValues(alpha: 0.6),
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
        return LostTab(searchQuery: _searchQuery);
      case 1:
        return FoundTab(searchQuery: _searchQuery);
      case 2:
        return MeTab(searchQuery: _searchQuery);
      default:
        return const LostTab();
    }
  }

  void _openAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLostFoundPage()),
    );

    if (result == true && mounted) {
      SnackbarUtils.success(context, 'Item posted successfully!');
      _onRefresh();
    }
  }

  Widget _buildSupabaseNotConfiguredUI(theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Configuration Incomplete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
