import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/config/env_config.dart';
import '../../../../../core/utils/logger.dart';
import '../models/faculty_model.dart';

class FacultyRepository {
  static const String _tag = 'FacultyRepository';
  static const String _owner = 'divyanshupatel17';
  static const String _repo = 'vit-connect-faculty';
  static const String _path = 'faculty-details.json';
  static const String _branch = 'main';
  static const String _cacheKey = 'faculty_data';
  static const String _cacheTimestampKey = 'faculty_data_timestamp';
  static const Duration _cacheThreshold = Duration(hours: 5);

  Future<List<FacultyMember>> fetchFacultyData({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedData = await _getCachedData();
        if (cachedData != null) {
          Logger.d(_tag, 'Loaded ${cachedData.length} faculties from cache');
          return cachedData;
        }
      }

      final token = EnvConfig.githubVitconnectToken;
      final apiUrl =
          'https://api.github.com/repos/$_owner/$_repo/contents/$_path?ref=$_branch';

      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final apiResponse = json.decode(response.body);
        final contentBase64 = apiResponse['content'] as String;
        final contentBytes = base64.decode(contentBase64.replaceAll('\n', ''));
        final contentString = utf8.decode(contentBytes);
        final Map<String, dynamic> jsonData = json.decode(contentString);
        final List<FacultyMember> facultyList = [];

        jsonData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            facultyList.add(FacultyMember.fromJson(value));
          }
        });

        facultyList.sort((a, b) => a.name.compareTo(b.name));
        await _cacheData(facultyList);
        Logger.d(_tag, 'Fetched ${facultyList.length} faculties from API');
        return facultyList;
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e(_tag, 'Fetch failed', e);
      final cachedData = await _getCachedData(ignoreExpiry: true);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  Future<List<FacultyMember>?> _getCachedData({
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedJson == null || timestamp == null) return null;

      if (!ignoreExpiry) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheThreshold) {
          return null;
        }
      }

      final List<dynamic> jsonList = json.decode(cachedJson);
      return jsonList.map((json) => FacultyMember.fromJson(json)).toList();
    } catch (e) {
      Logger.e(_tag, 'Cache read failed', e);
      return null;
    }
  }

  Future<void> _cacheData(List<FacultyMember> facultyList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = facultyList.map((f) => f.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      Logger.e(_tag, 'Cache write failed', e);
    }
  }

  List<FacultyMember> applyFilters(
    List<FacultyMember> facultyList, {
    String? searchQuery,
    String? selectedSchool,
  }) {
    var filtered = facultyList;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where((faculty) => faculty.matchesSearch(searchQuery))
              .toList();
    }

    if (selectedSchool != null && selectedSchool.isNotEmpty) {
      filtered =
          filtered
              .where((faculty) => faculty.school == selectedSchool)
              .toList();
    }

    return filtered;
  }

  List<String> getUniqueSchools(List<FacultyMember> facultyList) {
    final schools =
        facultyList
            .map((f) => f.school)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
    schools.sort();
    return schools;
  }
}
