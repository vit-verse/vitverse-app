import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/student_report_data.dart';

/// PDF Generator Service
/// Generates comprehensive student report in PDF format with charts and graphs
class PdfGeneratorService {
  static const String _tag = 'PdfGenerator';

  /// Sanitize text to remove unsupported Unicode characters
  String _sanitizeText(String text) {
    return text
        .replaceAll('₹', 'Rs ')
        .replaceAll('❤', '')
        .replaceAll('️', '')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll('…', '...')
        .replaceAll('•', '-');
  }

  /// Generate comprehensive PDF report
  Future<File> generatePDFReport(StudentReportData data) async {
    try {
      Logger.i(_tag, 'Starting PDF generation');

      final pdf = pw.Document();

      // Load logo image
      ByteData? logoData;
      try {
        logoData = await rootBundle.load('assets/images/vit-verse-love.png');
      } catch (e) {
        Logger.w(_tag, 'Failed to load logo image: $e');
      }

      pdf.addPage(_buildCoverPage(data));
      pdf.addPage(_buildAcademicAndFeeSummaryPage(data));

      if (data.curriculumProgress.isNotEmpty ||
          data.basketProgress.isNotEmpty) {
        pdf.addPage(_buildProgressPage(data));
      }

      _addSemesterPages(pdf, data);

      if (data.feeReceipts.isNotEmpty) {
        pdf.addPage(_buildDetailedFeePage(data));
      }

      pdf.addPage(_buildFooterPage(data, logoData));

      final output = await _savePDF(pdf, data.registerNumber);
      Logger.success(_tag, 'PDF generated successfully at ${output.path}');
      return output;
    } catch (e) {
      Logger.e(_tag, 'Failed to generate PDF', e);
      rethrow;
    }
  }

