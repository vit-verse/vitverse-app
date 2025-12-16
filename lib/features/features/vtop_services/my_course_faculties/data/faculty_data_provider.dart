import '../../../../../core/database/database.dart';
import '../../../../../core/utils/logger.dart';
import '../models/faculty_with_courses.dart';

class FacultyDataProvider {
  /// Get all faculties with their courses, sorted alphabetically
  Future<List<FacultyWithCourses>> getFacultiesWithCourses() async {
    try {
      final db = await VitConnectDatabase.instance.database;

      // Query to get all courses with their slots
      final coursesWithSlots = await db.rawQuery('''
        SELECT 
          c.code,
          c.title,
          c.type,
          c.credits,
          c.venue,
          c.faculty,
          c.faculty_erp_id,
          c.class_id,
          GROUP_CONCAT(s.slot, '+') as slot
        FROM courses c
        LEFT JOIN slots s ON c.id = s.course_id
        WHERE c.faculty IS NOT NULL AND c.faculty != ''
        GROUP BY c.id, c.code, c.title, c.type, c.credits, c.venue, c.faculty, c.faculty_erp_id, c.class_id
        ORDER BY c.code ASC
      ''');

      if (coursesWithSlots.isEmpty) {
        Logger.w(
          'FacultyDataProvider',
          'No courses found with faculty information',
        );
        return [];
      }

      // Group courses by faculty
      final Map<String, List<CourseInfo>> facultyCourses = {};
      final Map<String, String?> facultyErpIds = {}; // Store ERP IDs

      for (final courseMap in coursesWithSlots) {
        final faculty = courseMap['faculty'] as String;
        final courseInfo = CourseInfo.fromMap(courseMap);

        facultyCourses.putIfAbsent(faculty, () => []).add(courseInfo);

        // Store faculty ERP ID if available (from first course)
        if (!facultyErpIds.containsKey(faculty) &&
            courseInfo.facultyErpId != null) {
          facultyErpIds[faculty] = courseInfo.facultyErpId;
        }
      }

      // Convert to FacultyWithCourses objects and sort alphabetically
      final faculties =
          facultyCourses.entries
              .map(
                (entry) => FacultyWithCourses(
                  facultyName: entry.key,
                  facultyErpId: facultyErpIds[entry.key],
                  courses: entry.value,
                ),
              )
              .toList();

      // Sort faculties alphabetically by name
      faculties.sort((a, b) => a.facultyName.compareTo(b.facultyName));

      Logger.d(
        'FacultyDataProvider',
        'Loaded ${faculties.length} faculties with courses',
      );

      return faculties;
    } catch (e) {
      Logger.e(
        'FacultyDataProvider',
        'Failed to load faculties with courses',
        e,
      );
      rethrow;
    }
  }

  /// Get courses for a specific faculty
  Future<List<CourseInfo>> getCoursesForFaculty(String facultyName) async {
    try {
      final db = await VitConnectDatabase.instance.database;

      final coursesWithSlots = await db.rawQuery(
        '''
        SELECT 
          c.code,
          c.title,
          c.type,
          c.credits,
          c.venue,
          c.faculty,
          c.faculty_erp_id,
          c.class_id,
          GROUP_CONCAT(s.slot, '+') as slot
        FROM courses c
        LEFT JOIN slots s ON c.id = s.course_id
        WHERE c.faculty = ?
        GROUP BY c.id, c.code, c.title, c.type, c.credits, c.venue, c.faculty, c.faculty_erp_id, c.class_id
        ORDER BY c.code ASC
      ''',
        [facultyName],
      );

      return coursesWithSlots.map((map) => CourseInfo.fromMap(map)).toList();
    } catch (e) {
      Logger.e(
        'FacultyDataProvider',
        'Failed to load courses for faculty: $facultyName',
        e,
      );
      rethrow;
    }
  }

  /// Get faculty statistics
  Future<Map<String, dynamic>> getFacultyStatistics() async {
    try {
      final db = await VitConnectDatabase.instance.database;

      final stats = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT c.faculty) as total_faculties,
          COUNT(DISTINCT c.id) as total_courses,
          SUM(c.credits) as total_credits,
          COUNT(CASE WHEN c.type = 'theory' THEN 1 END) as theory_courses,
          COUNT(CASE WHEN c.type = 'lab' THEN 1 END) as lab_courses,
          COUNT(CASE WHEN c.type = 'project' THEN 1 END) as project_courses
        FROM courses c
        WHERE c.faculty IS NOT NULL AND c.faculty != ''
      ''');

      return stats.first;
    } catch (e) {
      Logger.e('FacultyDataProvider', 'Failed to load faculty statistics', e);
      rethrow;
    }
  }
}
