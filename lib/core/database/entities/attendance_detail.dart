/// Day-wise attendance detail entity
/// Maps to the 'attendance_detail' table in the database
/// Child of Attendance with CASCADE delete
class AttendanceDetail {
  final int? id;
  final int attendanceId; // Foreign key to attendance table
  final String attendanceDate; // Format: "11-Sep-2025"
  final String attendanceSlot; // Single slot: "G2" or "TG2"
  final String dayAndTiming; // Format: "THU,15:50-16:40"
  final String
  attendanceStatus; // "Present", "Absent", "On Duty", "Medical Leave"
  final bool isMedicalLeave; // Flag for medical leave
  final bool
  isVirtualSlot; // Flag for virtual slots (not counted in percentage)

  const AttendanceDetail({
    this.id,
    required this.attendanceId,
    required this.attendanceDate,
    required this.attendanceSlot,
    required this.dayAndTiming,
    required this.attendanceStatus,
    this.isMedicalLeave = false,
    this.isVirtualSlot = false,
  });

  /// Create AttendanceDetail from database map
  factory AttendanceDetail.fromMap(Map<String, dynamic> map) {
    return AttendanceDetail(
      id: map['id'] as int?,
      attendanceId: map['attendance_id'] as int,
      attendanceDate: map['attendance_date'] as String,
      attendanceSlot: map['attendance_slot'] as String,
      dayAndTiming: map['day_and_timing'] as String,
      attendanceStatus: map['attendance_status'] as String,
      isMedicalLeave: (map['is_medical_leave'] as int?) == 1,
      isVirtualSlot: (map['is_virtual_slot'] as int?) == 1,
    );
  }

  /// Convert AttendanceDetail to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attendance_id': attendanceId,
      'attendance_date': attendanceDate,
      'attendance_slot': attendanceSlot,
      'day_and_timing': dayAndTiming,
      'attendance_status': attendanceStatus,
      'is_medical_leave': isMedicalLeave ? 1 : 0,
      'is_virtual_slot': isVirtualSlot ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  AttendanceDetail copyWith({
    int? id,
    int? attendanceId,
    String? attendanceDate,
    String? attendanceSlot,
    String? dayAndTiming,
    String? attendanceStatus,
    bool? isMedicalLeave,
    bool? isVirtualSlot,
  }) {
    return AttendanceDetail(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      attendanceSlot: attendanceSlot ?? this.attendanceSlot,
      dayAndTiming: dayAndTiming ?? this.dayAndTiming,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      isMedicalLeave: isMedicalLeave ?? this.isMedicalLeave,
      isVirtualSlot: isVirtualSlot ?? this.isVirtualSlot,
    );
  }

  /// Check if attendance was marked as absent
  bool get isAbsent => attendanceStatus.toLowerCase() == 'absent';

  /// Check if attendance was marked as present
  bool get isPresent => attendanceStatus.toLowerCase() == 'present';

  /// Check if attendance was marked as on duty
  bool get isOnDuty =>
      attendanceStatus.toLowerCase().contains('on duty') ||
      attendanceStatus.toLowerCase().contains('onduty');

  @override
  String toString() {
    return 'AttendanceDetail{id: $id, attendanceId: $attendanceId, date: $attendanceDate, slot: $attendanceSlot, timing: $dayAndTiming, status: $attendanceStatus, isMedicalLeave: $isMedicalLeave, isVirtualSlot: $isVirtualSlot}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceDetail &&
        other.id == id &&
        other.attendanceId == attendanceId &&
        other.attendanceDate == attendanceDate &&
        other.attendanceSlot == attendanceSlot &&
        other.dayAndTiming == dayAndTiming &&
        other.attendanceStatus == attendanceStatus &&
        other.isMedicalLeave == isMedicalLeave &&
        other.isVirtualSlot == isVirtualSlot;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        attendanceId.hashCode ^
        attendanceDate.hashCode ^
        attendanceSlot.hashCode ^
        dayAndTiming.hashCode ^
        attendanceStatus.hashCode ^
        isMedicalLeave.hashCode ^
        isVirtualSlot.hashCode;
  }
}
