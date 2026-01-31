/// Grading System Information
/// Contains official VIT grading policies, formulas, and academic regulations
library;

class GradingSystemInfo {
  // Prevent instantiation
  GradingSystemInfo._();

  /// Grading System Information Sections
  static const List<GradingInfoSection> sections = [
    GradingInfoSection(
      title: 'Official Grading System',
      icon: 'grade',
      items: _gradingSystemItems,
    ),
    GradingInfoSection(
      title: 'GPA / CGPA Formulas',
      icon: 'calculate',
      items: _formulaItems,
    ),
    GradingInfoSection(
      title: 'Distribution of Marks',
      icon: 'assignment',
      items: _marksDistributionItems,
    ),
    GradingInfoSection(
      title: 'Relative Grading',
      icon: 'trending_up',
      items: _relativeGradingItems,
    ),
    GradingInfoSection(
      title: 'Absolute Grading',
      icon: 'rule',
      items: _absoluteGradingItems,
    ),
    GradingInfoSection(
      title: 'Passing Criteria',
      icon: 'check_circle',
      items: _passingCriteriaItems,
    ),
  ];

  /// Official Grading System
  static const List<GradingInfoItem> _gradingSystemItems = [
    GradingInfoItem(
      label: 'S Grade',
      value: '10 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'A Grade',
      value: '9 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'B Grade',
      value: '8 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'C Grade',
      value: '7 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'D Grade',
      value: '6 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'E Grade',
      value: '5 points',
      description: 'Pass in the Course',
    ),
    GradingInfoItem(
      label: 'F Grade',
      value: '0 points',
      description:
          'Failed in the course by not securing minimum marks or malpractice in exams / indiscipline',
    ),
    GradingInfoItem(
      label: 'N1 Grade',
      value: '0 points',
      description: 'Student fails to clear one or more components of a course',
    ),
    GradingInfoItem(
      label: 'N2 Grade',
      value: '0 points',
      description: 'Student debarred due to lack of attendance',
    ),
    GradingInfoItem(
      label: 'N3 Grade',
      value: '0 points',
      description: 'Student absent in the Final Assessment Test',
    ),
    GradingInfoItem(
      label: 'N4 Grade',
      value: '0 points',
      description:
          'Student debarred in Final Assessment Test due to indiscipline / malpractice',
    ),
    GradingInfoItem(
      label: 'W Grade',
      value: 'No points',
      description: 'Course registration withdrawn from a credit / audit course',
    ),
    GradingInfoItem(
      label: 'U Grade',
      value: 'No points',
      description: 'Successfully completed an Audit Course',
    ),
    GradingInfoItem(
      label: 'P Grade',
      value: 'No points',
      description: 'Passed in a \'Pass-Fail\' course',
    ),
    GradingInfoItem(
      label: 'Y Grade',
      value: 'No points',
      description: 'Yet to complete the course component (temporary)',
    ),
  ];

  /// GPA / CGPA Formulas
  static const List<GradingInfoItem> _formulaItems = [
    GradingInfoItem(
      label: 'Semester GPA (SGPA)',
      value: 'Σ(Credit × Grade Point) / Σ(Credits)',
      description:
          'Performance for one semester. Sum of all course credit-grade products divided by total semester credits.',
    ),
    GradingInfoItem(
      label: 'Cumulative GPA (CGPA)',
      value: 'Σ(GPAₛₑₘ × Creditsₛₑₘ) / Σ(Total Credits)',
      description:
          'Weighted average of all semesters. Sum of semester GPA-credit products divided by total credits.',
    ),
    GradingInfoItem(
      label: 'New CGPA (After Current Semester)',
      value:
          '((Prev CGPA × Prev Credits) + (Curr GPA × Curr Credits)) / (Prev + Curr Credits)',
      description:
          'Used in CGPA Predictor and Estimator tabs to calculate projected CGPA.',
    ),
    GradingInfoItem(
      label: 'Percentage Equivalent',
      value: 'CGPA × 10',
      description: 'Used for transcript conversion. Example: CGPA 9.2 = 92%',
    ),
  ];

  /// Distribution of Marks (Course Components)
  static const List<GradingInfoItem> _marksDistributionItems = [
    GradingInfoItem(
      label: 'Theory-only Course',
      value: 'CAT-I: 15, CAT-II: 15, DA: 3×10, FAT: 40',
      description: 'Total: 100 marks ',
    ),
    GradingInfoItem(
      label: 'Embedded Lab Course',
      value: 'CAT-I: 15, CAT-II: 15, DA: 3×10, Lab: 100, FAT: 40',
      description:
          'Theory + Lab integrated. Lab marks out of 100, scaled appropriately.',
    ),
    GradingInfoItem(
      label: 'Project Based Course with Lab',
      value: 'CAT-I: 15, CAT-II: 15, DA: 3×10, Lab: 100, Project: 100, FAT: 40',
      description: 'Theory + Lab + Project components combined.',
    ),
    GradingInfoItem(
      label: 'Project Based Course without Lab',
      value: 'CAT-I: 15, CAT-II: 15, DA: 3×10, Project: 100, FAT: 40',
      description: 'Theory + Project components combined.',
    ),
    GradingInfoItem(
      label: 'Project Only Course',
      value: 'Project: 100',
      description: 'No CATs, no FAT. Fully project-based evaluation.',
    ),
  ];

