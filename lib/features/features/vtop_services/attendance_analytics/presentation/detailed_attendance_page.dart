import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/daos/attendance_detail_dao.dart';
import '../../../../../core/database/entities/attendance_detail.dart';
import '../../../../../core/utils/sync_notifier.dart';
import '../../../../../firebase/analytics/analytics_service.dart';

/// Day-wise detailed attendance view for a course
class DetailedAttendancePage extends StatefulWidget {
  final String courseCode;
  final String courseName;
  final int attendanceId;
  final int attended;
  final int total;
  final double percentage;

  const DetailedAttendancePage({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.attendanceId,
    required this.attended,
    required this.total,
    required this.percentage,
  });

  @override
  State<DetailedAttendancePage> createState() => _DetailedAttendancePageState();
}

class _DetailedAttendancePageState extends State<DetailedAttendancePage> {
  final AttendanceDetailDao _dao = AttendanceDetailDao();
  List<AttendanceDetail> _details = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'DetailedAttendance',
      screenClass: 'DetailedAttendancePage',
    );
    _loadDetails();
    _syncSubscription = SyncNotifier.instance.onSyncComplete.listen((_) {
      if (mounted) _loadDetails();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _dao.getByAttendanceId(widget.attendanceId);

      details.sort((a, b) {
        try {
          final dateA = DateFormat('dd-MMM-yyyy').parse(a.attendanceDate);
          final dateB = DateFormat('dd-MMM-yyyy').parse(b.attendanceDate);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return const Color(0xFF059669);
      case 'ABSENT':
        return const Color(0xFFDC2626);
      case 'ON DUTY':
        return const Color(0xFFF59E0B);
      case 'MEDICAL LEAVE':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return Icons.check_circle;
      case 'ABSENT':
        return Icons.cancel;
      case 'ON DUTY':
        return Icons.work;
      case 'MEDICAL LEAVE':
        return Icons.local_hospital;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse "11-Sep-2025" format
      final date = DateFormat('dd-MMM-yyyy').parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _extractDay(String dayAndTiming) {
    return dayAndTiming.split(',').first;
  }

  String _extractTiming(String dayAndTiming) {
    final parts = dayAndTiming.split(',');
    return parts.length > 1 ? parts[1] : '';
  }

  int _calculateOnDutyCount() {
    int totalOdCount = 0;
    for (final detail in _details) {
      if (detail.attendanceStatus.toUpperCase() == 'ON DUTY') {
        final slotCount = detail.attendanceSlot.split('+').length;
        totalOdCount += slotCount;
      }
    }
    return totalOdCount;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day-wise Attendance',
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.courseCode,
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.currentTheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.currentTheme.text),
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseName,
                  style: TextStyle(
                    color: themeProvider.currentTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      themeProvider,
                      'Classes',
                      '${widget.attended}/${widget.total}',
                      Icons.event_note,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
                    ),
                    _buildSummaryItem(
                      themeProvider,
                      'Percentage',
                      '${widget.percentage.toStringAsFixed(1)}%',
                      Icons.percent,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
                    ),
                    _buildSummaryItem(
                      themeProvider,
                      'On Duty',
                      '${_calculateOnDutyCount()}',
                      Icons.work,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details List
          Expanded(child: _buildBody(themeProvider)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeProvider theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.currentTheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: theme.currentTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.currentTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: themeProvider.currentTheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeProvider.currentTheme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load attendance details',
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_details.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: themeProvider.currentTheme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              'No detailed attendance records',
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Day-wise attendance data not available',
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _details.length,
      itemBuilder: (context, index) {
        final detail = _details[index];
        return _buildAttendanceCard(themeProvider, detail);
      },
    );
  }

  Widget _buildAttendanceCard(ThemeProvider theme, AttendanceDetail detail) {
    final statusColor = _getStatusColor(context, detail.attendanceStatus);
    final statusIcon = _getStatusIcon(detail.attendanceStatus);
    final day = _extractDay(detail.dayAndTiming);
    final timing = _extractTiming(detail.dayAndTiming);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.currentTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.currentTheme.muted.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Date
                    Text(
                      _formatDate(detail.attendanceDate),
                      style: TextStyle(
                        color: theme.currentTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Day badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.currentTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: theme.currentTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Slot
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: theme.currentTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      detail.attendanceSlot,
                      style: TextStyle(
                        color: theme.currentTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Timing
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: theme.currentTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timing,
                      style: TextStyle(
                        color: theme.currentTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              detail.attendanceStatus.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
