import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/daos/attendance_dao.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../models/models.dart';
import '../logic/attendance_logic.dart';
import '../widgets/attendance_sections.dart';
import '../widgets/attendance_widgets.dart';

class AttendanceMatrixPage extends StatefulWidget {
  const AttendanceMatrixPage({super.key});

  @override
  State<AttendanceMatrixPage> createState() => _AttendanceMatrixPageState();
}

class _AttendanceMatrixPageState extends State<AttendanceMatrixPage> {
  final AttendanceDao _attendanceDao = AttendanceDao();

  bool _isLoading = true;
  OverallAttendance? _overallAttendance;
  List<CourseAttendance> _courses = [];
  List<List<AttendanceMatrixCell>>? _overallMatrix;
  CourseAttendance? _selectedCourse;
  List<List<AttendanceMatrixCell>>? _courseMatrix;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'Attendance Matrix',
      screenClass: 'AttendenceMatrixPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final attendanceData = await _attendanceDao.getAttendanceWithCourses();

      if (!mounted) return;

      if (attendanceData.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackbarUtils.info(
            context,
            'No attendance data available. Please sync with VTOP first.',
          );
        }
        return;
      }

      final overall = OverallAttendance.fromCourses(attendanceData);
      final courses =
          attendanceData.map((data) => CourseAttendance.fromMap(data)).toList();
      final overallMatrix = AttendanceMatrixLogic.generateMatrix(
        currentAttended: overall.totalAttended,
        currentTotal: overall.totalClasses,
        isOverall: true,
      );

      if (mounted) {
        setState(() {
          _overallAttendance = overall;
          _courses = courses;
          _overallMatrix = overallMatrix;
          if (courses.isNotEmpty) {
            _selectedCourse = courses.first;
            _courseMatrix = AttendanceMatrixLogic.generateMatrix(
              currentAttended: courses.first.attended,
              currentTotal: courses.first.total,
              isOverall: false,
            );
          }
          _isLoading = false;
        });

        Logger.i(
          'AttendanceMatrix',
          'Loaded ${courses.length} courses, Overall: ${overall.totalAttended}/${overall.totalClasses}',
        );
      }
    } catch (e, stackTrace) {
      Logger.e(
        'AttendanceMatrix',
        'Failed to load attendance data',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.error(context, 'Failed to load attendance data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Attendance Matrix',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text),
        ),
        body: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              'Loading attendance data...',
              style: TextStyle(fontSize: 16, color: theme.muted),
            ),
          ],
        ),
      );
    }

    if (_overallAttendance == null || _overallMatrix == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_off_outlined,
                size: 64,
                color: theme.muted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Data Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please sync your attendance data from VTOP first',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: theme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverallAttendanceSection(
              percentage: _overallAttendance!.percentage,
              attended: _overallAttendance!.totalAttended,
              total: _overallAttendance!.totalClasses,
              primaryColor: theme.primary,
              backgroundColor: theme.background,
              surfaceColor: theme.surface,
              textColor: theme.text,
              mutedColor: theme.muted,
              isDark: theme.isDark,
            ),
            const SizedBox(height: 16),
            OverallMatrixCard(
              matrix: _overallMatrix!,
              primaryColor: theme.primary,
              backgroundColor: theme.background,
              surfaceColor: theme.surface,
              textColor: theme.text,
              mutedColor: theme.muted,
              isDark: theme.isDark,
            ),
            const SizedBox(height: 16),
            CourseSelectionCard(
              courses: _courses,
              selectedCourse: _selectedCourse,
              onCourseSelected: (course) {
                setState(() {
                  _selectedCourse = course;
                  _courseMatrix = AttendanceMatrixLogic.generateMatrix(
                    currentAttended: course.attended,
                    currentTotal: course.total,
                    isOverall: false,
                  );
                });
              },
              primaryColor: theme.primary,
              surfaceColor: theme.surface,
              textColor: theme.text,
              mutedColor: theme.muted,
              isDark: theme.isDark,
            ),
            if (_courseMatrix != null) ...[
              const SizedBox(height: 16),
              CourseMatrixCard(
                matrix: _courseMatrix!,
                primaryColor: theme.primary,
                backgroundColor: theme.background,
                surfaceColor: theme.surface,
                textColor: theme.text,
                mutedColor: theme.muted,
                isDark: theme.isDark,
              ),
            ],
            const SizedBox(height: 16),
            ColorLegendWidget(
              textColor: theme.text,
              mutedColor: theme.muted,
              isDark: theme.isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
