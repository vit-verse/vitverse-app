import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../firebase/analytics/analytics_service.dart';
import 'about_constants.dart';
import 'about_widgets.dart';
import 'markdown_viewer_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'About',
      screenClass: 'AboutPage',
    );
  }

  Future<void> _launchUrl(String url, String eventName) async {
    try {
      AnalyticsService.instance.logEvent(
        name: eventName,
        parameters: {'url': url},
      );
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) SnackbarUtils.error(context, 'Could not open link');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.error(context, 'Error opening link');
    }
  }

  void _shareApp() {
    AnalyticsService.instance.logEvent(name: 'share_app_clicked');
    Share.share(AboutConstants.shareAppText);
  }

  void _checkForUpdates() {
    AnalyticsService.instance.logEvent(name: 'check_updates_clicked');
    SnackbarUtils.info(context, 'Feature coming soon!');
  }

  void _openPrivacyPolicy() {
    AnalyticsService.instance.logEvent(name: 'privacy_policy_opened');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MarkdownViewerPage(
              title: AboutConstants.privacyPolicyLabel,
              githubUrl: AboutConstants.privacyPolicyGithub,
              directUrl: AboutConstants.privacyPolicyRawUrl,
            ),
      ),
    );
  }

  void _openTermsOfService() {
    AnalyticsService.instance.logEvent(name: 'terms_of_service_opened');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MarkdownViewerPage(
              title: AboutConstants.termsOfServiceLabel,
              githubUrl: AboutConstants.termsOfServiceGithub,
              directUrl: AboutConstants.termsOfServiceRawUrl,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('About VIT Verse'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header with Version
            AppHeaderCard(
              theme: theme,
              onCheckUpdate: _checkForUpdates,
              onShare: _shareApp,
            ),
            const SizedBox(height: 16),

            // Visit Website
            ActionCard(
              theme: theme,
              icon: Icons.language,
              iconAsset: AboutConstants.websiteIconAsset,
              title: AboutConstants.visitWebsiteLabel,
              subtitle: AboutConstants.websiteSubtitle,
              onTap:
                  () => _launchUrl(AboutConstants.appWebsite, 'website_opened'),
            ),
            const SizedBox(height: 16),

            // Open Source
            ActionCard(
              theme: theme,
              icon: Icons.code,
              iconAsset: AboutConstants.githubAsset,
              title: AboutConstants.openSourceLabel,
              subtitle: AboutConstants.viewRepositoryLabel,
              onTap:
                  () => _launchUrl(
                    AboutConstants.githubRepo,
                    'github_repo_opened',
                  ),
            ),
            const SizedBox(height: 16),

            // // VIT Verse Organization
            // ActionCard(
            //   theme: theme,
            //   icon: Icons.business,
            //   iconAsset: AboutConstants.githubAsset,
            //   title: AboutConstants.vitVerseOrgLabel,
            //   subtitle: AboutConstants.vitVerseOrgSubtitle,
            //   onTap:
            //       () => _launchUrl(
            //         AboutConstants.vitVerseOrg,
            //         'vit_verse_org_opened',
            //       ),
            // ),
            // const SizedBox(height: 16),

            // Join Community
            ActionCard(
              theme: theme,
              icon: Icons.chat,
              iconAsset: AboutConstants.whatsappAsset,
              title: AboutConstants.joinCommunityLabel,
              subtitle: AboutConstants.communitySubtitle,
              onTap:
                  () => _launchUrl(
                    AboutConstants.whatsappGroup,
                    'community_group_opened',
                  ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            InfoCard(
              theme: theme,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.amber,
              title: AboutConstants.disclaimerTitle,
              content: AboutConstants.disclaimerText,
            ),
            const SizedBox(height: 16),

            // Security & Privacy
            InfoCard(
              theme: theme,
              icon: Icons.security,
              iconColor: Colors.green,
              title: AboutConstants.securityTitle,
              content: AboutConstants.securityText,
            ),
            const SizedBox(height: 16),

            // Tech Stack
            TechStackCard(theme: theme),
            const SizedBox(height: 16),

            // Lead Developer
            DeveloperCard(
              theme: theme,
              title: AboutConstants.leadDeveloperTitle,
              name: AboutConstants.leadDeveloperName,
              role: AboutConstants.leadDeveloperRole,
              initials: 'DP',
              githubUrl: AboutConstants.leadDeveloperGithub,
              linkedinUrl: AboutConstants.leadDeveloperLinkedin,
              iconAsset: AboutConstants.developerIconAsset,
              onGithubTap:
                  () => _launchUrl(
                    AboutConstants.leadDeveloperGithub,
                    'lead_developer_github',
                  ),
              onLinkedinTap:
                  () => _launchUrl(
                    AboutConstants.leadDeveloperLinkedin,
                    'lead_developer_linkedin',
                  ),
            ),
            const SizedBox(height: 16),

            // Collaborations
            CollaborationsCard(
              theme: theme,
              onWebsiteTap:
                  () => _launchUrl(
                    AboutConstants.collaborationWebsite,
                    'unmessify_website_opened',
                  ),
              onGithubTap:
                  () => _launchUrl(
                    AboutConstants.collaborationGithub,
                    'unmessify_github_opened',
                  ),
            ),
            const SizedBox(height: 16),

            // Contributors & Credits
            ContributorsCard(
              theme: theme,
              iconAsset: AboutConstants.contributionIconAsset,
              onGithubTap: (url) => _launchUrl(url, 'contributor_github'),
              onLinkedinTap: (url) => _launchUrl(url, 'contributor_linkedin'),
            ),
            const SizedBox(height: 16),

            // Request Feature & Report Bug
            Row(
              children: [
                Expanded(
                  child: SmallActionCard(
                    theme: theme,
                    icon: Icons.lightbulb_outline,
                    label: AboutConstants.requestFeatureLabel,
                    onTap:
                        () => _launchUrl(
                          '${AboutConstants.githubRepo}/issues/new?template=feature_request.md',
                          'request_feature_clicked',
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SmallActionCard(
                    theme: theme,
                    icon: Icons.bug_report_outlined,
                    label: AboutConstants.reportBugLabel,
                    onTap:
                        () => _launchUrl(
                          '${AboutConstants.githubRepo}/issues/new?template=bug_report.md',
                          'report_bug_clicked',
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit Feedback
            ActionCard(
              theme: theme,
              icon: Icons.feedback_outlined,
              title: AboutConstants.submitFeedbackLabel,
              subtitle: AboutConstants.feedbackSubtitle,
              onTap:
                  () => _launchUrl(
                    AboutConstants.feedbackFormUrl,
                    'feedback_form_opened',
                  ),
            ),
            const SizedBox(height: 16),

            // Legal & Privacy
            LegalCard(
              theme: theme,
              onPrivacyPolicyTap: _openPrivacyPolicy,
              onTermsOfServiceTap: _openTermsOfService,
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                AboutConstants.appTagline,
                style: TextStyle(color: theme.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
