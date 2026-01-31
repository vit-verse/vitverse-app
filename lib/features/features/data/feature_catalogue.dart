import 'package:flutter/material.dart';
import '../models/feature_model.dart';

/// Feature Catalogue - All available features in the app
class FeatureCatalogue {
  static const List<Feature> allFeatures = [
    Feature(
      id: 'vtop:attendance_analytics',
      key: 'attendance_analytics',
      title: 'Attendance Analytics',
      description: 'Visualize and analyze your attendance trends',
      icon: Icons.analytics_outlined,
      route: '/features/vtop/attendance_analytics',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:attendance_calculator',
      key: 'attendance_calculator',
      title: 'Attendance Calculator',
      description: 'Calculate required classes to maintain attendance',
      icon: Icons.calculate_outlined,
      route: '/features/vtop/attendance_calculator',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:academic_performance',
      key: 'academic_performance',
      title: 'Academic Performance',
      description: 'CGPA, GPA, Curriculum & Basket',
      icon: Icons.school_outlined,
      route: '/features/vtop/academic_performance',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:attendance_matrix',
      key: 'attendance_matrix',
      title: 'Attendance Matrix',
      description: 'Predict attendance based on future classes',
      icon: Icons.grid_4x4_outlined,
      route: '/features/vtop/attendance_matrix',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:examination_schedule',
      key: 'examination_schedule',
      title: 'Examination Schedule',
      description: 'View your upcoming exam schedule',
      icon: Icons.event_note_outlined,
      route: '/features/vtop/examination_schedule',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:grade_history',
      key: 'grade_history',
      title: 'Grade History',
      description: 'View complete grade history',
      icon: Icons.history_edu_outlined,
      route: '/features/vtop/grade_history',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:marks_history',
      key: 'marks_history',
      title: 'Marks History',
      description: 'View detailed marks for all assessments',
      icon: Icons.assignment_outlined,
      route: '/features/vtop/marks_history',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:cgpa_gpa_calculator',
      key: 'cgpa_gpa_calculator',
      title: 'CGPA & GPA Calculator',
      description: 'Calculate predicted CGPA and GPA',
      icon: Icons.functions_outlined,
      route: '/features/vtop/cgpa_gpa_calculator',
      source: FeatureSource.vtop,
      category: FeatureCategory.academic,
    ),
    Feature(
      id: 'vtop:staff',
      key: 'staff',
      title: 'Staff',
      description: 'Proctor, HOD & Dean details',
      icon: Icons.contacts_outlined,
      route: '/features/vtop/staff',
      source: FeatureSource.vtop,
      category: FeatureCategory.faculty,
    ),
    Feature(
      id: 'vtop:my_course_faculties',
      key: 'my_course_faculties',
      title: 'My Course Faculties',
      description: 'View faculties teaching your courses',
      icon: Icons.school_outlined,
      route: '/features/vtop/my_course_faculties',
      source: FeatureSource.vtop,
      category: FeatureCategory.faculty,
    ),
    Feature(
      id: 'vtop:all_faculties',
      key: 'all_faculties',
      title: 'All Faculties',
      description: 'Browse complete faculty directory',
      icon: Icons.people_outline,
      route: '/features/vtop/all_faculties',
      source: FeatureSource.vtop,
      category: FeatureCategory.faculty,
    ),
    Feature(
      id: 'vtop:fee_management',
      key: 'fee_management',
      title: 'Fee Management',
      description: 'Receipts & Dues',
      icon: Icons.account_balance_wallet_outlined,
      route: '/features/vtop/fee_management',
      source: FeatureSource.vtop,
      category: FeatureCategory.finance,
    ),
    Feature(
      id: 'vitconnect:faculty_rating',
      key: 'faculty_rating',
      title: 'Faculty Rating',
      description: 'Rate and review faculty members',
      icon: Icons.star_rate_outlined,
      route: '/features/vitconnect/faculty_rating',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.academics,
    ),
    Feature(
      id: 'vitconnect:pyq',
      key: 'pyq',
      title: 'PYQs',
      description: 'Previous Year Question Papers',
      icon: Icons.description_outlined,
      route: '/features/vitconnect/pyq',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.academics,
    ),
    Feature(
      id: 'vitconnect:cab_share',
      key: 'cab_share',
      title: 'Cab Share',
      description: 'Find students to share cabs',
      icon: Icons.local_taxi_outlined,
      route: '/features/vitconnect/cab_share',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.social,
    ),
    Feature(
      id: 'vitconnect:events',
      key: 'events',
      title: 'Events',
      description: 'Discover and post campus events',
      icon: Icons.event_outlined,
      route: '/features/vitconnect/events',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.social,
    ),
    Feature(
      id: 'vitconnect:lost_and_found',
      key: 'lost_and_found',
      title: 'Lost & Found',
      description: 'Report and find lost items',
      icon: Icons.search_outlined,
      route: '/features/vitconnect/lost_and_found',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.utilities,
    ),
    Feature(
      id: 'vitconnect:quick_links',
      key: 'quick_links',
      title: 'Quick Links',
      description: 'Access important VIT links quickly',
      icon: Icons.link_outlined,
      route: '/features/vitconnect/quick_links',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.utilities,
    ),
    Feature(
      id: 'vitconnect:mess_menu',
      key: 'mess_menu',
      title: 'Mess Menu',
      description: 'View daily mess menu (Unmessify)',
      icon: Icons.restaurant_menu_outlined,
      route: '/features/vitconnect/mess_menu',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.utilities,
    ),
    Feature(
      id: 'vitconnect:laundry',
      key: 'laundry',
      title: 'Laundry',
      description: 'Track laundry status (Unmessify)',
      icon: Icons.local_laundry_service_outlined,
      route: '/features/vitconnect/laundry',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.utilities,
    ),
    Feature(
      id: 'vitconnect:friends_schedule',
      key: 'friends_schedule',
      title: 'Friends\' Schedule',
      description: 'Add and view friends\' schedules',
      icon: Icons.people_alt_outlined,
      route: '/features/vitconnect/friends_schedule',
      source: FeatureSource.vitconnect,
      category: FeatureCategory.social,
    ),
  ];

  /// Get feature by ID
  static Feature? getFeatureById(String id) {
    try {
      return allFeatures.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get features by source
  static List<Feature> getFeaturesBySource(FeatureSource source) {
    return allFeatures.where((f) => f.source == source).toList();
  }

  /// Get features by category
  static List<Feature> getFeaturesByCategory(FeatureCategory category) {
    return allFeatures.where((f) => f.category == category).toList();
  }

  /// Get VTOP features by category
  static Map<FeatureCategory, List<Feature>> getVtopFeaturesByCategory() {
    final vtopFeatures = getFeaturesBySource(FeatureSource.vtop);
    return {
      FeatureCategory.academic:
          vtopFeatures
              .where((f) => f.category == FeatureCategory.academic)
              .toList(),
      FeatureCategory.faculty:
          vtopFeatures
              .where((f) => f.category == FeatureCategory.faculty)
              .toList(),
      FeatureCategory.finance:
          vtopFeatures
              .where((f) => f.category == FeatureCategory.finance)
              .toList(),
    };
  }

  /// Get VIT Connect features
  static List<Feature> getVitConnectFeatures() {
    return getFeaturesBySource(FeatureSource.vitconnect);
  }
}
