import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'student_profile/widgets/student_card.dart';
import 'student_profile/presentation/profile_detail_page.dart';
import 'widgets/semester_sync_card.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/theme_constants.dart';
import '../../core/theme/app_card_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/version_checker_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_settings/presentation/theme_settings_page.dart';
import 'theme_settings/presentation/color_customization_page.dart';
import 'widget_customization/presentation/widget_customization_page.dart';
import 'notification_settings/notification_settings_page.dart';
import 'about/lazy_about_page.dart';
import '../authentication/core/auth_service.dart';
import '../../firebase/analytics/analytics_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  VersionCheckResult? _versionCheckResult;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfilePage',
      screenClass: 'ProfilePage',
    );
    // Automatically check for updates when page loads
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final result = await VersionCheckerService.checkForUpdate();
      if (mounted) {
        setState(() {
          _versionCheckResult = result;
          _isCheckingUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _handleUpdateAction() {
    if (_versionCheckResult?.isUpdateAvailable ?? false) {
      _openDownloadPage();
    } else {
      // Already updated - show message
      SnackbarUtils.success(context, 'You\'re using the latest version!');
    }
  }

  Future<void> _openDownloadPage() async {
    const downloadUrl = 'https://vitverse.divyanshupatel.com';
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AnalyticsService.instance.logEvent(name: 'update_download_opened');
      } else {
        if (mounted) {
          SnackbarUtils.error(context, 'Could not open download page');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Error opening download page');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: themeProvider.currentTheme.background,
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: false,
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(ThemeConstants.spacingMd),
          children: [
            StudentCard(
              onMoreDetails: (profile) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailPage(profile: profile),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingMd),

            // Semester Sync Card
            const SemesterSyncCard(),

            const SizedBox(height: ThemeConstants.spacingLg),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(
                left: ThemeConstants.spacingSm,
                bottom: ThemeConstants.spacingSm,
              ),
              child: Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.currentTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Theme & Style Card
            _ProfileFeatureCard(
              icon: Icons.brush_outlined,
              title: 'Theme & Style',
              subtitle: 'Customize colors and fonts',
              themeProvider: themeProvider,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingMd),

            // Color Customization Card
            _ProfileFeatureCard(
              icon: Icons.color_lens_outlined,
              title: 'Color Customization',
              subtitle: 'Customize data visualization colors',
              themeProvider: themeProvider,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ColorCustomizationPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingMd),

            // Widget Customization Card
            _ProfileFeatureCard(
              icon: Icons.widgets_outlined,
              title: 'Widget Customization',
              subtitle: 'Customize home screen widgets',
              themeProvider: themeProvider,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WidgetCustomizationPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingMd),

            // Notification Settings Card
            _ProfileFeatureCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage class and exam alerts',
              themeProvider: themeProvider,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingXl),

            // About Section
            Padding(
              padding: const EdgeInsets.only(
                left: ThemeConstants.spacingSm,
                bottom: ThemeConstants.spacingSm,
              ),
              child: Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.currentTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            _buildSimpleListTile(
              context,
              icon: Icons.info_outline,
              title: 'About VIT Verse',
              subtitle: 'Version, credits & more',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LazyAboutPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: ThemeConstants.spacingMd),

            // Update Checker - Compact
            _buildCompactUpdateChecker(themeProvider),

            const SizedBox(height: ThemeConstants.spacingMd),
            _buildSimpleListTile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              titleColor: Colors.red,
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout'),
                          ],
                        ),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );

                if (shouldLogout == true && context.mounted) {
                  try {
                    final authService = VTOPAuthService.instance;
                    await authService.signOut();

                    // Navigate to login screen after successful logout
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarUtils.error(context, 'Logout failed: $e');
                    }
                  }
                }
              },
            ),

            const SizedBox(height: ThemeConstants.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingSm),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: titleColor ?? themeProvider.currentTheme.text,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? themeProvider.currentTheme.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.currentTheme.muted,
                  ),
                )
                : null,
        trailing: Icon(
          Icons.chevron_right,
          color: themeProvider.currentTheme.muted,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        ),
      ),
    );
  }

  Widget _buildCompactUpdateChecker(ThemeProvider themeProvider) {
    // Determine status
    String title;
    String? subtitle;
    IconData icon;
    Color? iconColor;

    if (_isCheckingUpdate) {
      title = 'Checking for updates...';
      icon = Icons.refresh;
      iconColor = themeProvider.currentTheme.primary;
    } else if (_versionCheckResult == null) {
      title = 'Check for Updates';
      subtitle = 'Tap to check';
      icon = Icons.system_update;
    } else if (_versionCheckResult!.isUpdateAvailable) {
      title = 'Update Available';
      subtitle = 'v${_versionCheckResult!.latestVersion} is ready';
      icon = Icons.arrow_circle_up;
      iconColor = Colors.green;
    } else if (_versionCheckResult!.isUpToDate) {
      title = 'Up to Date';
      subtitle = 'v${_versionCheckResult!.currentVersion}';
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      title = 'Check for Updates';
      subtitle = 'Tap to retry';
      icon = Icons.refresh;
      iconColor = Colors.orange;
    }

    return _buildSimpleListTile(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      titleColor: iconColor,
      onTap:
          _isCheckingUpdate
              ? () {}
              : () {
                if (_versionCheckResult?.isUpdateAvailable ?? false) {
                  _handleUpdateAction();
                } else {
                  _checkForUpdates();
                }
              },
    );
  }
}

class _ProfileFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeProvider themeProvider;
  final VoidCallback onTap;

  const _ProfileFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.themeProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
        customBorderColor: themeProvider.currentTheme.primary.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusMd,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: themeProvider.currentTheme.primary,
                  ),
                ),
                const SizedBox(width: ThemeConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeProvider.currentTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeProvider.currentTheme.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
