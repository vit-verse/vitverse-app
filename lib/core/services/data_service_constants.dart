/// Constants for VTOP data service configuration.
/// Defines phases, steps, and settings for data extraction.
class DataServiceConstants {
  // Phase Configuration

  /// Number of steps in Phase 1 (essential data for home screen).
  static const int phase1TotalSteps = 5;

  /// Number of steps in Phase 2 (background data loading).
  static const int phase2TotalSteps = 9;

  /// Total steps across all phases.
  static const int totalSteps = 14;

  // Timing Configuration

  /// Delay between steps in milliseconds to avoid server blocking.
  static const int stepDelayMs = 20;

  // Step Names and Metadata

  /// Names for Phase 1 steps (critical path).
  static const String step1Name = 'Loading profile information';
  static const String step3Name = 'Loading course information';
  static const String step4Name = 'Loading timetable data';
  static const String step5Name = 'Loading attendance data';
  static const String step13Name = 'Loading detailed attendance';

  /// Names for Phase 2 steps (background loading).
  static const String step6Name = 'Loading marks data';
  static const String step2Name = 'Loading grade history';
  static const String step7Name = 'Loading exam schedule';
  static const String step14Name = 'Loading all semester marks';
  static const String step11Name = 'Loading previous semester GPA';
  static const String step8Name = 'Loading staff information';
  static const String step9Name = 'Loading announcements';
  static const String step10Name = 'Loading fee receipts';
  static const String step12Name = 'Checking outstanding dues';

  // Notification Messages

  static const String phase1StartMessage = 'Phase 1/2 - Loading essential data...';
  static const String phase1CompleteMessage = 'Phase 1 complete - Opening VIT Connect';
  static const String phase2StartMessage = 'Phase 2/2 - Loading additional data in background...';
  static const String phase2CompleteMessage = 'All data loaded successfully!';

  // Error Messages

  static const String phase1ErrorMessage = 'Failed to load essential data. Please try again.';
  static const String phase2ErrorMessage = 'Some data failed to load. You can refresh later.';

  // Step Execution Order
  // (I wrote steps in increasing order, but for 2-phase sync + less UI block, we execute primary first and push the rest to background)
  /// Steps for Phase 1 in execution order.
  static const List<int> phase1Steps = [1, 3, 4, 5, 13];

  /// Steps for Phase 2 in execution order.
  static const List<int> phase2Steps = [6, 2, 7, 14, 11, 8, 9, 10, 12];

  // Parallel Execution Groups

  /// Phase 1 Group 1: Independent steps that can run in parallel.
  static const List<int> phase1Group1 = [1, 3]; // Profile and Courses

  /// Phase 1 Group 2: Steps dependent on courses, can run in parallel.
  static const List<int> phase1Group2 = [4, 5]; // Timetable and Attendance

  /// Phase 1 Group 3: Must run after Group 2.
  static const List<int> phase1Group3 = [13]; // Detailed Attendance

  // Data Validation

  /// Minimum expected records for data validation.
  static const int minExpectedCourses = 1;
  static const int minExpectedAttendanceRecords = 1;
  static const int minExpectedSlots = 1;

  // Retry Configuration

  /// Maximum retry attempts for failed steps.
  static const int maxRetryAttempts = 2;

  /// Critical steps (Phase 1) that should retry on failure.
  static const List<int> criticalSteps = [1, 3, 4, 5, 13];

  /// Non-critical steps (Phase 2) that can fail silently.
  static const List<int> nonCriticalSteps = [6, 2, 7, 14, 11, 8, 9, 10, 12];

  // Logging Configuration

  static const String logTag = 'VTOP_DATA';
  static const bool enableVerboseLogging = true;
  static const bool enableStepTiming = true;
}