  /// Add semester pages with dynamic content handling
  void _addSemesterPages(pw.Document pdf, StudentReportData data) {
    final totalSemesters = data.gradeHistory.length;

    for (int i = 0; i < totalSemesters; i++) {
      final gradeData = data.gradeHistory[i];
      final marksData =
          data.marksHistory
              .where((m) => m.semesterName == gradeData.semesterName)
              .firstOrNull;

      // Use MultiPage for each semester to handle overflow
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildSemesterContent(
              data,
              i,
              totalSemesters,
              gradeData,
              marksData,
            );
          },
        ),
      );
    }
  }

  /// Build semester content as list of widgets for MultiPage
  List<pw.Widget> _buildSemesterContent(
    StudentReportData data,
    int semesterIndex,
    int totalSemesters,
    SemesterGradeData gradeData,
    SemesterMarksData? marksData,
  ) {
    final widgets = <pw.Widget>[];

    // Header
    widgets.add(
      _buildSectionTitle(
        'SEMESTER ${semesterIndex + 1} / $totalSemesters: ${_sanitizeText(gradeData.semesterName)}',
      ),
    );
    widgets.add(pw.SizedBox(height: 15));

    // Summary Box
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Text('GPA', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  gradeData.semesterGpa.toStringAsFixed(2),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('Courses', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  '${gradeData.totalCourses}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('Credits', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  gradeData.totalCredits.toStringAsFixed(1),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('Passed', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  '${gradeData.passedCourses}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    widgets.add(pw.SizedBox(height: 15));
    widgets.add(
      pw.Text(
        'GRADE HISTORY',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // Grade History Table
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.8),
          1: const pw.FlexColumnWidth(3.5),
          2: const pw.FlexColumnWidth(0.8),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue100),
            children: [
              _buildTableCell('Code', isHeader: true, fontSize: 7),
              _buildTableCell('Title', isHeader: true, fontSize: 7),
              _buildTableCell('Grade', isHeader: true, fontSize: 7),
              _buildTableCell('Marks', isHeader: true, fontSize: 7),
              _buildTableCell('Credits', isHeader: true, fontSize: 7),
              _buildTableCell('Type', isHeader: true, fontSize: 7),
            ],
          ),
          ...gradeData.courses.map((course) {
            return pw.TableRow(
              children: [
                _buildTableCell(_sanitizeText(course.courseCode), fontSize: 6),
                _buildTableCell(_sanitizeText(course.courseTitle), fontSize: 6),
                _buildTableCell(course.grade, fontSize: 6),
                _buildTableCell(
                  course.totalMarks.toStringAsFixed(0),
                  fontSize: 6,
                ),
                _buildTableCell(course.credits.toStringAsFixed(1), fontSize: 6),
                _buildTableCell(_sanitizeText(course.courseType), fontSize: 5),
              ],
            );
          }),
        ],
      ),
    );

    // Marks History - Each course on new lines
    if (marksData != null && marksData.courses.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 15));
      widgets.add(
        pw.Text(
          'MARKS HISTORY',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));

      for (final courseMarks in marksData.courses) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${_sanitizeText(courseMarks.courseCode)} - ${_sanitizeText(courseMarks.courseTitle)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                // Each assessment on new line
                ...courseMarks.assessments.map((assessment) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      '${_sanitizeText(assessment.title)}: ${assessment.score.toStringAsFixed(1)}/${assessment.maxScore.toStringAsFixed(1)}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  pw.Page _buildCoverPage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ACADEMIC REPORT',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    data.name,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    data.registerNumber,
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Basic Information
            _buildSection('BASIC INFORMATION', [
              _buildRow('Name', data.name),
              _buildRow('Registration Number', data.registerNumber),
              _buildRow('VIT Email', data.vitEmail),
              if (data.nickname != null) _buildRow('Nickname', data.nickname!),
              if (data.gender != null) _buildRow('Gender', data.gender!),
              if (data.dateOfBirth != null)
                _buildRow('Date of Birth', data.dateOfBirth!),
            ]),

            pw.SizedBox(height: 20),

            // Academic Profile
            _buildSection('ACADEMIC PROFILE', [
              _buildRow('Program', data.program),
              _buildRow('Branch', data.branch),
              _buildRow('School', data.schoolName),
              if (data.yearJoined != null)
                _buildRow('Year Joined', data.yearJoined!),
              if (data.studySystem != null)
                _buildRow('Study System', data.studySystem!),
              if (data.campus != null) _buildRow('Campus', data.campus!),
            ]),

            pw.SizedBox(height: 20),

            // Hostel/Mess Information
            if (data.hostelBlock != null)
              _buildSection('HOSTEL & MESS INFORMATION', [
                if (data.hostelBlock != null)
                  _buildRow('Hostel Block', data.hostelBlock!),
                if (data.roomNumber != null)
                  _buildRow('Room Number', data.roomNumber!),
                if (data.bedType != null) _buildRow('Bed Type', data.bedType!),
                if (data.messName != null)
                  _buildRow('Mess Name', data.messName!),
              ]),
          ],
        );
      },
    );
  }

  pw.Page _buildAcademicPage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ACADEMIC PERFORMANCE SUMMARY'),
            pw.SizedBox(height: 20),

            // CGPA Overview
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard('CGPA', data.cgpa.toStringAsFixed(2)),
                      _buildMetricCard(
                        'Credits Earned',
                        '${data.creditsEarned.toStringAsFixed(1)}/${data.creditsRegistered.toStringAsFixed(1)}',
                      ),
                      _buildMetricCard(
                        'Total Courses',
                        data.totalCourses.toString(),
                      ),
                      _buildMetricCard(
                        'Pass %',
                        '${data.passPercentage.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Grade Distribution
            _buildSectionTitle('GRADE DISTRIBUTION'),
            pw.SizedBox(height: 15),
            _buildGradeDistributionChart(data),

            pw.SizedBox(height: 30),

            // Grade Breakdown Table
            _buildGradeBreakdownTable(data),
          ],
        );
      },
    );
  }

  pw.MultiPage _buildProgressPage(StudentReportData data) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        final widgets = <pw.Widget>[];

        if (data.curriculumProgress.isNotEmpty) {
          widgets.add(_buildSectionTitle('CURRICULUM PROGRESS'));
          widgets.add(pw.SizedBox(height: 15));

          for (final curr in data.curriculumProgress) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      curr.distributionType,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Credits: ${curr.creditsEarned.toStringAsFixed(1)}/${curr.creditsRequired.toStringAsFixed(1)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '${curr.completionPercentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color:
                                curr.completionPercentage >= 100
                                    ? PdfColors.green
                                    : PdfColors.orange,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    _buildProgressBar(curr.completionPercentage),
                  ],
                ),
              ),
            );
          }
        }

        if (data.basketProgress.isNotEmpty) {
          if (data.curriculumProgress.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 30));
          }

          widgets.add(_buildSectionTitle('BASKET PROGRESS'));
          widgets.add(pw.SizedBox(height: 15));

          for (final basket in data.basketProgress) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      basket.basketTitle,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Credits: ${basket.creditsEarned.toStringAsFixed(1)}/${basket.creditsRequired.toStringAsFixed(1)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '${basket.completionPercentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color:
                                basket.completionPercentage >= 100
                                    ? PdfColors.green
                                    : PdfColors.orange,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    _buildProgressBar(basket.completionPercentage),
                  ],
                ),
              ),
            );
          }
        }

        return widgets;
      },
    );
  }

  pw.Page _buildGradeDistributionPage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('SEMESTER-WISE PERFORMANCE OVERVIEW'),
            pw.SizedBox(height: 20),

            // Semester Performance Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('Semester', isHeader: true),
                    _buildTableCell('GPA', isHeader: true),
                    _buildTableCell('Courses', isHeader: true),
                    _buildTableCell('Credits', isHeader: true),
                  ],
                ),
                // Data rows
                ...data.semesterPerformances.map((sem) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(sem.semesterName),
                      _buildTableCell(sem.gpa.toStringAsFixed(2)),
                      _buildTableCell(sem.courseCount.toString()),
                      _buildTableCell(sem.totalCredits.toStringAsFixed(1)),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 30),

            // CGPA Trend Chart (Simple line representation)
            _buildSectionTitle('CGPA TREND'),
            pw.SizedBox(height: 15),
            _buildGPATrendChart(data.semesterPerformances),
          ],
        );
      },
    );
  }

  pw.Page _buildSemesterPage(StudentReportData data, int semesterIndex) {
    final semester = data.gradeHistory[semesterIndex];
    final marks = data.marksHistory.firstWhere(
      (m) => m.semesterName == semester.semesterName,
      orElse: () => SemesterMarksData(semesterName: '', courses: []),
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(semester.semesterName.toUpperCase()),
            pw.SizedBox(height: 10),

            // Semester Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCard(
                    'Semester GPA',
                    semester.semesterGpa.toStringAsFixed(2),
                  ),
                  _buildMetricCard(
                    'Courses',
                    '${semester.passedCourses}/${semester.totalCourses}',
                  ),
                  _buildMetricCard(
                    'Credits',
                    semester.totalCredits.toStringAsFixed(1),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Course Grades
            _buildSectionTitle('COURSE GRADES'),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('Code', isHeader: true),
                    _buildTableCell('Title', isHeader: true),
                    _buildTableCell('Grade', isHeader: true),
                    _buildTableCell('Credits', isHeader: true),
                  ],
                ),
                ...semester.courses.map((course) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(course.courseCode, fontSize: 8),
                      _buildTableCell(course.courseTitle, fontSize: 8),
                      _buildTableCell(course.grade, fontSize: 8),
                      _buildTableCell(
                        course.credits.toStringAsFixed(1),
                        fontSize: 8,
                      ),
                    ],
                  );
                }),
              ],
            ),

            if (marks.courses.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildSectionTitle('ASSESSMENT DETAILS'),
              pw.SizedBox(height: 10),
              ...marks.courses.map((course) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${course.courseCode} - ${course.courseTitle}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      ...course.assessments.map((assessment) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                assessment.title,
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                              pw.Text(
                                '${assessment.score.toStringAsFixed(1)}/${assessment.maxScore.toStringAsFixed(1)} (${assessment.percentage.toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  pw.Page _buildDetailedAssessmentPage(StudentReportData data, int index) {
    if (index >= data.marksHistory.length) {
      return pw.Page(build: (context) => pw.Container());
    }

    final marks = data.marksHistory[index];
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('${marks.semesterName} - DETAILED ASSESSMENTS'),
            pw.SizedBox(height: 20),

            ...marks.courses.map((course) {
              final avgPercentage =
                  course.assessments.isEmpty
                      ? 0.0
                      : course.assessments
                              .map((a) => a.percentage)
                              .reduce((a, b) => a + b) /
                          course.assessments.length;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            course.courseCode,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            course.courseTitle,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Average: ${avgPercentage.toStringAsFixed(1)}%',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(1),
                          2: const pw.FlexColumnWidth(1),
                          3: const pw.FlexColumnWidth(1),
                        },
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.grey200,
                            ),
                            children: [
                              _buildTableCell(
                                'Assessment',
                                isHeader: true,
                                fontSize: 8,
                              ),
                              _buildTableCell(
                                'Score',
                                isHeader: true,
                                fontSize: 8,
                              ),
                              _buildTableCell(
                                'Max',
                                isHeader: true,
                                fontSize: 8,
                              ),
                              _buildTableCell('%', isHeader: true, fontSize: 8),
                            ],
                          ),
                          ...course.assessments.map((assessment) {
                            return pw.TableRow(
                              children: [
                                _buildTableCell(assessment.title, fontSize: 7),
                                _buildTableCell(
                                  assessment.score.toStringAsFixed(1),
                                  fontSize: 7,
                                ),
                                _buildTableCell(
                                  assessment.maxScore.toStringAsFixed(1),
                                  fontSize: 7,
                                ),
                                _buildTableCell(
                                  '${assessment.percentage.toStringAsFixed(1)}%',
                                  fontSize: 7,
                                  textColor:
                                      assessment.percentage >= 50
                                          ? PdfColors.green700
                                          : PdfColors.red700,
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  pw.Page _buildCourseWiseAnalysisPage(StudentReportData data) {
    final allCourses = <String, List<double>>{};

    for (final semester in data.marksHistory) {
      for (final course in semester.courses) {
        final key = '${course.courseCode} - ${course.courseTitle}';
        if (!allCourses.containsKey(key)) {
          allCourses[key] = [];
        }
        final avgPercentage =
            course.assessments.isEmpty
                ? 0.0
                : course.assessments
                        .map((a) => a.percentage)
                        .reduce((a, b) => a + b) /
                    course.assessments.length;
        allCourses[key]!.add(avgPercentage);
      }
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('COURSE-WISE PERFORMANCE ANALYSIS'),
            pw.SizedBox(height: 20),

            pw.Text(
              'Overall Course Performance Summary',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('Course', isHeader: true, fontSize: 9),
                    _buildTableCell('Avg %', isHeader: true, fontSize: 9),
                    _buildTableCell('Count', isHeader: true, fontSize: 9),
                    _buildTableCell('Status', isHeader: true, fontSize: 9),
                  ],
                ),
                ...allCourses.entries.map((entry) {
                  final avgPercentage =
                      entry.value.reduce((a, b) => a + b) / entry.value.length;
                  final status = avgPercentage >= 50 ? 'Pass' : 'Fail';
                  final statusColor =
                      avgPercentage >= 50
                          ? PdfColors.green700
                          : PdfColors.red700;

                  return pw.TableRow(
                    children: [
                      _buildTableCell(entry.key, fontSize: 7),
                      _buildTableCell(
                        avgPercentage.toStringAsFixed(1),
                        fontSize: 7,
                      ),
                      _buildTableCell(
                        entry.value.length.toString(),
                        fontSize: 7,
                      ),
                      _buildTableCell(
                        status,
                        fontSize: 7,
                        textColor: statusColor,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Performance Insights',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '- Total Courses Analyzed: ${allCourses.length}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '- Overall Pass Rate: ${data.passPercentage.toStringAsFixed(1)}%',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '- CGPA: ${data.cgpa.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '- Credits: ${data.creditsEarned.toStringAsFixed(1)}/${data.totalCreditsRequired.toStringAsFixed(1)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildFeePage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('FEE DETAILS'),
            pw.SizedBox(height: 20),

            // Total Fees
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Total Fees Paid: ',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs ${data.totalFeesPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Receipt List
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('Receipt No', isHeader: true),
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                  ],
                ),
                ...data.feeReceipts.map((receipt) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(receipt.receiptNumber, fontSize: 8),
                      _buildTableCell(
                        receipt.date != null
                            ? '${receipt.date!.day}/${receipt.date!.month}/${receipt.date!.year}'
                            : 'N/A',
                        fontSize: 8,
                      ),
                      _buildTableCell(receipt.description, fontSize: 8),
                      _buildTableCell(
                        'Rs ${receipt.amount.toStringAsFixed(2)}',
                        fontSize: 8,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildDetailedFeePage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('DETAILED FEE RECEIPTS'),
            pw.SizedBox(height: 20),

            // Summary Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'TOTAL FEES PAID',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Rs ${data.totalFeesPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Total Receipts: ${data.feeReceipts.length}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Detailed Receipt Table
            pw.Text(
              'Receipt Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('S.No', isHeader: true, fontSize: 8),
                    _buildTableCell('Receipt No', isHeader: true, fontSize: 8),
                    _buildTableCell('Date', isHeader: true, fontSize: 8),
                    _buildTableCell('Amount (Rs)', isHeader: true, fontSize: 8),
                    _buildTableCell('Mode', isHeader: true, fontSize: 8),
                  ],
                ),
                ...data.feeReceipts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final receipt = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                          index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                    ),
                    children: [
                      _buildTableCell('${index + 1}', fontSize: 7),
                      _buildTableCell(receipt.receiptNumber, fontSize: 7),
                      _buildTableCell(
                        receipt.date != null
                            ? '${receipt.date!.day.toString().padLeft(2, '0')}/${receipt.date!.month.toString().padLeft(2, '0')}/${receipt.date!.year}'
                            : 'N/A',
                        fontSize: 7,
                      ),
                      _buildTableCell(
                        receipt.amount.toStringAsFixed(2),
                        fontSize: 7,
                      ),
                      _buildTableCell(_sanitizeText(receipt.mode), fontSize: 7),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Note
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Note: ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Fee details are fetched from VTOP. For official fee receipts, please visit VTOP portal.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildAcademicAndFeeSummaryPage(StudentReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ACADEMIC PERFORMANCE'),
            pw.SizedBox(height: 15),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CGPA',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            data.cgpa.toStringAsFixed(2),
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Credits',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            '${data.creditsEarned.toStringAsFixed(1)}/${data.totalCreditsRequired.toStringAsFixed(1)}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Pass Rate',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            '${data.passPercentage.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Grade Distribution:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Wrap(
                    spacing: 10,
                    children: [
                      pw.Text(
                        'S: ${data.sGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'A: ${data.aGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'B: ${data.bGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'C: ${data.cGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'D: ${data.dGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'E: ${data.eGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'F: ${data.fGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'N: ${data.nGrades}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),
            _buildSectionTitle('SEMESTER-WISE GPA'),
            pw.SizedBox(height: 10),

            if (data.gradeHistory.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue100,
                    ),
                    children: [
                      _buildTableCell('Semester', isHeader: true, fontSize: 9),
                      _buildTableCell('GPA', isHeader: true, fontSize: 9),
                      _buildTableCell('Courses', isHeader: true, fontSize: 9),
                      _buildTableCell('Credits', isHeader: true, fontSize: 9),
                    ],
                  ),
                  ...data.gradeHistory.map((sem) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(sem.semesterName, fontSize: 8),
                        _buildTableCell(
                          sem.semesterGpa.toStringAsFixed(2),
                          fontSize: 8,
                        ),
                        _buildTableCell(
                          sem.totalCourses.toString(),
                          fontSize: 8,
                        ),
                        _buildTableCell(
                          sem.totalCredits.toStringAsFixed(1),
                          fontSize: 8,
                        ),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 20),

            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  data.curriculumProgress.map((curriculum) {
                    return pw.Container(
                      width: 240,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            curriculum.distributionType,
                            style: const pw.TextStyle(fontSize: 8),
                            maxLines: 2,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${curriculum.creditsEarned.toStringAsFixed(1)}/${curriculum.creditsRequired.toStringAsFixed(1)} credits',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),

            pw.SizedBox(height: 20),
            _buildSectionTitle('FEE SUMMARY'),
            pw.SizedBox(height: 15),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Fees Paid:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs ${data.totalFeesPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            if (data.feeReceipts.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue100,
                    ),
                    children: [
                      _buildTableCell(
                        'Receipt No',
                        isHeader: true,
                        fontSize: 8,
                      ),
                      _buildTableCell('Date', isHeader: true, fontSize: 8),
                      _buildTableCell(
                        'Description',
                        isHeader: true,
                        fontSize: 8,
                      ),
                      _buildTableCell('Amount', isHeader: true, fontSize: 8),
                    ],
                  ),
                  ...data.feeReceipts.map((receipt) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(receipt.receiptNumber, fontSize: 7),
                        _buildTableCell(
                          receipt.date != null
                              ? '${receipt.date!.day}/${receipt.date!.month}/${receipt.date!.year}'
                              : 'N/A',
                          fontSize: 7,
                        ),
                        _buildTableCell(receipt.description, fontSize: 7),
                        _buildTableCell(
                          'Rs ${receipt.amount.toStringAsFixed(2)}',
                          fontSize: 7,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        );
      },
    );
  }

  pw.Page _buildSemesterDetailPage(
    StudentReportData data,
    int semesterIndex,
    int totalSemesters,
  ) {
    final gradeData = data.gradeHistory[semesterIndex];
    // Match marks data by semester name instead of index
    final marksData =
        data.marksHistory
            .where((m) => m.semesterName == gradeData.semesterName)
            .firstOrNull;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'SEMESTER ${semesterIndex + 1} / $totalSemesters: ${gradeData.semesterName}',
            ),
            pw.SizedBox(height: 15),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('GPA', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        gradeData.semesterGpa.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Courses',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '${gradeData.totalCourses}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Credits',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        gradeData.totalCredits.toStringAsFixed(0),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Passed', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        '${gradeData.passedCourses}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 15),
            pw.Text(
              'GRADE HISTORY',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(3.5),
                2: const pw.FlexColumnWidth(0.8),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('Code', isHeader: true, fontSize: 7),
                    _buildTableCell('Title', isHeader: true, fontSize: 7),
                    _buildTableCell('Grade', isHeader: true, fontSize: 7),
                    _buildTableCell('Marks', isHeader: true, fontSize: 7),
                    _buildTableCell('Credits', isHeader: true, fontSize: 7),
                    _buildTableCell('Type', isHeader: true, fontSize: 7),
                  ],
                ),
                ...gradeData.courses.map((course) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(course.courseCode, fontSize: 6),
                      _buildTableCell(course.courseTitle, fontSize: 6),
                      _buildTableCell(course.grade, fontSize: 6),
                      _buildTableCell(
                        course.totalMarks.toStringAsFixed(0),
                        fontSize: 6,
                      ),
                      _buildTableCell(
                        course.credits.toStringAsFixed(1),
                        fontSize: 6,
                      ),
                      _buildTableCell(course.courseType, fontSize: 5),
                    ],
                  );
                }),
              ],
            ),

            if (marksData != null && marksData.courses.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text(
                'MARKS HISTORY',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              ...marksData.courses.map((courseMarks) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${courseMarks.courseCode} - ${courseMarks.courseTitle}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children:
                            courseMarks.assessments.map((assessment) {
                              return pw.Text(
                                '${assessment.title}: ${assessment.score}/${assessment.maxScore}',
                                style: const pw.TextStyle(fontSize: 7),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  pw.Page _buildFooterPage(StudentReportData data, ByteData? logoData) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
              ),
              child: pw.Column(
                children: [
                  if (logoData != null)
                    pw.Container(
                      height: 100,
                      child: pw.Image(
                        pw.MemoryImage(logoData.buffer.asUint8List()),
                      ),
                    ),
                  if (logoData != null) pw.SizedBox(height: 20),
                  pw.Text(
                    'Report Generated By',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'VIT VERSE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: 400,
                    child: pw.Text(
                      'A student-driven, open-source organization dedicated to building reliable, secure, and thoughtfully designed digital tools for VIT University students.',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'https://github.com/vit-verse/',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'DISCLAIMER',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'This report is generated by VIT Verse app for informational purposes only.',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'It is NOT an official document and is NOT affiliated with VIT Chennai.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated on: ${data.generatedAt.day}/${data.generatedAt.month}/${data.generatedAt.year} at ${data.generatedAt.hour}:${data.generatedAt.minute.toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Build Semester GPA Trend Chart
  pw.Widget _buildSemesterGPAChart(StudentReportData data) {
    final maxGPA = 10.0;
    final chartHeight = 120.0;
    final chartWidth = 500.0;

    // Reverse to show chronological order in chart (oldest to newest left to right)
    final semesters = data.gradeHistory.reversed.toList();

    return pw.Container(
      height: chartHeight + 60,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Chart area
          pw.Container(
            height: chartHeight,
            width: chartWidth,
            child: pw.Stack(
              children: [
                // Grid lines
                ...List.generate(5, (i) {
                  final y = (chartHeight / 5) * i;
                  return pw.Positioned(
                    left: 0,
                    top: y,
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 30,
                          child: pw.Text(
                            (maxGPA - (maxGPA / 5 * i)).toStringAsFixed(1),
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ),
                        pw.Container(
                          width: chartWidth - 30,
                          height: 0.5,
                          color: PdfColors.grey300,
                        ),
                      ],
                    ),
                  );
                }),
                // Bar chart
                pw.Positioned(
                  left: 35,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children:
                        semesters.asMap().entries.map((entry) {
                          final semester = entry.value;
                          final barWidth =
                              (chartWidth - 40) / semesters.length - 5;
                          final barHeight =
                              (semester.semesterGpa / maxGPA) * chartHeight;

                          return pw.Container(
                            width: barWidth,
                            margin: const pw.EdgeInsets.only(right: 5),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Container(
                                  height: barHeight,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.blue400,
                                    borderRadius:
                                        const pw.BorderRadius.vertical(
                                          top: pw.Radius.circular(3),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          // Labels
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children:
                semesters.map((sem) {
                  // Shorten semester name for display
                  String shortName = sem.semesterName;
                  if (shortName.length > 15) {
                    shortName = shortName.substring(0, 12) + '...';
                  }
                  return pw.Container(
                    width: (chartWidth - 40) / semesters.length,
                    child: pw.Column(
                      children: [
                        pw.Text(
                          shortName,
                          style: const pw.TextStyle(fontSize: 6),
                          textAlign: pw.TextAlign.center,
                          maxLines: 2,
                        ),
                        pw.Text(
                          'GPA: ${sem.semesterGpa.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        ...children,
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              _sanitizeText(label),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizeText(value),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricCard(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    double fontSize = 10,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        _sanitizeText(text),
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildProgressBar(double percentage, {double maxWidth = 200}) {
    return pw.Container(
      height: 8,
      width: maxWidth,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Stack(
        children: [
          pw.Container(
            width: maxWidth * (percentage / 100).clamp(0.0, 1.0),
            decoration: pw.BoxDecoration(
              color: percentage >= 100 ? PdfColors.green : PdfColors.blue,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGradeDistributionChart(StudentReportData data) {
    final grades = [
      {'label': 'S', 'count': data.sGrades},
      {'label': 'A', 'count': data.aGrades},
      {'label': 'B', 'count': data.bGrades},
      {'label': 'C', 'count': data.cGrades},
      {'label': 'D', 'count': data.dGrades},
      {'label': 'E', 'count': data.eGrades},
      {'label': 'F', 'count': data.fGrades},
      {'label': 'N', 'count': data.nGrades},
    ];

    final maxCount = grades
        .map((g) => g['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children:
            grades.map((grade) {
              final count = grade['count'] as int;
              final height = maxCount > 0 ? (count / maxCount) * 100 : 0.0;
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    count.toString(),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: 30,
                    height: height,
                    color: PdfColors.blue600,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    grade['label'] as String,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  pw.Widget _buildGradeBreakdownTable(StudentReportData data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('Grade', isHeader: true),
            _buildTableCell('Count', isHeader: true),
            _buildTableCell('Percentage', isHeader: true),
          ],
        ),
        _buildGradeRow('S', data.sGrades, data.totalCourses),
        _buildGradeRow('A', data.aGrades, data.totalCourses),
        _buildGradeRow('B', data.bGrades, data.totalCourses),
        _buildGradeRow('C', data.cGrades, data.totalCourses),
        _buildGradeRow('D', data.dGrades, data.totalCourses),
        _buildGradeRow('E', data.eGrades, data.totalCourses),
        _buildGradeRow('F', data.fGrades, data.totalCourses),
        _buildGradeRow('N', data.nGrades, data.totalCourses),
      ],
    );
  }

  pw.TableRow _buildGradeRow(String grade, int count, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    return pw.TableRow(
      children: [
        _buildTableCell(grade),
        _buildTableCell(count.toString()),
        _buildTableCell('${percentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  pw.Widget _buildGPATrendChart(List<SemesterPerformanceData> semesters) {
    if (semesters.isEmpty) return pw.SizedBox();

    return pw.Container(
      height: 100,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children:
            semesters.map((sem) {
              final height = (sem.gpa / 10.0) * 70;
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    sem.gpa.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 20,
                    height: height,
                    color: PdfColors.blue600,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    sem.semesterName.length > 10
                        ? '${sem.semesterName.substring(0, 7)}...'
                        : sem.semesterName,
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Future<File> _savePDF(pw.Document pdf, String regNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/VIT_Report_${regNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
