class StaffLogic {
  String getFacultyName(Map<String, String> facultyData) {
    return facultyData['Faculty Name'] ??
        facultyData['Name of the Faculty'] ??
        facultyData['Name'] ??
        facultyData['name'] ??
        facultyData['faculty_name'] ??
        'N/A';
  }

  String getDesignation(Map<String, String> facultyData) {
    return facultyData['Faculty Designation'] ??
        facultyData['Designation'] ??
        facultyData['designation'] ??
        facultyData['Post'] ??
        facultyData['post'] ??
        'N/A';
  }

  String getDepartment(Map<String, String> facultyData) {
    return facultyData['Faculty Department'] ??
        facultyData['Department'] ??
        facultyData['department'] ??
        facultyData['School'] ??
        facultyData['school'] ??
        'N/A';
  }

  String? getEmail(Map<String, String> facultyData) {
    return facultyData['Faculty Email'] ??
        facultyData['Email ID'] ??
        facultyData['Email'] ??
        facultyData['email'] ??
        facultyData['E-Mail'] ??
        facultyData['e-mail'] ??
        facultyData['Mail'] ??
        facultyData['mail'];
  }

  String? getPhone(Map<String, String> facultyData) {
    return facultyData['Faculty Mobile Number'] ??
        facultyData['Mobile Number'] ??
        facultyData['Phone'] ??
        facultyData['phone'] ??
        facultyData['Mobile'] ??
        facultyData['mobile'] ??
        facultyData['Contact'] ??
        facultyData['contact'] ??
        facultyData['Phone Number'] ??
        facultyData['phone_number'];
  }

  String? getOfficeLocation(Map<String, String> facultyData) {
    return facultyData['Cabin'] ??
        facultyData['Cabin Number'] ??
        facultyData['Office'] ??
        facultyData['office'] ??
        facultyData['Room'] ??
        facultyData['room'] ??
        facultyData['Location'] ??
        facultyData['location'];
  }

  String? getEmployeeId(Map<String, String> facultyData) {
    return facultyData['Faculty ID'] ??
        facultyData['Employee ID'] ??
        facultyData['employee_id'] ??
        facultyData['ID'] ??
        facultyData['id'] ??
        facultyData['Staff ID'] ??
        facultyData['staff_id'];
  }

  Map<String, String> getAdditionalDetails(Map<String, String> facultyData) {
    final extractedKeys = {
      'Faculty Name',
      'Name of the Faculty',
      'Name',
      'name',
      'faculty_name',
      'Faculty Designation',
      'Designation',
      'designation',
      'Post',
      'post',
      'Faculty Department',
      'Department',
      'department',
      'School',
      'school',
      'Faculty Email',
      'Email ID',
      'Email',
      'email',
      'E-Mail',
      'e-mail',
      'Mail',
      'mail',
      'Faculty Mobile Number',
      'Mobile Number',
      'Phone',
      'phone',
      'Mobile',
      'mobile',
      'Contact',
      'contact',
      'Phone Number',
      'phone_number',
      'Cabin',
      'Cabin Number',
      'Office',
      'office',
      'Room',
      'room',
      'Location',
      'location',
      'Faculty ID',
      'Employee ID',
      'employee_id',
      'ID',
      'id',
      'Staff ID',
      'staff_id',
    };

    final Map<String, String> additionalDetails = {};
    for (final entry in facultyData.entries) {
      if (!extractedKeys.contains(entry.key) && entry.value.isNotEmpty) {
        additionalDetails[entry.key] = entry.value;
      }
    }

    return additionalDetails;
  }

  String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return digitsOnly;
  }
}
