import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'data_service_constants.dart';
import '../database/database.dart';
import '../database/daos/course_dao.dart';
import '../database/daos/slot_dao.dart';
import '../database/daos/attendance_dao.dart';
import '../database/daos/attendance_detail_dao.dart';
import '../database/daos/mark_dao.dart';
import '../database/daos/all_semester_mark_dao.dart';
import '../database_vitverse/database.dart';
import '../database/entities/course.dart';
import '../database/entities/attendance.dart';
import '../database/entities/attendance_detail.dart';
import '../database/entities/mark.dart';
import '../database/entities/all_semester_mark.dart';
import '../database/entities/slot.dart';
import '../database/entities/timetable.dart';
import '../database/entities/exam.dart';
import '../database/entities/cumulative_mark.dart';
import '../database/entities/staff.dart';
import '../database/entities/spotlight.dart';
import '../database/entities/receipt.dart';
import '../database/entities/student_profile.dart';
import '../database/entities/cgpa_summary.dart';
import '../database/entities/curriculum_progress.dart';
import '../database/entities/basket_progress.dart';
import '../utils/logger.dart';
import '../../firebase/analytics/analytics_service.dart';
import '../../firebase/crashlytics/crashlytics_service.dart';
import '../../firebase/analytics/analytics_events.dart';

/// VTOP 14-step data extraction service
class VTOPDataService {
  final WebViewController _webViewController;
  final CourseDao _courseDao = CourseDao();
  final AttendanceDao _attendanceDao = AttendanceDao();
  final AttendanceDetailDao _attendanceDetailDao = AttendanceDetailDao();
  final MarkDao _markDao = MarkDao();
  final AllSemesterMarkDao _allSemesterMarkDao = AllSemesterMarkDao();

  int _currentStep = 0;
  final int _totalSteps = 14;
  String _currentStepName = '';

  final Map<String, Slot> _theorySlots = {};
  final Map<String, Slot> _labSlots = {};
  final Map<String, Slot> _projectSlots = {};
  final Map<int, Course> _theoryCourses = {};
  final Map<int, Course> _labCourses = {};
  final Map<int, Course> _projectCourses = {};

  // Progress callbacks
  Function(int current, int total, String stepName)? onProgress;
  Function(String message)? onStatusUpdate;
  Function(String error)? onError;
  Function()? onComplete;

  VTOPDataService(this._webViewController);

  // ═══════════════════════════════════════════════════════
  // CORE EXECUTION
  // ═══════════════════════════════════════════════════════

