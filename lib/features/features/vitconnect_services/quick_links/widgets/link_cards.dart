import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../models/quick_links_data.dart';

class ImportantLinkCard extends StatelessWidget {
  final ImportantLink link;
  final ThemeProvider themeProvider;

  const ImportantLinkCard({
    super.key,
    required this.link,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(context, link.link),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: themeProvider.currentTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                      if (link.desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          link.desc,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeProvider.currentTheme.muted,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: themeProvider.currentTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          SnackbarUtils.error(context, 'Cannot open this link');
        }
      }
    } catch (e) {
      Logger.e('ImportantLinkCard', 'Error launching URL: $e');
      if (context.mounted) {
        SnackbarUtils.error(context, 'Failed to open link');
      }
    }
  }
}

class CommunityLinkCard extends StatelessWidget {
  final CommunityLink link;
  final ThemeProvider themeProvider;

  const CommunityLinkCard({
    super.key,
    required this.link,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(context, link.link),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(),
                    color: themeProvider.currentTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCommunityTypeLabel(),
                        style: TextStyle(
                          fontSize: 13,
                          color: themeProvider.currentTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: themeProvider.currentTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    final iconLower = link.icon.toLowerCase();
    switch (iconLower) {
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'telegram':
        return Icons.send_rounded;
      case 'discord':
        return Icons.discord_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'youtube':
        return Icons.play_circle_filled_rounded;
      case 'twitter':
      case 'x':
        return Icons.tag_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'linkedin':
        return Icons.work_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  // ignore: unused_element
  Color _getIconColor() {
    final iconLower = link.icon.toLowerCase();
    switch (iconLower) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'discord':
        return const Color(0xFF5865F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
      case 'x':
        return const Color(0xFF1DA1F2);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      default:
        return themeProvider.currentTheme.primary;
    }
  }

  String _getCommunityTypeLabel() {
    final iconLower = link.icon.toLowerCase();
    switch (iconLower) {
      case 'whatsapp':
        return 'Community';
      case 'telegram':
        return 'Telegram Channel';
      case 'discord':
        return 'Discord Server';
      case 'instagram':
        return 'Instagram Page';
      case 'youtube':
        return 'YouTube Channel';
      case 'twitter':
      case 'x':
        return 'Twitter/X Profile';
      case 'facebook':
        return 'Facebook Page';
      case 'linkedin':
        return 'LinkedIn Page';
      default:
        return 'Community Link';
    }
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          SnackbarUtils.error(context, 'Cannot open this link');
        }
      }
    } catch (e) {
      Logger.e('CommunityLinkCard', 'Error launching URL: $e');
      if (context.mounted) {
        SnackbarUtils.error(context, 'Failed to open link');
      }
    }
  }
}
