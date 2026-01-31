import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import '../../../../core/utils/avatar_utils.dart';
import '../../../../core/services/avatar_cache_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/logger.dart';

/// Avatar picker dialog with random mode option
class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({super.key});

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  static const String _tag = 'AvatarPicker';
  List<String> _avatarIds = [];
  String? _selectedId;
  bool _isRandomMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isRandomMode = await AvatarCacheService.isRandomMode();
    _generateAvatars();
    setState(() => _isLoading = false);
  }

  void _generateAvatars() {
    setState(() {
      _avatarIds = AvatarUtils.generateRandomIds(12);
      _selectedId = null;
    });
    Logger.d(_tag, 'Generated 12 new avatars');
  }

  Future<void> _selectAvatar(String id) async {
    await AvatarCacheService.saveAvatar(id);
    if (mounted) {
      Navigator.pop(context, true);
      SnackbarUtils.success(context, 'Avatar updated');
    }
  }

  Future<void> _toggleRandomMode(bool value) async {
    await AvatarCacheService.setRandomMode(value);
    setState(() => _isRandomMode = value);
    if (value && mounted) {
      Navigator.pop(context, true);
      SnackbarUtils.success(context, 'Random avatar enabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (_isLoading) {
      return AlertDialog(
        backgroundColor: theme.surface,
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      title: Row(
        children: [
          Icon(Icons.account_circle, color: theme.primary),
          const SizedBox(width: 12),
          Text(
            'Choose Avatar',
            style: TextStyle(color: theme.text, fontSize: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isRandomMode,
              onChanged: (value) => _toggleRandomMode(value ?? false),
              title: Text(
                'Random every time',
                style: TextStyle(color: theme.text),
              ),
              subtitle: Text(
                'Show different avatar on each app launch',
                style: TextStyle(color: theme.muted, fontSize: 12),
              ),
              activeColor: theme.primary,
            ),
            const SizedBox(height: ThemeConstants.spacingSm),
            if (!_isRandomMode) ...[
              SizedBox(
                height: 320,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _avatarIds.length,
                  itemBuilder: (context, index) {
                    final id = _avatarIds[index];
                    final isSelected = _selectedId == id;

                    return GestureDetector(
                      onTap: () => _selectAvatar(id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.background,
                          border:
                              isSelected
                                  ? Border.all(color: theme.primary, width: 3)
                                  : Border.all(
                                    color: theme.muted.withValues(alpha: 0.3),
                                  ),
                        ),
                        child: Center(
                          child: RandomAvatar(id, width: 70, height: 70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isRandomMode)
          TextButton.icon(
            onPressed: _generateAvatars,
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