  /// Phase 1: Essential data (Profile, Courses, Timetable, Attendance)
  Future<void> executePhase1(String semesterId) async {
    final phase1StartTime = DateTime.now();

    // Track Phase 1 start
    await AnalyticsService.instance.logDataSync(
      DataSyncEvent.syncStarted,
      parameters: {'phase': 1, 'total_steps': 5},
    );

    try {
      Logger.i(
        DataServiceConstants.logTag,
        DataServiceConstants.phase1StartMessage,
      );

      await _initDatabase();
      await _clearExistingData();

      // Parallel: Profile + Courses
      await Future.wait([
        _executeStep(
          () => _step1_getProfileInfo(),
          1,
          DataServiceConstants.step1Name,
        ),
        _executeStep(
          () => _step3_getCourseInfo(semesterId),
          3,
          DataServiceConstants.step3Name,
        ),
      ]);
      await Future.delayed(
        Duration(milliseconds: DataServiceConstants.stepDelayMs),
      );

      // Parallel: Timetable + Attendance
      await Future.wait([
        _executeStep(
          () => _step4_getTimetableData(semesterId),
          4,
          DataServiceConstants.step4Name,
        ),
        _executeStep(
          () => _step5_getAttendanceData(semesterId),
          5,
          DataServiceConstants.step5Name,
        ),
      ]);
      await Future.delayed(
        Duration(milliseconds: DataServiceConstants.stepDelayMs),
      );

      // Sequential: Detailed Attendance
      await _executeStep(
        () => _step13_getAttendanceDetails(semesterId),
        13,
        DataServiceConstants.step13Name,
      );

      Logger.success(
        DataServiceConstants.logTag,
        DataServiceConstants.phase1CompleteMessage,
      );
      onStatusUpdate?.call(DataServiceConstants.phase1CompleteMessage);

      // Track Phase 1 complete
      final phase1Duration = DateTime.now().difference(phase1StartTime);
      await AnalyticsService.instance.logDataSync(
        DataSyncEvent.phase1Completed,
        parameters: {
          'duration_ms': phase1Duration.inMilliseconds,
          'steps_completed': 5,
        },
      );
    } catch (e) {
      Logger.e(DataServiceConstants.logTag, 'Phase 1 failed', e);
      onError?.call(DataServiceConstants.phase1ErrorMessage);

      // Track Phase 1 failure
      await CrashlyticsService.recordError(
        Exception(
          'Phase 1 sync failed: ${e.toString()} (Semester: $semesterId)',
        ),
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Phase 2: Secondary data (Marks, Exams, Staff, etc.)
  Future<void> executePhase2(String semesterId) async {
    final phase2StartTime = DateTime.now();

    // Track Phase 2 start
    await AnalyticsService.instance.logDataSync(
      DataSyncEvent.syncStarted,
      parameters: {'phase': 2, 'total_steps': 9},
    );

    try {
      Logger.i(
        DataServiceConstants.logTag,
        DataServiceConstants.phase2StartMessage,
      );

      final steps = [
        () => _step6_getMarksData(semesterId),
        () => _step2_getGradeHistory(),
        () => _step7_getExamSchedule(semesterId),
        () => _step14_getAllSemesterMarks(),
        () => _step11_previousSemesterGradesAndGPA(semesterId),
        () => _step8_getStaffInfo(semesterId),
        () => _step9_getSpotlightData(),
        () => _step10_getReceiptData(),
        () => _step12_checkDues(),
      ];

      final stepNumbers = [6, 2, 7, 14, 11, 8, 9, 10, 12];
      final stepNames = [
        DataServiceConstants.step6Name,
        DataServiceConstants.step2Name,
        DataServiceConstants.step7Name,
        DataServiceConstants.step14Name,
        DataServiceConstants.step11Name,
        DataServiceConstants.step8Name,
        DataServiceConstants.step9Name,
        DataServiceConstants.step10Name,
        DataServiceConstants.step12Name,
      ];

      int completedSteps = 0;
      List<String> failedSteps = [];

      for (int i = 0; i < steps.length; i++) {
        try {
          await _executeStep(steps[i], stepNumbers[i], stepNames[i]);
          completedSteps++;
        } catch (e) {
          Logger.e('VTOPData', 'Step ${stepNames[i]} failed: $e', e);
          failedSteps.add(stepNames[i]);
          if (stepNames[i].contains('marks')) {
            onError?.call(
              'Failed to sync marks data. Some information may be incomplete.',
            );
          }
        }
        await Future.delayed(
          Duration(milliseconds: DataServiceConstants.stepDelayMs),
        );
      }

      Logger.success(
        DataServiceConstants.logTag,
        'Phase 2 complete: $completedSteps/${steps.length} steps successful${failedSteps.isNotEmpty ? " (Failed: ${failedSteps.join(", ")})" : ""}',
      );
      onStatusUpdate?.call(DataServiceConstants.phase2CompleteMessage);
      onComplete?.call();

      // Track Phase 2 complete
      final phase2Duration = DateTime.now().difference(phase2StartTime);
      await AnalyticsService.instance.logDataSync(
        DataSyncEvent.phase2Completed,
        parameters: {
          'duration_ms': phase2Duration.inMilliseconds,
          'steps_completed': completedSteps,
          'steps_total': steps.length,
        },
      );
    } catch (e) {
      Logger.w(
        DataServiceConstants.logTag,
        'Phase 2 completed with errors: $e',
      );
      onStatusUpdate?.call(DataServiceConstants.phase2ErrorMessage);

      // Track Phase 2 failure
      await CrashlyticsService.recordError(
        Exception(
          'Phase 2 sync failed: ${e.toString()} (Semester: $semesterId)',
        ),
        StackTrace.current,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // EXTRACTION STEPS (1-14)
  // ═══════════════════════════════════════════════════════

  Future<void> _step1_getProfileInfo() async {
    _updateProgress(1, 'Extracting profile');

    final jsCode = '''
      (function() {
        try {
          var data = 'verifyMenu=true&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now();
          var profile = {};
          
          \$.ajax({
            type: 'POST',
            url: 'studentsRecord/StudentProfileAllView',
            data: data,
            async: false,
            success: function(res) {
              if(res.toLowerCase().includes('personal information')) {
                var doc = new DOMParser().parseFromString(res, 'text/html');
                
                var nameElement = doc.querySelector('p[style*="font-weight: bold"]');
                profile.name = nameElement ? nameElement.innerText.trim() : '';
                
                var labels = doc.querySelectorAll('label[class*="col-form-label"]');
                for(var i = 0; i < labels.length; i++) {
                  var labelText = labels[i].innerText.toUpperCase();
                  var nextLabel = labels[i].nextElementSibling;
                  
                  if(labelText.includes('REGISTER NUMBER') && nextLabel) {
                    profile.registerNumber = nextLabel.innerText.trim();
                  } else if(labelText.includes('VIT EMAIL') && nextLabel) {
                    profile.vitEmail = nextLabel.innerText.trim();
                  } else if(labelText.includes('PROGRAM') && labelText.includes('BRANCH') && nextLabel) {
                    var fullText = nextLabel.innerText.trim();
                    profile.program = fullText;
                    var parts = fullText.split(' - ');
                    profile.branch = parts.length > 1 ? parts.slice(1).join(' - ') : fullText;
                  } else if(labelText.includes('SCHOOL NAME') && nextLabel) {
                    profile.schoolName = nextLabel.innerText.trim();
                  }
                }
                
                var rows = doc.querySelectorAll('tr');
                for(var i = 0; i < rows.length; i++) {
                  var cells = rows[i].querySelectorAll('td');
                  if(cells.length >= 2) {
                    var label = cells[0].innerText.trim().toUpperCase();
                    var value = cells[1].innerText.trim();
                    
                    if(label.includes('BLOCK NAME')) profile.hostelBlock = value;
                    else if(label.includes('ROOM NO')) profile.roomNumber = value;
                    else if(label.includes('BED TYPE')) profile.bedType = value;
                    else if(label.includes('MESS')) profile.messName = value;
                    else if(label.includes('DATE OF BIRTH') || label.includes('DOB')) profile.dateOfBirth = value;
                  }
                }
              }
            }
          });
          
          return JSON.stringify(profile);
        } catch (e) {
          return JSON.stringify({ error: e.message });
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      if (data.containsKey('name') && data['name'].toString().isNotEmpty) {
        await _saveProfileData(data);
        Logger.success('VTOP', 'Profile: ${data['name']}');
      }
    }
  }

  Future<void> _step2_getGradeHistory() async {
    _updateProgress(2, 'Extracting grade history');

    final jsCode = '''
      (function() {
        try {
          var data = 'verifyMenu=true&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now();
          var response = { studentDetails: {}, cgpaSummary: {}, curriculumProgress: [], basketProgress: [], totalCreditsRequired: 0.0 };
          
          \$.ajax({
            type: 'POST',
            url: 'examinations/examGradeView/StudentGradeHistory',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var tables = doc.querySelectorAll('table.customTable');
              
              // Student Details
              if (tables.length > 0) {
                var studentRows = tables[0].querySelectorAll('tr.tableContent');
                if (studentRows.length > 0) {
                  var cells = studentRows[0].querySelectorAll('td');
                  if (cells.length >= 10) {
                    response.studentDetails = {
                      registerNumber: cells[0].textContent.trim(),
                      name: cells[1].textContent.trim(),
                      programmeAndBranch: cells[2].textContent.trim(),
                      programmeMode: cells[3].textContent.trim(),
                      studySystem: cells[4].textContent.trim(),
                      gender: cells[5].textContent.trim(),
                      yearJoined: cells[6].textContent.trim(),
                      eduStatus: cells[7].textContent.trim(),
                      school: cells[8].textContent.trim(),
                      campus: cells[9].textContent.trim()
                    };
                  }
                }
              }
              
              // Curriculum Progress
              var allTableHeaders = doc.querySelectorAll('tr.tableHeader');
              for (var i = 0; i < allTableHeaders.length; i++) {
                if (allTableHeaders[i].textContent.includes('Curriculum Details')) {
                  var curriculumTable = allTableHeaders[i].closest('table');
                  if (curriculumTable) {
                    var curriculumRows = curriculumTable.querySelectorAll('tr.tableContent');
                    curriculumRows.forEach(function(row) {
                      var cells = row.querySelectorAll('td');
                      if (cells.length === 3) {
                        var distType = cells[0].textContent.trim();
                        var credReq = cells[1].textContent.trim();
                        var credEarn = cells[2].textContent.trim();
                        
                        if (distType && distType.includes('Total Credits')) {
                          response.totalCreditsRequired = parseFloat(credReq) || 0.0;
                        } else if (distType && credReq && credEarn) {
                          response.curriculumProgress.push({
                            distributionType: distType,
                            creditsRequired: parseFloat(credReq) || 0.0,
                            creditsEarned: parseFloat(credEarn) || 0.0
                          });
                        }
                      }
                    });
                  }
                  break;
                }
              }
              
              // Basket Progress
              for (var i = 0; i < allTableHeaders.length; i++) {
                if (allTableHeaders[i].textContent.includes('Basket Details')) {
                  var basketTable = allTableHeaders[i].closest('table');
                  if (basketTable) {
                    var basketRows = basketTable.querySelectorAll('tr.tableContent');
                    basketRows.forEach(function(row) {
                      var cells = row.querySelectorAll('td');
                      if (cells.length === 4) {
                        var basketTitle = cells[0].textContent.trim();
                        var distType = cells[1].textContent.trim();
                        var credReq = cells[2].textContent.trim();
                        var credEarn = cells[3].textContent.trim();
                        
                        if (basketTitle && distType && credReq && credEarn) {
                          response.basketProgress.push({
                            basketTitle: basketTitle,
                            distributionType: distType,
                            creditsRequired: parseFloat(credReq) || 0.0,
                            creditsEarned: parseFloat(credEarn) || 0.0
                          });
                        }
                      }
                    });
                  }
                  break;
                }
              }
              
              // CGPA Summary
              var cgpaTable = doc.querySelector('table.table-hover');
              if (cgpaTable) {
                var cgpaRow = cgpaTable.querySelector('tbody tr');
                if (cgpaRow) {
                  var cells = cgpaRow.querySelectorAll('td');
                  if (cells.length >= 11) {
                    response.cgpaSummary = {
                      creditsRegistered: parseFloat(cells[0].textContent.trim()) || 0.0,
                      creditsEarned: parseFloat(cells[1].textContent.trim()) || 0.0,
                      cgpa: parseFloat(cells[2].textContent.trim()) || 0.0,
                      sGrades: parseInt(cells[3].textContent.trim()) || 0,
                      aGrades: parseInt(cells[4].textContent.trim()) || 0,
                      bGrades: parseInt(cells[5].textContent.trim()) || 0,
                      cGrades: parseInt(cells[6].textContent.trim()) || 0,
                      dGrades: parseInt(cells[7].textContent.trim()) || 0,
                      eGrades: parseInt(cells[8].textContent.trim()) || 0,
                      fGrades: parseInt(cells[9].textContent.trim()) || 0,
                      nGrades: parseInt(cells[10].textContent.trim()) || 0
                    };
                  }
                }
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      await _saveGradeHistoryData(data);
      Logger.success('VTOP', 'Grade history extracted');
    }
  }

  Future<void> _step3_getCourseInfo(String semesterId) async {
    _updateProgress(3, 'Extracting courses');

    final jsCode = '''
      (function() {
        try {
          var data = '_csrf=' + \$('input[name="_csrf"]').val() + '&semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val();
          var response = { courses: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'processViewTimeTable',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              if (!doc.getElementById('studentDetailsList')) return;
              
              var table = doc.getElementById('studentDetailsList').getElementsByTagName('table')[0];
              var headings = table.getElementsByTagName('th');
              var courseIndex, creditsIndex, slotVenueIndex, facultyIndex, classIdIndex, categoryIndex, courseOptionIndex;
              
              for(var i = 0; i < headings.length; i++) {
                var heading = headings[i].innerText.toLowerCase();
                if (heading == 'course') courseIndex = i;
                else if (heading == 'l t p j c') creditsIndex = i;
                else if (heading.includes('class') && heading.includes('id')) classIdIndex = i;
                else if (heading.includes('slot')) slotVenueIndex = i;
                else if (heading.includes('faculty')) facultyIndex = i;
                else if (heading == 'category') categoryIndex = i;
                else if (heading.includes('course') && heading.includes('option')) courseOptionIndex = i;
              }
              
              var cells = table.getElementsByTagName('td');
              var offset = (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0) + 
                          (cells[0].innerText.toLowerCase().includes('invoice') ? 1 : 0);
              
              while (courseIndex < cells.length) {
                var course = {};
                var rawCourse = cells[courseIndex + offset].innerText.replace(/\\t/g,'').replace(/\\n/g,' ');
                var rawCourseType = rawCourse.split('(').slice(-1)[0].toLowerCase();
                var rawCredits = cells[creditsIndex + offset].innerText.replace(/\\t/g,'').replace(/\\n/g,' ').trim().split(' ');
                var rawSlotVenue = cells[slotVenueIndex + offset].innerText.replace(/\\t/g,'').replace(/\\n/g,'').split('-');
                var rawFaculty = cells[facultyIndex + offset].innerText.replace(/\\t/g,'').replace(/\\n/g,'').split('-');
                
                course.code = rawCourse.split('-')[0].trim();
                course.title = rawCourse.split('-').slice(1).join('-').split('(')[0].trim();
                course.type = rawCourseType.includes('lab') ? 'lab' : (rawCourseType.includes('project') ? 'project' : 'theory');
                course.credits = parseFloat(rawCredits[rawCredits.length - 1]) || 0;
                course.classId = cells[classIdIndex + offset].innerText.replace(/\\t/g,'').replace(/\\n/g,' ').trim();
                course.slots = rawSlotVenue[0].trim().split('+');
                course.venue = rawSlotVenue.slice(1).join(' - ').trim();
                course.faculty = rawFaculty[0].trim();
                course.category = categoryIndex !== undefined ? cells[categoryIndex + offset].innerText.trim() : null;
                course.courseOption = courseOptionIndex !== undefined ? cells[courseOptionIndex + offset].innerText.trim() : null;
                
                response.courses.push(course);
                
                courseIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                creditsIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                classIdIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                slotVenueIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                facultyIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                if (categoryIndex !== undefined) categoryIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
                if (courseOptionIndex !== undefined) courseOptionIndex += headings.length + (headings[0].innerText.toLowerCase().includes('invoice') ? -1 : 0);
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      // Sanitize JSON: Remove control characters (newlines, tabs) inside string values
      final sanitized = result.replaceAllMapped(RegExp(r'"([^"]*)"'), (match) {
        final value = match.group(1)!;
        // Replace newlines, tabs, carriage returns with spaces
        final cleaned = value
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll('\t', ' ');
        return '"$cleaned"';
      });

      final data = jsonDecode(sanitized);
      if (data.containsKey('courses')) {
        await _saveCourseData(data['courses'] as List);
        Logger.success('VTOP', '${(data['courses'] as List).length} courses');
      }
    }
  }

  Future<void> _step4_getTimetableData(String semesterId) async {
    _updateProgress(4, 'Extracting timetable');

    final jsCode = '''
      (function() {
        var data = '_csrf=' + \$('input[name="_csrf"]').val() + '&semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val();
        var response = { lab: [], theory: [] };
        
        \$.ajax({
          type: 'POST',
          url: 'processViewTimeTable',
          data: data,
          async: false,
          success: function(res) {
            var doc = new DOMParser().parseFromString(res, 'text/html');
            var spans = doc.getElementById('getStudentDetails') ? doc.getElementById('getStudentDetails').getElementsByTagName('span') : [];
            if (spans.length > 0 && spans[0].innerText.toLowerCase().includes('no record(s) found')) return;
            
            var cells = doc.getElementById('timeTableStyle') ? doc.getElementById('timeTableStyle').getElementsByTagName('td') : [];
            var key, type;
            
            for (var i = 0, j = 0; i < cells.length; i++) {
              var content = cells[i].innerText.toUpperCase();
              
              if (content.includes('THEORY')) { type = 'theory'; j = 0; continue; }
              else if (content.includes('LAB')) { type = 'lab'; j = 0; continue; }
              else if (content.includes('START')) { key = 'start'; continue; }
              else if (content.includes('END')) { key = 'end'; continue; }
              else if (content.includes('SUN')) { key = 'sunday'; continue; }
              else if (content.includes('MON')) { key = 'monday'; continue; }
              else if (content.includes('TUE')) { key = 'tuesday'; continue; }
              else if (content.includes('WED')) { key = 'wednesday'; continue; }
              else if (content.includes('THU')) { key = 'thursday'; continue; }
              else if (content.includes('FRI')) { key = 'friday'; continue; }
              else if (content.includes('SAT')) { key = 'saturday'; continue; }
              else if (content.includes('LUNCH')) continue;
              
              if (key == 'start') {
                response[type].push({ start_time: content.trim() });
              } else if (key == 'end') {
                response[type][j++].end_time = content.trim();
              } else if (cells[i].bgColor == '#CCFF33' || cells[i].bgColor == '#FC6C85') {
                // VTOP doing random shitt -> change color among pink & green randomly
                response[type][j++][key] = content.split('-')[0].trim();
              } else {
                response[type][j++][key] = null;
              }
            }
          }
        });
        return JSON.stringify(response);
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final response = jsonDecode(result);
      final labArray = response['lab'] as List;
      final theoryArray = response['theory'] as List;

      await _saveTimetableData(labArray, theoryArray);
      Logger.success('VTOP', 'Timetable extracted');
    }
  }

  Future<void> _step5_getAttendanceData(String semesterId) async {
    _updateProgress(5, 'Extracting attendance');

    final jsCode = '''
      (function() {
        try {
          var data = '_csrf=' + \$('input[name="_csrf"]').val() + '&semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val();
          var response = { attendance: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'processViewStudentAttendance',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var table = doc.getElementById('getStudentDetails');
              if (!table) return;
              
              var headings = table.getElementsByTagName('th');
              var courseTypeIndex, slotIndex, facultyIndex, attendedIndex, totalIndex, percentageIndex;
              
              for(var i = 0; i < headings.length; i++) {
                var heading = headings[i].innerText.toLowerCase();
                if (heading.includes('course') && heading.includes('type')) courseTypeIndex = i;
                else if (heading.includes('slot')) slotIndex = i;
                else if (heading.includes('faculty')) facultyIndex = i;
                else if (heading.includes('attended')) attendedIndex = i;
                else if (heading.includes('total')) totalIndex = i;
                else if (heading.includes('percentage')) percentageIndex = i;
              }
              
              var cells = table.getElementsByTagName('td');
              while (courseTypeIndex < cells.length) {
                var attendanceObject = {};
                attendanceObject.course_type = cells[courseTypeIndex].innerText.trim();
                attendanceObject.slot = cells[slotIndex].innerText.trim().split('+')[0].trim();
                attendanceObject.attended = parseInt(cells[attendedIndex].innerText.trim()) || 0;
                attendanceObject.total = parseInt(cells[totalIndex].innerText.trim()) || 0;
                attendanceObject.percentage = parseInt(cells[percentageIndex].innerText.trim()) || 0;
                
                if (facultyIndex !== undefined) {
                  var facultyCell = cells[facultyIndex];
                  var facultyParagraphs = facultyCell.getElementsByTagName('p');
                  if (facultyParagraphs.length > 0) {
                    var erpId = facultyParagraphs[0].innerText.trim();
                    if (erpId && !isNaN(erpId)) {
                      attendanceObject.faculty_erp_id = erpId;
                    }
                  }
                }
                
                response.attendance.push(attendanceObject);
                
                courseTypeIndex += headings.length;
                slotIndex += headings.length;
                if (facultyIndex !== undefined) facultyIndex += headings.length;
                attendedIndex += headings.length;
                totalIndex += headings.length;
                percentageIndex += headings.length;
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      if (data.containsKey('attendance')) {
        await _saveAttendanceData(data['attendance'] as List);
        Logger.success(
          'VTOP',
          '${(data['attendance'] as List).length} attendance records',
        );
      }
    }
  }

  Future<void> _step6_getMarksData(String semesterId) async {
    _updateProgress(6, 'Extracting marks');

    final jsCode = '''
      (function() {
        try {
          var data = 'semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val();
          var response = { marks: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'examinations/doStudentMarkView',
            data: data,
            async: false,
            success: function(res) {
              if(res.toLowerCase().includes('no data found')) return;
              
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var table = doc.getElementById('fixedTableContainer');
              if (!table) return;
              
              var rows = table.getElementsByTagName('tr');
              var headings = rows[0].getElementsByTagName('td');
              var courseTypeIndex, slotIndex;
              
              for (var i = 0; i < headings.length; i++) {
                var heading = headings[i].innerText.toLowerCase();
                if (heading.includes('course') && heading.includes('type')) courseTypeIndex = i;
                else if (heading.includes('slot')) slotIndex = i;
              }
              
              for (var i = 1; i < rows.length; i++) {
                var rawCourseType = rows[i].getElementsByTagName('td')[courseTypeIndex].innerText.trim().toLowerCase();
                var courseType = rawCourseType.includes('lab') ? 'lab' : (rawCourseType.includes('project') ? 'project' : 'theory');
                var slot = rows[i++].getElementsByTagName('td')[slotIndex].innerText.split('+')[0].trim();
                
                var innerTable = rows[i].getElementsByTagName('table')[0];
                var innerRows = innerTable.getElementsByTagName('tr');
                var innerHeadings = innerRows[0].getElementsByTagName('td');
                var titleIndex, scoreIndex, maxScoreIndex, weightageIndex, maxWeightageIndex, averageIndex, statusIndex;
                
                for (var j = 0; j < innerHeadings.length; j++) {
                  var innerHeading = innerHeadings[j].innerText.toLowerCase();
                  if (innerHeading.includes('title')) titleIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('max')) maxScoreIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('%')) maxWeightageIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('status')) statusIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('scored')) scoreIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('weightage') && innerHeading.includes('mark')) weightageIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('average')) averageIndex = j + innerHeadings.length;
                }
                
                var innerCells = innerTable.getElementsByTagName('td');
                while(titleIndex < innerCells.length) {
                  var mark = {};
                  mark.slot = slot;
                  mark.course_type = courseType;
                  mark.title = innerCells[titleIndex].innerText.trim();
                  mark.score = parseFloat(innerCells[scoreIndex].innerText) || 0;
                  mark.max_score = parseFloat(innerCells[maxScoreIndex].innerText) || null;
                  mark.weightage = parseFloat(innerCells[weightageIndex].innerText) || 0;
                  mark.max_weightage = parseFloat(innerCells[maxWeightageIndex].innerText) || null;
                  mark.average = parseFloat(innerCells[averageIndex].innerText) || null;
                  mark.status = innerCells[statusIndex].innerText.trim();
                  response.marks.push(mark);
                  
                  titleIndex += innerHeadings.length;
                  scoreIndex += innerHeadings.length;
                  maxScoreIndex += innerHeadings.length;
                  weightageIndex += innerHeadings.length;
                  maxWeightageIndex += innerHeadings.length;
                  averageIndex += innerHeadings.length;
                  statusIndex += innerHeadings.length;
                }
                i += innerRows.length;
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      if (data.containsKey('marks')) {
        await _saveMarksData(data['marks'] as List);
        Logger.success('VTOP', '${(data['marks'] as List).length} marks');
      }
    }
  }

  Future<void> _step7_getExamSchedule(String semesterId) async {
    _updateProgress(7, 'Extracting exam schedule');

    final jsCode = '''
      (function() {
        try {
          var data = 'semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val();
          var response = {};
          
          \$.ajax({
            type: 'POST',
            url: 'examinations/doSearchExamScheduleForStudent',
            data: data,
            async: false,
            success: function(res) {
              if(res.toLowerCase().includes('not found')) return;
              
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var slotIndex, dateIndex, timingIndex, venueIndex, locationIndex, numberIndex;
              var columns = doc.getElementsByTagName('tr')[0].getElementsByTagName('td');
              
              for (var i = 0; i < columns.length; i++) {
                var heading = columns[i].innerText.toLowerCase();
                if (heading.includes('slot')) slotIndex = i;
                else if (heading.includes('date')) dateIndex = i;
                else if (heading.includes('exam') && heading.includes('time')) timingIndex = i;
                else if (heading.includes('venue')) venueIndex = i;
                else if (heading.includes('location')) locationIndex = i;
                else if (heading.includes('seat') && heading.includes('no.')) numberIndex = i;
              }
              
              var examTitle = '', exam = {}, cells = doc.getElementsByTagName('td');
              for (var i = columns.length; i < cells.length; i++) {
                if (cells[i].colSpan > 1) {
                  examTitle = cells[i].innerText.trim();
                  response[examTitle] = [];
                  continue;
                }
                
                var index = (i - Object.keys(response).length) % columns.length;
                if (index == slotIndex) exam.slot = cells[i].innerText.trim().split('+')[0];
                else if (index == dateIndex) {
                  var date = cells[i].innerText.trim().toUpperCase();
                  exam.date = date == '' ? null : date;
                }
                else if (index == timingIndex) {
                  var timings = cells[i].innerText.trim().split('-');
                  if (timings.length == 2) {
                    exam.start_time = timings[0].trim();
                    exam.end_time = timings[1].trim();
                  } else {
                    exam.start_time = null;
                    exam.end_time = null;
                  }
                }
                else if (index == venueIndex) {
                  var venue = cells[i].innerText.trim();
                  exam.venue = venue.replace(/-/g,'') == '' ? null : venue;
                }
                else if (index == locationIndex) {
                  var location = cells[i].innerText.trim();
                  exam.seat_location = location.replace(/-/g,'') == '' ? null : location;
                }
                else if (index == numberIndex) {
                  var number = cells[i].innerText.trim();
                  exam.seat_number = number.replace(/-/g,'') == '' ? null : parseInt(number);
                }
                
                if (Object.keys(exam).length == 7) {
                  response[examTitle].push(exam);
                  exam = {};
                }
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      await _saveExamScheduleData(data);
      Logger.success('VTOP', 'Exam schedule extracted');
    }
  }

  Future<void> _step8_getStaffInfo(String semesterId) async {
    _updateProgress(8, 'Extracting staff info');

    final proctorJs = '''
      (function() {
        try {
          var data = 'verifyMenu=true&winImage=' + \$('#winImage').val() + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now();
          var response = { proctor: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'proctor/viewProctorDetails',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var cells = doc.getElementById('showDetails').getElementsByTagName('td');
              for(var i = 0; i < cells.length; i++) {
                if(cells[i].innerHTML.includes('img')) continue;
                var record = {};
                record.key = cells[i].innerText.trim() || null;
                record.value = cells[++i].innerText.trim() || null;
                response.proctor.push(record);
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final deanHodJs = '''
      (function() {
        try {
          var data = 'verifyMenu=true&winImage=' + \$('#winImage').val() + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now();
          var response = {};
          
          \$.ajax({
            type: 'POST',
            url: 'hrms/viewHodDeanDetails',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var tables = doc.getElementsByTagName('table');
              var headings = doc.getElementsByTagName('h3');
              
              for (var i = 0; i < tables.length; i++) {
                var heading = headings[i].innerText.toLowerCase().trim();
                var cells = tables[i].getElementsByTagName('td');
                response[heading] = [];
                
                for (var j = 0; j < cells.length; j++) {
                  if(cells[j].innerHTML.includes('img')) continue;
                  var record = {};
                  record.key = cells[j].innerText.trim() || null;
                  record.value = cells[++j].innerText.trim() || null;
                  response[heading].push(record);
                }
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final proctorResult = await _executeJavaScript(proctorJs);
    final deanHodResult = await _executeJavaScript(deanHodJs);
    await _saveStaffData(proctorResult, deanHodResult);
    Logger.success('VTOP', 'Staff info extracted');
  }

  // TODO: fix this as vtop removed old spotlight

  Future<void> _step9_getSpotlightData() async {
    _updateProgress(9, 'Extracting announcements');

    final jsCode = '''
      (function() {
        try {
          var data = '_csrf=' + \$('input[name="_csrf"]').val() + '&authorizedID=' + \$('#authorizedIDX').val() + '&x=';
          var response = { spotlight: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'home',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              if (!doc.getElementsByClassName('box-info').length) {
                return;
              }
              
              var sheets = doc.getElementsByClassName('offcanvas');
              for (var i = 0; i < sheets.length; ++i) {
                const header = sheets[i].getElementsByClassName('offcanvas-header')[0];
                const title = header.getElementsByTagName('span')[0];
                if (title === undefined) {
                  continue;
                }
                
                const category = title.textContent;
                var announcements = sheets[i].getElementsByClassName('offcanvas-body')[0].getElementsByTagName('li');
                
                for (var j = 0; j < announcements.length; ++j) {
                  var spotlightItem = {};
                  spotlightItem.category = category;
                  // Remove tabs, newlines, and carriage returns, then trim
                  spotlightItem.announcement = announcements[j].textContent.replace(/\\t/g, '').replace(/\\n/g, ' ').replace(/\\r/g, ' ').trim();
                  
                  if (announcements[j].getElementsByTagName('a').length == 0) {
                    spotlightItem.link = null;
                  } else {
                    var link = announcements[j].getElementsByTagName('a')[0];
                    if (link.getAttribute('onclick')) {
                      spotlightItem.link = link.getAttribute('onclick').split("'")[1];
                    } else {
                      spotlightItem.link = link.href;
                    }
                  }
                  
                  response.spotlight.push(spotlightItem);
                }
              }
            }
          });
          
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      try {
        final sanitized = result.replaceAllMapped(RegExp(r'"([^"]*)"'), (
          match,
        ) {
          final value = match.group(1)!;
          final cleaned =
              value
                  .replaceAll('\n', ' ')
                  .replaceAll('\r', ' ')
                  .replaceAll('\t', ' ')
                  .trim();
          return '"$cleaned"';
        });

        final data = jsonDecode(sanitized);

        if (data.containsKey('spotlight') && data['spotlight'] is List) {
          final spotlightData = List<Map<String, dynamic>>.from(
            data['spotlight'],
          );

          if (spotlightData.isEmpty) {
            spotlightData.add({
              'category': 'System',
              'announcement': 'Welcome to VIT Connect!',
              'link': null,
            });
          }

          await _saveSpotlightData(spotlightData);
          Logger.success('VTOP', '${spotlightData.length} announcements');
        }
      } catch (e) {
        Logger.e('VTOP_DATA', 'Failed to parse spotlight data: $e');
        // Save fallback data
        await _saveSpotlightData([
          {
            'category': 'System',
            'announcement': 'Welcome to VIT Connect!',
            'link': null,
          },
        ]);
      }
    }
  }

  Future<void> _step10_getReceiptData() async {
    _updateProgress(10, 'Extracting receipts');

    final jsCode = '''
      (function() {
        try {
          var data = 'verifyMenu=true&winImage=' + \$('#winImage').val() + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now();
          var response = { receipts: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'p2p/getReceiptsApplno',
            data: data,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var headings = doc.getElementsByTagName('tr')[0].getElementsByTagName('td');
              var cells = doc.getElementsByTagName('td');
              var receiptIndex, amountIndex, dateIndex;
              
              for(var i = 0; i < headings.length; i++) {
                var heading = headings[i].innerText.toLowerCase();
                if(heading.includes('receipt')) receiptIndex = i + headings.length;
                else if (heading.includes('date')) dateIndex = i + headings.length;
                else if (heading.includes('amount')) amountIndex = i + headings.length;
              }
              
              while (receiptIndex < cells.length) {
                var receipt = {};
                receipt.number = parseInt(cells[receiptIndex].innerText.trim()) || null;
                receipt.amount = parseFloat(cells[amountIndex].innerText.trim()) || 0;
                receipt.date = cells[dateIndex].innerText.trim();
                response.receipts.push(receipt);
                
                receiptIndex += headings.length;
                amountIndex += headings.length;
                dateIndex += headings.length;
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final data = jsonDecode(result);
      if (data.containsKey('receipts')) {
        await _saveReceiptData(data['receipts'] as List);
        Logger.success('VTOP', '${(data['receipts'] as List).length} receipts');
      }
    }
  }

  Future<void> _step11_previousSemesterGradesAndGPA(
    String currentSemesterId,
  ) async {
    _updateProgress(11, 'Extracting grade history');

    final prefs = await SharedPreferences.getInstance();
    final semestersJson = prefs.getString('available_semesters');
    final semesterMapJson = prefs.getString('semester_map');

    if (semestersJson == null || semesterMapJson == null) return;

    final List<dynamic> semesters = jsonDecode(semestersJson);
    final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('cumulative_marks');

    List<CumulativeMark> allGrades = [];
    for (String semesterName in semesters) {
      final semesterId = semesterMap[semesterName];
      if (semesterId == null) continue;

      final semesterGrades = await _extractSemesterGrades(
        semesterId.toString(),
        semesterName,
      );
      allGrades.addAll(semesterGrades);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (allGrades.isNotEmpty) {
      final batch = database.batch();
      for (final grade in allGrades) {
        batch.insert(
          'cumulative_marks',
          grade.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      Logger.success(
        'VTOP',
        '${allGrades.length} grades across ${semesters.length} semesters',
      );
    }
  }

  Future<void> _step12_checkDues() async {
    _updateProgress(12, 'Checking dues');

    final jsCode = '''
      (function() {
        var data = 'verifyMenu=true&winImage=' + \$('#winImage').val() + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=@(new Date().getTime())';
        var response = {};
        
        \$.ajax({
          type: 'POST',
          url: 'p2p/Payments',
          data: data,
          async: false,
          success: function(res) {
            response.due_payments = !res.toLowerCase().includes('no payment dues');
          },
          error: function() {
            response.due_payments = false;
          }
        });
        return JSON.stringify(response);
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isNotEmpty && result != 'null') {
      final response = jsonDecode(result);
      final prefs = await SharedPreferences.getInstance();
      if (response['due_payments'] == true) {
        await prefs.setBool('duePayments', true);
      } else {
        await prefs.remove('duePayments');
      }
      Logger.success(
        'VTOP',
        'Dues: ${response['due_payments'] == true ? "YES" : "NO"}',
      );
    }
  }

  Future<void> _step13_getAttendanceDetails(String semesterId) async {
    _updateProgress(13, 'Extracting attendance details');

    final attendanceRecords = await _attendanceDao.getAll();
    if (attendanceRecords.isEmpty) return;

    int totalDetails = 0;
    for (var attendance in attendanceRecords) {
      final course = await _courseDao.getById(attendance.courseId!);
      if (course == null || course.classId == null) continue;

      final db = await VitConnectDatabase.instance.database;
      final slotDao = SlotDao(db);
      final slots = await slotDao.getByCourseId(course.id!);
      if (slots.isEmpty) continue;

      final combinedSlot = slots.map((s) => s.slot).join('+');
      final details = await _extractAttendanceDetails(
        course.classId!,
        combinedSlot,
      );

      if (details.isNotEmpty) {
        await _saveAttendanceDetails(attendance.id!, details);
        totalDetails += details.length;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    Logger.success('VTOP', '$totalDetails attendance details');
  }

  Future<void> _step14_getAllSemesterMarks() async {
    _updateProgress(14, 'Extracting marks history');

    final prefs = await SharedPreferences.getInstance();
    final semestersJson = prefs.getString('available_semesters');
    final semesterMapJson = prefs.getString('semester_map');

    if (semestersJson == null || semesterMapJson == null) return;

    final List<dynamic> semesters = jsonDecode(semestersJson);
    final Map<String, dynamic> semesterMap = jsonDecode(semesterMapJson);

    await _allSemesterMarkDao.deleteAll();

    int totalMarks = 0;
    for (String semesterName in semesters) {
      final semesterId = semesterMap[semesterName];
      if (semesterId == null) continue;

      final semesterMarks = await _extractSemesterMarksForHistory(
        semesterId.toString(),
        semesterName,
      );
      totalMarks += semesterMarks.length;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Logger.success(
      'VTOP',
      '$totalMarks marks from ${semesters.length} semesters',
    );
  }

  // ═══════════════════════════════════════════════════════
  // DATA PERSISTENCE
  // ═══════════════════════════════════════════════════════

  Future<void> _saveProfileData(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();

    // Preserve existing nickname if present (check both current profile and preserved nickname)
    String? existingNickname;

    // First check if there's a preserved nickname from _clearExistingData
    existingNickname = prefs.getString('preserved_nickname');

    // If not, check existing profile
    if (existingNickname == null || existingNickname.isEmpty) {
      final existingProfileJson = prefs.getString('student_profile');
      if (existingProfileJson != null && existingProfileJson.isNotEmpty) {
        try {
          final existingProfile =
              jsonDecode(existingProfileJson) as Map<String, dynamic>;
          existingNickname = existingProfile['nickname'] as String?;
        } catch (e) {
          Logger.e('VTOP', 'Error parsing existing profile for nickname', e);
        }
      }
    }

    final profile = StudentProfile(
      name: profileData['name']?.toString().trim() ?? '',
      registerNumber: profileData['registerNumber']?.toString().trim() ?? '',
      vitEmail: profileData['vitEmail']?.toString().trim() ?? '',
      program: profileData['program']?.toString().trim() ?? '',
      branch: profileData['branch']?.toString().trim() ?? '',
      schoolName: profileData['schoolName']?.toString().trim() ?? '',
      hostelBlock: profileData['hostelBlock']?.toString().trim(),
      roomNumber: profileData['roomNumber']?.toString().trim(),
      bedType: profileData['bedType']?.toString().trim(),
      messName: profileData['messName']?.toString().trim(),
      dateOfBirth: profileData['dateOfBirth']?.toString().trim(),
      nickname: existingNickname, // Preserve existing nickname
    );
    await prefs.setString('student_profile', jsonEncode(profile.toJson()));

    // Clean up preserved nickname after restoring it
    if (existingNickname != null && existingNickname.isNotEmpty) {
      await prefs.remove('preserved_nickname');
      Logger.i('VTOP', 'Nickname preserved during sync: $existingNickname');
    }
  }

  Future<void> _saveGradeHistoryData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final db = await VitConnectDatabase.instance.database;

    // Update profile with Step 2 data
    if (data.containsKey('studentDetails')) {
      final studentDetails = data['studentDetails'] as Map<String, dynamic>;
      final existingProfileJson = prefs.getString('student_profile');
      Map<String, dynamic> profileJson = {};

      if (existingProfileJson != null) {
        profileJson = jsonDecode(existingProfileJson) as Map<String, dynamic>;
      }

      profileJson['gender'] = studentDetails['gender']?.toString().trim();
      profileJson['yearJoined'] =
          studentDetails['yearJoined']?.toString().trim();
      profileJson['studySystem'] =
          studentDetails['studySystem']?.toString().trim();
      profileJson['eduStatus'] = studentDetails['eduStatus']?.toString().trim();
      profileJson['campus'] = studentDetails['campus']?.toString().trim();
      profileJson['programmeMode'] =
          studentDetails['programmeMode']?.toString().trim();

      await prefs.setString('student_profile', jsonEncode(profileJson));
    }

    // Save CGPA Summary
    if (data.containsKey('cgpaSummary')) {
      final cgpaData = data['cgpaSummary'] as Map<String, dynamic>;
      final cgpaSummary = CGPASummary(
        creditsRegistered: (cgpaData['creditsRegistered'] ?? 0.0).toDouble(),
        creditsEarned: (cgpaData['creditsEarned'] ?? 0.0).toDouble(),
        cgpa: (cgpaData['cgpa'] ?? 0.0).toDouble(),
        sGrades: cgpaData['sGrades'] ?? 0,
        aGrades: cgpaData['aGrades'] ?? 0,
        bGrades: cgpaData['bGrades'] ?? 0,
        cGrades: cgpaData['cGrades'] ?? 0,
        dGrades: cgpaData['dGrades'] ?? 0,
        eGrades: cgpaData['eGrades'] ?? 0,
        fGrades: cgpaData['fGrades'] ?? 0,
        nGrades: cgpaData['nGrades'] ?? 0,
      );
      await prefs.setString('cgpa_summary', jsonEncode(cgpaSummary.toJson()));
      await prefs.setDouble(
        'total_credits_required',
        (data['totalCreditsRequired'] ?? 0.0).toDouble(),
      );
    }

    // Save Curriculum Progress
    if (data.containsKey('curriculumProgress')) {
      final curriculumList = data['curriculumProgress'] as List;
      if (curriculumList.isNotEmpty) {
        await db.delete('curriculum_progress');
        for (final item in curriculumList) {
          final curriculum = CurriculumProgress(
            distributionType: item['distributionType']?.toString().trim() ?? '',
            creditsRequired: (item['creditsRequired'] ?? 0.0).toDouble(),
            creditsEarned: (item['creditsEarned'] ?? 0.0).toDouble(),
          );
          await db.insert('curriculum_progress', curriculum.toMap());
        }
      }
    }

    // Save Basket Progress
    if (data.containsKey('basketProgress')) {
      final basketList = data['basketProgress'] as List;
      if (basketList.isNotEmpty) {
        await db.delete('basket_progress');
        for (final item in basketList) {
          final basket = BasketProgress(
            basketTitle: item['basketTitle']?.toString().trim() ?? '',
            distributionType: item['distributionType']?.toString().trim() ?? '',
            creditsRequired: (item['creditsRequired'] ?? 0.0).toDouble(),
            creditsEarned: (item['creditsEarned'] ?? 0.0).toDouble(),
          );
          await db.insert('basket_progress', basket.toMap());
        }
      }
    }
  }

  Future<void> _saveCourseData(List<dynamic> courses) async {
    _theorySlots.clear();
    _labSlots.clear();
    _projectSlots.clear();
    _theoryCourses.clear();
    _labCourses.clear();
    _projectCourses.clear();

    for (final courseData in courses) {
      final course = Course(
        code: courseData['code']?.toString() ?? '',
        title: courseData['title']?.toString() ?? '',
        type: (courseData['type']?.toString() ?? 'theory').toLowerCase(),
        credits: (courseData['credits'] as num?)?.toDouble() ?? 0.0,
        classId: courseData['classId']?.toString() ?? '',
        venue: courseData['venue']?.toString() ?? '',
        faculty: courseData['faculty']?.toString() ?? '',
        category: courseData['category']?.toString(),
        courseOption: courseData['courseOption']?.toString(),
        semesterId: 'current',
      );

      final courseId = await _courseDao.insert(course);
      final slots = courseData['slots'] as List<dynamic>? ?? [];

      Map<String, Slot> slotReference;
      if (course.type == 'lab') {
        slotReference = _labSlots;
        _labCourses[courseId] = course.copyWith(id: courseId);
      } else if (course.type == 'project') {
        slotReference = _projectSlots;
        _projectCourses[courseId] = course.copyWith(id: courseId);
      } else {
        slotReference = _theorySlots;
        _theoryCourses[courseId] = course.copyWith(id: courseId);
      }

      for (String slotStr in slots.map((s) => s.toString())) {
        if (slotStr.isNotEmpty) {
          final trimmedSlot = slotStr.trim();
          final slotEntity = Slot(slot: trimmedSlot, courseId: courseId);
          final dbSlotId = await _courseDao.insertSlot(slotEntity);
          final slotWithId = Slot(
            id: dbSlotId,
            slot: trimmedSlot,
            courseId: courseId,
          );
          slotReference[trimmedSlot] = slotWithId;
        }
      }
    }
  }

  Future<void> _saveTimetableData(
    List<dynamic> labArray,
    List<dynamic> theoryArray,
  ) async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('timetable');

    int timetableId = 1;
    final maxLength =
        labArray.length > theoryArray.length
            ? labArray.length
            : theoryArray.length;

    for (int i = 0; i < maxLength; i++) {
      if (i < labArray.length) {
        final labObject = labArray[i] as Map<String, dynamic>;
        final labEntry = Timetable(
          id: timetableId++,
          startTime: _formatTime(labObject['start_time']?.toString()),
          endTime: _formatTime(labObject['end_time']?.toString()),
          sunday: _getSlotIdByName(labObject['sunday']?.toString()),
          monday: _getSlotIdByName(labObject['monday']?.toString()),
          tuesday: _getSlotIdByName(labObject['tuesday']?.toString()),
          wednesday: _getSlotIdByName(labObject['wednesday']?.toString()),
          thursday: _getSlotIdByName(labObject['thursday']?.toString()),
          friday: _getSlotIdByName(labObject['friday']?.toString()),
          saturday: _getSlotIdByName(labObject['saturday']?.toString()),
        );
        await database.insert('timetable', labEntry.toMap());
      }

      if (i < theoryArray.length) {
        final theoryObject = theoryArray[i] as Map<String, dynamic>;
        final theoryEntry = Timetable(
          id: timetableId++,
          startTime: _formatTime(theoryObject['start_time']?.toString()),
          endTime: _formatTime(theoryObject['end_time']?.toString()),
          sunday: _getSlotIdByName(theoryObject['sunday']?.toString()),
          monday: _getSlotIdByName(theoryObject['monday']?.toString()),
          tuesday: _getSlotIdByName(theoryObject['tuesday']?.toString()),
          wednesday: _getSlotIdByName(theoryObject['wednesday']?.toString()),
          thursday: _getSlotIdByName(theoryObject['thursday']?.toString()),
          friday: _getSlotIdByName(theoryObject['friday']?.toString()),
          saturday: _getSlotIdByName(theoryObject['saturday']?.toString()),
        );
        await database.insert('timetable', theoryEntry.toMap());
      }
    }
  }

  Future<void> _saveAttendanceData(List<dynamic> attendanceList) async {
    for (var attendanceData in attendanceList) {
      final slot = attendanceData['slot']?.toString() ?? '';
      final facultyErpId = attendanceData['faculty_erp_id']?.toString();
      final courseType = attendanceData['course_type']?.toString();

      final course = await _courseDao.getCourseBySlot(slot);
      if (course != null) {
        if (facultyErpId != null && facultyErpId.isNotEmpty) {
          await _courseDao.update(course.copyWith(facultyErpId: facultyErpId));
        }

        final attendance = Attendance(
          courseId: course.id!,
          courseType: courseType,
          attended: attendanceData['attended'] ?? 0,
          total: attendanceData['total'] ?? 0,
          percentage: attendanceData['percentage'] ?? 0,
        );
        await _attendanceDao.insert(attendance);
      }
    }
  }

  Future<void> _saveMarksData(List<dynamic> marksList) async {
    for (var markData in marksList) {
      final slot = markData['slot']?.toString() ?? '';
      final course = await _courseDao.getCourseBySlot(slot);
      if (course != null) {
        final signature =
            '${course.code}_${markData['title']}_${markData['score']}'.hashCode;
        final mark = Mark(
          courseId: course.id!,
          title: markData['title']?.toString() ?? '',
          score: (markData['score'] ?? 0).toDouble(),
          maxScore: (markData['max_score'] ?? 0).toDouble(),
          weightage: (markData['weightage'] ?? 0).toDouble(),
          maxWeightage: (markData['max_weightage'] ?? 0).toDouble(),
          average: (markData['average'] ?? 0).toDouble(),
          status: markData['status']?.toString() ?? '',
          isRead: false,
          signature: signature,
        );
        await _markDao.insert(mark);
      }
    }
    await _restoreMarksMetaFromVitverse();
  }

  Future<void> _restoreMarksMetaFromVitverse() async {
    try {
      final vitverse = VitVerseDatabase.instance;
      final readSigs = await vitverse.marksMetaDao.getReadSignatures();
      final avgMap = await vitverse.marksMetaDao.getAverages();
      if (readSigs.isEmpty && avgMap.isEmpty) return;

      final db = await VitConnectDatabase.instance.database;
      final freshRows = await db.rawQuery('''
        SELECT m.id, m.signature, m.title, c.code AS course_code
        FROM marks m
        LEFT JOIN courses c ON m.course_id = c.id
      ''');
      for (final row in freshRows) {
        final id = row['id'] as int;
        final sig = row['signature'] as int?;
        final courseCode = row['course_code'] as String? ?? '';
        final title = row['title'] as String? ?? '';
        final identityKey = '${courseCode}_$title'.hashCode;
        final isRead = sig != null && readSigs.contains(sig);
        final savedAvg = avgMap[identityKey];
        final updates = <String, Object?>{
          if (isRead) 'is_read': 1,
          if (savedAvg != null) 'average': savedAvg,
        };
        if (updates.isNotEmpty) {
          await db.update('marks', updates, where: 'id = ?', whereArgs: [id]);
        }
      }
    } catch (e) {
      Logger.e('VTOP', 'Failed to restore marks meta from vitverse: $e');
    }
  }

  Future<void> _saveExamScheduleData(Map<String, dynamic> examData) async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('exams');

    examData.forEach((examTitle, exams) async {
      if (exams is List) {
        for (var examItem in exams) {
          final slot = examItem['slot']?.toString() ?? '';
          final course = await _courseDao.getCourseBySlot(slot);

          if (course != null) {
            DateTime? startDateTime;
            DateTime? endDateTime;

            final date = examItem['date']?.toString();
            final startTime = examItem['start_time']?.toString();
            final endTime = examItem['end_time']?.toString();

            if (date != null && startTime != null) {
              startDateTime = _parseDateTime(date, startTime);
              if (startDateTime != null && endTime != null) {
                endDateTime = _parseDateTime(date, endTime);
              }
            }

            final exam = Exam(
              courseId: course.id!,
              title: examTitle,
              startTime: startDateTime?.millisecondsSinceEpoch,
              endTime: endDateTime?.millisecondsSinceEpoch,
              venue: examItem['venue']?.toString(),
              seatLocation: examItem['seat_location']?.toString(),
              seatNumber: examItem['seat_number'],
            );
            await database.insert('exams', exam.toMap());
          }
        }
      }
    });
  }

  Future<void> _saveStaffData(
    String? proctorResult,
    String? deanHodResult,
  ) async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('staff');

    if (proctorResult != null &&
        proctorResult != 'null' &&
        proctorResult.isNotEmpty) {
      final proctorData = jsonDecode(proctorResult);
      if (proctorData.containsKey('proctor')) {
        final proctorList = proctorData['proctor'] as List;
        for (var proctorItem in proctorList) {
          final key = proctorItem['key']?.toString() ?? '';
          final value = proctorItem['value']?.toString() ?? '';
          if (key.isNotEmpty && value.isNotEmpty) {
            final staff = Staff(type: 'proctor', key: key, value: value);
            await database.insert('staff', staff.toMap());
          }
        }
      }
    }

    if (deanHodResult != null &&
        deanHodResult != 'null' &&
        deanHodResult.isNotEmpty) {
      final deanHodData = jsonDecode(deanHodResult);
      deanHodData.forEach((staffType, staffList) async {
        if (staffList is List) {
          String type = staffType.toString().toLowerCase();
          if (type.contains('dean')) {
            type = 'dean';
          } else if (type.contains('hod'))
            type = 'hod';

          for (var staffItem in staffList) {
            final key = staffItem['key']?.toString() ?? '';
            final value = staffItem['value']?.toString() ?? '';
            if (key.isNotEmpty && value.isNotEmpty) {
              final staff = Staff(type: type, key: key, value: value);
              await database.insert('staff', staff.toMap());
            }
          }
        }
      });
    }
  }

  Future<void> _saveSpotlightData(List<dynamic> spotlightList) async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('spotlight');

    for (final spotlightData in spotlightList) {
      final announcement = spotlightData['announcement']?.toString() ?? '';
      if (announcement.isNotEmpty) {
        final signature =
            (announcement + (spotlightData['link']?.toString() ?? '')).hashCode;
        final spotlight = Spotlight(
          announcement: announcement,
          category: spotlightData['category']?.toString() ?? '',
          link: spotlightData['link']?.toString(),
          isRead: false,
          signature: signature,
        );
        await database.insert('spotlight', spotlight.toMap());
      }
    }
  }

  Future<void> _saveReceiptData(List<dynamic> receiptsList) async {
    final db = VitConnectDatabase.instance;
    final database = await db.database;
    await database.delete('receipts');

    for (var receiptData in receiptsList) {
      final number = receiptData['number'];
      final dateStr = receiptData['date']?.toString() ?? '';

      if (number != null && dateStr.isNotEmpty) {
        DateTime? receiptDate = _parseDate(dateStr);
        final receipt = Receipt(
          number: number,
          amount: (receiptData['amount'] ?? 0).toDouble(),
          date: receiptDate?.millisecondsSinceEpoch ?? 0,
        );
        await database.insert('receipts', receipt.toMap());
      }
    }
  }

  Future<void> _saveAttendanceDetails(
    int attendanceId,
    List<Map<String, dynamic>> detailsList,
  ) async {
    if (detailsList.isEmpty) return;

    await _attendanceDetailDao.deleteByAttendanceId(attendanceId);

    final details =
        detailsList.map((detail) {
          return AttendanceDetail(
            attendanceId: attendanceId,
            attendanceDate: detail['date']?.toString() ?? '',
            attendanceSlot: detail['slot']?.toString() ?? '',
            dayAndTiming: detail['dayTiming']?.toString() ?? '',
            attendanceStatus: detail['status']?.toString() ?? '',
            isMedicalLeave: detail['isMedicalLeave'] == true,
            isVirtualSlot: false,
          );
        }).toList();

    await _attendanceDetailDao.insertBatch(details);
  }

  // ═══════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════

  Future<List<CumulativeMark>> _extractSemesterGrades(
    String semesterId,
    String semesterName,
  ) async {
    final jsCode = '''
      (function() {
        try {
          var data = 'semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val();
          var response = { courses: [], gpa: null };
          
          \$.ajax({
            type: 'POST',
            url: 'examinations/examGradeView/doStudentGradeView',
            data: data,
            async: false,
            success: function(res) {
              if (res.toLowerCase().includes('no records found') || res.toLowerCase().includes('no data')) return;
              
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var tables = doc.getElementsByTagName('table');
              
              for (var t = 0; t < tables.length; t++) {
                var table = tables[t];
                var rows = table.getElementsByTagName('tr');
                if (rows.length < 3) continue;
                
                var headerRow = rows[0];
                var headerText = headerRow.innerText.toLowerCase();
                if (!headerText.includes('course') || !headerText.includes('grade')) continue;
                
                for (var i = 2; i < rows.length - 1; i++) {
                  var cells = rows[i].getElementsByTagName('td');
                  if (cells.length < 11) continue;
                  
                  var course = {
                    courseCode: cells[1].innerText.trim(),
                    courseTitle: cells[2].innerText.trim(),
                    courseType: cells[3].innerText.trim(),
                    credits: parseFloat(cells[7].innerText.trim()),
                    gradingType: cells[8].innerText.trim(),
                    grandTotal: parseFloat(cells[9].innerText.trim()),
                    grade: cells[10].innerText.trim(),
                    isOnlineCourse: rows[i].style.backgroundColor.includes('C0D8C0') || rows[i].style.backgroundColor.includes('c0d8c0'),
                  };
                  
                  if (course.courseCode && course.grade) {
                    response.courses.push(course);
                  }
                }
                
                var allCells = table.getElementsByTagName('td');
                if (allCells.length > 0) {
                  var lastCell = allCells[allCells.length - 1];
                  var lastCellText = lastCell.innerText || lastCell.textContent || '';
                  
                  if (lastCellText.includes(':')) {
                    var parts = lastCellText.split(':');
                    if (parts.length >= 2) {
                      var gpaValue = parseFloat(parts[1].trim());
                      if (!isNaN(gpaValue)) response.gpa = gpaValue;
                    }
                  }
                  
                  if (!response.gpa) {
                    var gpaMatch = lastCellText.match(/GPAs*:?s*([d.]+)/i);
                    if (gpaMatch && gpaMatch[1]) {
                      response.gpa = parseFloat(gpaMatch[1]);
                    }
                  }
                }
                break;
              }
            }
          });
          return JSON.stringify(response);
        } catch (e) {
          return JSON.stringify({ error: e.message });
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isEmpty || result == 'null') return [];

    final data = jsonDecode(result);
    if (data.containsKey('error')) return [];

    final courses = data['courses'] as List? ?? [];
    final gpa = (data['gpa'] as num?)?.toDouble();

    return courses.map((courseData) {
      return CumulativeMark(
        semesterId: semesterId,
        semesterName: semesterName,
        courseCode: courseData['courseCode']?.toString() ?? '',
        courseTitle: courseData['courseTitle']?.toString() ?? '',
        courseType: courseData['courseType']?.toString() ?? '',
        credits: (courseData['credits'] as num?)?.toDouble() ?? 0.0,
        gradingType: courseData['gradingType']?.toString() ?? '',
        grandTotal: (courseData['grandTotal'] as num?)?.toDouble() ?? 0.0,
        grade: courseData['grade']?.toString() ?? '',
        isOnlineCourse: courseData['isOnlineCourse'] == true,
        semesterGpa: gpa,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _extractAttendanceDetails(
    String classId,
    String slotName,
  ) async {
    final jsCode = '''
      (function() {
        try {
          var detailData = '_csrf=' + \$('input[name="_csrf"]').val() + 
                          '&classId=' + '$classId' + 
                          '&slotName=' + '$slotName' + 
                          '&authorizedID=' + \$('#authorizedIDX').val() + 
                          '&x=' + new Date().toUTCString();
          
          var response = { details: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'processViewAttendanceDetail',
            data: detailData,
            async: false,
            success: function(res) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var table = doc.querySelector('table.table');
              
              if (table) {
                var rows = table.querySelectorAll('tr');
                for (var i = 1; i < rows.length; i++) {
                  var cells = rows[i].querySelectorAll('td');
                  if (cells.length >= 5) {
                    var statusCell = cells[4];
                    var statusSpan = statusCell.querySelector('span');
                    
                    if (statusSpan) {
                      var status = statusSpan.textContent.trim();
                      response.details.push({
                        date: cells[1].textContent.trim(),
                        slot: cells[2].querySelector('p') ? cells[2].querySelector('p').textContent.trim() : cells[2].textContent.trim(),
                        dayTiming: cells[3].querySelector('p') ? cells[3].querySelector('p').textContent.trim() : cells[3].textContent.trim(),
                        status: status,
                        isAbsent: status.toLowerCase() === 'absent',
                        isMedicalLeave: status.toLowerCase().includes('medical')
                      });
                    }
                  }
                }
              }
            }
          });
          return { success: true, data: response };
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isEmpty || result == 'null') return [];

    final data = jsonDecode(result);
    if (data['success'] == false) return [];
    if (data['success'] == true && data['data'] != null) {
      final responseData = data['data'];
      if (responseData['details'] is List) {
        return List<Map<String, dynamic>>.from(responseData['details']);
      }
    }
    return [];
  }

  Future<List<AllSemesterMark>> _extractSemesterMarksForHistory(
    String semesterId,
    String semesterName,
  ) async {
    final jsCode = '''
      (function() {
        try {
          var data = 'semesterSubId=' + '$semesterId' + '&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val();
          var response = { marks: [] };
          
          \$.ajax({
            type: 'POST',
            url: 'examinations/doStudentMarkView',
            data: data,
            async: false,
            success: function(res) {
              if(res.toLowerCase().includes('no data found')) return;
              
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var table = doc.getElementById('fixedTableContainer');
              if (!table) return;
              
              var rows = table.getElementsByTagName('tr');
              var headings = rows[0].getElementsByTagName('td');
              var courseCodeIndex, courseTitleIndex, courseTypeIndex, slotIndex;
              
              for (var i = 0; i < headings.length; i++) {
                var heading = headings[i].innerText.toLowerCase();
                if (heading.includes('course') && heading.includes('code')) courseCodeIndex = i;
                else if (heading.includes('course') && heading.includes('title')) courseTitleIndex = i;
                else if (heading.includes('course') && heading.includes('type')) courseTypeIndex = i;
                else if (heading.includes('slot')) slotIndex = i;
              }
              
              for (var i = 1; i < rows.length; i++) {
                var courseCode = rows[i].getElementsByTagName('td')[courseCodeIndex].innerText.trim();
                var courseTitle = rows[i].getElementsByTagName('td')[courseTitleIndex].innerText.trim();
                var rawCourseType = rows[i].getElementsByTagName('td')[courseTypeIndex].innerText.trim().toLowerCase();
                var courseType = rawCourseType.includes('lab') ? 'lab' : (rawCourseType.includes('project') ? 'project' : 'theory');
                var slot = rows[i++].getElementsByTagName('td')[slotIndex].innerText.split('+')[0].trim();
                
                var innerTable = rows[i].getElementsByTagName('table')[0];
                var innerRows = innerTable.getElementsByTagName('tr');
                var innerHeadings = innerRows[0].getElementsByTagName('td');
                var titleIndex, scoreIndex, maxScoreIndex, weightageIndex, maxWeightageIndex, averageIndex, statusIndex;
                
                for (var j = 0; j < innerHeadings.length; j++) {
                  var innerHeading = innerHeadings[j].innerText.toLowerCase();
                  if (innerHeading.includes('title')) titleIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('max')) maxScoreIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('%')) maxWeightageIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('status')) statusIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('scored')) scoreIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('weightage') && innerHeading.includes('mark')) weightageIndex = j + innerHeadings.length;
                  else if (innerHeading.includes('average')) averageIndex = j + innerHeadings.length;
                }
                
                var innerCells = innerTable.getElementsByTagName('td');
                while(titleIndex < innerCells.length) {
                  var mark = {};
                  mark.course_code = courseCode;
                  mark.course_title = courseTitle;
                  mark.slot = slot;
                  mark.course_type = courseType;
                  mark.title = innerCells[titleIndex].innerText.trim();
                  mark.score = parseFloat(innerCells[scoreIndex].innerText) || 0;
                  mark.max_score = parseFloat(innerCells[maxScoreIndex].innerText) || null;
                  mark.weightage = parseFloat(innerCells[weightageIndex].innerText) || 0;
                  mark.max_weightage = parseFloat(innerCells[maxWeightageIndex].innerText) || null;
                  mark.average = parseFloat(innerCells[averageIndex].innerText) || null;
                  mark.status = innerCells[statusIndex].innerText.trim();
                  response.marks.push(mark);
                  
                  titleIndex += innerHeadings.length;
                  scoreIndex += innerHeadings.length;
                  maxScoreIndex += innerHeadings.length;
                  weightageIndex += innerHeadings.length;
                  maxWeightageIndex += innerHeadings.length;
                  averageIndex += innerHeadings.length;
                  statusIndex += innerHeadings.length;
                }
                i += innerRows.length;
              }
            }
          });
          return response;
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    ''';

    final result = await _executeJavaScript(jsCode);
    if (result.isEmpty || result == 'null') return [];

    final data = jsonDecode(result);
    if (data.containsKey('success') && data['success'] == false) return [];
    if (!data.containsKey('marks')) return [];

    return await _saveAllSemesterMarksData(
      data['marks'] as List,
      semesterId,
      semesterName,
    );
  }

  Future<List<AllSemesterMark>> _saveAllSemesterMarksData(
    List<dynamic> marksList,
    String semesterId,
    String semesterName,
  ) async {
    List<AllSemesterMark> savedMarks = [];

    for (var markData in marksList) {
      try {
        final signature =
            '${semesterId}_${markData['course_code']}_${markData['title']}'
                .hashCode;
        final existing = await _allSemesterMarkDao.getBySignature(signature);

        if (existing == null) {
          final mark = AllSemesterMark(
            semesterId: semesterId,
            semesterName: semesterName,
            courseCode: markData['course_code']?.toString() ?? '',
            courseTitle: markData['course_title']?.toString() ?? '',
            courseType: markData['course_type']?.toString() ?? '',
            slot: markData['slot']?.toString() ?? '',
            title: markData['title']?.toString() ?? '',
            score: (markData['score'] ?? 0).toDouble(),
            maxScore: (markData['max_score'] ?? 0).toDouble(),
            weightage: (markData['weightage'] ?? 0).toDouble(),
            maxWeightage: (markData['max_weightage'] ?? 0).toDouble(),
            average: (markData['average'] ?? 0).toDouble(),
            status: markData['status']?.toString() ?? '',
            signature: signature,
          );

          await _allSemesterMarkDao.insert(mark);
          savedMarks.add(mark);
        }
      } catch (e) {
        Logger.w(
          'VTOP',
          'Failed to save mark: ${markData['course_code']} - ${markData['title']}: $e',
        );
      }
    }
    return savedMarks;
  }

  int? _getSlotIdByName(String? slotName) {
    if (slotName == null || slotName.isEmpty) return null;

    int? slotId;

    if (slotName.toUpperCase().startsWith('L') &&
        slotName.length > 1 &&
        int.tryParse(slotName.substring(1)) != null) {
      slotId = _labSlots[slotName]?.id;
    } else if (slotName.toUpperCase().startsWith('V') &&
        slotName.length > 1 &&
        int.tryParse(slotName.substring(1)) != null) {
      slotId = _projectSlots[slotName]?.id;
    } else {
      slotId = _theorySlots[slotName]?.id;
    }

    return slotId;
  }

  String? _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    try {
      if (timeStr.toUpperCase().contains('AM') ||
          timeStr.toUpperCase().contains('PM')) {
        return timeStr;
      }

      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        if (hour != null && hour < 8) {
          final newHour = hour + 12;
          return '$newHour:${parts[1]}';
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      final dateParts = date.split('-');
      if (dateParts.length == 3) {
        final day = int.parse(dateParts[0]);
        final monthName = dateParts[1];
        final year = int.parse(dateParts[2]);

        final months = {
          'JAN': 1,
          'FEB': 2,
          'MAR': 3,
          'APR': 4,
          'MAY': 5,
          'JUN': 6,
          'JUL': 7,
          'AUG': 8,
          'SEP': 9,
          'OCT': 10,
          'NOV': 11,
          'DEC': 12,
        };
        final month = months[monthName] ?? 1;

        final timeParts = time.split(' ');
        if (timeParts.length == 2) {
          final timeStr = timeParts[0];
          final amPm = timeParts[1];
          final hourMinute = timeStr.split(':');

          if (hourMinute.length == 2) {
            int hour = int.parse(hourMinute[0]);
            final minute = int.parse(hourMinute[1]);

            if (amPm.toUpperCase() == 'PM' && hour != 12) {
              hour += 12;
            } else if (amPm.toUpperCase() == 'AM' && hour == 12)
              hour = 0;

            return DateTime(year, month, day, hour, minute);
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final dateParts = dateStr.split('-');
      if (dateParts.length == 3) {
        final day = int.parse(dateParts[0]);
        final monthName = dateParts[1];
        final year = int.parse(dateParts[2]);

        final months = {
          'JAN': 1,
          'FEB': 2,
          'MAR': 3,
          'APR': 4,
          'MAY': 5,
          'JUN': 6,
          'JUL': 7,
          'AUG': 8,
          'SEP': 9,
          'OCT': 10,
          'NOV': 11,
          'DEC': 12,
        };
        final month = months[monthName] ?? 1;

        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════

  Future<void> _initDatabase() async {
    final db = VitConnectDatabase.instance;
    try {
      await db.database;
    } catch (e) {
      await db.deleteDatabase();
      await db.database;
    }
  }

  Future<void> _clearExistingData() async {
    await _courseDao.deleteAll();
    await _attendanceDao.deleteAll();
    await _markDao.deleteAll();
    final prefs = await SharedPreferences.getInstance();

    // Preserve nickname before clearing profile
    String? existingNickname;
    final existingProfileJson = prefs.getString('student_profile');
    if (existingProfileJson != null && existingProfileJson.isNotEmpty) {
      try {
        final existingProfile =
            jsonDecode(existingProfileJson) as Map<String, dynamic>;
        existingNickname = existingProfile['nickname'] as String?;
      } catch (e) {
        Logger.e('VTOP', 'Error parsing existing profile for nickname', e);
      }
    }

    // Remove profile (it will be recreated with new data during sync)
    await prefs.remove('student_profile');

    // Save nickname separately if it exists
    if (existingNickname != null && existingNickname.isNotEmpty) {
      await prefs.setString('preserved_nickname', existingNickname);
    }
  }

  Future<void> _executeStep(
    Future<void> Function() stepFunction,
    int stepNumber,
    String stepName,
  ) async {
    try {
      _updateProgress(stepNumber, stepName);
      await stepFunction();
      Logger.d('VTOP', 'Step $stepNumber completed: $stepName');
    } catch (e) {
      Logger.e(
        DataServiceConstants.logTag,
        'Step $stepNumber failed: $stepName',
        e,
      );
      if (DataServiceConstants.criticalSteps.contains(stepNumber)) rethrow;
    }
  }

  Future<String> _executeJavaScript(String jsCode) async {
    try {
      final result = await _webViewController.runJavaScriptReturningResult(
        jsCode,
      );
      String cleanResult = result.toString();
      if (cleanResult.startsWith('"') && cleanResult.endsWith('"')) {
        cleanResult = cleanResult.substring(1, cleanResult.length - 1);
      }
      cleanResult = cleanResult
          .replaceAll('\\"', '"')
          .replaceAll('\\\\', '\\')
          .replaceAll('\\n', '\n')
          .replaceAll('\\r', '\r')
          .replaceAll('\\t', '\t');

      return cleanResult;
    } catch (e) {
      Logger.e('VTOP', 'JavaScript execution failed', e);
      return '{}';
    }
  }

  void _updateProgress(int step, String stepName) {
    _currentStep = step;
    _currentStepName = stepName;
    Logger.progress('VTOP', _currentStep, _totalSteps, _currentStepName);
    onProgress?.call(_currentStep, _totalSteps, _currentStepName);
    onStatusUpdate?.call(_currentStepName);
  }

  Future<StudentProfile?> getStudentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('student_profile');
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return StudentProfile.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
