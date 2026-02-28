import '../../../core/utils/logger.dart';

// Auth & OCR error codes (0-100)
class AuthError {
  // SUCCESS / UNKNOWN (0)
  static const int success = 0;

  // LOGIN ERRORS (1-5)
  static const int invalidCaptcha = 1;
  static const int invalidCredentials = 2;
  static const int accountLocked = 3;
  static const int maxAttempts = 4;
  static const int unknownError = 5;

  // CONNECTION ERRORS (51-60)
  static const int serverConnection = 51;
  static const int userAgentBlocked = 52;
  static const int networkTimeout = 53;
  static const int credentialsFetch = 54;
  static const int sslHandshakeError = 55;
  static const int httpError = 56;

  // PAGE NAVIGATION ERRORS (61-70)
  static const int openSignIn = 61;
  static const int captchaTypeDetection = 62;
  static const int captchaImageExtraction = 63;
  static const int loginSubmission = 64;
  static const int semesterFetch = 65;

  // OCR ERRORS (71-80)
  static const int ocrProcessing = 71;
  static const int ocrTimeout = 72;
  static const int ocrImageConversion = 73;

  // Error messages
  static const Map<int, String> messages = {
    // Success case
    success: 'Operation completed successfully',

    // Login errors
    invalidCaptcha: 'Invalid captcha. Please try again.',
    invalidCredentials: 'Invalid username or password.',
    accountLocked: 'Your account is locked.',
    maxAttempts: 'Maximum login attempts reached. Reset your password on VTOP.',
    unknownError: 'An unknown error occurred.',

    // Connection errors
    serverConnection: 'Could not connect to server.',
    userAgentBlocked: 'User agent blocked. Refreshing...',
    networkTimeout: 'Network timeout. Please try again.',
    credentialsFetch: 'Failed to fetch credentials.',
    sslHandshakeError: 'SSL connection error. Retrying...',
    httpError: 'HTTP error occurred.',

    // Navigation errors
    openSignIn: 'Error opening sign in page.',
    captchaTypeDetection: 'Error detecting captcha type.',
    captchaImageExtraction: 'Error loading captcha image.',
    loginSubmission: 'Error submitting login.',
    semesterFetch: 'Error fetching semesters.',

    // OCR errors
    ocrProcessing: 'OCR processing failed.',
    ocrTimeout: 'OCR timeout.',
    ocrImageConversion: 'Error converting image for OCR.',
  };

  // Get error category for Crashlytics
  static String getErrorType(int code) {
    if (code == 0) return 'success';
    if (code >= 1 && code <= 5) return 'login_error';
    if (code >= 51 && code <= 60) return 'connection_error';
    if (code >= 61 && code <= 70) return 'navigation_error';
    if (code >= 71 && code <= 80) return 'ocr_error';
    return 'unknown_error';
  }

  // Get error message
  static String getMessage(int code) {
    return messages[code] ?? 'Error $code occurred.';
  }

  // Simple error handler
  static void handle(int code, String? details, Function()? onReload) {
    final message = getMessage(code);

    // Don't log success as error!
    if (code == 0) {
      Logger.d('Auth', 'Operation successful');
      return;
    }

    Logger.e('Auth', '❌ Error $code: $message');
    if (details != null) {
      Logger.e('Auth', '❌ Details: $details');
    }

    // Call reload callback if provided
    onReload?.call();
  }

  // Check if error is retryable
  static bool isRetryable(int code) {
    return code == invalidCaptcha ||
        code == serverConnection ||
        code == networkTimeout ||
        code == sslHandshakeError ||
        code >= 71; // OCR errors are retryable
  }
}
