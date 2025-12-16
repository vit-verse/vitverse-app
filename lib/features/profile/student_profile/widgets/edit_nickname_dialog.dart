import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/database/entities/student_profile_helper.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Dialog for editing student nickname
class EditNicknameDialog extends StatefulWidget {
  final String currentNickname;
  final Function() onNicknameUpdated;

  const EditNicknameDialog({
    super.key,
    required this.currentNickname,
    required this.onNicknameUpdated,
  });

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() {
      _isSaving = true;
    });

    final nickname = _controller.text.trim();
    final success = await StudentProfileHelper.updateNickname(nickname);

    if (success) {
      widget.onNicknameUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        SnackbarUtils.success(
          context,
          nickname.isEmpty
              ? 'Nickname cleared'
              : 'Nickname updated to "$nickname"',
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        SnackbarUtils.error(context, 'Failed to update nickname');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      title: Text(
        'Edit Nickname',
        style: TextStyle(
          color: theme.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter a nickname (with emoji support 😊)',
            style: TextStyle(color: theme.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 30,
            style: TextStyle(color: theme.text, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                borderSide: BorderSide(color: theme.primary, width: 2),
              ),
              counterStyle: TextStyle(color: theme.muted, fontSize: 11),
            ),
            onSubmitted: (_) => _saveNickname(),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave empty to clear nickname',
            style: TextStyle(
              color: theme.muted.withOpacity(0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.muted)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveNickname,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
            ),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }
}
