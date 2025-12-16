// Authentication constants
class AuthConstants {
  // VTOP URLs
  static const String vtopBaseUrl = 'https://vtopcc.vit.ac.in/vtop';
  static const String openPagePath = '';
  static const String loginPagePath = '/login';
  static const String contentPath = '/content';
  static const String newCaptchaPath = '/vtop/get/new/captcha';

  // Storage keys
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keySemester = 'semester';
  static const String keyIsSignedIn = 'isVTOPSignedIn';
  static const String keyLastSyncTimestamp = 'lastSyncTimestamp';
  static const String keyOCREnabled = 'ocr_enabled';
  static const String keyAutoSemesterEnabled = 'auto_semester_enabled';

  // Progress tracking (from DataServiceConstants)
  static const int maxProgress = 14; // Total steps: Phase 1 (5) + Phase 2 (9)
  static const int phase1Steps = 5; // Essential data for home screen
  static const int phase2Steps = 9; // Secondary data loaded in background
  static const int totalAuthSteps = 8; // Auth flow steps (1-8)

  // Auth step labels (for notifications)
  static const String authStepConnecting = 'Connecting to VTOP...';
  static const String authStepAuthenticating = 'Authenticating...';
  static const String authStepLoginSuccess = 'Login successful!';
  static const String authStepFetchingSemesters = 'Fetching semesters...';
  static const String authStepSemesterSelected = 'Semester selected';
  static const String authStepDownloadingData = 'Downloading essential data...';
  static const String authStepDataComplete = 'Data download complete';
  static const String authStepComplete = 'Authentication complete';

  // Page detection limits
  static const int maxLandingPageAttempts = 5;
  static const Duration landingPageTimeout = Duration(seconds: 5);
}
