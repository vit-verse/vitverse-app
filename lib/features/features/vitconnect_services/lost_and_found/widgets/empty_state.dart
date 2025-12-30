import 'package:flutter/material.dart';
import '../../../../../core/widgets/themed_lottie_widget.dart';

/// Empty state widget for Lost & Found
class LostFoundEmptyState extends StatelessWidget {
  final String message;

  const LostFoundEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThemedLottieWidget(
                  assetPath: 'assets/lottie/lostFound.lottie',
                  width: 200,
                  height: 200,
                  repeat: true,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
