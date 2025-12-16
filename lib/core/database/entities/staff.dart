/// Staff entity representing faculty information and contact details
/// Maps to the 'staff' table in the database
/// Independent entity (no foreign keys)
// As of now, only Proc., HOD, DEAN
class Staff {
  final int? id;
  final String? type;
  final String? key;
  final String? value;

  const Staff({this.id, this.type, this.key, this.value});

  /// Create Staff from database map
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as int?,
      type: map['type'] as String?,
      key: map['key'] as String?,
      value: map['value'] as String?,
    );
  }

  /// Convert Staff to database map
  Map<String, dynamic> toMap() {
    return {'id': id, 'type': type, 'key': key, 'value': value};
  }

  /// Create copy with updated fields
  Staff copyWith({int? id, String? type, String? key, String? value}) {
    return Staff(
      id: id ?? this.id,
      type: type ?? this.type,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return 'Staff{id: $id, type: $type, key: $key, value: $value}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Staff &&
        other.id == id &&
        other.type == type &&
        other.key == key &&
        other.value == value;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ key.hashCode ^ value.hashCode;
  }
}
