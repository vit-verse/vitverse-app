import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_constants.dart';
import '../../../core/theme/app_card_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/sync_notifier.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../authentication/core/auth_service.dart';
import '../../authentication/core/auth_constants.dart';
import '../../authentication/core/auth_handler.dart';
import '../../authentication/utils/auth_states.dart';
import '../../authentication/ui/dialogs/captcha_dialog.dart';

/// Semester Sync Card Widget
class SemesterSyncCard extends StatefulWidget {
  const SemesterSyncCard({super.key});

  @override
  State<SemesterSyncCard> createState() => _SemesterSyncCardState();
}

class _SemesterSyncCardState extends State<SemesterSyncCard> {
  bool _isBackgroundSyncing = false;
  String? _selectedSemester;
  List<String> _availableSemesters = [];
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadSemesterData();

    _syncSubscription = SyncNotifier.instance.onSyncComplete.listen((_) {
      if (mounted) _loadSemesterData();
    });

    VTOPAuthService.instance.addListener(_onAuthStateChanged);
    VTOPAuthHandler.instance.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    try {
      _syncSubscription?.cancel();
    } catch (_) {}
    _syncSubscription = null;
    VTOPAuthService.instance.removeListener(_onAuthStateChanged);
    VTOPAuthHandler.instance.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final currentPhase = VTOPAuthService.instance.currentSyncPhase;
    if (currentPhase == null && _isBackgroundSyncing) {
      setState(() => _isBackgroundSyncing = false);
    } else {
      setState(() {});
    }
  }

  /// Load semester data from SharedPreferences
  Future<void> _loadSemesterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load available semesters
      final semestersJson = prefs.getString('available_semesters');
      if (semestersJson != null && semestersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(semestersJson);
        _availableSemesters = decoded.map((e) => e.toString()).toList();
      }

      final lastSemester = prefs.getString(AuthConstants.keySemester);
      if (lastSemester != null && _availableSemesters.contains(lastSemester)) {
        _selectedSemester = lastSemester;
      } else if (_availableSemesters.isNotEmpty) {
        _selectedSemester = _availableSemesters.first;
      }

      if (mounted) {
        setState(() {});
      }

      Logger.d(
        'SemesterSync',
        'Loaded ${_availableSemesters.length} semesters, selected: $_selectedSemester',
      );
    } catch (e) {
      Logger.e('SemesterSync', 'Failed to load semester data', e);
    }
  }

  /// Show semester selection dialog
  Future<void> _showSemesterSelectionDialog() async {
    if (_availableSemesters.isEmpty) {
      SnackbarUtils.warning(
        context,
        'No semesters available. Please login first.',
      );
      return;
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final selected = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blue),
                SizedBox(width: 12),
                Text('Select Semester'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableSemesters.length,
                itemBuilder: (context, index) {
                  final semester = _availableSemesters[index];
                  final isSelected = semester == _selectedSemester;

                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color:
                          isSelected
                              ? themeProvider.currentTheme.primary
                              : Colors.grey,
                    ),
                    title: Text(
                      semester,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color:
                            isSelected
                                ? themeProvider.currentTheme.primary
                                : themeProvider.currentTheme.text,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(semester),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );

    if (selected != null && selected != _selectedSemester) {
      setState(() {
        _selectedSemester = selected;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthConstants.keySemester, selected);

      Logger.i(
        'SemesterSync',
        'Semester changed to: $selected (saved to SharedPreferences)',
      );
    }
  }

  /// Handle background sync (uses the same function as home page attendance widget)
  Future<void> _handleBackgroundSync() async {
    if (_isBackgroundSyncing) return;

    if (_selectedSemester == null) {
      SnackbarUtils.warning(context, 'Please select a semester first');
      return;
    }

    setState(() {
      _isBackgroundSyncing = true;
    });

    try {
      Logger.i(
        'SemesterSync',
        'Starting background sync for: $_selectedSemester',
      );

      final authService = VTOPAuthService.instance;

      final success = await authService.backgroundSync(
        semesterName: _selectedSemester,
        onSyncStateChanged: (isSyncing) {
          if (mounted) {
            setState(() {
              _isBackgroundSyncing = isSyncing;
            });
          }
        },
        onStatusUpdate: (message) {
          Logger.d('SemesterSync', 'Background sync: $message');
        },
        onError: (error, {String? errorType}) {
          Logger.e(
            'SemesterSync',
            'Background sync error: $error (type: $errorType)',
          );
          if (mounted) {
            // Determine user-friendly error message and type based on error type
            String displayMessage = error;
            SnackbarType snackbarType = SnackbarType.error;
            SnackBarAction? action;

            switch (errorType) {
              case 'INVALID_CREDENTIALS':
                displayMessage =
                    'Invalid username or password. Please login again.';
                snackbarType = SnackbarType.error;
                action = SnackBarAction(
                  label: 'Login',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                );
                break;
              case 'INVALID_CAPTCHA':
                displayMessage =
                    'Captcha verification failed. Please try again.';
                snackbarType = SnackbarType.warning;
                break;
              case 'TIMEOUT':
                displayMessage =
                    'Connection timeout. Please check your internet and try again.';
                snackbarType = SnackbarType.info;
                break;
              case 'NO_CREDENTIALS':
                displayMessage = 'Please login first to sync data.';
                snackbarType = SnackbarType.warning;
                break;
              case 'NO_SEMESTER':
                displayMessage = 'Please select a semester first.';
                snackbarType = SnackbarType.warning;
                break;
              default:
                displayMessage = error;
                snackbarType = SnackbarType.error;
            }

            SnackbarUtils.show(
              context,
              message: displayMessage,
              type: snackbarType,
              duration: const Duration(seconds: 4),
              action: action,
            );
          }
        },
      );

      if (success) {
        // Sync completed successfully
        Logger.success('SemesterSync', 'Background sync Phase 1 completed');

        if (mounted) {
          SnackbarUtils.success(
            context,
            'Data synced successfully',
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Sync failed or requires manual captcha
        Logger.w(
          'SemesterSync',
          'Background sync requires manual intervention',
        );

        // Check if we need to show captcha dialog
        if (authService.authState == AuthState.captchaRequired) {
          Logger.i('SemesterSync', 'Showing manual captcha dialog...');

          if (mounted) {
            // Show captcha dialog
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => CaptchaDialog(authService: authService),
            );
            if (result == true) {
              // User solved captcha, wait for sync to complete
              Logger.d(
                'SemesterSync',
                'Captcha solved, waiting for sync to complete...',
              );
              await Future.delayed(const Duration(seconds: 2));
            }
          }
        }
      }
    } catch (e) {
      Logger.e('SemesterSync', 'Background sync exception', e);

      if (mounted) {
        SnackbarUtils.error(context, 'Sync failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundSyncing = false;
        });
      }
    }
  }

  // Helper method to get human-readable sync phase text
  String _getSyncPhaseText() {
    final phase = VTOPAuthService.instance.currentSyncPhase;
    if (phase == null || phase.isEmpty) {
      return _isBackgroundSyncing ? 'Authenticating...' : 'Sync';
    }

    switch (phase) {
      case 'A':
        return 'Authenticating...';
      case 'P1':
        return 'Syncing Data...';
      case 'P2':
        return 'Finishing Up...';
      default:
        return 'Syncing...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingLg),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                Icons.sync_rounded,
                color: themeProvider.currentTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Semester Data Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Sync Button with Detailed Status
              ElevatedButton.icon(
                onPressed:
                    (_isBackgroundSyncing ||
                            VTOPAuthService.instance.currentSyncPhase != null)
                        ? null
                        : _handleBackgroundSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusMd,
                    ),
                  ),
                  elevation: 0,
                ),
                icon:
                    (_isBackgroundSyncing ||
                            VTOPAuthService.instance.currentSyncPhase != null)
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  (_isBackgroundSyncing ||
                          VTOPAuthService.instance.currentSyncPhase != null)
                      ? _getSyncPhaseText()
                      : 'Sync',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ThemeConstants.spacingMd),

          // Semester Selection Row
          InkWell(
            onTap: _showSemesterSelectionDialog,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.spacingMd,
                vertical: ThemeConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.background,
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                border: Border.all(
                  color: themeProvider.currentTheme.primary.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: themeProvider.currentTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Semester',
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.currentTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedSemester ?? 'No semester selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.currentTheme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: themeProvider.currentTheme.muted,
                  ),
                ],
              ),
            ),
          ),

          // Last Synced Info
          const SizedBox(height: ThemeConstants.spacingSm),
          FutureBuilder<String?>(
            future: _getLastSyncTime(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: themeProvider.currentTheme.muted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Last synced: ${snapshot.data}',
                        style: TextStyle(
                          fontSize: 11,
                          color: themeProvider.currentTheme.muted,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTimestamp = prefs.getInt('lastSyncTimestamp');
      if (syncTimestamp != null) {
        final syncDate = DateTime.fromMillisecondsSinceEpoch(syncTimestamp);
        return _formatSyncTime(syncDate);
      }
    } catch (e) {
      Logger.e('SemesterSync', 'Failed to get last sync time', e);
    }
    return null;
  }

  String _formatSyncTime(DateTime syncDate) {
    final now = DateTime.now();
    final difference = now.difference(syncDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${syncDate.day}/${syncDate.month}/${syncDate.year} ${syncDate.hour.toString().padLeft(2, '0')}:${syncDate.minute.toString().padLeft(2, '0')}';
    }
  }
}
