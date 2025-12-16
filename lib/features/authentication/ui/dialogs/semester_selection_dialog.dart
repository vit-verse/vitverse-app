import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../core/auth_service.dart';
import '../../utils/auth_states.dart';

class SemesterSelectionDialog extends StatefulWidget {
  final VTOPAuthService authService;

  const SemesterSelectionDialog({super.key, required this.authService});

  @override
  State<SemesterSelectionDialog> createState() =>
      _SemesterSelectionDialogState();
}

class _SemesterSelectionDialogState extends State<SemesterSelectionDialog> {
  String? _selectedSemester;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_handleAuthStateChange);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _handleAuthStateChange() {
    if (!mounted) return;

    if (widget.authService.authState != AuthState.semesterSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _selectSemester() async {
    if (_selectedSemester == null) return;

    setState(() => _isSelecting = true);

    try {
      await widget.authService.selectSemester(_selectedSemester!);
    } catch (e) {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final semesters = widget.authService.availableSemesters;

    return PopScope(
      canPop: !_isSelecting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          decoration: AppCardStyles.largeCardDecoration(
            isDark: themeProvider.currentTheme.isDark,
            customBackgroundColor: themeProvider.currentTheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Semester',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Semester list
              Flexible(
                child:
                    semesters.isEmpty
                        ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('No semesters available'),
                            ],
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: semesters.length,
                          itemBuilder: (context, index) {
                            final semester = semesters[index];
                            final isSelected = _selectedSemester == semester;

                            return RadioListTile<String>(
                              title: Text(semester),
                              value: semester,
                              groupValue: _selectedSemester,
                              selected: isSelected,
                              onChanged:
                                  _isSelecting
                                      ? null
                                      : (value) {
                                        setState(
                                          () => _selectedSemester = value,
                                        );
                                      },
                            );
                          },
                        ),
              ),

              const Divider(height: 1),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSelecting
                              ? null
                              : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed:
                          _isSelecting || _selectedSemester == null
                              ? null
                              : _selectSemester,
                      child:
                          _isSelecting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
