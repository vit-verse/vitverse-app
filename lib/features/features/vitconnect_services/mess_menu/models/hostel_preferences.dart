/// Model for hostel preferences
class HostelPreferences {
  final String gender; // 'M' or 'W'
  final String block; // 'A', 'B', 'CB', 'CG', 'D1', 'D2', 'E'
  final String messType; // 'V' (Veg), 'N' (Non-Veg), 'S' (Special)
  final String? caterer; // Optional, for UX only
  final int? roomNumber; // User's room number for laundry highlighting

  HostelPreferences({
    required this.gender,
    required this.block,
    required this.messType,
    this.caterer,
    this.roomNumber,
  });

  factory HostelPreferences.fromJson(Map<String, dynamic> json) {
    return HostelPreferences(
      gender: json['gender'] as String? ?? '',
      block: json['block'] as String? ?? '',
      messType: json['messType'] as String? ?? '',
      caterer: json['caterer'] as String?,
      roomNumber: json['roomNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'block': block,
      'messType': messType,
      'caterer': caterer,
      'roomNumber': roomNumber,
    };
  }

  /// Get the mess menu file name based on gender and mess type
  /// Examples: VITC-M-V.json, VITC-W-N.json
  String getMessMenuFileName() {
    return 'VITC-$gender-$messType.json';
  }

  /// Get the laundry schedule file name based on block
  /// Examples: VITC-A-L.json, VITC-CB-L.json
  String getLaundryFileName() {
    return 'VITC-$block-L.json';
  }

  /// Check if preferences are complete (minimum required fields)
  bool get isComplete {
    return gender.isNotEmpty && block.isNotEmpty && messType.isNotEmpty;
  }

  /// Get display name for gender
  String get genderDisplay {
    return gender == 'M'
        ? 'Men'
        : gender == 'W'
        ? 'Women'
        : '';
  }

  /// Get display name for mess type
  String get messTypeDisplay {
    switch (messType) {
      case 'V':
        return 'Vegetarian';
      case 'N':
        return 'Non-Vegetarian';
      case 'S':
        return 'Special';
      default:
        return '';
    }
  }

  /// Get available blocks based on gender
  static List<String> getAvailableBlocks(String gender) {
    if (gender == 'M') {
      return ['A', 'C', 'D1', 'D2', 'E'];
    } else if (gender == 'W') {
      return ['B', 'C'];
    }
    return [];
  }

  /// Map selected block to actual file block name
  /// C block needs to be mapped to CB (for men) or CG (for women)
  static String mapBlockToFileName(String gender, String selectedBlock) {
    if (selectedBlock == 'C') {
      return gender == 'M' ? 'CB' : 'CG';
    }
    return selectedBlock;
  }

  HostelPreferences copyWith({
    String? gender,
    String? block,
    String? messType,
    String? caterer,
    int? roomNumber,
  }) {
    return HostelPreferences(
      gender: gender ?? this.gender,
      block: block ?? this.block,
      messType: messType ?? this.messType,
      caterer: caterer ?? this.caterer,
      roomNumber: roomNumber ?? this.roomNumber,
    );
  }
}
