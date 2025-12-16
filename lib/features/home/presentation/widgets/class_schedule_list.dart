import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/loading/skeleton_widgets.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/themed_lottie_widget.dart';
import '../../logic/home_logic.dart';
import 'class_card.dart';

/// Widget displaying the list of classes for a specific day
class ClassScheduleList extends StatefulWidget {
  static const String _tag = 'ClassScheduleList';

  final int dayIndex;
  final HomeLogic homeLogic;
  final bool isDataLoading;

  const ClassScheduleList({
    super.key,
    required this.dayIndex,
    required this.homeLogic,
    required this.isDataLoading,
  });

  @override
  State<ClassScheduleList> createState() => _ClassScheduleListState();
}

class _ClassScheduleListState extends State<ClassScheduleList> {
  static const String _tag = 'ClassScheduleList';
  Set<int> _holidayDays = {};

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final holidayList = prefs.getStringList('holiday_days') ?? [];

      if (mounted) {
        setState(() {
          _holidayDays = holidayList.map((day) => int.parse(day)).toSet();
        });
      }

      Logger.d(_tag, 'Loaded holidays: $_holidayDays');
    } catch (e) {
      Logger.e(_tag, 'Failed to load holidays', e);
    }
  }

  Widget _buildEmptyState(
    ThemeProvider themeProvider,
    String title,
    String subtitle,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen Lottie animation
        const Positioned.fill(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: ThemedLottieWidget(
            assetPath: 'assets/lottie/SpaceCat.lottie',
            fallbackIcon: Icons.celebration_rounded,
            fallbackText: 'Holiday',
            showContainer: false,
          ),
        ),
        // Text overlay in the center
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.background.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.currentTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Show skeleton loading while data is loading
        if (widget.isDataLoading) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SkeletonWidgets.classCard(themeProvider),
                ),
              ),
            ),
          );
        }

        // Check if this day is marked as holiday
        final isHoliday = _holidayDays.contains(widget.dayIndex);

        // If it's a holiday, show holiday message with full screen animation
        if (isHoliday) {
          return _buildEmptyState(
            themeProvider,
            'Holiday',
            'No classes scheduled',
          );
        }

        // Get classes for the day
        final dayClasses = widget.homeLogic.getClassesForDay(widget.dayIndex);

        // Sort classes by start time
        dayClasses.sort((a, b) {
          final timeA = a['start_time']?.toString() ?? '';
          final timeB = b['start_time']?.toString() ?? '';
          return timeA.compareTo(timeB);
        });

        if (dayClasses.isEmpty) {
          return _buildEmptyState(
            themeProvider,
            'No classes scheduled',
            'Enjoy your free day!',
          );
        }

        // Return scrollable ListView to show all classes
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dayClasses.length,
          itemBuilder: (context, index) {
            final classData = dayClasses[index];
            return ClassCard(
              classData: classData,
              dayIndex: widget.dayIndex,
              homeLogic: widget.homeLogic,
            );
          },
        );
      },
    );
  }
}
