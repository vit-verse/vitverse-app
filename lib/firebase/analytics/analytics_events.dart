/// Firebase Analytics events for VIT Connect
/// Focus: Screen views and critical user actions only
class AnalyticsEvents {
  // App Lifecycle
  static const String appStartup = 'app_startup';
  static const String appResume = 'app_resume';

  // Authentication
  static const String loginSuccess = 'login_success';
  static const String loginFailure = 'login_failure';
  static const String logout = 'logout';

  // Data Sync
  static const String dataSyncCompleted = 'data_sync_completed';
  static const String dataSyncFailed = 'data_sync_failed';

  // Errors (lightweight)
  static const String errorOccurred = 'error_occurred';
  static const String networkError = 'network_error';
}

/// Authentication events
enum AuthEvent {
  loginAttempt('login_attempt'),
  loginSuccess('login_success'),
  loginFailure('login_failure'),
  logout('logout'),
  captchaSolved('captcha_solved'),
  captchaFailed('captcha_failed'),
  semesterSelected('semester_selected');

  const AuthEvent(this.name);
  final String name;
}

/// Data sync events
enum DataSyncEvent {
  syncStarted('data_sync_started'),
  syncCompleted('data_sync_completed'),
  syncFailed('data_sync_failed'),
  phase1Completed('phase1_completed'),
  phase2Completed('phase2_completed');

  const DataSyncEvent(this.name);
  final String name;
}

/// Error events (lightweight)
enum ErrorEvent {
  errorOccurred('error_occurred'),
  networkError('network_error');

  const ErrorEvent(this.name);
  final String name;
}

/// App lifecycle events
enum AppLifecycleEvent {
  appStartup('app_startup'),
  appResume('app_resume');

  const AppLifecycleEvent(this.name);
  final String name;
}
