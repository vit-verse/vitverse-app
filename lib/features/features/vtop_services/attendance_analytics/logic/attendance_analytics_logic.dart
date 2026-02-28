import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/daos/attendance_dao.dart';
import '../../../../../core/database/daos/attendance_detail_dao.dart';
import '../../../../authentication/core/auth_service.dart';
import '../../../../../core/utils/logger.dart';

/// Business logic for attendance analytics
/// Handles calculations, formatting, and data processing
class AttendanceAnalyticsLogic {
  final AttendanceDao _attendanceDao = AttendanceDao();
  final AttendanceDetailDao _attendanceDetailDao = AttendanceDetailDao();
  final VTOPAuthService _authService = VTOPAuthService.instance;

  Future<List<Map<String, dynamic>>> getAttendanceData() async {
    try {
      return await _attendanceDao.getAttendanceWithCourses();
    } catch (e) {
      Logger.e('AttendanceAnalytics', 'Failed to fetch attendance data', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      return await _authService.getUserData();
    } catch (e) {
      Logger.e('AttendanceAnalytics', 'Failed to fetch user data', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> calculateOverallStats(
    List<Map<String, dynamic>> attendanceData,
  ) async {
    if (attendanceData.isEmpty) {
      return {
        'percentage': 0.0,
        'present': 0,
        'onDuty': 0,
        'absent': 0,
        'total': 0,
      };
    }

    int totalPresent = 0;
    int totalClasses = 0;
    int totalOnDuty = 0;

    for (var attendance in attendanceData) {
      final attendanceId = attendance['id'] as int?;
      final attended = (attendance['attended'] as int?) ?? 0;
      final total = (attendance['total'] as int?) ?? 0;

      totalPresent += attended;
      totalClasses += total;

      if (attendanceId != null) {
        try {
          final odCount = await _attendanceDetailDao.getOnDutyCount(
            attendanceId,
          );
          totalOnDuty += odCount;
        } catch (e) {
          Logger.w(
            'AttendanceAnalytics',
            'Failed to fetch OD count for attendance $attendanceId',
          );
        }
      }
    }

    final absent = totalClasses - totalPresent;
    final percentage =
        totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0.0;

    return {
      'percentage': percentage,
      'present': totalPresent,
      'onDuty': totalOnDuty,
      'absent': absent,
      'total': totalClasses,
    };
  }

  /// Calculate classes needed to maintain target
  /// Positive: can miss, Negative: need to attend
  int calculateClassesToTarget({
    required int attended,
    required int total,
    required double targetPercentage,
  }) {
    if (total == 0) return 0;

    final clampedTarget = targetPercentage.clamp(0.1, 99.9);
    final currentPercentage = (attended / total) * 100;
    final target = clampedTarget / 100;

    if (currentPercentage < clampedTarget) {
      final divisor = 1 - target;
      if (divisor.abs() < 1e-9) return -total;
      final classesNeeded = ((target * total - attended) / divisor).ceil();
      return -classesNeeded.abs();
    } else if (currentPercentage >= 99.99) {
      if (target.abs() < 1e-9) return total;
      final maxTotal = (attended / target).floor();
      return maxTotal - total;
    } else {
      if (target.abs() < 1e-9) return total;
      final canMiss = ((attended - target * total) / target).floor();
      return canMiss >= 0 ? canMiss : 0;
    }
  }

  String formatLastSynced(int? timestamp) {
    if (timestamp == null) return 'Never synced';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    final monthNames = [
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

    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;

    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today at $hour:$minute $ampm';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Yesterday at $hour:$minute $ampm';
    }

    return '$month $day, $year at $hour:$minute $ampm';
  }

  static Color getAttendanceColorFromProvider(
    ThemeProvider provider,
    double percentage,
  ) {
    return provider.attendanceColorScheme.getColor(percentage);
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final time = '$formattedHour:$minute $ampm';

    final month = _getMonthName(dateTime.month);
    final day = dateTime.day;

    final year = dateTime.year.toString();

    if (date.isAtSameMomentAs(today)) {
      return 'Today at $time';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return 'Yesterday at $time';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow at $time';
    }

    return '$month $day, $year at $time';
  }

  static String _getMonthName(int month) {
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
}
