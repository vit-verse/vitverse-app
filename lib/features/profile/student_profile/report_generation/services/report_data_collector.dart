import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/database/database.dart';
import '../../../../../core/database/daos/cumulative_mark_dao.dart';
import '../../../../../core/database/daos/all_semester_mark_dao.dart';
import '../../../../../core/database/daos/curriculum_progress_dao.dart';
import '../../../../../core/database/daos/basket_progress_dao.dart';
import '../../../../../core/database/daos/receipt_dao.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/database/entities/cgpa_summary.dart';
import '../../../../../core/database/entities/cumulative_mark.dart';
import '../../../../../core/database/entities/all_semester_mark.dart';
import '../../../../../core/utils/logger.dart';
import '../models/student_report_data.dart';

/// Service to collect all student data for report generation
class ReportDataCollectorService {
  static const String _tag = 'ReportDataCollector';

  // Cache for report data
  static StudentReportData? _cachedReportData;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Clear cached data
  static void clearCache() {
    _cachedReportData = null;
    _cacheTimestamp = null;
    Logger.i(_tag, 'Report data cache cleared');
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cachedReportData == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Collect all student data for report generation
  Future<StudentReportData> collectReportData({bool forceRefresh = false}) async {
    try {
      // Return cached data if valid and not forcing refresh
      if (!forceRefresh && _isCacheValid()) {
        Logger.i(_tag, 'Returning cached report data');
        return _cachedReportData!;
      }

      Logger.i(_tag, 'Starting comprehensive data collection for report');

      // Load basic data
      final profile = await _loadStudentProfile();
      final cgpaSummary = await _loadCGPASummary();

      // Load curriculum and basket progress
      final curriculumProgress = await _loadCurriculumProgress();
      final basketProgress = await _loadBasketProgress();

      // Get total credits required from SharedPreferences (same as CGPA Tools)
      final totalCreditsRequired = await _getTotalCreditsRequired();

      // Load semester performances
      final semesterPerformances = await _loadSemesterPerformances();

      // Load grade history
      final gradeHistory = await _loadGradeHistory();

      // Load marks history
      final marksHistory = await _loadMarksHistory();

      // Load fee details
      final feeReceipts = await _loadFeeReceipts();
      final totalFees = feeReceipts.fold<double>(
        0,
        (sum, receipt) => sum + receipt.amount,
      );

      final reportData = StudentReportData(
        // Basic info
        name: profile.name,
        registerNumber: profile.registerNumber,
        vitEmail: profile.vitEmail,
        nickname: profile.nickname,
        gender: profile.gender,
        dateOfBirth: profile.dateOfBirth,

        // Academic profile
        program: profile.program,
        branch: profile.branch,
        schoolName: profile.schoolName,
        yearJoined: profile.yearJoined,
        studySystem: profile.studySystem,
        eduStatus: profile.eduStatus,
        campus: profile.campus,
        programmeMode: profile.programmeMode,

        // Hostel/Mess
        hostelBlock: profile.hostelBlock,
        roomNumber: profile.roomNumber,
        bedType: profile.bedType,
        messName: profile.messName,

        // Academic performance
        cgpa: cgpaSummary.cgpa,
        creditsRegistered: cgpaSummary.creditsRegistered,
        creditsEarned: cgpaSummary.creditsEarned,
        totalCreditsRequired: totalCreditsRequired,
        sGrades: cgpaSummary.sGrades,
        aGrades: cgpaSummary.aGrades,
        bGrades: cgpaSummary.bGrades,
        cGrades: cgpaSummary.cGrades,
        dGrades: cgpaSummary.dGrades,
        eGrades: cgpaSummary.eGrades,
        fGrades: cgpaSummary.fGrades,
        nGrades: cgpaSummary.nGrades,

        // Progress data
        curriculumProgress: curriculumProgress,
        basketProgress: basketProgress,
        semesterPerformances: semesterPerformances,

        // History data
        gradeHistory: gradeHistory,
        marksHistory: marksHistory,

        // Fee data
        feeReceipts: feeReceipts,
        totalFeesPaid: totalFees,

        // Metadata
        generatedAt: DateTime.now(),
      );

      // Cache the report data
      _cachedReportData = reportData;
      _cacheTimestamp = DateTime.now();

      Logger.success(_tag, 'Successfully collected all report data');
      return reportData;
    } catch (e) {
      Logger.e(_tag, 'Failed to collect report data', e);
      rethrow;
    }
  }

  Future<StudentProfile> _loadStudentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        throw Exception('Student profile not found');
      }

