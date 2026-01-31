import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../../../../authentication/core/auth_service.dart';
import '../models/friend.dart';
import '../models/timetable_constants.dart';
import '../services/friends_timetable_service.dart';
import '../widgets/qr_code_share_widget.dart';
import 'add_friends_page.dart';

class FriendsSchedulePage extends StatefulWidget {
  const FriendsSchedulePage({super.key});

  @override
  State<FriendsSchedulePage> createState() => _FriendsSchedulePageState();
}

class _FriendsSchedulePageState extends State<FriendsSchedulePage> {
  final FriendsScheduleService _service = FriendsScheduleService();
  bool _isLoading = true;
  String? _selectedDay;
  String? _selectedTimeSlot;

  String _studentName = '';
  String _studentReg = '';
  Friend? _ownSchedule;

  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'FriendsSchedule',
      screenClass: 'FriendsSchedulePage',
    );
    _loadData();
    _startColorAnimation();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startColorAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _service.friendsForSchedulePage.isNotEmpty) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson != null && profileJson.isNotEmpty) {
        try {
          final profile = jsonDecode(profileJson) as Map<String, dynamic>;
          _studentName = profile['name']?.toString() ?? 'You';
          _studentReg = profile['registerNumber']?.toString() ?? '';
        } catch (e) {
          Logger.w('FriendsSchedule', 'Failed to parse student profile: $e');
          _studentName = 'You';
          _studentReg = '';
        }
      } else {
        final authService = VTOPAuthService.instance;
        final session = authService.currentSession;
        _studentName = session?.studentName ?? 'You';
        _studentReg = session?.registrationNumber ?? '';
      }

      _ownSchedule = await _service.loadOwnSchedule();
      await _service.loadFriends();

      setState(() => _isLoading = false);
      Logger.success('FriendsSchedule', 'Data loaded successfully');
    } catch (e) {
      Logger.e('FriendsSchedule', 'Failed to load data', e);
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load schedule data');
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _onCellTap(String day, String timeSlot) {
    setState(() {
      _selectedDay = day;
      _selectedTimeSlot = timeSlot;
    });
    _showSlotDetailsCard();
  }

  void _showAddFriends() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddFriendsPage()),
    );
    if (result == true) {
      await _loadData();
    }
  }

  void _showQRShare() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('student_profile');

    String name = _studentName;
    String reg = _studentReg;

    if (profileJson != null && profileJson.isNotEmpty) {
      try {
        final profile = jsonDecode(profileJson) as Map<String, dynamic>;
        name = profile['name']?.toString() ?? _studentName;
        reg = profile['registerNumber']?.toString() ?? _studentReg;
      } catch (e) {
        Logger.w('FriendsSchedule', 'Failed to parse profile for QR: $e');
      }
    }

    final qrData = await _service.generateOwnQRData();
    if (qrData == null) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to generate QR code');
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => QRCodeShareWidget(
                qrData: qrData,
                studentName: name,
                studentReg: reg,
              ),
        ),
      );
    }
  }

  void _showSlotDetailsCard() {
    if (_selectedDay == null || _selectedTimeSlot == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSlotDetailsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.text,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Friends' Schedule",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_studentName.isNotEmpty)
              Text(
                _studentName,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.muted,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, size: 22),
            onPressed: _showQRShare,
            tooltip: 'Share QR Code',
          ),
          Padding(
            padding: EdgeInsets.only(right: screenWidth < 360 ? 4 : 8),
            child: ElevatedButton.icon(
              onPressed: _showAddFriends,
              icon: Icon(Icons.person_add, size: screenWidth < 360 ? 16 : 18),
              label: Text(
                screenWidth < 360 ? 'Add' : 'Add Friends',
                style: TextStyle(fontSize: screenWidth < 360 ? 11 : 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 8 : 12,
                  vertical: screenWidth < 360 ? 6 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : RefreshIndicator(
                onRefresh: _handleRefresh,
                color: theme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMyScheduleSection(themeProvider),
                      SizedBox(height: screenWidth < 360 ? 12 : 16),
                      if (_service.friends.isNotEmpty) ...[
                        _buildFriendsSection(themeProvider),
                        SizedBox(height: screenWidth < 360 ? 12 : 16),
                      ],
                      if (_service.friendsForSchedulePage.isNotEmpty) ...[
                        _buildOverallSchedulesSection(themeProvider),
                        SizedBox(height: screenWidth < 360 ? 16 : 24),
                      ],
                      if (_service.friendsForSchedulePage.isNotEmpty)
                        ..._service.friendsForSchedulePage.map(
                          (friend) => Padding(
                            padding: EdgeInsets.only(
                              bottom: screenWidth < 360 ? 12 : 16,
                            ),
                            child: _buildFriendMatrix(friend, themeProvider),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _showColorPicker(Friend friend, dynamic theme) async {
    Color? selectedColor;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Choose color for ${friend.nickname}',
              style: TextStyle(color: theme.text, fontSize: 16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: ScheduleConstants.friendColorValues.length,
                itemBuilder: (context, index) {
                  final color = Color(
                    ScheduleConstants.friendColorValues[index],
                  );
                  final isSelected = friend.color.value == color.value;

                  return GestureDetector(
                    onTap: () {
                      selectedColor = color;
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.muted)),
              ),
            ],
          ),
    );

    if (selectedColor != null) {
      await _service.updateFriendColor(friend.id, selectedColor!);
      setState(() {});
      if (mounted) {
        SnackbarUtils.success(context, 'Color updated');
      }
    }
  }

  Widget _buildMyScheduleSection(ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY SCHEDULE',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: theme.text,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 8 : 12),
          _buildScheduleMatrix(
            _ownSchedule?.classSlots ?? [],
            theme.primary,
            themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FRIENDS (${_service.friendsForSchedulePage.length}/${_service.friends.length})',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: theme.text,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 8 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _service.friendsForSchedulePage.map((friend) {
                  return GestureDetector(
                    onLongPress: () => _showColorPicker(friend, theme),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 8 : 12,
                        vertical: screenWidth < 360 ? 6 : 8,
                      ),
                      decoration: AppCardStyles.smallWidgetDecoration(
                        isDark: theme.isDark,
                        customBackgroundColor: friend.color.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: screenWidth < 360 ? 16 : 20,
                            height: screenWidth < 360 ? 16 : 20,
                            decoration: BoxDecoration(
                              color: friend.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                friend.nickname[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth < 360 ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth < 360 ? 6 : 8),
                          Text(
                            friend.nickname,
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 11 : 12,
                              color: friend.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: screenWidth < 360 ? 2 : 4),
                          Icon(
                            Icons.palette,
                            size: screenWidth < 360 ? 10 : 12,
                            color: friend.color.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSchedulesSection(ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERALL SCHEDULES',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: theme.text,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 8 : 12),
          _buildOverallMatrix(themeProvider),
        ],
      ),
    );
  }

  Widget _buildScheduleMatrix(
    List<dynamic> slots,
    Color cellColor,
    ThemeProvider themeProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12 : 16;
    final containerMargin = screenWidth < 360 ? 24 : 32;
    final availableWidth =
        screenWidth - (horizontalPadding * 2) - containerMargin - 10;
    final cellSpacing = screenWidth < 360 ? 1.0 : 1.2;
    final cellWidth =
        (availableWidth / ScheduleConstants.timeSlots.length) - cellSpacing;
    final cellHeight = screenWidth < 360 ? 16.0 : 20.0;

    final now = DateTime.now();
    final currentDay =
        now.weekday <= 5 ? ScheduleConstants.weekDays[now.weekday - 1] : null;
    final currentHour = now.hour;
    final currentMinute = now.minute;

    return Column(
      children:
          ScheduleConstants.weekDays.asMap().entries.map((dayEntry) {
            final day = dayEntry.value;
            final isCurrentDay = day == currentDay;

            return Padding(
              padding: EdgeInsets.only(bottom: screenWidth < 360 ? 1.5 : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children:
                    ScheduleConstants.timeSlots.asMap().entries.map((
                      timeEntry,
                    ) {
                      final timeSlot = timeEntry.value;

                      final hasClass = slots.any(
                        (s) => s.day == day && s.timeSlot == timeSlot,
                      );
                      final isSelected =
                          _selectedDay == day && _selectedTimeSlot == timeSlot;

                      final isCurrentTime = _isCurrentTimeSlot(
                        timeSlot,
                        currentHour,
                        currentMinute,
                      );
                      final isCurrentCell = isCurrentDay && isCurrentTime;

                      return Padding(
                        padding: EdgeInsets.only(
                          right: screenWidth < 360 ? 1.0 : 1.2,
                        ),
                        child: GestureDetector(
                          onTap: () => _onCellTap(day, timeSlot),
                          child: Container(
                            width: cellWidth,
                            height: cellHeight,
                            decoration: BoxDecoration(
                              color: hasClass ? cellColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                screenWidth < 360 ? 3 : 4,
                              ),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.amber
                                        : isCurrentCell
                                        ? Colors.orange
                                        : hasClass
                                        ? cellColor
                                        : themeProvider.currentTheme.border
                                            .withValues(alpha: 0.3),
                                width:
                                    isSelected
                                        ? 3
                                        : isCurrentCell
                                        ? 2
                                        : hasClass
                                        ? 1.5
                                        : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildOverallMatrix(ThemeProvider themeProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12 : 16;
    final containerMargin = screenWidth < 360 ? 24 : 32;
    final availableWidth =
        screenWidth - (horizontalPadding * 2) - containerMargin - 10;
    final cellSpacing = screenWidth < 360 ? 1.0 : 1.2;
    final cellWidth =
        (availableWidth / ScheduleConstants.timeSlots.length) - cellSpacing;
    final cellHeight = screenWidth < 360 ? 16.0 : 20.0;

    final now = DateTime.now();
    final currentDay =
        now.weekday <= 5 ? ScheduleConstants.weekDays[now.weekday - 1] : null;
    final currentHour = now.hour;
    final currentMinute = now.minute;

    return Column(
      children:
          ScheduleConstants.weekDays.asMap().entries.map((dayEntry) {
            final day = dayEntry.value;
            final isCurrentDay = day == currentDay;

            return Padding(
              padding: EdgeInsets.only(bottom: screenWidth < 360 ? 1.5 : 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children:
                    ScheduleConstants.timeSlots.asMap().entries.map((
                      timeEntry,
                    ) {
                      final timeSlot = timeEntry.value;

                      final friendsWithClass = _service.getFriendsWithClassAt(
                        day,
                        timeSlot,
                      );
                      final ownHasClass =
                          _ownSchedule?.hasClassAt(day, timeSlot) ?? false;
                      final busyCount =
                          friendsWithClass.length + (ownHasClass ? 1 : 0);

                      final isSelected =
                          _selectedDay == day && _selectedTimeSlot == timeSlot;
                      final isCurrentTime = _isCurrentTimeSlot(
                        timeSlot,
                        currentHour,
                        currentMinute,
                      );
                      final isCurrentCell = isCurrentDay && isCurrentTime;

                      Color cellColor = Colors.transparent;
                      List<Color> friendColors = [];

                      if (ownHasClass) {
                        friendColors.add(themeProvider.currentTheme.primary);
                      }

                      for (final friend in friendsWithClass) {
                        friendColors.add(friend.color);
                      }

                      if (friendColors.isNotEmpty) {
                        if (friendColors.length == 1) {
                          cellColor = friendColors.first.withValues(alpha: 0.7);
                        } else {
                          final colorIndex =
                              (DateTime.now().millisecondsSinceEpoch ~/ 1000) %
                              friendColors.length;
                          cellColor = friendColors[colorIndex].withValues(
                            alpha: 0.7,
                          );
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          right: screenWidth < 360 ? 1.0 : 1.2,
                        ),
                        child: GestureDetector(
                          onTap: () => _onCellTap(day, timeSlot),
                          child: Container(
                            width: cellWidth,
                            height: cellHeight,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(
                                screenWidth < 360 ? 3 : 4,
                              ),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.amber
                                        : isCurrentCell
                                        ? Colors.orange
                                        : friendColors.isNotEmpty
                                        ? friendColors.first
                                        : themeProvider.currentTheme.border
                                            .withValues(alpha: 0.3),
                                width:
                                    isSelected
                                        ? 3
                                        : isCurrentCell
                                        ? 2
                                        : friendColors.isNotEmpty
                                        ? 1.5
                                        : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }

  bool _isCurrentTimeSlot(String timeSlot, int currentHour, int currentMinute) {
    try {
      final parts = timeSlot.split('-');
      if (parts.length != 2) return false;

      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final currentTotalMinutes = currentHour * 60 + currentMinute;
      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      return currentTotalMinutes >= startTotalMinutes &&
          currentTotalMinutes <= endTotalMinutes;
    } catch (e) {
      return false;
    }
  }

  Widget _buildFriendMatrix(Friend friend, ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: friend.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth < 360 ? 32 : 36,
                height: screenWidth < 360 ? 32 : 36,
                decoration: BoxDecoration(
                  color: friend.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    friend.nickname.isNotEmpty
                        ? friend.nickname[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 360 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth < 360 ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.nickname,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      friend.regNumber,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 10 : 12,
                        color: theme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth < 360 ? 8 : 12),
          _buildScheduleMatrix(friend.classSlots, friend.color, themeProvider),
        ],
      ),
    );
  }

  Widget _buildSlotDetailsBottomSheet() {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      return const SizedBox();
    }

    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final allFriends = [
      if (_ownSchedule != null) _ownSchedule!,
      ..._service.friendsForSchedulePage,
    ];

    final busyFriends = <Friend>[];
    final freeFriends = <Friend>[];

    for (final friend in allFriends) {
      if (friend.hasClassAt(_selectedDay!, _selectedTimeSlot!)) {
        busyFriends.add(friend);
      } else {
        freeFriends.add(friend);
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 360 ? 16 : 20,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.primary,
                  size: screenWidth < 360 ? 20 : 24,
                ),
                SizedBox(width: screenWidth < 360 ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDay!,
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        _selectedTimeSlot!,
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 12 : 14,
                          color: theme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDay = null;
                      _selectedTimeSlot = null;
                    });
                  },
                  icon: Icon(Icons.close, color: theme.muted),
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 16 : 20),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 16 : 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                            SizedBox(width: screenWidth < 360 ? 6 : 8),
                            Text(
                              'Free (${freeFriends.length})',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth < 360 ? 8 : 12),
                        if (freeFriends.isEmpty)
                          Text(
                            'No one is free',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: screenWidth < 360 ? 12 : 14,
                            ),
                          )
                        else
                          ...freeFriends.map(
                            (friend) => Padding(
                              padding: EdgeInsets.only(
                                bottom: screenWidth < 360 ? 6 : 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: screenWidth < 360 ? 20 : 24,
                                    height: screenWidth < 360 ? 20 : 24,
                                    decoration: BoxDecoration(
                                      color: friend.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.nickname[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth < 360 ? 9 : 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth < 360 ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      friend.nickname,
                                      style: TextStyle(
                                        fontSize: screenWidth < 360 ? 12 : 14,
                                        color: theme.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth < 360 ? 16 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                            SizedBox(width: screenWidth < 360 ? 6 : 8),
                            Text(
                              'Busy (${busyFriends.length})',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth < 360 ? 8 : 12),
                        if (busyFriends.isEmpty)
                          Text(
                            'Everyone is free!',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: screenWidth < 360 ? 12 : 14,
                            ),
                          )
                        else
                          ...busyFriends.map((friend) {
                            final slot = friend.getSlotForCell(
                              _selectedDay!,
                              _selectedTimeSlot!,
                            );
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: screenWidth < 360 ? 8 : 12,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(
                                  screenWidth < 360 ? 8 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: friend.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: friend.color.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: screenWidth < 360 ? 18 : 20,
                                          height: screenWidth < 360 ? 18 : 20,
                                          decoration: BoxDecoration(
                                            color: friend.color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              friend.nickname[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    screenWidth < 360 ? 8 : 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: screenWidth < 360 ? 6 : 8,
                                        ),
                                        Expanded(
                                          child: Text(
                                            friend.nickname,
                                            style: TextStyle(
                                              fontSize:
                                                  screenWidth < 360 ? 11 : 12,
                                              fontWeight: FontWeight.bold,
                                              color: theme.text,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (slot != null) ...[
                                      SizedBox(
                                        height: screenWidth < 360 ? 6 : 8,
                                      ),
                                      Text(
                                        '${slot.courseCode} - ${slot.courseTitle}',
                                        style: TextStyle(
                                          fontSize: screenWidth < 360 ? 10 : 11,
                                          color: theme.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (slot.venue.isNotEmpty) ...[
                                        SizedBox(
                                          height: screenWidth < 360 ? 3 : 4,
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: screenWidth < 360 ? 10 : 12,
                                              color: theme.muted,
                                            ),
                                            SizedBox(
                                              width: screenWidth < 360 ? 3 : 4,
                                            ),
                                            Expanded(
                                              child: Text(
                                                slot.venue,
                                                style: TextStyle(
                                                  fontSize:
                                                      screenWidth < 360
                                                          ? 9
                                                          : 10,
                                                  color: theme.muted,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (slot.slotId.isNotEmpty) ...[
                                        SizedBox(
                                          height: screenWidth < 360 ? 3 : 4,
                                        ),
                                        Text(
                                          'Slot: ${slot.slotId}',
                                          style: TextStyle(
                                            fontSize:
                                                screenWidth < 360 ? 9 : 10,
                                            color: theme.muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 16 : 20),
        ],
      ),
    );
  }
}
