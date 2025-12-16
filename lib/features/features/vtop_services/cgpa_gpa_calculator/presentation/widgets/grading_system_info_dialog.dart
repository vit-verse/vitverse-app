import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../constants/grading_system_info.dart';

class GradingSystemInfoDialog extends StatelessWidget {
  const GradingSystemInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.school, color: theme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Grading System Guide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    'VIT Academic Regulations',
                    style: TextStyle(fontSize: 12, color: theme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All Sections
            ...GradingSystemInfo.sections.map(
              (section) => _GradingInfoSectionWidget(section: section),
            ),

            // Source & Disclaimer
            const SizedBox(height: 24),
            _buildSourceSection(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Source',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            GradingSystemInfo.source,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: theme.muted, height: 1.5),
              children: [
                const TextSpan(
                  text:
                      'This information may contain human error during transcription. Please verify from official sources:\n\n',
                ),
                TextSpan(
                  text:
                      '• https://chennai.vit.ac.in/files/Academic-Regulations.pdf',
                  style: TextStyle(
                    color: theme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          _launchURL(
                            'https://chennai.vit.ac.in/files/Academic-Regulations.pdf',
                          );
                        },
                ),
                const TextSpan(
                  text: '\n•Institute\'s latest academic regulations',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Widget for a single grading info section (collapsible)
class _GradingInfoSectionWidget extends StatefulWidget {
  final GradingInfoSection section;

  const _GradingInfoSectionWidget({required this.section});

  @override
  State<_GradingInfoSectionWidget> createState() =>
      _GradingInfoSectionWidgetState();
}

class _GradingInfoSectionWidgetState extends State<_GradingInfoSectionWidget> {
  bool _isExpanded = false;

  IconData _getIcon() {
    switch (widget.section.icon) {
      case 'grade':
        return Icons.grade;
      case 'calculate':
        return Icons.calculate;
      case 'assignment':
        return Icons.assignment;
      case 'trending_up':
        return Icons.trending_up;
      case 'rule':
        return Icons.rule;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // Header (Collapsible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_getIcon(), color: theme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.section.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.muted,
                  ),
                ],
              ),
            ),
          ),

          // Content (Expandable)
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    widget.section.items
                        .map((item) => _buildInfoItem(item, theme))
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(GradingInfoItem item, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