      return StudentProfile.fromJson(jsonDecode(profileJson));
    } catch (e) {
      Logger.e(_tag, 'Failed to load student profile', e);
      rethrow;
    }
  }

  Future<CGPASummary> _loadCGPASummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cgpaJson = prefs.getString('cgpa_summary');

      if (cgpaJson == null || cgpaJson.isEmpty) {
        return CGPASummary.empty();
      }

      return CGPASummary.fromJson(jsonDecode(cgpaJson));
    } catch (e) {
      Logger.e(_tag, 'Failed to load CGPA summary', e);
      return CGPASummary.empty();
    }
  }

  Future<double> _getTotalCreditsRequired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalCredits = prefs.getDouble('total_credits_required');

      if (totalCredits != null && totalCredits > 0) {
        Logger.d(
          _tag,
          'Total credits required from SharedPreferences: $totalCredits',
        );
        return totalCredits;
      }

      // Fallback: calculate from curriculum progress
      final dao = CurriculumProgressDao();
      final curriculums = await dao.getAll();
      final calculated = curriculums.fold<double>(
        0,
        (sum, curriculum) => sum + curriculum.creditsRequired,
      );

      Logger.d(_tag, 'Total credits calculated from curriculum: $calculated');
      return calculated > 0 ? calculated : 151.0; // Default fallback
    } catch (e) {
      Logger.e(_tag, 'Failed to get total credits', e);
      return 151.0;
    }
  }

  Future<List<CurriculumProgressData>> _loadCurriculumProgress() async {
    try {
      final dao = CurriculumProgressDao();
      final curriculums = await dao.getAll();

      return curriculums
          .map(
            (c) => CurriculumProgressData(
              distributionType: c.distributionType,
              creditsRequired: c.creditsRequired,
              creditsEarned: c.creditsEarned,
              completionPercentage: c.completionPercentage,
            ),
          )
          .toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to load curriculum progress', e);
      return [];
    }
  }

  Future<List<BasketProgressData>> _loadBasketProgress() async {
    try {
      final dao = BasketProgressDao();
      final baskets = await dao.getAll();

      return baskets
          .map(
            (b) => BasketProgressData(
              basketTitle: b.basketTitle,
              creditsRequired: b.creditsRequired,
              creditsEarned: b.creditsEarned,
              completionPercentage: b.completionPercentage,
            ),
          )
          .toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to load basket progress', e);
      return [];
    }
  }

  Future<List<SemesterPerformanceData>> _loadSemesterPerformances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semesterListJson = prefs.getString('available_semesters');

      List<String> semesterOrder = [];
      if (semesterListJson != null && semesterListJson.isNotEmpty) {
        final List<dynamic> semesterList = jsonDecode(semesterListJson);
        semesterOrder = semesterList.cast<String>();
      }

      final db = await VitConnectDatabase.instance.database;
      final result = await db.rawQuery('''
        SELECT 
          semester_id,
          semester_name,
          semester_gpa,
          COUNT(*) as course_count,
          SUM(credits) as total_credits,
          GROUP_CONCAT(grade) as grades
        FROM cumulative_marks
        GROUP BY semester_id
      ''');

      final performances =
          result.map((row) {
            final grades = (row['grades'] as String?)?.split(',') ?? [];
            return SemesterPerformanceData(
              semesterId: row['semester_id'] as String? ?? '',
              semesterName: row['semester_name'] as String? ?? '',
              gpa: (row['semester_gpa'] as num?)?.toDouble() ?? 0.0,
              courseCount: row['course_count'] as int? ?? 0,
              totalCredits: (row['total_credits'] as num?)?.toDouble() ?? 0.0,
              grades: grades,
            );
          }).toList();

      // Sort by semester order if available
      if (semesterOrder.isNotEmpty) {
        performances.sort((a, b) {
          final aIndex = semesterOrder.indexOf(a.semesterName);
          final bIndex = semesterOrder.indexOf(b.semesterName);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });
      }

      return performances;
    } catch (e) {
      Logger.e(_tag, 'Failed to load semester performances', e);
      return [];
    }
  }

  Future<List<SemesterGradeData>> _loadGradeHistory() async {
    try {
      final db = await VitConnectDatabase.instance.database;
      final dao = CumulativeMarkDao(db);
      final allGrades = await dao.getAll();

      if (allGrades.isEmpty) return [];

      // Get semester order from SharedPreferences (this is the correct order from app)
      final prefs = await SharedPreferences.getInstance();
      List<String> semesterOrder = [];
      
      // Try multiple keys for semester order
      final semesterList = prefs.getStringList('semester_order');
      if (semesterList != null && semesterList.isNotEmpty) {
        semesterOrder = semesterList;
      } else {
        // Try alternative key
        final semesterListJson = prefs.getString('available_semesters');
        if (semesterListJson != null && semesterListJson.isNotEmpty) {
          final List<dynamic> parsed = jsonDecode(semesterListJson);
          semesterOrder = parsed.cast<String>();
        }
      }

      Logger.d(_tag, 'Semester order from prefs: $semesterOrder');

      // Group by semester
      final Map<String, List<CumulativeMark>> bySemester = {};
      for (final grade in allGrades) {
        bySemester.putIfAbsent(grade.semesterName, () => []).add(grade);
      }

      // Create semester grade data list
      final semesterGradeDataList =
          bySemester.entries.map((entry) {
            final semesterGrades = entry.value;
            final passedCourses =
                semesterGrades.where((g) => g.isPassing).length;
            final totalCredits = semesterGrades.fold<double>(
              0,
              (sum, g) => sum + g.credits,
            );

            final courses =
                semesterGrades.map((grade) {
                  return CourseGradeData(
                    courseCode: grade.courseCode,
                    courseTitle: grade.courseTitle,
                    grade: grade.grade,
                    credits: grade.credits,
                    courseType: grade.courseType,
                    totalMarks: grade.grandTotal,
                  );
                }).toList();

            return SemesterGradeData(
              semesterName: entry.key,
              semesterGpa: semesterGrades.first.semesterGpa ?? 0.0,
              totalCourses: semesterGrades.length,
              passedCourses: passedCourses,
              totalCredits: totalCredits,
              courses: courses,
            );
          }).toList();

      // Sort by semester order (most recent first as per app display)
      // The semesterOrder list has most recent at index 0
      if (semesterOrder.isNotEmpty) {
        semesterGradeDataList.sort((a, b) {
          final aIndex = semesterOrder.indexOf(a.semesterName);
          final bIndex = semesterOrder.indexOf(b.semesterName);
          // If not found in order, put at end
          if (aIndex == -1 && bIndex == -1) return 0;
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });
      }

      // For PDF, we want chronological order (oldest first)
      // So we reverse the list (since semesterOrder has most recent first)
      return semesterGradeDataList.reversed.toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to load grade history', e);
      return [];
    }
  }

  Future<List<SemesterMarksData>> _loadMarksHistory() async {
    try {
      final dao = AllSemesterMarkDao();
      final allMarks = await dao.getAll();

      if (allMarks.isEmpty) return [];

      // Get semester order from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> semesterOrder = [];
      
      // Try multiple keys for semester order
      final semesterList = prefs.getStringList('semester_order');
      if (semesterList != null && semesterList.isNotEmpty) {
        semesterOrder = semesterList;
      } else {
        // Try alternative key
        final semesterListJson = prefs.getString('available_semesters');
        if (semesterListJson != null && semesterListJson.isNotEmpty) {
          final List<dynamic> parsed = jsonDecode(semesterListJson);
          semesterOrder = parsed.cast<String>();
        }
      }

      // Group by semester
      final Map<String, List<AllSemesterMark>> bySemester = {};
      for (final mark in allMarks) {
        final semName = mark.semesterName ?? 'Unknown';
        bySemester.putIfAbsent(semName, () => []).add(mark);
      }

      // Create semester marks data list
      final semesterMarksDataList =
          bySemester.entries.map((entry) {
            // Group by course within semester
            final Map<String, List<AllSemesterMark>> byCourse = {};
            for (final mark in entry.value) {
              final courseKey = '${mark.courseCode}_${mark.courseTitle}';
              byCourse.putIfAbsent(courseKey, () => []).add(mark);
            }

            final courses =
                byCourse.entries.map((courseEntry) {
                  final courseMarks = courseEntry.value;
                  final assessments =
                      courseMarks.map((mark) {
                        final percentage =
                            (mark.maxScore ?? 0) > 0
                                ? ((mark.score ?? 0) / (mark.maxScore ?? 1)) *
                                    100
                                : 0.0;
                        return AssessmentData(
                          title: mark.title ?? 'Assessment',
                          score: mark.score ?? 0,
                          maxScore: mark.maxScore ?? 0,
                          percentage: percentage,
                        );
                      }).toList();

                  final totalScore = courseMarks.fold<double>(
                    0,
                    (sum, m) => sum + (m.score ?? 0),
                  );
                  final totalMax = courseMarks.fold<double>(
                    0,
                    (sum, m) => sum + (m.maxScore ?? 0),
                  );
                  final overallPercentage =
                      totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;

                  return CourseMarksData(
                    courseCode: courseMarks.first.courseCode ?? '',
                    courseTitle: courseMarks.first.courseTitle ?? '',
                    assessments: assessments,
                    overallPercentage: overallPercentage,
                  );
                }).toList();

            return SemesterMarksData(semesterName: entry.key, courses: courses);
          }).toList();

      // Sort by semester order (most recent first as per app display)
      if (semesterOrder.isNotEmpty) {
        semesterMarksDataList.sort((a, b) {
          final aIndex = semesterOrder.indexOf(a.semesterName);
          final bIndex = semesterOrder.indexOf(b.semesterName);
          if (aIndex == -1 && bIndex == -1) return 0;
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });
      }

      // For PDF, we want chronological order (oldest first)
      return semesterMarksDataList.reversed.toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to load marks history', e);
      return [];
    }
  }

  Future<List<FeeReceiptData>> _loadFeeReceipts() async {
    try {
      final dao = ReceiptDao();
      final receipts = await dao.getAll();

      return receipts
          .map(
            (r) => FeeReceiptData(
              receiptNumber: r.number.toString(),
              date: r.paymentDate,
              description: 'Fee Payment',
              amount: r.amount ?? 0.0,
              mode: 'Online',
            ),
          )
          .toList();
    } catch (e) {
      Logger.e(_tag, 'Failed to load fee receipts', e);
      return [];
    }
  }
}
