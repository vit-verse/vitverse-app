import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/sync_notifier.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../logic/attendance_analytics_logic.dart';
import '../widgets/overall_attendance_summary_card.dart';
import '../widgets/course_attendance_card.dart';

/// Main attendance analytics page with overall summary and course cards
class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() =>
      _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  final AttendanceAnalyticsLogic _logic = AttendanceAnalyticsLogic();

  Map<String, dynamic>? _overallData;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String? _error;
  double? _syncedTarget;
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AttendanceAnalytics',
      screenClass: 'AttendanceAnalyticsPage',
    );
    reload();
    _syncSubscription = SyncNotifier.instance.onSyncComplete.listen((_) {
      reload();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attendanceData = await _logic.getAttendanceData();
      final userData = await _logic.getUserData();

      final overallStats = await _logic.calculateOverallStats(attendanceData);
      final lastSynced = _logic.formatLastSynced(userData['last_refresh']);

      setState(() {
        _overallData = {'overallStats': overallStats, 'lastSynced': lastSynced};
        _courses = attendanceData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleTargetChange(double newTarget) {
    setState(() {
      _syncedTarget = newTarget;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        title: Text(
          'Attendance Analytics',
          style: TextStyle(
            color: themeProvider.currentTheme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: themeProvider.currentTheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.currentTheme.text),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: themeProvider.currentTheme.text,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: themeProvider.currentTheme.surface,
                      title: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: themeProvider.currentTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Note',
                            style: TextStyle(
                              color: themeProvider.currentTheme.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'VTOP rounds up attendance percentages. We display the exact calculated percentage for precision.',
                        style: TextStyle(
                          color: themeProvider.currentTheme.text,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Got it',
                            style: TextStyle(
                              color: themeProvider.currentTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(themeProvider),
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
              'Failed to load attendance data',
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
              onPressed: _loadData,
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

    if (_overallData == null) {
      return Center(
        child: Text(
          'No attendance data available',
          style: TextStyle(
            color: themeProvider.currentTheme.muted,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: themeProvider.currentTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OverallAttendanceSummaryCard(
                overallStats: _overallData!['overallStats'],
                lastSynced: _overallData!['lastSynced'],
                onTargetChanged: _handleTargetChange,
              ),
            ),
          ),

          if (_courses.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No course attendance data',
                    style: TextStyle(
                      color: themeProvider.currentTheme.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      1.05, // Increased height to prevent title overflow
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return CourseAttendanceCard(
                    courseData: _courses[index],
                    targetPercentage: _syncedTarget ?? 75.0,
                  );
                }, childCount: _courses.length),
              ),
            ),
        ],
      ),
    );
  }
}
