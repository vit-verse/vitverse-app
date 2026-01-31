import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/database/entities/student_profile.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/utils/sync_notifier.dart';
import 'user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StudentCard widget in profile page
/// Shows avatar, name, reg no, and details button
class StudentCard extends StatefulWidget {
  final void Function(StudentProfile) onMoreDetails;

  const StudentCard({super.key, required this.onMoreDetails});

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  StudentProfile? _profile;
  bool _isLoading = true;
  StreamSubscription<void>? _syncSubscription;
  int _avatarKey = 0;

  @override
  void initState() {
    super.initState();
    reload();

    _syncSubscription = SyncNotifier.instance.onSyncComplete.listen((_) {
      reload();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    StudentProfile profile = StudentProfile.empty();
    final jsonString = prefs.getString('student_profile');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        profile = StudentProfile.fromJson(json);
      } catch (_) {}
    }

    setState(() {
      _profile = profile;
      _isLoading = false;
      _avatarKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(ThemeConstants.spacingLg),
        decoration: AppCardStyles.largeCardDecoration(
          isDark: themeProvider.currentTheme.isDark,
          customBackgroundColor: themeProvider.currentTheme.surface,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName =
        _profile?.nickname?.isNotEmpty == true
            ? _profile!.nickname!
            : _profile?.name ?? 'Student';
    final reg = _profile?.registerNumber ?? '';

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(
                key: ValueKey(_avatarKey),
                size: 84,
                backgroundColor: themeProvider.currentTheme.primary.withOpacity(
                  0.12,
                ),
                iconColor: themeProvider.currentTheme.primary,
              ),
              const SizedBox(width: ThemeConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: themeProvider.currentTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: ThemeConstants.spacingXs),
                    Text(
                      reg,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeProvider.currentTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_profile != null) {
                      Navigator.pushNamed(
                        context,
                        '/generate-report',
                        arguments: _profile,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Report'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: ThemeConstants.spacingSm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_profile != null) widget.onMoreDetails(_profile!);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Details'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
