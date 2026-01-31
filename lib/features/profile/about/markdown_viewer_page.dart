import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../firebase/analytics/analytics_service.dart';

class MarkdownViewerPage extends StatefulWidget {
  final String title;
  final String githubUrl;
  final String? directUrl;

  const MarkdownViewerPage({
    super.key,
    required this.title,
    required this.githubUrl,
    this.directUrl,
  });

  @override
  State<MarkdownViewerPage> createState() => _MarkdownViewerPageState();
}

class _MarkdownViewerPageState extends State<MarkdownViewerPage> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: widget.title,
      screenClass: 'MarkdownViewerPage',
    );
    _fetchMarkdown();
  }

  Future<void> _fetchMarkdown() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use direct URL if provided, otherwise fall back to GitHub API
      final url = widget.directUrl;

      if (url == null) {
        throw Exception('No URL provided');
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Direct raw content - no need to decode from base64
        final decodedContent = utf8.decode(response.bodyBytes);

        if (mounted) {
          setState(() {
            _markdownContent = decodedContent;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load document: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openInGitHub() async {
    try {
      AnalyticsService.instance.logEvent(
        name: 'open_github_document',
        parameters: {'document': widget.title},
      );

      final uri = Uri.parse(widget.githubUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          SnackbarUtils.error(context, 'Could not open GitHub');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Error opening link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInGitHub,
            tooltip: 'Open in GitHub',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorView(theme)
              : _buildMarkdownView(theme),
    );
  }

  Widget _buildErrorView(theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load document',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection or try again later',
              style: TextStyle(color: theme.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchMarkdown,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openInGitHub,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open in GitHub'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownView(theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: theme.border, width: 1)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Loaded from GitHub repository',
                  style: TextStyle(color: theme.text, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: _openInGitHub,
                icon: Icon(
                  Icons.open_in_browser,
                  size: 16,
                  color: theme.primary,
                ),
                label: Text(
                  'GitHub',
                  style: TextStyle(color: theme.primary, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Markdown(
            data: _markdownContent ?? '',
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: theme.text, fontSize: 14, height: 1.6),
              h1: TextStyle(
                color: theme.text,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              h4: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              strong: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
              em: TextStyle(color: theme.text, fontStyle: FontStyle.italic),
              code: TextStyle(
                color: theme.primary,
                backgroundColor: theme.surface,
                fontFamily: 'monospace',
              ),
              blockquote: TextStyle(
                color: theme.muted,
                fontStyle: FontStyle.italic,
              ),
              blockquotePadding: const EdgeInsets.all(12),
              blockquoteDecoration: BoxDecoration(
                color: theme.surface,
                border: Border(
                  left: BorderSide(color: theme.primary, width: 4),
                ),
              ),
              listBullet: TextStyle(color: theme.text),
              a: TextStyle(
                color: theme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            onTapLink: (text, url, title) async {
              if (url != null) {
                try {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  )) {
                    if (mounted) {
                      SnackbarUtils.error(context, 'Could not open link');
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    SnackbarUtils.error(context, 'Invalid link');
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
