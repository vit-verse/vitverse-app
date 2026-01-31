import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/github_release_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_constants.dart';

/// Widget to display update notification with release notes
class UpdateNotificationWidget extends StatefulWidget {
  final String latestVersion;
  final ThemeProvider themeProvider;

  const UpdateNotificationWidget({
    super.key,
    required this.latestVersion,
    required this.themeProvider,
  });

  @override
  State<UpdateNotificationWidget> createState() =>
      _UpdateNotificationWidgetState();
}

class _UpdateNotificationWidgetState extends State<UpdateNotificationWidget> {
  ReleaseInfo? _releaseInfo;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchReleaseNotes();
  }

  Future<void> _fetchReleaseNotes() async {
    setState(() => _isLoading = true);

    try {
      final releaseInfo = await GitHubReleaseService.getRelease(
        widget.latestVersion,
      );
      if (mounted) {
        setState(() {
          _releaseInfo = releaseInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openReleaseUrl() async {
    const downloadUrl = 'https://vitverse.divyanshupatel.com/';
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider.currentTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with version and button
          Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: Row(
              children: [
                Icon(Icons.arrow_circle_up, color: Colors.green, size: 24),
                const SizedBox(width: ThemeConstants.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.latestVersion}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openReleaseUrl,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Release notes section
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(
                left: ThemeConstants.spacingMd,
                right: ThemeConstants.spacingMd,
                bottom: ThemeConstants.spacingMd,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading release notes...',
                    style: TextStyle(fontSize: 12, color: theme.muted),
                  ),
                ],
              ),
            )
          else if (_releaseInfo != null && _releaseInfo!.body.isNotEmpty)
            _buildReleaseNotes(theme),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(theme) {
    final body = _releaseInfo!.body;

    // Split by lines to show only first 3 lines when collapsed
    final lines = body.split('\n');
    final hasMoreContent = lines.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(color: Colors.green.withValues(alpha: 0.2), height: 1),

        // Release notes content
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingMd,
            vertical: ThemeConstants.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Release Notes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 8),

              // Markdown content without overlay
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _isExpanded ? double.infinity : 60,
                ),
                child: SingleChildScrollView(
                  physics:
                      _isExpanded
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                  child: MarkdownBody(
                    data: body,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 12,
                        color: theme.text,
                        height: 1.4,
                      ),
                      h1: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                      h2: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                      h3: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                      listBullet: TextStyle(fontSize: 12, color: theme.text),
                      code: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        backgroundColor: theme.surface,
                      ),
                    ),
                  ),
                ),
              ),

              // Read more button (right aligned)
              if (hasMoreContent)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: () {
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Show less' : 'Read more',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
