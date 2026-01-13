import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../logic/faculty_rating_provider.dart';
import 'tabs/rate_faculty_tab.dart';
import 'tabs/all_faculties_tab.dart';

/// Main Faculty Rating page with two tabs
class FacultyRatingsPage extends StatefulWidget {
  final String? scrollToFacultyId;

  const FacultyRatingsPage({super.key, this.scrollToFacultyId});

  @override
  State<FacultyRatingsPage> createState() => _FacultyRatingsPageState();
}

class _FacultyRatingsPageState extends State<FacultyRatingsPage>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'FacultyRatings';

  FacultyRatingProvider? _provider;
  bool _isSupabaseConfigured = false;
  StudentProfile? _profile;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });

    _checkSupabaseAndInit();
    _loadProfile();

    AnalyticsService.instance.logScreenView(
      screenName: 'FacultyRatings',
      screenClass: 'FacultyRatingsPage',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkSupabaseAndInit() {
    if (!SupabaseClientService.isInitialized) {
      setState(() => _isSupabaseConfigured = false);
      return;
    }

    setState(() => _isSupabaseConfigured = true);
    _provider = FacultyRatingProvider();
    _initProvider();
  }

  Future<void> _initProvider() async {
    if (_provider == null) return;
    await _provider!.initialize();
    await _provider!.loadFaculties();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        Logger.w(_tag, 'Student profile not found');
        return;
      }

      final profile = StudentProfile.fromJson(jsonDecode(profileJson));
      setState(() => _profile = profile);
    } catch (e) {
      Logger.e(_tag, 'Error loading profile', e);
    }
  }

  Future<void> _refreshRatings() async {
    try {
      if (_selectedTabIndex == 0) {
        await _provider?.refresh();
      } else {
        await _provider?.loadAllFaculties();
      }
      if (mounted) {
        SnackbarUtils.success(context, 'Ratings refreshed');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to refresh ratings');
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required dynamic theme,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.primary),
                  ),
                )
                : Icon(icon, size: 20, color: theme.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    if (!_isSupabaseConfigured) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('Faculty Ratings'),
          backgroundColor: theme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: theme.muted),
              const SizedBox(height: 16),
              Text(
                'Supabase not configured',
                style: TextStyle(fontSize: 16, color: theme.muted),
              ),
            ],
          ),
        ),
      );
    }

    if (_provider == null) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider!,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Faculty Ratings',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text),
          actions: [
            Consumer<FacultyRatingProvider>(
              builder: (context, provider, _) {
                if (provider.lastSyncTime != null) {
                  final timeAgo = _getTimeAgo(provider.lastSyncTime!);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 14),
                    child: Text(
                      timeAgo,
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Consumer<FacultyRatingProvider>(
                builder: (context, provider, _) {
                  return _buildActionButton(
                    icon: provider.isSyncing ? Icons.sync : Icons.refresh,
                    onPressed: provider.isSyncing ? () {} : _refreshRatings,
                    theme: theme,
                    isLoading: provider.isSyncing,
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RateFacultyTab(profile: _profile),
                  const AllFacultiesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              label: 'Rate Faculty',
              icon: Icons.rate_review_outlined,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'All Faculties',
              icon: Icons.school_outlined,
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
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _selectedTabIndex = index);
      },
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
              size: 16,
              color:
                  isSelected ? Colors.white : theme.text.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected
                          ? Colors.white
                          : theme.text.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
