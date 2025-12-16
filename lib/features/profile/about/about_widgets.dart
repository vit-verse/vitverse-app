import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_card_styles.dart';
import 'about_constants.dart';

/// App Header Card with Logo, Version, and Action Buttons
class AppHeaderCard extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onShare;

  const AppHeaderCard({super.key, required this.theme, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AboutConstants.appLogoAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AboutConstants.appName,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${AboutConstants.appVersion}',
                      style: TextStyle(color: theme.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Share App Button
          _ActionButton(
            theme: theme,
            icon: Icons.share,
            label: AboutConstants.shareAppLabel,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.text),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action Card with Icon and Navigation
class ActionCard extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.theme,
    required this.icon,
    this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: AppCardStyles.cardDecoration(
          isDark: theme.isDark,
          customBackgroundColor: theme.surface,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                    iconAsset != null
                        ? Image.asset(
                          iconAsset!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                        : Icon(icon, color: theme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.muted),
          ],
        ),
      ),
    );
  }
}

/// Info Card with Icon and Content
class InfoCard extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const InfoCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
        customBorderColor: iconColor.withOpacity(0.3),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: theme.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tech Stack Card
class TechStackCard extends StatelessWidget {
  final AppTheme theme;

  const TechStackCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: theme.muted, size: 20),
              const SizedBox(width: 8),
              Text(
                AboutConstants.techStackTitle,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                AboutConstants.techStackIcons
                    .map(
                      (tech) => _TechIconBadge(
                        theme: theme,
                        iconAsset: tech['icon']!,
                        label: tech['name']!,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            AboutConstants.techStackDescription,
            style: TextStyle(color: theme.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Tech Icon Badge Widget
class _TechIconBadge extends StatelessWidget {
  final AppTheme theme;
  final String iconAsset;
  final String? label;

  const _TechIconBadge({
    required this.theme,
    required this.iconAsset,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(iconAsset, fit: BoxFit.contain),
    );
  }
}

/// Developer Card
class DeveloperCard extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String name;
  final String role;
  final String initials;
  final String githubUrl;
  final String linkedinUrl;
  final VoidCallback onGithubTap;
  final VoidCallback onLinkedinTap;
  final String? iconAsset;

  const DeveloperCard({
    super.key,
    required this.theme,
    required this.title,
    required this.name,
    required this.role,
    required this.initials,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.onGithubTap,
    required this.onLinkedinTap,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child:
                    iconAsset != null
                        ? Image.asset(iconAsset!, fit: BoxFit.contain)
                        : Icon(Icons.person, color: theme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(color: theme.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _SocialIconButton(
                theme: theme,
                iconAsset: AboutConstants.githubAsset,
                onTap: onGithubTap,
              ),
              const SizedBox(width: 8),
              _SocialIconButton(
                theme: theme,
                iconAsset: AboutConstants.linkedinAsset,
                onTap: onLinkedinTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Social Icon Button
class _SocialIconButton extends StatelessWidget {
  final AppTheme theme;
  final String iconAsset;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.theme,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(iconAsset, fit: BoxFit.contain),
      ),
    );
  }
}

/// Collaborations Card - Redesigned for Unmessify
class CollaborationsCard extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onWebsiteTap;
  final VoidCallback onGithubTap;

  const CollaborationsCard({
    super.key,
    required this.theme,
    required this.onWebsiteTap,
    required this.onGithubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  AboutConstants.collaborationIconAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AboutConstants.collaborationsTitle,
                      style: TextStyle(
                        color: theme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Collaboration with ${AboutConstants.collaborationProject}',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            AboutConstants.collaborationDescription,
            style: TextStyle(color: theme.muted, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _CollaborationButton(
                  theme: theme,
                  icon: Icons.language,
                  label: 'Website',
                  onTap: onWebsiteTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CollaborationButton(
                  theme: theme,
                  iconAsset: AboutConstants.githubAsset,
                  label: 'GitHub',
                  onTap: onGithubTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Collaboration Button
class _CollaborationButton extends StatelessWidget {
  final AppTheme theme;
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;

  const _CollaborationButton({
    required this.theme,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconAsset != null)
                Image.asset(iconAsset!, width: 18, height: 18)
              else if (icon != null)
                Icon(icon, size: 18, color: theme.text),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contributors Card
class ContributorsCard extends StatelessWidget {
  final AppTheme theme;
  final Function(String) onGithubTap;
  final Function(String) onLinkedinTap;
  final String? iconAsset;

  const ContributorsCard({
    super.key,
    required this.theme,
    required this.onGithubTap,
    required this.onLinkedinTap,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AboutConstants.contributorsTitle,
            style: TextStyle(
              color: theme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...AboutConstants.contributors.map((contributor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _ContributorRow(
                theme: theme,
                name: contributor['name']!,
                githubUrl: contributor['github']!,
                linkedinUrl: contributor['linkedin']!,
                onGithubTap: () => onGithubTap(contributor['github']!),
                onLinkedinTap: () => onLinkedinTap(contributor['linkedin']!),
                iconAsset: iconAsset,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Contributor Row
class _ContributorRow extends StatelessWidget {
  final AppTheme theme;
  final String name;
  final String githubUrl;
  final String linkedinUrl;
  final VoidCallback onGithubTap;
  final VoidCallback onLinkedinTap;
  final String? iconAsset;

  const _ContributorRow({
    required this.theme,
    required this.name,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.onGithubTap,
    required this.onLinkedinTap,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        name
            .split(' ')
            .map((word) => word.isNotEmpty ? word[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: theme.primary.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(8),
          child:
              iconAsset != null
                  ? Image.asset(iconAsset!, fit: BoxFit.contain)
                  : Icon(Icons.person, color: theme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: theme.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _SocialIconButton(
          theme: theme,
          iconAsset: AboutConstants.githubAsset,
          onTap: onGithubTap,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          theme: theme,
          iconAsset: AboutConstants.linkedinAsset,
          onTap: onLinkedinTap,
        ),
      ],
    );
  }
}

/// Small Action Card for Request Feature / Report Bug
class SmallActionCard extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SmallActionCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: AppCardStyles.cardDecoration(
          isDark: theme.isDark,
          customBackgroundColor: theme.surface,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Legal & Privacy Card
class LegalCard extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onTermsOfServiceTap;

  const LegalCard({
    super.key,
    required this.theme,
    required this.onPrivacyPolicyTap,
    required this.onTermsOfServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.cardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legal & Privacy',
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _LegalItem(
            theme: theme,
            label: AboutConstants.privacyPolicyLabel,
            onTap: onPrivacyPolicyTap,
          ),
          const SizedBox(height: 8),
          Divider(color: theme.border, height: 1),
          const SizedBox(height: 8),
          _LegalItem(
            theme: theme,
            label: AboutConstants.termsOfServiceLabel,
            onTap: onTermsOfServiceTap,
          ),
        ],
      ),
    );
  }
}

/// Legal Item
class _LegalItem extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final VoidCallback onTap;

  const _LegalItem({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.text, fontSize: 15),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: theme.muted),
          ],
        ),
      ),
    );
  }
}
