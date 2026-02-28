import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/logger.dart';

class ForceUpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String minVersion;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.minVersion,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  static const String _tag = 'ForceUpdateScreen';
  static const String _downloadUrl = 'https://vitverse.divyanshupatel.com';
  static const int _countdownSeconds = 5;

  int _secondsLeft = _countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Logger.i(
      _tag,
      'Showing force update: ${widget.currentVersion} < ${widget.minVersion}',
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _launchDownload();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _launchDownload() async {
    try {
      final uri = Uri.parse(_downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Logger.w(_tag, 'Cannot launch $_downloadUrl');
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to launch download URL', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 40,
                      color: theme.error,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  'Update Required',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'This version of VIT Verse is no longer supported. '
                  'Please update to continue.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.muted,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Version info card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _VersionLabel(
                        label: 'Current',
                        version: widget.currentVersion,
                        color: theme.error,
                        theme: theme,
                      ),
                      Container(width: 1, height: 32, color: theme.border),
                      _VersionLabel(
                        label: 'Required',
                        version: widget.minVersion,
                        color: theme.success,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Countdown text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'Redirecting in $_secondsLeft second${_secondsLeft == 1 ? '' : 's'}...',
                    key: ValueKey(_secondsLeft),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: theme.muted),
                  ),
                ),

                const SizedBox(height: 16),

                // Manual CTA
                FilledButton(
                  onPressed: _launchDownload,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Download Now',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  final String label;
  final String version;
  final Color color;
  final dynamic theme;

  const _VersionLabel({
    required this.label,
    required this.version,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(color: theme.muted)),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
