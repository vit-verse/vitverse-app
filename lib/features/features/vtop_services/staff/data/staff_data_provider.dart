import '../../../../../core/database/daos/staff_dao.dart';
import '../../../../../core/database/entities/staff.dart';
import '../../../../../core/utils/logger.dart';

class StaffDataProvider {
  Future<Map<String, List<Map<String, String>>>> getStaffByType() async {
    try {
      final staffDao = StaffDao();

      final allStaff = await staffDao.getAll();
      Logger.d(
        'StaffDataProvider',
        'Fetched ${allStaff.length} staff records from database',
      );

      final Map<String, List<Staff>> groupedStaff = {};
      for (final staff in allStaff) {
        String? normalizedType;
        final type = staff.type?.toLowerCase() ?? '';

        if (type.contains('proctor')) {
          normalizedType = 'Proctor';
        } else if (type.contains('hod') ||
            type.contains('head of the department')) {
          normalizedType = 'HOD';
        } else if (type.contains('dean')) {
          normalizedType = 'Dean';
        }

        if (normalizedType != null) {
          if (!groupedStaff.containsKey(normalizedType)) {
            groupedStaff[normalizedType] = [];
          }
          groupedStaff[normalizedType]!.add(staff);
        }
      }

      Logger.d(
        'StaffDataProvider',
        'Grouped into ${groupedStaff.length} types',
      );

      final Map<String, List<Map<String, String>>> result = {};

      for (final entry in groupedStaff.entries) {
        final type = entry.key;
        final staffList = entry.value;

        final Map<String, String> staffData = {};
        for (final staff in staffList) {
          if (staff.key != null && staff.value != null) {
            staffData[staff.key!] = staff.value!;
          }
        }

        if (staffData.isNotEmpty) {
          result[type] = [staffData];
          Logger.d(
            'StaffDataProvider',
            '$type has ${staffData.length} fields: ${staffData.keys.join(", ")}',
          );
        }
      }

      return result;
    } catch (e) {
      Logger.e('StaffDataProvider', 'Error fetching staff data', e);
      return {};
    }
  }

  Future<Map<String, String>> getStaffBySpecificType(String type) async {
    try {
      final staffDao = StaffDao();

      final allStaff = await staffDao.getAll();

      final staffList =
          allStaff.where((staff) {
            final staffType = staff.type?.toLowerCase() ?? '';
            final searchType = type.toLowerCase();

            if (searchType == 'hod') {
              return staffType.contains('hod') ||
                  staffType.contains('head of the department');
            }
            return staffType.contains(searchType);
          }).toList();

      final Map<String, String> staffData = {};
      for (final staff in staffList) {
        if (staff.key != null && staff.value != null) {
          staffData[staff.key!] = staff.value!;
        }
      }

      Logger.d(
        'StaffDataProvider',
        'Found ${staffData.length} fields for $type',
      );
      return staffData;
    } catch (e) {
      Logger.e('StaffDataProvider', 'Error fetching $type data', e);
      return {};
    }
  }

  Future<Map<String, String>> getProctor() async {
    return await getStaffBySpecificType('Proctor');
  }

  Future<Map<String, String>> getHOD() async {
    return await getStaffBySpecificType('HOD');
  }

  Future<Map<String, String>> getDean() async {
    return await getStaffBySpecificType('Dean');
  }
}
