import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/student_report_data.dart';

/// JSON Export Service
/// Exports student report data in JSON format for ChatGPT analysis or download
class JsonExportService {
  static const String _tag = 'JsonExport';

  // Cache for exported files
  static File? _cachedJsonFile;
  static String? _cachedJsonString;
  static String? _cachedCsvString;
  static String? _cachedTextString;
  static String? _lastRegNumber;

  /// Clear cached data
  static void clearCache() {
    _cachedJsonFile = null;
    _cachedJsonString = null;
    _cachedCsvString = null;
    _cachedTextString = null;
    _lastRegNumber = null;
    Logger.i(_tag, 'JSON export cache cleared');
  }

  /// Export report data to JSON file
  Future<File> exportToJson(StudentReportData data) async {
    try {
      // Return cached file if same student
      if (_cachedJsonFile != null &&
          _lastRegNumber == data.registerNumber &&
          await _cachedJsonFile!.exists()) {
        Logger.i(_tag, 'Returning cached JSON file');
        return _cachedJsonFile!;
      }

      Logger.i(_tag, 'Exporting data to JSON');

      final jsonString = getJsonString(data);

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/VIT_Report_${data.registerNumber}_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      await file.writeAsString(jsonString);

      // Cache the file
      _cachedJsonFile = file;
      _lastRegNumber = data.registerNumber;

      Logger.success(_tag, 'JSON exported successfully at ${file.path}');

      return file;
    } catch (e) {
      Logger.e(_tag, 'Failed to export JSON', e);
      rethrow;
    }
  }

  /// Get JSON string for sharing
  String getJsonString(StudentReportData data) {
    try {
      if (_cachedJsonString != null && _lastRegNumber == data.registerNumber) {
        return _cachedJsonString!;
      }

      _cachedJsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(data.toJson());
      _lastRegNumber = data.registerNumber;
      return _cachedJsonString!;
    } catch (e) {
      Logger.e(_tag, 'Failed to convert to JSON string', e);
      rethrow;
    }
  }

