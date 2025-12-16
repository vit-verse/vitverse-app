/// Student Profile Entity
/// Stores basic student information from VTOP
/// Data sources:
/// - Step 1: Basic profile and hostel info
/// - Step 2: Academic profile details (gender, year, etc.)
/// Saved in SharedPreferences for fast access
/// Not required DETAILED INFO now; for future use only. No core DB changes or versioning needed.
class StudentProfile {
  // Basic Information (from Step 1)
  final String name;
  final String registerNumber;
  final String vitEmail;
  final String program;
  final String branch;
  final String schoolName;

  // Hostel Information (from Step 1)
  final String? hostelBlock;
  final String? roomNumber;
  final String? bedType;
  final String? messName;

  // Additional Information (from Step 1)
  final String? dateOfBirth;

  // Academic Profile (from Step 2)
  final String? gender; // MALE/FEMALE
  final String? yearJoined; // 2023, 2024, etc.
  final String? studySystem; // CBCS, etc.
  final String? eduStatus; // Admitted, Graduated, etc.
  final String? campus; // CHN, VLR, etc.
  final String? programmeMode; // Regular, Distance, etc.

  // User Customization
  final String? nickname; // Custom nickname (with emoji support)

  StudentProfile({
    required this.name,
    required this.registerNumber,
    required this.vitEmail,
    required this.program,
    required this.branch,
    required this.schoolName,
    this.hostelBlock,
    this.roomNumber,
    this.bedType,
    this.messName,
    this.dateOfBirth,
    this.gender,
    this.yearJoined,
    this.studySystem,
    this.eduStatus,
    this.campus,
    this.programmeMode,
    this.nickname,
  });

  /// Convert to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'registerNumber': registerNumber,
      'vitEmail': vitEmail,
      'program': program,
      'branch': branch,
      'schoolName': schoolName,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'bedType': bedType,
      'messName': messName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'yearJoined': yearJoined,
      'studySystem': studySystem,
      'eduStatus': eduStatus,
      'campus': campus,
      'programmeMode': programmeMode,
      'nickname': nickname,
    };
  }

  /// Create from JSON (from SharedPreferences)
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] ?? '',
      registerNumber: json['registerNumber'] ?? '',
      vitEmail: json['vitEmail'] ?? '',
      program: json['program'] ?? '',
      branch: json['branch'] ?? '',
      schoolName: json['schoolName'] ?? '',
      hostelBlock: json['hostelBlock'],
      roomNumber: json['roomNumber'],
      bedType: json['bedType'],
      messName: json['messName'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      yearJoined: json['yearJoined'],
      studySystem: json['studySystem'],
      eduStatus: json['eduStatus'],
      campus: json['campus'],
      programmeMode: json['programmeMode'],
      nickname: json['nickname'],
    );
  }

  /// Create empty profile
  factory StudentProfile.empty() {
    return StudentProfile(
      name: '',
      registerNumber: '',
      vitEmail: '',
      program: '',
      branch: '',
      schoolName: '',
    );
  }

  @override
  String toString() {
    return 'StudentProfile(name: $name, registerNumber: $registerNumber, vitEmail: $vitEmail)';
  }
}
