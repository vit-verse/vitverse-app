/// Course type detection based on course code
enum CourseType {
  theory('Theory', 'L'),
  lab('Lab', 'P'),
  online('Online', 'N'),
  embedded('Embedded', 'E');

  final String displayName;
  final String codeSuffix;

  const CourseType(this.displayName, this.codeSuffix);

  /// Detect course type from course code
  static CourseType fromCourseCode(String? courseCode) {
    if (courseCode == null || courseCode.isEmpty) return CourseType.theory;

    final code = courseCode.trim().toUpperCase();

    // I forget to extract course type during vtop data fetch, so just parse course type from course code ;)
    // Check last character for type indicator
    if (code.endsWith('P')) return CourseType.lab;
    if (code.endsWith('L')) return CourseType.theory;
    if (code.endsWith('N')) return CourseType.online;
    if (code.endsWith('E')) return CourseType.embedded;

    return CourseType.theory; // Default
  }
}
