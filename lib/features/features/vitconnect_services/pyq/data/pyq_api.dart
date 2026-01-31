import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../../core/config/env_config.dart';
import '../../../../../core/utils/logger.dart';
import 'pyq_models.dart';

/// PYQ API Service - handles all network calls for PYQ feature
class PyqApi {
  static const _tag = 'PyqApi';
  static const _base =
      'https://raw.githubusercontent.com/vit-verse/vit-pyqs-metadata/main';
  static const _uploadUrl =
      'https://asia-south1-vit-connect-app.cloudfunctions.net/uploadPyqPaper';

  /// Fetch global metadata (all courses and paper counts)
  static Future<GlobalPyqMeta> fetchGlobal() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final res = await http.get(
        Uri.parse('$_base/global.json?t=$timestamp'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (res.statusCode != 200) {
        Logger.e(_tag, 'Failed to fetch global metadata: ${res.statusCode}');
        throw Exception('Failed to load global metadata');
      }

      final data = jsonDecode(res.body);
      Logger.i(
        _tag,
        'Global metadata loaded: ${data['total_courses'] ?? 0} courses',
      );
      return GlobalPyqMeta.fromJson(data);
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error fetching global metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Fetch papers for a specific course
  static Future<List<PyqPaper>> fetchCoursePapers(String courseCode) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final res = await http.get(
        Uri.parse('$_base/courses/$courseCode.json?t=$timestamp'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (res.statusCode == 404) {
        Logger.w(_tag, 'No papers found for course: $courseCode');
        return [];
      }

      if (res.statusCode != 200) {
        Logger.e(_tag, 'Failed to fetch course papers: ${res.statusCode}');
        throw Exception('Failed to load course papers');
      }

      final data = jsonDecode(res.body);
      final papers =
          (data['papers'] as List? ?? [])
              .map((e) => PyqPaper.fromJson(e as Map<String, dynamic>))
              .toList();

      Logger.i(_tag, 'Loaded ${papers.length} papers for $courseCode');
      return papers;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error fetching course papers', e, stackTrace);
      rethrow;
    }
  }

  /// Upload a new PYQ paper (admin only)
  static Future<Map<String, dynamic>> uploadPaper({
    required File file,
    required String courseCode,
    required String courseTitle,
    required String examType,
    required String examDate,
    required String slot,
    required String semester,
    required String faculty,
    required String classNo,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.headers['X-PYQ-SECRET'] = EnvConfig.pyqSecretHeader;

      request.fields['courseCode'] = courseCode;
      request.fields['courseTitle'] = courseTitle;
      request.fields['exam'] = examType;
      request.fields['examDate'] = examDate;
      request.fields['slot'] = slot;
      request.fields['semester'] = semester;
      request.fields['faculty'] = faculty;
      request.fields['classNo'] = classNo;

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Logger.i(_tag, 'Paper uploaded successfully');
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Paper uploaded successfully',
          'data': responseData,
        };
      } else {
        Logger.e(
          _tag,
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'message': 'Upload failed: ${response.reasonPhrase}',
        };
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error uploading paper', e, stackTrace);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