/*
Refrences ;)
| 1 | Contact Us | hrms/contactDetails |
| 2 | Profile | studentsRecord/StudentProfileAllView |
| 3 | Your Credentials | proctor/viewStudentCredentials |
| 4 | Dayboarder Info | admissions/dayboarderForMenu |
| 5 | Acknowledgement View | admissions/AcknowledgmentView |
| 6 | Student Bank Info | studentBankInformation/BankInfoStudent |
| 7 | EPT schedule | compre/eptScheduleShow |
| 8 | Registration Schedule | examinations/hostelDetails |
| 9 | FeedBack Status | academics/common/FeedBackStatusStudent |
| 10 | Hostel Counselling OTP | examinations/technoCrendentials |
| 11 | FAQ | academics/common/FaqPreview |
| 12 | Spotlight | spotlight/spotlightViewOld |
| 13 | View Circular(s) | admissions/costCentreCircularsViewPageController |
| 14 | Course Withdraw | academics/withdraw/courseWithdraw |
| 15 | WishList | academics/registration/wishlistRegPage |
| 16 | EXC Registration | academics/exc/studentRegistration |
| 17 | MOOC Registration | academics/mooc/studentRegistration |
| 18 | View Proctor Details | proctor/viewProctorDetails |
| 19 | View VTOP Message from Proctor | proctor/viewMessagesSendByProctor |
| 20 | HOD and Dean Info | hrms/viewHodDeanDetails |
| 21 | Faculty Info | hrms/employeeSearchForStudent |
| 22 | Biometric Info | academics/common/BiometricInfo |
| 23 | Class Messages | academics/common/StudentClassMessage |
| 24 | Regulation | academics/council/CouncilRegulationView/new |
| 25 | My Curriculum | academics/common/Curriculum |
| 26 | Minor/ Honour | academics/additionalLearning/AdditionalLearningStudentView |
| 27 | Time Table | academics/common/StudentTimeTableChn |
| 28 | Course Option Change | academics/OnlineCOC/StudentOnlineCOC |
| 29 | Course Withdraw View | academics/common/CourseWithDraw |
| 30 | Class Attendance | academics/common/StudentAttendance |
| 31 | Course Page | academics/common/StudentCoursePage |
| 32 | Industrial Internship | internship/InternshipRegistration |
| 33 | Project | academics/common/ProjectView |
| 34 | Capstone Project Upload | examinations/StudentDA |
| 35 | QCM View | academics/common/QCMStudentLogin |
| 36 | Outcome SET Conference | outcome/set/studentRegistrationPage |
| 37 | Co-Extra Curricular | academics/common/ExtraCurricular |
| 38 | WishList Registraion | academics/common/WishlistStudent |
| 39 | Academic Calendar | academics/common/CalendarPreview |
| 40 | Project Course | academics/student/PJTReg/loadRegistrationPage |
| 41 | Temp | null |
| 42 | SLO Student Feedback | academics/Others/doSloStudentFeedback |
| 43 | ApaarId Upload | apaarid/upload |
| 44 | View Multidisciplinary Project | mdp/viewMDPStudent |
| 45 | My Research Profile | research/researchProfile |
| 46 | SEM Request | admissions/semTransactionPageControllerGeneral |
| 47 | Course Work Registration | research/CourseworkRegistration |
| 48 | Registration Status | research/CourseworkRegistrationViewtoScholar |
| 49 | Meeting info | research/scholarsMeetingView |
| 50 | Attendance view | research/scholarsAttendanceView |
| 51 | ScholarLeave Request | research/scholar/leave/request |
| 52 | Thesis Status | research/thesisStatusResearchScholar |
| 53 | Research Letters | research/researchLettersStudentView |
| 54 | Research Document Upload | research/researchDocumentUpload |
| 55 | Monthly Work Report | research/researchWkProgressReport |
| 56 | Research Award Application | research/monthlyAwardApplication |
| 57 | Electronic Thesis Submission | research/thesisSubmission |
| 58 | Research Template Download | research/reseachScholarTempleteView |
| 59 | Exam Schedule | examinations/StudExamSchedule |
| 60 | Marks | examinations/StudentMarkView |
| 61 | Online Exam Student Attempt View | compre/onlineExamStudentAttemptView |
| 62 | Grades | examinations/examGradeView/StudentGradeView |
| 63 | Paper See/Rev | examinations/paperSeeing/PaperSeeing |
| 64 | Grade History | examinations/examGradeView/StudentGradeHistory |
| 65 | Additional Learning | examinations/doGetAddLearnCourseDashboard |
| 66 | Project File Upload | examinations/projectFileUpload/ProjectView |
| 67 | MOOC File upload | examinations/gotToMoocCourseInitial |
| 68 | ECA File Upload | examinations/ecaUpload/viewCourse |
| 69 | Comprehensive Exam | compre/registrationForm |
| 70 | Question Preview | compre/questionPreview |
| 71 | Exam Information | compre/studentExamInfo |
| 72 | Regular Arrear Registration | examinations/arrearRegistration/RegularArrearStudentReg |
| 73 | Registration Details | examinations/arrearRegistration/LoadRegularArrearViewPage |
| 74 | Exam Schedule (Arrear) | examinations/arrearRegistration/viewRARExamSchedule |
| 75 | Grade View (Arrear) | examinations/arrearRegistration/StudentArrearGradeView |
| 76 | Paper See/Rev (Arrear) | examinations/regularArrear/RegularArrearPaperSeeing |
| 77 | Re-Exam Application | examinations/reFAT/StudentReFATRequestPageController |
| 78 | Certificate Collection Registration | cert/certificateCollectionRegistration |
| 79 | Certificate Collection Acknowledgement | examinations/certificate/CertificateStudent |
| 80 | Convocation Registration | convocation/entryPage |
| 81 | Facility Registration | phyedu/facilityAvailable |
| 82 | Transport Registration | transport/transportRegistration |
| 83 | Pat Registration | pat/PatRegistrationProcess |
| 84 | Online Book Recommendation | hrms/onlineBookRecommendation |
| 85 | Transcript Request | alumni/alumniTranscriptPageControl |
| 86 | Achievements | admissions/SpecialAchieversAwards |
| 87 | Programme Migration | admissions/programmeMigration |
| 88 | Graduated information | admissions/doGetPassedOutInformation |
| 89 | Late Hour Request | hostels/late/hour/student/request/1 |
| 90 | SAP Information | sap/SapInformation |
| 91 | SAP Project | sap/SapManage |
| 92 | Student Outgoing Report | vitaa/finalyearcheck |
| 93 | Student Withdraw | studentWithdraw |
| 94 | Scanning Request | p2p/studentScanningRequest |
| 95 | My Keys | library/studentScanningRequestKeys |
| 96 | Apply Bonafide | others/bonafide/StudentBonafidePageControl |
| 97 | Course Completion | others/bonafide/CourseCompleteControl |
| 98 | Wallet Amount Addtion | finance/getStudentWallet |
| 99 | Payments | p2p/Payments |
| 100 | Payment Receipts | p2p/getReceiptsApplno |
| 101 | Fees Intimation | finance/getFeesIntimation |
| 102 | Online Transfer | finance/getOnlineTransfer |
| 103 | Library Due | finance/libraryPayments |
| 104 | Online Booking | hostels/online/room/allotment/1 |
| 105 | My Room Information | hostels/room/allotment/info/student/1 |
| 106 | Leave Request | hostels/student/leave/1 |
| 107 | Mess Selection 2025-2026 | hostels/counselling/mess/registration |
| 108 | Caterer Change | hostels/onlineCatererChange |
| 109 | Hostel Mess Feedback | hostels/feedback1 |
| 110 | Summer Room Registration | hostels/summer/room/allotment/1 |
| 111 | Attendance View | hostels/student/month/attendance/report/1 |
| 112 | External Billing | finance/ReceiptBookExternalBilling |
| 113 | My Collection Report | finance/getTotstudentReport |
| 114 | Internal Billing | finance/ReceiptBookInternalBilling |
| 115 | FDP Registration | events/ASC/EventsRegistration |
| 116 | Participant Certificate | events/ASC/EventsCertificateDownload |
| 117 | eCertificates | event/uday/certificates |
| 118 | Event Requisition | event/swf/loadRequisitionPage |
| 119 | Event Attendance | event/swf/loadEventAttendance |
| 120 | Event Registration | event/swf/loadEventRegistration |
| 121 | Club/Chapter Enrollment | event/swf/student/loadClubChapterEnrollmentPage |
| 122 | Student Outbound Request | ir/student/visitingRequest |
| 123 | Change Password | controlpanel/ChangePassword |
| 124 | Update LoginID | controlpanel/ChangePreferredUser |

Dashboard Endpoints:
| Sl.No | Name | Endpoint |
|-------|------|----------|
| 125 | Proctor Message | get/dashboard/proctor/message |
| 126 | CGPA and Credits | get/dashboard/current/cgpa/credits |
| 127 | Course Details | get/dashboard/current/semester/course/details |
| 128 | Digital Assignments | get/upcoming/digital/assignments |
| 129 | Last Five Feedbacks | get/last/five/feedbacks |
| 130 | Scheduled Events | get/scheduled/events |


LOGIC:
final jsCode = '''
  (function() {
    try {

      var data = /* prepare request params */ like 'verifyMenu=true&authorizedID=' + \$('#authorizedIDX').val() + '&_csrf=' + \$('input[name="_csrf"]').val() + '&nocache=' + Date.now() + other + .. + .. ;
      var storeResponse = {};

      $.ajax({
        type: 'POST',
        url: /* endpoint URL */,
        data: data,
        async: false,
        success: function(res) {

          /* parse response */
          var doc = new DOMParser().parseFromString(res, 'text/html');
          // TODO extract desired text via querySelector, label loops, table rows
          // example:
          // storeResponse.field = doc.querySelector(/*selector*/)?.innerText.trim() || '';

        }
      });

      return JSON.stringify(storeResponse);

    } catch (e) {
      return JSON.stringify({ error: e.message });
    }
  })();
''';

*/
