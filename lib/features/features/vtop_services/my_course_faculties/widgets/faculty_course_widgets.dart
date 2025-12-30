import 'package:flutter/material.dart';
import '../models/faculty_with_courses.dart';

class FacultyStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const FacultyStatisticsCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final totalFaculties = statistics['total_faculties'] ?? 0;
    final totalCourses = statistics['total_courses'] ?? 0;
    final totalCredits = (statistics['total_credits'] ?? 0.0);
    final creditsDisplay =
        totalCredits is double
            ? totalCredits.toStringAsFixed(1)
            : totalCredits.toString();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.people_outline,
            totalFaculties.toString(),
            'Faculties',
            context,
          ),
          _buildDivider(context),
          _buildStatItem(
            Icons.menu_book_outlined,
            totalCourses.toString(),
            'Courses',
            context,
          ),
          _buildDivider(context),
          _buildStatItem(
            Icons.workspace_premium_outlined,
            creditsDisplay,
            'Credits',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}

class FacultyExpansionCard extends StatelessWidget {
  final FacultyWithCourses faculty;

  const FacultyExpansionCard({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    final facultyNameWithErp =
        faculty.facultyErpId != null
            ? '${faculty.facultyName} (${faculty.facultyErpId})'
            : faculty.facultyName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            facultyNameWithErp,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildBadge(
                  '${faculty.totalCourses} ${faculty.totalCourses == 1 ? 'Course' : 'Courses'}',
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                _buildBadge(
                  '${faculty.totalCredits % 1 == 0 ? faculty.totalCredits.toInt() : faculty.totalCredits.toStringAsFixed(1)} Credits',
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                  const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          children: [
            ...faculty.courses.map((course) => CourseInfoTile(course: course)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CourseInfoTile extends StatelessWidget {
  final CourseInfo course;

  const CourseInfoTile({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getCourseTypeColor(course.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCourseTypeIcon(course.type),
                  color: _getCourseTypeColor(course.type),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      course.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildDetailChip(
                Icons.category,
                course.formattedType,
                _getCourseTypeColor(course.type),
                context,
              ),
              if (course.credits != null)
                _buildDetailChip(
                  Icons.star_outline,
                  '${course.creditsDisplay} Credits',
                  const Color(0xFFF59E0B),
                  context,
                ),
              if (course.slot != null && course.slot!.isNotEmpty)
                _buildDetailChip(
                  Icons.schedule,
                  course.slot!,
                  const Color(0xFF3B82F6),
                  context,
                ),
              if (course.classId != null && course.classId!.isNotEmpty)
                _buildDetailChip(
                  Icons.numbers,
                  course.classId!,
                  const Color(0xFF8B5CF6),
                  context,
                ),
              if (course.venue != null && course.venue!.isNotEmpty)
                _buildDetailChip(
                  Icons.location_on_outlined,
                  course.venue!,
                  Theme.of(context).colorScheme.primary,
                  context,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String label,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCourseTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'lab':
        return const Color(0xFF3B82F6);
      case 'project':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getCourseTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'lab':
        return Icons.science_outlined;
      case 'project':
        return Icons.assignment_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
