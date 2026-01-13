import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../logic/examination_logic.dart';

/// Individual exam card widget - displays all exam details
class ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final ThemeProvider themeProvider;
  final ExaminationLogic logic;

  const ExamCard({
    super.key,
    required this.exam,
    required this.themeProvider,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final course = exam['course'] as Map<String, dynamic>?;
    final courseCode = course?['code']?.toString() ?? 'N/A';
    final courseTitle = course?['title']?.toString() ?? 'Unknown Course';
    final venue = exam['venue']?.toString() ?? 'Venue TBA';
    final seatLocation = exam['seat_location']?.toString();
    final seatNumber = exam['seat_number']?.toString();
    final startTime = exam['start_time'] as int?;
    final endTime = exam['end_time'] as int?;
    final slots = exam['slots'] as List<dynamic>? ?? [];

    final status = logic.getExamStatus(startTime);
    final isCompleted = status == ExamStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppCardStyles.largeCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor:
            isCompleted
                ? themeProvider.currentTheme.surface.withValues(alpha: 0.5)
                : themeProvider.currentTheme.surface,
      ),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with course code and status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.currentTheme.primary.withOpacity(
                        0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      courseCode,
                      style: TextStyle(
                        color: themeProvider.currentTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      logic.getExamCountdownShort(startTime),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Course title
              Text(
                courseTitle,
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Slots display
              if (slots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      slots.map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.currentTheme.muted.withOpacity(
                              0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: themeProvider.currentTheme.muted
                                  .withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            slot.toString(),
                            style: TextStyle(
                              color: themeProvider.currentTheme.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Exam details - Two column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Date',
                          logic.formatExamDate(startTime),
                          themeProvider,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          'Venue',
                          venue,
                          themeProvider,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.schedule_outlined,
                          'Time',
                          logic.formatExamTime(startTime, endTime),
                          themeProvider,
                        ),
                        if (seatLocation != null || seatNumber != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.event_seat_outlined,
                            'Seat',
                            '${seatLocation ?? 'TBA'} ${seatNumber != null ? '- #$seatNumber' : ''}',
                            themeProvider,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeProvider themeProvider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: themeProvider.currentTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.currentTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ExamStatus status) {
    switch (status) {
      case ExamStatus.completed:
        return themeProvider.currentTheme.muted;
      case ExamStatus.today:
        return Colors.red;
      case ExamStatus.upcoming:
        return Colors.orange;
      case ExamStatus.scheduled:
        return themeProvider.currentTheme.primary;
    }
  }
}

/// Banner showing countdown to next exam
class ExamCountdownBanner extends StatelessWidget {
  final Map<String, dynamic>? nextExam;
  final ThemeProvider themeProvider;
  final ExaminationLogic logic;

  const ExamCountdownBanner({
    super.key,
    required this.nextExam,
    required this.themeProvider,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    if (nextExam == null) {
      return const SizedBox.shrink();
    }

    final course = nextExam!['course'] as Map<String, dynamic>?;
    final courseCode = course?['code']?.toString() ?? 'N/A';
    final courseTitle = course?['title']?.toString() ?? 'Unknown Course';
    final startTime = nextExam!['start_time'] as int?;
    final endTime = nextExam!['end_time'] as int?;
    final venue = nextExam!['venue']?.toString() ?? 'Venue TBA';
    final daysUntil = logic.getDaysUntilExam(startTime);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.currentTheme.primary,
            themeProvider.currentTheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.currentTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NEXT EXAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (daysUntil >= 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'TODAY'
                        : daysUntil == 1
                        ? 'TOMORROW'
                        : '$daysUntil DAYS',
                    style: TextStyle(
                      color: themeProvider.currentTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            courseCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            courseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  logic.formatExamTime(startTime, endTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  venue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tab bar for exam types (CAT 1, CAT 2, FAT, etc.)
class ExamTypeTabs extends StatelessWidget {
  final List<String> examTypes;
  final String selectedType;
  final Function(String) onTypeSelected;
  final ThemeProvider themeProvider;

  const ExamTypeTabs({
    super.key,
    required this.examTypes,
    required this.selectedType,
    required this.onTypeSelected,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (examTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: examTypes.length,
          itemBuilder: (context, index) {
            final type = examTypes[index];
            final isSelected = type == selectedType;

            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 16 : 6,
                right: index == examTypes.length - 1 ? 16 : 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTypeSelected(type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? themeProvider.currentTheme.primary
                              : themeProvider.currentTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? themeProvider.currentTheme.primary
                                : themeProvider.currentTheme.muted.withOpacity(
                                  0.2,
                                ),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 18,
                          color:
                              isSelected
                                  ? Colors.white
                                  : themeProvider.currentTheme.text,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : themeProvider.currentTheme.text,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Empty state widget when no exams are found
class EmptyExamState extends StatelessWidget {
  final String message;
  final ThemeProvider themeProvider;

  const EmptyExamState({
    super.key,
    required this.message,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.currentTheme.text.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Exams Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.currentTheme.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
