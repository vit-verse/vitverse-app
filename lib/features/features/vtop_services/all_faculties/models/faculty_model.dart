class FacultyMember {
  final String employeeId;
  final String name;
  final String designation;
  final String school;
  final String cabin;
  final String imageUrl;
  final String profileUrl;

  FacultyMember({
    required this.employeeId,
    required this.name,
    required this.designation,
    required this.school,
    required this.cabin,
    required this.imageUrl,
    required this.profileUrl,
  });

  factory FacultyMember.fromJson(Map<String, dynamic> json) {
    // Handle both int and String types for employee_id
    final employeeIdValue = json['employee_id'];
    final employeeIdStr =
        employeeIdValue is int
            ? employeeIdValue.toString()
            : (employeeIdValue as String? ?? '');

    return FacultyMember(
      employeeId: employeeIdStr,
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      school: json['school'] as String? ?? '',
      cabin: json['cabin'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      profileUrl: json['profile_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'name': name,
      'designation': designation,
      'school': school,
      'cabin': cabin,
      'image_url': imageUrl,
      'profile_url': profileUrl,
    };
  }

  // Search helper method
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return employeeId.toLowerCase().contains(lowerQuery) ||
        name.toLowerCase().contains(lowerQuery) ||
        designation.toLowerCase().contains(lowerQuery) ||
        school.toLowerCase().contains(lowerQuery) ||
        cabin.toLowerCase().contains(lowerQuery);
  }

  // Get first letter of name for avatar
  String getInitial() {
    if (name.isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }
}
