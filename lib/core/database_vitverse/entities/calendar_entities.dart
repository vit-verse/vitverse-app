/// Calendar entities for VIT Verse database
/// Separate from VTOP student data
class CalendarCacheEntity {
  final String id;
  final String data;
  final int lastUpdated;
  final int expiresAt;
  final String cacheType; // 'metadata', 'calendar_data'

  const CalendarCacheEntity({
    required this.id,
    required this.data,
    required this.lastUpdated,
    required this.expiresAt,
    required this.cacheType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'last_updated': lastUpdated,
      'expires_at': expiresAt,
      'cache_type': cacheType,
    };
  }

  factory CalendarCacheEntity.fromMap(Map<String, dynamic> map) {
    return CalendarCacheEntity(
      id: map['id'] as String,
      data: map['data'] as String,
      lastUpdated: map['last_updated'] as int,
      expiresAt: map['expires_at'] as int,
      cacheType: map['cache_type'] as String,
    );
  }
}

class PersonalEventEntity {
  final String id;
  final String name;
  final String description;
  final int date; // Unix timestamp
  final int? timeHour;
  final int? timeMinute;
  final int createdAt;

  const PersonalEventEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    this.timeHour,
    this.timeMinute,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date,
      'time_hour': timeHour,
      'time_minute': timeMinute,
      'created_at': createdAt,
    };
  }

  factory PersonalEventEntity.fromMap(Map<String, dynamic> map) {
    return PersonalEventEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      date: map['date'] as int,
      timeHour: map['time_hour'] as int?,
      timeMinute: map['time_minute'] as int?,
      createdAt: map['created_at'] as int,
    );
  }
}

class SelectedCalendarEntity {
  final String id;
  final String semesterName;
  final String classGroup;
  final String filePath;
  final int isActive; // 0 or 1 (SQLite boolean)
  final int addedAt;

  const SelectedCalendarEntity({
    required this.id,
    required this.semesterName,
    required this.classGroup,
    required this.filePath,
    required this.isActive,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_name': semesterName,
      'class_group': classGroup,
      'file_path': filePath,
      'is_active': isActive,
      'added_at': addedAt,
    };
  }

  factory SelectedCalendarEntity.fromMap(Map<String, dynamic> map) {
    return SelectedCalendarEntity(
      id: map['id'] as String,
      semesterName: map['semester_name'] as String,
      classGroup: map['class_group'] as String,
      filePath: map['file_path'] as String,
      isActive: map['is_active'] as int,
      addedAt: map['added_at'] as int,
    );
  }
}

class AppPreferenceEntity {
  final String key;
  final String value;
  final int updatedAt;

  const AppPreferenceEntity({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value, 'updated_at': updatedAt};
  }

  factory AppPreferenceEntity.fromMap(Map<String, dynamic> map) {
    return AppPreferenceEntity(
      key: map['key'] as String,
      value: map['value'] as String,
      updatedAt: map['updated_at'] as int,
    );
  }
}