  /// Relative Grading (For classes > 10 students)
  static const List<GradingInfoItem> _relativeGradingItems = [
    GradingInfoItem(
      label: 'S Grade (10 points)',
      value: 'Total ≥ (Mean + 1.5σ)',
      description: 'Top performers significantly above class average.',
    ),
    GradingInfoItem(
      label: 'A Grade (9 points)',
      value: '(Mean + 0.5σ) ≤ Total < (Mean + 1.5σ)',
      description:
          'Above average performance. Between 0.5 and 1.5 standard deviations above mean.',
    ),
    GradingInfoItem(
      label: 'B Grade (8 points)',
      value: '(Mean − 0.5σ) ≤ Total < (Mean + 0.5σ)',
      description:
          'Average performance. Within ±0.5 standard deviations of mean.',
    ),
    GradingInfoItem(
      label: 'C Grade (7 points)',
      value: '(Mean − 1.0σ) ≤ Total < (Mean − 0.5σ)',
      description:
          'Below average. Between 0.5 and 1.0 standard deviations below mean.',
    ),
    GradingInfoItem(
      label: 'D Grade (6 points)',
      value: '(Mean − 1.5σ) ≤ Total < (Mean − 1.0σ)',
      description:
          'Significantly below average. Between 1.0 and 1.5 standard deviations below mean.',
    ),
    GradingInfoItem(
      label: 'E Grade (5 points)',
      value: '(Mean − 2.0σ) ≤ Total < (Mean − 1.5σ)',
      description:
          'Well below average. Between 1.5 and 2.0 standard deviations below mean.',
    ),
    GradingInfoItem(
      label: 'F Grade (0 points)',
      value: 'Total < (Mean − 2.0σ)',
      description:
          'Failed. More than 2.0 standard deviations below class mean.',
    ),
  ];

  /// Absolute Grading (For classes ≤ 10 students)
  static const List<GradingInfoItem> _absoluteGradingItems = [
    GradingInfoItem(
      label: 'S Grade (10 points)',
      value: '≥ 90 marks',
      description: 'Excellent performance. 90-100 marks out of 100.',
    ),
    GradingInfoItem(
      label: 'A Grade (9 points)',
      value: '80-89 marks',
      description: 'Very good performance. 80 to less than 90 marks.',
    ),
    GradingInfoItem(
      label: 'B Grade (8 points)',
      value: '70-79 marks',
      description: 'Good performance. 70 to less than 80 marks.',
    ),
    GradingInfoItem(
      label: 'C Grade (7 points)',
      value: '60-69 marks',
      description: 'Above average. 60 to less than 70 marks.',
    ),
    GradingInfoItem(
      label: 'D Grade (6 points)',
      value: '55-59 marks',
      description: 'Average performance. 55 to less than 60 marks.',
    ),
    GradingInfoItem(
      label: 'E Grade (5 points)',
      value: '50-54 marks',
      description: 'Pass with minimum marks. 50 to less than 55 marks.',
    ),
    GradingInfoItem(
      label: 'F Grade (0 points)',
      value: '< 50 marks',
      description: 'Failed. Less than 50 marks out of 100.',
    ),
  ];

  /// Passing Criteria
  static const List<GradingInfoItem> _passingCriteriaItems = [
    GradingInfoItem(
      label: 'Final Assessment Test (FAT)',
      value: '40% minimum',
      description:
          'Must score at least 40 marks out of 100 equivalent in FAT to pass the course.',
    ),
    GradingInfoItem(
      label: 'Overall Total (Internal + FAT)',
      value: '50% minimum',
      description:
          'Combined internal and FAT marks must be at least 50 out of 100 to pass.',
    ),
    GradingInfoItem(
      label: 'Laboratory and Project Courses',
      value: '50% minimum',
      description:
          'Must score at least 50 marks out of 100 to pass lab/project courses.',
    ),
    GradingInfoItem(
      label: 'Fail or Non-Completion Grades',
      value: 'F / N grades',
      description:
          'Must re-register and clear the course in subsequent semester. Affects CGPA.',
    ),
    GradingInfoItem(
      label: 'Attendance Requirement',
      value: '75% minimum',
      description:
          'Below 75% attendance results in N2 grade (debarred). No FAT eligibility.',
    ),
  ];

  /// Source Information
  static const String source =
      'Vellore Institute of Technology, Academic Regulations 2023–2025';

  static const String disclaimer =
      'This information may contain human error during transcription. '
      'Please verify from official sources:\n\n'
      '• https://chennai.vit.ac.in/files/Academic-Regulations.pdf\n'
      '• Institute\'s latest academic regulations';
}

/// Model for a grading information section
class GradingInfoSection {
  final String title;
  final String icon;
  final List<GradingInfoItem> items;

  const GradingInfoSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// Model for a grading information item
class GradingInfoItem {
  final String label;
  final String value;
  final String description;

  const GradingInfoItem({
    required this.label,
    required this.value,
    required this.description,
  });
}