  /// Get comprehensive CSV string with all details
  String getCsvString(StudentReportData data) {
    try {
      if (_cachedCsvString != null && _lastRegNumber == data.registerNumber) {
        return _cachedCsvString!;
      }

      final buffer = StringBuffer();

      // Header
      buffer.writeln('=== ACADEMIC REPORT ===');
      buffer.writeln('');

      // Basic Information
      buffer.writeln('=== BASIC INFORMATION ===');
      buffer.writeln('Name,${data.name}');
      buffer.writeln('Registration Number,${data.registerNumber}');
      buffer.writeln('VIT Email,${data.vitEmail}');
      if (data.nickname != null) buffer.writeln('Nickname,${data.nickname}');
      if (data.gender != null) buffer.writeln('Gender,${data.gender}');
      if (data.dateOfBirth != null) {
        buffer.writeln('Date of Birth,${data.dateOfBirth}');
      }
      buffer.writeln('');

      // Academic Profile
      buffer.writeln('=== ACADEMIC PROFILE ===');
      buffer.writeln('Program,${data.program}');
      buffer.writeln('Branch,${data.branch}');
      buffer.writeln('School,${data.schoolName}');
      if (data.yearJoined != null) {
        buffer.writeln('Year Joined,${data.yearJoined}');
      }
      if (data.studySystem != null) {
        buffer.writeln('Study System,${data.studySystem}');
      }
      if (data.campus != null) buffer.writeln('Campus,${data.campus}');
      buffer.writeln('');

      // Hostel/Mess Info
      if (data.hostelBlock != null ||
          data.roomNumber != null ||
          data.messName != null) {
        buffer.writeln('=== HOSTEL & MESS INFORMATION ===');
        if (data.hostelBlock != null) {
          buffer.writeln('Hostel Block,${data.hostelBlock}');
        }
        if (data.roomNumber != null) {
          buffer.writeln('Room Number,${data.roomNumber}');
        }
        if (data.bedType != null) buffer.writeln('Bed Type,${data.bedType}');
        if (data.messName != null) buffer.writeln('Mess Name,${data.messName}');
        buffer.writeln('');
      }

      // Academic Performance
      buffer.writeln('=== ACADEMIC PERFORMANCE ===');
      buffer.writeln('CGPA,${data.cgpa.toStringAsFixed(2)}');
      buffer.writeln('Credits Earned,${data.creditsEarned.toStringAsFixed(0)}');
      buffer.writeln(
        'Credits Registered,${data.creditsRegistered.toStringAsFixed(0)}',
      );
      buffer.writeln(
        'Total Credits Required,${data.totalCreditsRequired.toStringAsFixed(0)}',
      );
      buffer.writeln('Total Courses,${data.totalCourses}');
      buffer.writeln(
        'Pass Percentage,${data.passPercentage.toStringAsFixed(1)}%',
      );
      buffer.writeln('');

      // Grade Distribution
      buffer.writeln('=== GRADE DISTRIBUTION ===');
      buffer.writeln('Grade,Count');
      buffer.writeln('S,${data.sGrades}');
      buffer.writeln('A,${data.aGrades}');
      buffer.writeln('B,${data.bGrades}');
      buffer.writeln('C,${data.cGrades}');
      buffer.writeln('D,${data.dGrades}');
      buffer.writeln('E,${data.eGrades}');
      buffer.writeln('F,${data.fGrades}');
      buffer.writeln('N,${data.nGrades}');
      buffer.writeln('');

      // Curriculum Progress
      if (data.curriculumProgress.isNotEmpty) {
        buffer.writeln('=== CURRICULUM PROGRESS ===');
        buffer.writeln(
          'Distribution Type,Credits Required,Credits Earned,Completion %',
        );
        for (final curr in data.curriculumProgress) {
          buffer.writeln(
            '${curr.distributionType},${curr.creditsRequired},${curr.creditsEarned},${curr.completionPercentage.toStringAsFixed(1)}%',
          );
        }
        buffer.writeln('');
      }

      // Basket Progress
      if (data.basketProgress.isNotEmpty) {
        buffer.writeln('=== BASKET PROGRESS ===');
        buffer.writeln(
          'Basket Title,Credits Required,Credits Earned,Completion %',
        );
        for (final basket in data.basketProgress) {
          buffer.writeln(
            '${basket.basketTitle},${basket.creditsRequired},${basket.creditsEarned},${basket.completionPercentage.toStringAsFixed(1)}%',
          );
        }
        buffer.writeln('');
      }

      // Semester-wise GPA
      buffer.writeln('=== SEMESTER-WISE GPA ===');
      buffer.writeln('Semester,GPA,Courses,Credits');
      for (final sem in data.gradeHistory) {
        buffer.writeln(
          '${sem.semesterName},${sem.semesterGpa.toStringAsFixed(2)},${sem.totalCourses},${sem.totalCredits.toStringAsFixed(1)}',
        );
      }
      buffer.writeln('');

      // Grade History (All Courses)
      buffer.writeln('=== COMPLETE GRADE HISTORY ===');
      buffer.writeln(
        'Semester,Course Code,Course Title,Grade,Marks,Credits,Type',
      );
      for (final sem in data.gradeHistory) {
        for (final course in sem.courses) {
          buffer.writeln(
            '${sem.semesterName},${course.courseCode},"${course.courseTitle}",${course.grade},${course.totalMarks.toStringAsFixed(0)},${course.credits.toStringAsFixed(1)},${course.courseType}',
          );
        }
      }
      buffer.writeln('');

      // Marks History (All Assessments)
      buffer.writeln('=== COMPLETE MARKS HISTORY ===');
      for (final sem in data.marksHistory) {
        buffer.writeln('');
        buffer.writeln('--- ${sem.semesterName} ---');
        for (final course in sem.courses) {
          buffer.writeln('');
          buffer.writeln('${course.courseCode} - ${course.courseTitle}');
          buffer.writeln('Assessment,Score,Max Score,Percentage');
          for (final assessment in course.assessments) {
            buffer.writeln(
              '${assessment.title},${assessment.score.toStringAsFixed(1)},${assessment.maxScore.toStringAsFixed(1)},${assessment.percentage.toStringAsFixed(1)}%',
            );
          }
        }
      }
      buffer.writeln('');

      // Fee Details
      buffer.writeln('=== FEE DETAILS ===');
      buffer.writeln(
        'Total Fees Paid,Rs ${data.totalFeesPaid.toStringAsFixed(2)}',
      );
      buffer.writeln('');
      if (data.feeReceipts.isNotEmpty) {
        buffer.writeln('Receipt Number,Date,Description,Amount');
        for (final receipt in data.feeReceipts) {
          final dateStr =
              receipt.date != null
                  ? '${receipt.date!.day}/${receipt.date!.month}/${receipt.date!.year}'
                  : 'N/A';
          buffer.writeln(
            '${receipt.receiptNumber},$dateStr,${receipt.description},Rs ${receipt.amount.toStringAsFixed(2)}',
          );
        }
      }
      buffer.writeln('');

      // Metadata
      buffer.writeln('=== REPORT METADATA ===');
      buffer.writeln(
        'Generated At,${data.generatedAt.day}/${data.generatedAt.month}/${data.generatedAt.year} ${data.generatedAt.hour}:${data.generatedAt.minute.toString().padLeft(2, '0')}',
      );
      buffer.writeln('Generated By,VIT Verse');
      buffer.writeln('');
      buffer.writeln(
        'DISCLAIMER: This report is generated by VIT Verse app for informational purposes only. It is NOT an official document and is NOT affiliated with VIT Chennai.',
      );

      _cachedCsvString = buffer.toString();
      _lastRegNumber = data.registerNumber;
      return _cachedCsvString!;
    } catch (e) {
      Logger.e(_tag, 'Failed to convert to CSV string', e);
      rethrow;
    }
  }

