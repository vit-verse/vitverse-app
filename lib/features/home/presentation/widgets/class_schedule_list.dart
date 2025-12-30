import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/themed_lottie_widget.dart';
import '../../logic/home_logic.dart';
import 'class_card.dart';

/// Widget displaying the list of classes for a specific day
class ClassScheduleList extends StatefulWidget {
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
    } catch (e) {
      // Silent error handling
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
        const Positioned.fill(
          child: ThemedLottieWidget(
            assetPath: 'assets/lottie/SpaceCat.lottie',
            fallbackIcon: Icons.celebration_rounded,
            fallbackText: 'Holiday',
            showContainer: false,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.background.withValues(alpha: 0.8),
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
        final isHoliday = _holidayDays.contains(widget.dayIndex);

        if (isHoliday) {
          return _buildEmptyState(
            themeProvider,
            'Holiday',
            'No classes scheduled',
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.homeLogic.getCombinedClassesForDay(widget.dayIndex),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: themeProvider.currentTheme.primary,
                  ),
                ),
              );
            }

            final dayClasses = snapshot.data ?? [];

            if (dayClasses.isEmpty) {
              return _buildEmptyState(
                themeProvider,
                'No classes scheduled',
                'Enjoy your free day!',
              );
            }

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
      },
    );
  }
}
