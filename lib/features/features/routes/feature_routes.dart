import 'package:flutter/material.dart';

// VTOP Services Pages - Lazy Loading Wrappers
import '../vtop_services/attendance_analytics/lazy_attendance_analytics_page.dart';
import '../vtop_services/attendance_calculator/lazy_attendance_calculator_page.dart';
import '../vtop_services/academic_performance/lazy_academic_performance_page.dart';
import '../vtop_services/attendance_matrix/lazy_attendance_matrix_page.dart';
import '../vtop_services/examination_schedule/lazy_examination_schedule_page.dart';
import '../vtop_services/grade_history/lazy_grade_history_page.dart';
import '../vtop_services/marks_history/lazy_marks_history_page.dart';
import '../vtop_services/cgpa_gpa_calculator/lazy_cgpa_calculator_page.dart';
import '../vtop_services/staff/lazy_staff_page.dart';
import '../vtop_services/my_course_faculties/lazy_my_course_faculties_page.dart';
import '../vtop_services/all_faculties/lazy_all_faculties_page.dart';
import '../vtop_services/fee_management/lazy_fee_management_page.dart';

// VIT Connect Services Pages - Lazy Loading Wrappers
import '../vitconnect_services/faculty_rating/presentation/lazy_faculty_rating_page.dart';
import '../vitconnect_services/cab_share/lazy_cab_share_page.dart';
import '../vitconnect_services/eventhub/lazy_eventhub_page.dart';
import '../vitconnect_services/lost_and_found/lazy_lost_and_found_page.dart';
import '../vitconnect_services/quick_links/lazy_quick_links_page.dart';
import '../vitconnect_services/mess_menu/lazy_mess_menu_page.dart';
import '../vitconnect_services/laundry/lazy_laundry_page.dart';
import '../vitconnect_services/friends_schedule/lazy_friends_schedule_page.dart';

/// Feature Routes - Centralized route configuration
class FeatureRoutes {
  /// Get all feature routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // VTOP Services - Academic (Lazy Loaded)
      '/features/vtop/attendance_analytics':
          (context) => const LazyAttendanceAnalyticsPage(),
      '/features/vtop/attendance_calculator':
          (context) => const LazyAttendanceCalculatorPage(),
      '/features/vtop/academic_performance':
          (context) => const LazyAcademicPerformancePage(),
      '/features/vtop/attendance_matrix':
          (context) => const LazyAttendanceMatrixPage(),
      '/features/vtop/examination_schedule':
          (context) => const LazyExaminationSchedulePage(),
      '/features/vtop/grade_history': (context) => const LazyGradeHistoryPage(),
      '/features/vtop/marks_history': (context) => const LazyMarksHistoryPage(),
      '/features/vtop/cgpa_gpa_calculator':
          (context) => const LazyCgpaCalculatorPage(),

      // VTOP Services - Faculty (Lazy Loaded)
      '/features/vtop/staff': (context) => const LazyStaffPage(),
      '/features/vtop/my_course_faculties':
          (context) => const LazyMyCourseFacultiesPage(),
      '/features/vtop/all_faculties': (context) => const LazyAllFacultiesPage(),

      // VTOP Services - Finance (Lazy Loaded)
      '/features/vtop/fee_management':
          (context) => const LazyFeeManagementPage(),

      // VIT Connect Services (Lazy Loaded)
      '/features/vitconnect/faculty_rating':
          (context) => const LazyFacultyRatingPage(),
      '/features/vitconnect/cab_share': (context) => const LazyCabSharePage(),
      '/features/vitconnect/eventhub': (context) => const LazyEventHubPage(),
      '/features/vitconnect/lost_and_found':
          (context) => const LazyLostAndFoundPage(),
      '/features/vitconnect/quick_links':
          (context) => const LazyQuickLinksPage(),
      '/features/vitconnect/mess_menu': (context) => const LazyMessMenuPage(),
      '/features/vitconnect/laundry': (context) => const LazyLaundryPage(),
      '/features/vitconnect/friends_schedule':
          (context) => const LazyFriendsSchedulePage(),
    };
  }
}
