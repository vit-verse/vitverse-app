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
import '../widgets/faculty_rating_card.dart';
import '../widgets/faculty_rating_empty_state.dart';
import 'rate_faculty_page.dart';

/// Faculty Rating home page
class FacultyRatingHomePage extends StatefulWidget {
  final String? scrollToFacultyId;

  const FacultyRatingHomePage({super.key, this.scrollToFacultyId});

  @override
  State<FacultyRatingHomePage> createState() => _FacultyRatingHomePageState();
}

class _FacultyRatingHomePageState extends State<FacultyRatingHomePage> {
  static const String _tag = 'FacultyRatingHome';

  FacultyRatingProvider? _provider;
  bool _isSupabaseConfigured = false;
  StudentProfile? _profile;

  @override
  void initState() {
    super.initState();
    _checkSupabaseAndInit();
    _loadProfile();

    AnalyticsService.instance.logScreenView(
      screenName: 'FacultyRating',
      screenClass: 'FacultyRatingHomePage',
    );

    // If facultyId provided, navigate to rate page after loading
    if (widget.scrollToFacultyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToRatingForFaculty(widget.scrollToFacultyId!);
      });
    }
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

  Future<void> _onRefresh() async {
    if (_provider == null) return;
    await _provider!.refresh();
  }

  void _navigateToRatingForFaculty(String facultyId) {
    if (_profile == null || _provider == null) {
      Logger.w(_tag, 'Cannot navigate: profile or provider not loaded');
      return;
    }

    // Wait for provider to load faculties
    if (_provider!.isLoading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToRatingForFaculty(facultyId);
      });
      return;
    }

    final faculty = _provider!.getFacultyById(facultyId);
    if (faculty == null) {
      Logger.w(_tag, 'Faculty not found: $facultyId');
      if (mounted) {
        SnackbarUtils.info(context, 'Faculty not found in your courses');
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: _provider!,
              child: RateFacultyPage(
                facultyId: faculty.facultyId,
                studentProfile: _profile!,
              ),
            ),
      ),
    );
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (!_isSupabaseConfigured) {
      return Scaffold(
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
        ),
        body: _buildSupabaseNotConfiguredUI(theme),
      );
    }

    if (_provider == null) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text('Faculty Ratings', style: TextStyle(color: theme.text)),
          backgroundColor: theme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
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
        ),
        body: Consumer<FacultyRatingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingView(theme);
            }

            if (provider.errorMessage != null) {
              return _buildErrorView(theme, provider.errorMessage!);
            }

            if (provider.faculties.isEmpty) {
              return const FacultyRatingEmptyState();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: provider.faculties.length,
                itemBuilder: (context, index) {
                  final faculty = provider.faculties[index];
                  return FacultyRatingCard(
                    faculty: faculty,
                    onTap: () => _openRatingPage(faculty.facultyId),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView(theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 16),
          Text('Loading faculties...', style: TextStyle(color: theme.muted)),
        ],
      ),
    );
  }

  Widget _buildErrorView(theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.destructive),
            const SizedBox(height: 16),
            Text(
              'Error Loading Faculties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: theme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupabaseNotConfiguredUI(theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 80,
              color: theme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Configuration Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Supabase is not configured. Please check your .env file.',
              style: TextStyle(color: theme.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openRatingPage(String facultyId) async {
    if (_profile == null) {
      SnackbarUtils.error(context, 'Student profile not found');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider.value(
              value: _provider,
              child: RateFacultyPage(
                facultyId: facultyId,
                studentProfile: _profile!,
              ),
            ),
      ),
    );

    if (result == true && mounted) {
      SnackbarUtils.success(context, 'Rating submitted successfully!');
      _onRefresh();
    }
  }
}
