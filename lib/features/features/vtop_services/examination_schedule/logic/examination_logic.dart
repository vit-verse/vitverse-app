/// Business logic for examination schedule
class ExaminationLogic {
  /// Format exam date and time
  String formatExamDateTime(int? timestamp) {
    if (timestamp == null) return 'TBA';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final examDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      final difference = examDate.difference(today).inDays;

      if (difference == 0) {
        return 'Today, ${_formatTime(dateTime)}';
      } else if (difference == 1) {
        return 'Tomorrow, ${_formatTime(dateTime)}';
      } else if (difference > 1 && difference <= 7) {
        return '${_getWeekday(dateTime.weekday)}, ${_formatTime(dateTime)}';
      } else {
        return '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} • ${_formatTime(dateTime)}';
      }
    } catch (e) {
      return 'Invalid Date';
    }
  }

  /// Format exam date only
  String formatExamDate(int? timestamp) {
    if (timestamp == null) return 'TBA';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${_getWeekdayShort(dateTime.weekday)}, ${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  /// Format exam time only
  String formatExamTime(int? startTimestamp, int? endTimestamp) {
    if (startTimestamp == null) return 'TBA';

    try {
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
      final startStr = _formatTime(startTime);

      if (endTimestamp != null) {
        final endTime = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
        final endStr = _formatTime(endTime);
        return '$startStr - $endStr';
      }

      return startStr;
    } catch (e) {
      return 'Invalid Time';
    }
  }

  /// Format time to 12-hour format
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }

  /// Get weekday name
  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  /// Get short weekday name
  String _getWeekdayShort(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  /// Get month name
  String _getMonth(int month) {
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

  /// Get countdown text for exam
  String getExamCountdown(int? timestamp) {
    if (timestamp == null) return 'Date TBA';

    try {
      final examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = examDateTime.difference(now);

      if (difference.isNegative) {
        return 'Completed';
      } else if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'In ${difference.inMinutes} minutes';
        }
        return 'In ${difference.inHours} hours';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays <= 7) {
        return 'In ${difference.inDays} days';
      } else if (difference.inDays <= 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
      } else {
        final months = (difference.inDays / 30).floor();
        return 'In $months ${months == 1 ? 'month' : 'months'}';
      }
    } catch (e) {
      return 'Date TBA';
    }
  }

  /// Get short countdown text for exam (for small capsule)
  String getExamCountdownShort(int? timestamp) {
    if (timestamp == null) return 'TBA';

    try {
      final examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final examDate = DateTime(
        examDateTime.year,
        examDateTime.month,
        examDateTime.day,
      );
      final difference = examDate.difference(today).inDays;

      if (difference < 0) {
        // Show exact days ago
        final daysAgo = -difference;
        return '$daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago';
      } else if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else {
        // Show exact days remaining
        return 'In $difference ${difference == 1 ? 'day' : 'days'}';
      }
    } catch (e) {
      return 'TBA';
    }
  }

  /// Get exam status color indicator
  ExamStatus getExamStatus(int? timestamp) {
    if (timestamp == null) return ExamStatus.scheduled;

    try {
      final examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = examDateTime.difference(now);

      if (difference.isNegative) {
        return ExamStatus.completed;
      } else if (difference.inDays == 0) {
        return ExamStatus.today;
      } else if (difference.inDays <= 7) {
        return ExamStatus.upcoming;
      } else {
        return ExamStatus.scheduled;
      }
    } catch (e) {
      return ExamStatus.scheduled;
    }
  }

  /// Extract exam types from exam list and sort by earliest exam date
  List<String> extractExamTypes(
    Map<String, List<Map<String, dynamic>>> examsByType,
  ) {
    if (examsByType.isEmpty) return [];

    // Create a list of types with their earliest exam timestamp
    final typeWithTimestamp = <Map<String, dynamic>>[];

    examsByType.forEach((type, exams) {
      if (exams.isNotEmpty) {
        // Find the earliest exam for this type
        int? earliestTime;
        for (var exam in exams) {
          final startTime = exam['start_time'] as int?;
          if (startTime != null) {
            if (earliestTime == null || startTime < earliestTime) {
              earliestTime = startTime;
            }
          }
        }

        typeWithTimestamp.add({'type': type, 'timestamp': earliestTime ?? 0});
      }
    });

    // Sort by timestamp (earliest first)
    typeWithTimestamp.sort((a, b) {
      final aTime = a['timestamp'] as int;
      final bTime = b['timestamp'] as int;
      return aTime.compareTo(bTime);
    });

    // Extract sorted types
    return typeWithTimestamp.map((e) => e['type'] as String).toList();
  }

  /// Check if exam is in the past
  bool isExamPast(int? timestamp) {
    if (timestamp == null) return false;

    try {
      final examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return examDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get days until exam
  int getDaysUntilExam(int? timestamp) {
    if (timestamp == null) return -1;

    try {
      final examDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final examDate = DateTime(
        examDateTime.year,
        examDateTime.month,
        examDateTime.day,
      );

      return examDate.difference(today).inDays;
    } catch (e) {
      return -1;
    }
  }
}

/// Enum for exam status
enum ExamStatus { completed, today, upcoming, scheduled }
