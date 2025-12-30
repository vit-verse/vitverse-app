import 'package:flutter/material.dart';
import 'friend_class_slot.dart';

/// Represents a friend's timetable data
/// Contains student info and all their class slots
class Friend {
  final String id; // Unique identifier (reg number or generated)
  final String name;
  final String nickname; // Display name for friend
  final String regNumber;
  final List<FriendClassSlot> classSlots;
  final Color color; // Theme color for this friend
  final DateTime addedAt;
  final bool showInFriendsSchedule; // Show in Friends Schedule page
  final bool showInHomePage; // Show in Home page

  const Friend({
    required this.id,
    required this.name,
    required this.nickname,
    required this.regNumber,
    required this.classSlots,
    required this.color,
    required this.addedAt,
    this.showInFriendsSchedule = false,
    this.showInHomePage = false,
  });

  /// Get class slot for a specific cell (day + timeSlot)
  FriendClassSlot? getSlotForCell(String day, String timeSlot) {
    try {
      return classSlots.firstWhere(
        (slot) => slot.day == day && slot.timeSlot == timeSlot,
      );
    } catch (e) {
      return null; // No class at this time
    }
  }

  /// Check if friend has class at specific time
  bool hasClassAt(String day, String timeSlot) {
    return getSlotForCell(day, timeSlot) != null;
  }

  /// Get all classes for a specific day
  List<FriendClassSlot> getClassesForDay(String day) {
    return classSlots.where((slot) => slot.day == day).toList();
  }

  /// Create Friend from JSON
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? json['name'] as String? ?? '',
      regNumber: json['regNumber'] as String? ?? '',
      classSlots:
          (json['classSlots'] as List<dynamic>?)
              ?.map((e) => FriendClassSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      color: Color(json['color'] as int? ?? 0xFF6366F1),
      addedAt: DateTime.parse(
        json['addedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      showInFriendsSchedule: json['showInFriendsSchedule'] as bool? ?? false,
      showInHomePage: json['showInHomePage'] as bool? ?? false,
    );
  }

  /// Convert Friend to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'regNumber': regNumber,
      'classSlots': classSlots.map((e) => e.toJson()).toList(),
      'color': color.value,
      'addedAt': addedAt.toIso8601String(),
      'showInFriendsSchedule': showInFriendsSchedule,
      'showInHomePage': showInHomePage,
    };
  }

  /// Create compact QR-friendly string
  /// Format: name|regNumber|slot1||slot2||slot3...
  String toQRString() {
    final slotsString = classSlots.map((s) => s.toCompactString()).join('||');
    return '$name|$regNumber|$slotsString';
  }

  /// Parse from QR string
  factory Friend.fromQRString(String qrData, {Color? color}) {
    try {
      final parts = qrData.split('|');
      if (parts.length < 2) {
        throw FormatException('Invalid QR data format');
      }

      final name = parts[0];
      final regNumber = parts[1];
      final slotsData = parts.length > 2 ? parts.sublist(2).join('|') : '';

      final classSlots = <FriendClassSlot>[];
      if (slotsData.isNotEmpty) {
        final slotStrings = slotsData.split('||');
        for (var slotStr in slotStrings) {
          if (slotStr.isNotEmpty) {
            try {
              classSlots.add(FriendClassSlot.fromCompactString(slotStr));
            } catch (e) {
              // Skip invalid slots
            }
          }
        }
      }

      return Friend(
        id: regNumber,
        name: name,
        nickname: name, // Default nickname is the name
        regNumber: regNumber,
        classSlots: classSlots,
        color: color ?? _generateColorFromString(regNumber),
        addedAt: DateTime.now(),
        showInFriendsSchedule: false, // User will choose
        showInHomePage: false, // User will choose
      );
    } catch (e) {
      throw FormatException('Failed to parse QR data: $e');
    }
  }

  /// Generate a consistent color from string (for unique friend colors)
  static Color _generateColorFromString(String str) {
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Green
      const Color(0xFFA855F7), // Purple
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF8B5CF6), // Violet
    ];

    final hash = str.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Create a copy with updated fields
  Friend copyWith({
    String? id,
    String? name,
    String? nickname,
    String? regNumber,
    List<FriendClassSlot>? classSlots,
    Color? color,
    DateTime? addedAt,
    bool? showInFriendsSchedule,
    bool? showInHomePage,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      regNumber: regNumber ?? this.regNumber,
      classSlots: classSlots ?? this.classSlots,
      color: color ?? this.color,
      addedAt: addedAt ?? this.addedAt,
      showInFriendsSchedule: showInFriendsSchedule ?? this.showInFriendsSchedule,
      showInHomePage: showInHomePage ?? this.showInHomePage,
    );
  }

  @override
  String toString() {
    return 'Friend{name: $name, nickname: $nickname, regNumber: $regNumber, slots: ${classSlots.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friend && other.id == id && other.regNumber == regNumber;
  }

  @override
  int get hashCode => id.hashCode ^ regNumber.hashCode;
}
