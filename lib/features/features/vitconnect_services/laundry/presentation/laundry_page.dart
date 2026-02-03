import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/theme/app_card_styles.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../../../../../firebase/analytics/analytics_service.dart';
import '../../../../../../core/services/notification_service.dart';
import '../../mess_menu/models/hostel_preferences.dart';
import '../../mess_menu/services/hostel_preferences_service.dart';
import '../../mess_menu/widgets/hostel_preferences_selector.dart';
import '../models/laundry_schedule.dart';
import '../services/laundry_service.dart';

class LaundryPage extends StatefulWidget {
  const LaundryPage({super.key});

  @override
  State<LaundryPage> createState() => _LaundryPageState();
}

class _LaundryPageState extends State<LaundryPage> {
  static const String _tag = 'LaundryPage';

  HostelPreferences? _preferences;
  List<LaundrySchedule>? _scheduleItems;
  bool _isLoading = true;
  String? _error;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'Laundry',
      screenClass: 'LaundryPage',
    );
    _loadData();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await HostelPreferencesService.loadPreferences();

      if (prefs == null || !prefs.isComplete) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _preferences = prefs;
      });

      if (forceRefresh) {
        Logger.i(_tag, 'Force refreshing laundry schedule');
      }

      final fileName = prefs.getLaundryFileName();
      final items = await LaundryService.fetchLaundrySchedule(
        fileName,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _scheduleItems = items;
        _isLoading = false;
      });

      Logger.i(_tag, 'Schedule loaded: ${items.length} items');

      if (prefs.roomNumber != null) {
        _scheduleLaundryNotifications(items, prefs.roomNumber!);
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error loading schedule: $e', stackTrace);
      setState(() {
        _error = 'Failed to load schedule. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onPreferencesSelected(HostelPreferences preferences) async {
    try {
      await HostelPreferencesService.savePreferences(preferences);
      Logger.i(_tag, 'Preferences saved successfully');
      if (mounted) {
        SnackbarUtils.success(context, 'Preferences saved');
      }
      await _loadData(forceRefresh: true);
    } catch (e) {
      Logger.e(_tag, 'Error saving preferences: $e');
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to save preferences');
      }
    }
  }

  Future<void> _openSettings() async {
    final currentPrefs = _preferences;
    if (currentPrefs == null) return;

    final result = await Navigator.push<HostelPreferences>(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Update Preferences'),
                backgroundColor:
                    Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).currentTheme.surface,
              ),
              backgroundColor:
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).currentTheme.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: HostelPreferencesSelector(
                  initialPreferences: currentPrefs,
                  onPreferencesSelected: (prefs) {
                    Navigator.pop(context, prefs);
                  },
                ),
              ),
            ),
      ),
    );

    if (result != null) {
      await _onPreferencesSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Laundry Schedule'),
        backgroundColor: theme.surface,
        actions: [
          if (_preferences != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: _openSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: theme.text,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            Text('Loading schedule...', style: TextStyle(color: theme.muted)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.muted),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.text, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_preferences == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: HostelPreferencesSelector(
          onPreferencesSelected: _onPreferencesSelected,
        ),
      );
    }

    if (_scheduleItems == null || _scheduleItems!.isEmpty) {
      return Center(
        child: Text(
          'No schedule data available',
          style: TextStyle(color: theme.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: theme.primary,
      child: ListView(
        children: [
          if (_preferences!.roomNumber != null) _buildNextLaundryWidget(theme),
          _buildScheduleList(theme),
        ],
      ),
    );
  }

  Widget _buildNextLaundryWidget(theme) {
    if (_scheduleItems == null || _preferences?.roomNumber == null) {
      return const SizedBox.shrink();
    }

    final nextLaundry = LaundryService.getNextLaundryForRoom(
      _scheduleItems!,
      _preferences!.roomNumber!,
    );

    if (nextLaundry == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: theme.isDark,
          customBackgroundColor: theme.surface,
        ),
        child: Row(
          children: [
            Icon(Icons.local_laundry_service, color: theme.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No upcoming laundry scheduled for your room',
                style: TextStyle(color: theme.muted),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate countdown
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Get today at midnight
    final currentMonth = now.month;
    final currentYear = now.year;
    final scheduleDate = nextLaundry.dateNumber;

    DateTime nextDateTime;
    if (scheduleDate >= now.day) {
      // Schedule is in current month
      nextDateTime = DateTime(currentYear, currentMonth, scheduleDate);
    } else {
      // Schedule is in next month
      nextDateTime = DateTime(currentYear, currentMonth + 1, scheduleDate);
    }

    // Calculate days difference from today at midnight to schedule date at midnight
    final scheduleDateMidnight = DateTime(
      nextDateTime.year,
      nextDateTime.month,
      nextDateTime.day,
    );
    final difference = scheduleDateMidnight.difference(today);
    final daysLeft = difference.inDays;

    String countdownText;
    if (daysLeft == 0) {
      countdownText = 'Today';
    } else if (daysLeft == 1) {
      countdownText = 'Tomorrow';
    } else {
      countdownText = '$daysLeft days';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.primary.withValues(alpha: 0.05),
      ),
      child: Stack(
        children: [
          // Background icon in bottom right
          Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
              opacity: theme.isDark ? 0.5 : 0.5,
              child: Image.asset(
                'assets/icons/laundry.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_laundry_service,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Laundry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          'Room ${_preferences!.roomNumber}',
                          style: TextStyle(fontSize: 14, color: theme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(fontSize: 12, color: theme.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextDateTime.day} ${_getMonthName(nextDateTime.month)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Countdown',
                        style: TextStyle(fontSize: 12, color: theme.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countdownText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(theme) {
    final activeSchedules = LaundryService.getActiveSchedules(_scheduleItems!);
    final userRoom = _preferences?.roomNumber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...List.generate(activeSchedules.length, (index) {
            final schedule = activeSchedules[index];
            final isUserRoom =
                userRoom != null && schedule.containsRoom(userRoom);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppCardStyles.listTileDecoration(
                isDark: theme.isDark,
                customBackgroundColor:
                    isUserRoom
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.surface,
              ),
              child: Stack(
                children: [
                  // Background icon only for user's room
                  if (isUserRoom)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Opacity(
                        opacity: theme.isDark ? 0.5 : 0.4,
                        child: Image.asset(
                          'assets/icons/laundry.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  // Content
                  Row(
                    children: [
                      // Date Circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isUserRoom ? theme.primary : theme.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isUserRoom
                                    ? theme.primary
                                    : theme.muted.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            schedule.date,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isUserRoom ? Colors.white : theme.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Room Numbers
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.roomRangeDisplay,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                              ),
                            ),
                            if (isUserRoom) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Your room is scheduled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildLastUpdatedText(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Schedule laundry notifications for the user's room
  Future<void> _scheduleLaundryNotifications(
    List<LaundrySchedule> scheduleItems,
    int roomNumber,
  ) async {
    try {
      final nextLaundry = LaundryService.getNextLaundryForRoom(
        scheduleItems,
        roomNumber,
      );

      if (nextLaundry == null) {
        Logger.d(_tag, 'No upcoming laundry found for room $roomNumber');
        return;
      }

      // Calculate the next laundry date
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      final scheduleDate = nextLaundry.dateNumber;

      DateTime nextDateTime;
      if (scheduleDate >= now.day) {
        // Schedule is in current month
        nextDateTime = DateTime(currentYear, currentMonth, scheduleDate);
      } else {
        // Schedule is in next month
        nextDateTime = DateTime(currentYear, currentMonth + 1, scheduleDate);
      }

      // Schedule notifications
      final notificationService = NotificationService();
      await notificationService.scheduleLaundryNotifications(
        roomNumber: roomNumber,
        laundryDate: nextDateTime,
      );

      Logger.i(
        _tag,
        'Laundry notifications scheduled for room $roomNumber on ${nextDateTime.toString()}',
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to schedule laundry notifications: $e');
    }
  }

  Widget _buildLastUpdatedText(theme) {
    if (_scheduleItems == null || _scheduleItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime latestUpdate = _scheduleItems![0].updatedAt;
    for (final item in _scheduleItems!) {
      if (item.updatedAt.isAfter(latestUpdate)) {
        latestUpdate = item.updatedAt;
      }
    }

    final formattedDate =
        '${latestUpdate.day.toString().padLeft(2, '0')}/${latestUpdate.month.toString().padLeft(2, '0')}/${latestUpdate.year}';

    return Center(
      child: Column(
        children: [
          Text(
            'Last Updated: $formattedDate',
            style: TextStyle(
              fontSize: 11,
              color: theme.muted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(
                'https://github.com/Kanishka-Developer/unmessify',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  SnackbarUtils.error(context, 'Could not open link');
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'If this is outdated, please inform us or update it by raising a PR.',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 10, color: theme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