  /// Get plain text format (readable format for copying)
  String getTextString(StudentReportData data) {
    try {
      if (_cachedTextString != null && _lastRegNumber == data.registerNumber) {
        return _cachedTextString!;
      }

      final buffer = StringBuffer();

      buffer.writeln('ACADEMIC REPORT');
      buffer.writeln('================');
      buffer.writeln('');

      // Basic Information
      buffer.writeln('BASIC INFORMATION');
      buffer.writeln('-----------------');
      buffer.writeln('Name: ${data.name}');
      buffer.writeln('Registration Number: ${data.registerNumber}');
      buffer.writeln('VIT Email: ${data.vitEmail}');
      if (data.nickname != null) buffer.writeln('Nickname: ${data.nickname}');
      if (data.gender != null) buffer.writeln('Gender: ${data.gender}');
      if (data.dateOfBirth != null) {
        buffer.writeln('Date of Birth: ${data.dateOfBirth}');
      }
      buffer.writeln('');

      // Academic Profile
      buffer.writeln('ACADEMIC PROFILE');
      buffer.writeln('----------------');
      buffer.writeln('Program: ${data.program}');
      buffer.writeln('Branch: ${data.branch}');
      buffer.writeln('School: ${data.schoolName}');
      if (data.yearJoined != null) {
        buffer.writeln('Year Joined: ${data.yearJoined}');
      }
      if (data.studySystem != null) {
        buffer.writeln('Study System: ${data.studySystem}');
      }
      if (data.campus != null) buffer.writeln('Campus: ${data.campus}');
      buffer.writeln('');

      // Hostel/Mess Info
      if (data.hostelBlock != null ||
          data.roomNumber != null ||
          data.messName != null) {
        buffer.writeln('HOSTEL & MESS INFORMATION');
        buffer.writeln('-------------------------');
        if (data.hostelBlock != null) {
          buffer.writeln('Hostel Block: ${data.hostelBlock}');
        }
        if (data.roomNumber != null) {
          buffer.writeln('Room Number: ${data.roomNumber}');
        }
        if (data.bedType != null) buffer.writeln('Bed Type: ${data.bedType}');
        if (data.messName != null) {
          buffer.writeln('Mess Name: ${data.messName}');
        }
        buffer.writeln('');
      }

      // Academic Performance Summary
      buffer.writeln('ACADEMIC PERFORMANCE SUMMARY');
      buffer.writeln('----------------------------');
      buffer.writeln('CGPA: ${data.cgpa.toStringAsFixed(2)}');
      buffer.writeln(
        'Credits: ${data.creditsEarned.toStringAsFixed(0)}/${data.totalCreditsRequired.toStringAsFixed(0)}',
      );
      buffer.writeln('Total Courses: ${data.totalCourses}');
      buffer.writeln('Pass Rate: ${data.passPercentage.toStringAsFixed(1)}%');
      buffer.writeln('');
      buffer.writeln('Grade Distribution:');
      buffer.writeln(
        '  S: ${data.sGrades}  A: ${data.aGrades}  B: ${data.bGrades}  C: ${data.cGrades}',
      );
      buffer.writeln(
        '  D: ${data.dGrades}  E: ${data.eGrades}  F: ${data.fGrades}  N: ${data.nGrades}',
      );
      buffer.writeln('');

      // Curriculum Progress
      if (data.curriculumProgress.isNotEmpty) {
        buffer.writeln('CURRICULUM PROGRESS');
        buffer.writeln('-------------------');
        for (final curr in data.curriculumProgress) {
          buffer.writeln(
            '${curr.distributionType}: ${curr.creditsEarned.toStringAsFixed(0)}/${curr.creditsRequired.toStringAsFixed(0)} credits (${curr.completionPercentage.toStringAsFixed(1)}%)',
          );
        }
        buffer.writeln('');
      }

      // Semester-wise Performance
      buffer.writeln('SEMESTER-WISE PERFORMANCE');
      buffer.writeln('=========================');
      for (int i = 0; i < data.gradeHistory.length; i++) {
        final sem = data.gradeHistory[i];
        buffer.writeln('');
        buffer.writeln('SEMESTER ${i + 1}: ${sem.semesterName}');
        buffer.writeln(
          'GPA: ${sem.semesterGpa.toStringAsFixed(2)} | Courses: ${sem.totalCourses} | Credits: ${sem.totalCredits.toStringAsFixed(1)} | Passed: ${sem.passedCourses}',
        );
        buffer.writeln('');
        buffer.writeln('Courses:');
        for (final course in sem.courses) {
          buffer.writeln('  ${course.courseCode} - ${course.courseTitle}');
          buffer.writeln(
            '    Grade: ${course.grade} | Marks: ${course.totalMarks.toStringAsFixed(0)} | Credits: ${course.credits.toStringAsFixed(1)} | Type: ${course.courseType}',
          );
        }

        // Add marks for this semester if available
        final marksData =
            data.marksHistory
                .where((m) => m.semesterName == sem.semesterName)
                .firstOrNull;
        if (marksData != null && marksData.courses.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('Assessment Details:');
          for (final course in marksData.courses) {
            buffer.writeln('  ${course.courseCode} - ${course.courseTitle}');
            for (final assessment in course.assessments) {
              buffer.writeln(
                '    ${assessment.title}: ${assessment.score.toStringAsFixed(1)}/${assessment.maxScore.toStringAsFixed(1)} (${assessment.percentage.toStringAsFixed(1)}%)',
              );
            }
          }
        }
      }
      buffer.writeln('');

      // Fee Details
      buffer.writeln('FEE DETAILS');
      buffer.writeln('-----------');
      buffer.writeln(
        'Total Fees Paid: Rs ${data.totalFeesPaid.toStringAsFixed(2)}',
      );
      if (data.feeReceipts.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Receipt Details:');
        for (final receipt in data.feeReceipts) {
          final dateStr =
              receipt.date != null
                  ? '${receipt.date!.day}/${receipt.date!.month}/${receipt.date!.year}'
                  : 'N/A';
          buffer.writeln(
            '  Receipt #${receipt.receiptNumber} | Date: $dateStr | Amount: Rs ${receipt.amount.toStringAsFixed(2)}',
          );
        }
      }
      buffer.writeln('');

      // Footer
      buffer.writeln('================');
      buffer.writeln(
        'Generated by VIT Verse on ${data.generatedAt.day}/${data.generatedAt.month}/${data.generatedAt.year}',
      );
      buffer.writeln('https://github.com/vit-verse/');
      buffer.writeln('');
      buffer.writeln(
        'DISCLAIMER: This report is for informational purposes only.',
      );
      buffer.writeln(
        'It is NOT an official document and is NOT affiliated with VIT Chennai.',
      );

      _cachedTextString = buffer.toString();
      _lastRegNumber = data.registerNumber;
      return _cachedTextString!;
    } catch (e) {
      Logger.e(_tag, 'Failed to convert to text string', e);
      rethrow;
    }
  }
}
