import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/color_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/utils/logger.dart';
import '../../logic/home_logic.dart';

/// Widget displaying overall attendance
class AttendanceWidget extends StatelessWidget {
  static const String _tag = 'AttendanceWidget';

  final HomeLogic homeLogic;

  const AttendanceWidget({super.key, required this.homeLogic});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final attendanceData = homeLogic.attendanceData;
    final overallAttendance = homeLogic.calculateOverallAttendance(
      attendanceData,
    );

    final attended = attendanceData.fold(
      0,
      (sum, item) => sum + (item['attended'] as int? ?? 0),
    );
    final total = attendanceData.fold(
      0,
      (sum, item) => sum + (item['total'] as int? ?? 0),
    );

    // Get attendance color
    final attendanceColor = ColorUtils.getAttendanceColorFromProvider(
      themeProvider,
      overallAttendance,
    );

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Label
            Column(
              children: [
                Text(
                  'OVERALL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.currentTheme.muted,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'ATTENDANCE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.currentTheme.muted,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Attendance percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: attendanceColor, width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${overallAttendance.floor()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: attendanceColor,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Attended/Total classes
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$attended / $total classes',
                style: TextStyle(
                  fontSize: 11,
                  color: themeProvider.currentTheme.text,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
