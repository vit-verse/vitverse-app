import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/auth_states.dart';
import 'auth_constants.dart';
import 'auth_errors.dart';
import 'auth_handler.dart';
import 'user_agent_service.dart';
import '../ocr_custom/captcha_solver.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/logger.dart';
import '../../../firebase/analytics/analytics_service.dart';
import '../../../firebase/crashlytics/crashlytics_service.dart';
import '../../../firebase/analytics/analytics_events.dart';

/// User session data model
class UserSession {
  final String username;
  final String? studentName;
  final String? registrationNumber;
  final String? semesterName;
  final String? semesterID;
  final DateTime loginTime;
  final DateTime lastRefresh;

  UserSession({
    required this.username,
    this.studentName,
    this.registrationNumber,
    this.semesterName,
    this.semesterID,
    required this.loginTime,
    required this.lastRefresh,
  });
}

/// Page state enumeration
enum PageState { landing, login, home }

/// 1. VTOP authentication service - handles login and session management
class VTOPAuthService extends ChangeNotifier {
  static VTOPAuthService? _instance;
  static VTOPAuthService get instance => _instance ??= VTOPAuthService._();

  VTOPAuthService._() {
    _notificationService.setOnCancelSyncCallback(() => abortAuthentication());
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();
  final VTOPAuthHandler _authHandler = VTOPAuthHandler.instance;

  WebViewController? _webView;
  PageState? _pageState;
  AuthState _authState = AuthState.idle;

  String? _username;
  String? _password;
  String? _semesterID;
  Map<String, String> _semesters = {};

  CaptchaType _captchaType = CaptchaType.defaultCaptcha;
  Uint8List? _captchaImage;
  bool _isOCREnabled = true;
  bool _isAutoSemesterEnabled = true;
  String? _ocrRecognizedText;
  String? _statusMessage;
  String? _errorMessage;

  int _landingPageAttempts = 0;
  bool _isAuthenticating = false;
  bool _reCaptchaTokenSubmitted = false;
  bool _suppressUIUpdates =
      false; // Prevent UI updates during internal operations
  DateTime? _loginStartTime;

  AuthState get authState => _authState;
  int get progress => _authHandler.progress;
  CaptchaType get captchaType => _captchaType;
  Uint8List? get captchaImage => _captchaImage;
  bool get isOCREnabled => _isOCREnabled;
  bool get isAutoSemesterEnabled => _isAutoSemesterEnabled;
  String? get ocrRecognizedText => _ocrRecognizedText;
  bool get isPhase2Running => _authHandler.isPhase2Running;
  bool get isBackgroundSyncing => _authHandler.isBackgroundSyncing;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  List<String> get availableSemesters => _semesters.keys.toList();
  String? get currentSyncPhase => _authHandler.currentSyncPhase;

  UserSession? get currentSession {
    if (_username == null || _username!.isEmpty) return null;

    return UserSession(
      username: _username!,
      studentName: null,
      registrationNumber: _username,
      semesterName: _semesters.keys.isNotEmpty ? _semesters.keys.first : null,
      semesterID: _semesterID,
      loginTime: DateTime.now(),
      lastRefresh: DateTime.now(),
    );
  }

  /// 1. Initialize authentication service
  Future<void> initialize() async {
    try {
      await CustomCaptchaSolver.instance.initialize();
      await _authHandler.initialize();

      final userAgent =
          await UserAgentService.instance.getAuthorizedUserAgent();

      _webView =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setUserAgent(userAgent)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: _onPageFinished,
                onWebResourceError: _handleWebResourceError,
                onHttpError: _handleHttpError,
              ),
            )
            // to capture reCaptcha
            ..addJavaScriptChannel(
              'FlutterCaptcha',
              onMessageReceived: (JavaScriptMessage message) {
                final token = message.message;
                Logger.d(
                  'Auth',
                  'Received reCAPTCHA message: ${token.length > 50 ? "${token.substring(0, 50)}..." : token}',
                );

                if (token == 'TIMEOUT') {
                  Logger.w(
                    'Auth',
                    'reCAPTCHA timed out after multiple attempts',
                  );
                  _setState(AuthState.error);
                  _errorMessage =
                      'reCAPTCHA timed out. Please refresh and try again.';
                  notifyListeners();
                } else if (token == 'GRECAPTCHA_NOT_READY') {
                  Logger.w('Auth', 'reCAPTCHA not ready');
                  _setState(AuthState.error);
                  _errorMessage =
                      'reCAPTCHA failed to load. Please refresh and try again.';
                  notifyListeners();
                } else if (token.startsWith('ERROR:')) {
                  Logger.e('Auth', 'reCAPTCHA error: $token');
                  _setState(AuthState.error);
                  _errorMessage =
                      'reCAPTCHA error. Please refresh and try again.';
                  notifyListeners();
                } else if (token.length > 20) {
                  if (_reCaptchaTokenSubmitted) {
                    Logger.d(
                      'Auth',
                      'reCAPTCHA token already submitted, ignoring duplicate',
                    );
                    return;
                  }
                  _reCaptchaTokenSubmitted = true;
                  Logger.success(
                    'Auth',
                    'reCAPTCHA token received, submitting...',
                  );
                  solveCaptcha(token);
                } else {
                  Logger.w('Auth', 'Invalid reCAPTCHA token received: $token');
                  _setState(AuthState.error);
                  _errorMessage =
                      'Invalid reCAPTCHA response. Please try again.';
                  notifyListeners();
                }
              },
            );

      await _loadStoredCredentials();
      await _checkAutoLogin();

      Logger.d('Auth', 'Initialized successfully');
    } catch (e) {
      Logger.e('Auth', 'Initialization failed', e);
      AuthError.handle(AuthError.serverConnection, e.toString(), null);
    }
  }

  // CHECK PREVIOUS SESSION
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSignedIn = prefs.getBool(AuthConstants.keyIsSignedIn) ?? false;
      final lastSyncTimestamp = prefs.getInt('lastSyncTimestamp') ?? 0;

      if (!isSignedIn || lastSyncTimestamp == 0) {
        Logger.d('Auth', 'No previous session found');
        return;
      }

      // Check if we have cached data to show
      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
      final now = DateTime.now();
      final daysSinceSync = now.difference(lastSync).inDays;

      if (daysSinceSync > 30) {
        Logger.d(
          'Auth',
          'Cached data too old (${daysSinceSync} days), clearing session',
        );
        await prefs.setBool(AuthConstants.keyIsSignedIn, false);
        return;
      }

      // Show last synced data (user can refresh manually if needed)
      Logger.i(
        'Auth',
        'Previous session found - showing last synced data (${daysSinceSync} days old)',
      );
      _setState(AuthState.complete);
    } catch (e) {
      Logger.e('Auth', 'Session check failed', e);
    }
  }

  // LOAD CREDENTIALS
  Future<void> _loadStoredCredentials() async {
    try {
      _username = await _secureStorage.read(key: AuthConstants.keyUsername);
      _password = await _secureStorage.read(key: AuthConstants.keyPassword);

      final prefs = await SharedPreferences.getInstance();
      _isOCREnabled = prefs.getBool(AuthConstants.keyOCREnabled) ?? true;
      _isAutoSemesterEnabled =
          prefs.getBool(AuthConstants.keyAutoSemesterEnabled) ?? true;
    } catch (e) {
      Logger.e('Auth', 'Failed to load credentials', e);
    }
  }

  // ERROR HANDLERS

  /// Handle WebView resource errors (SSL, connection resets, etc.)
  void _handleWebResourceError(WebResourceError error) {
    final errorCode = error.errorCode;
    final description = error.description;
    final url = error.url ?? '';

    // SSL errors: net_error -101, -100, -200
    if (errorCode == -101 || errorCode == -100 || errorCode == -200) {
      Logger.d('Auth', 'SSL error (code: $errorCode) - continuing anyway');
      return; // Don't stop auth flow
    }

    // Connection reset errors
    if (errorCode == -6) {
      // ERR_CONNECTION_RESET
      Logger.w('Auth', 'Connection reset - may retry');
      return;
    }

    // Ignore VTOP's broken assets and JavaScript errors that don't affect functionality
    if (url.contains('/get/jq/js/') ||
        url.contains('/assets/js/') ||
        url.contains('/assets/css/') ||
        url.contains('pdf.js') ||
        url.contains('dashboard.css') ||
        url.contains('.css') ||
        url.contains('.js') ||
        url.contains('.png') ||
        url.contains('.jpg') ||
        url.contains('.ico') ||
        url.contains('.woff') ||
        url.contains('.ttf') ||
        description.contains('addEventListener') ||
        description.contains('jQuery') ||
        description.contains('innerHTML') ||
        description.contains('XMLHttpRequestResponseType') ||
        description.contains('moz-chunked-arraybuffer') ||
        description.contains('MIME type') ||
        description.contains('stylesheet') ||
        description.contains('Refused to apply style') ||
        description.contains('Cannot read properties of null') ||
        description.contains('Cannot set properties of null')) {
      // Don't log these at all - they're just VTOP's broken assets/JS that don't affect functionality
      return;
    }

    // Other errors - log but don't stop
    Logger.w('Auth', 'WebView resource error: $description (code: $errorCode)');
  }

  /// Handle HTTP errors (404, 500, etc.)
  void _handleHttpError(HttpResponseError error) {
    final statusCode = error.response?.statusCode;
    final uri = error.response?.uri?.toString() ?? '';

    // Ignore 404s for assets, JS libraries, and CSS - VTOP has broken references
    if (statusCode == 404 &&
        (uri.contains('/assets/') ||
            uri.contains('/get/jq/js/') ||
            uri.contains('dashboard.css') ||
            uri.contains('pdf.js') ||
            uri.contains('.css') ||
            uri.contains('.js') ||
            uri.contains('.png') ||
            uri.contains('.jpg') ||
            uri.contains('.ico') ||
            uri.contains('.woff') ||
            uri.contains('.ttf') ||
            uri.contains('vtopcc.vit.ac.in'))) {
      // Don't log these at all - they're just VTOP's broken asset references
      return;
    }

    // Ignore content page errors after successful login (VTOP has JS issues)
    if (uri.contains('/vtop/content') && statusCode == 404) {
      return;
    }

    // Log other HTTP errors (but filter out common VTOP issues)
    if (statusCode != null && statusCode >= 400) {
      if (statusCode == 404 && uri.contains('vtopcc.vit.ac.in')) {
        return;
      }

      Logger.w('Auth', 'HTTP error: $statusCode - $uri');

      // Only record critical errors (5xx) in Crashlytics, and not from VTOP domain
      if (statusCode >= 500 && !uri.contains('vtopcc.vit.ac.in')) {
        CrashlyticsService.recordError(
          Exception('HTTP $statusCode on $uri'),
          StackTrace.current,
        );
      }
    }
  }

  // AUTHENTICATE
  Future<void> authenticate(String username, String password) async {
    if (_isAuthenticating) {
      Logger.w('Auth', 'Authentication already in progress');
      return;
    }

    // Ensure auth service is initialized
    if (_webView == null) {
      Logger.w('Auth', 'WebView not initialized, initializing now...');
      await initialize();
      if (_webView == null) {
        Logger.e('Auth', '❌ Failed to initialize WebView');
        _setState(AuthState.error);
        _errorMessage = 'Failed to initialize authentication system';
        notifyListeners();
        return;
      }
    }

    // Use current settings (don't reload to avoid toggle bug)
    Logger.d(
      'Auth',
      'Using current settings: OCR=$_isOCREnabled, AutoSemester=$_isAutoSemesterEnabled',
    );

    _isAuthenticating = true;
    _reCaptchaTokenSubmitted =
        false; // Reset reCAPTCHA flag for new authentication
    Logger.d('Auth', 'Starting authentication for: $username');

    // Track login start time for analytics
    _loginStartTime = DateTime.now();

    // Track login attempt
    await AnalyticsService.instance.logAuth(
      AuthEvent.loginAttempt,
      parameters: {
        'ocr_enabled': _isOCREnabled ? 'yes' : 'no',
        'auto_semester': _isAutoSemesterEnabled ? 'yes' : 'no',
      },
    );

    _username = username;
    _password = password;

    // Store credentials
    await _secureStorage.write(key: AuthConstants.keyUsername, value: username);
    await _secureStorage.write(key: AuthConstants.keyPassword, value: password);

    // Reset state
    _resetState();
    _setState(AuthState.loading);

    await _notificationService.showProgressNotification(
      currentStep: 1,
      totalSteps: AuthConstants.totalAuthSteps,
      stepLabel: AuthConstants.authStepConnecting,
    );

    await _reloadPage(AuthConstants.openPagePath, true);
  }

  // PAGE FINISHED
  Future<void> _onPageFinished(String url) async {
    Logger.d(
      'Auth',
      ' Page loaded: ${url.length > 100 ? url.substring(0, 100) + "..." : url}',
    );
    await _detectPageState();
  }

  /// 2. Detect page state
  Future<void> _detectPageState() async {
    final String script = '''
      (function() {
        const response = { page_type: 'LANDING' };
        
        if (document.body === null) {
          response.page_type = 'BODY_NOT_READY';
        } else if (\$('input[id="authorizedIDX"]').length === 1) {
          response.page_type = 'HOME';
        } else if (\$('form[id="vtopLoginForm"]').length === 1) {
          response.page_type = 'LOGIN';
        }
        
        return response;
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);
        final pageType = response['page_type'];

        switch (pageType) {
          case 'LANDING':
            if (_landingPageAttempts >= AuthConstants.maxLandingPageAttempts) {
              Logger.e(
                'Auth',
                'Could not connect to server after ${AuthConstants.maxLandingPageAttempts} attempts',
              );
              _setState(AuthState.error);
              _errorMessage = 'Could not connect to server';
              return;
            }
            _handleLandingPage();
            _landingPageAttempts++;
            _pageState = PageState.landing;
            break;
          case 'LOGIN':
            if (_pageState == PageState.login) break;
            _handleLoginPage();
            _pageState = PageState.login;
            break;
          case 'HOME':
            if (_pageState == PageState.home) break;
            _handleHomePage();
            _pageState = PageState.home;
            break;
          case 'BODY_NOT_READY':
            break;
          default:
            Logger.w('Auth', 'Unknown page type: $pageType');
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Page detection failed', e);
    }
  }

  // HANDLE LANDING PAGE
  void _handleLandingPage() {
    _landingPageAttempts++;
    Logger.d('Auth', 'Landing page (attempt $_landingPageAttempts)');

    if (_landingPageAttempts > AuthConstants.maxLandingPageAttempts) {
      Logger.w(
        'Auth',
        'Max landing attempts (${AuthConstants.maxLandingPageAttempts}), going to login directly',
      );
      _reloadPage(AuthConstants.loginPagePath, true);
      _landingPageAttempts = 0; // Reset counter
      return;
    }

    // Try to open sign in with timeout
    Future.delayed(AuthConstants.landingPageTimeout, () {
      if (_pageState == PageState.landing) {
        Logger.w(
          'Auth',
          'Landing page timeout (${AuthConstants.landingPageTimeout.inSeconds}s), retrying...',
        );
        _reloadPage(AuthConstants.openPagePath, false);
      }
    });

    _openSignIn();
  }

  // OPEN SIGN IN
  Future<void> _openSignIn() async {
    const String script = r'''
      (function() {
        return new Promise((resolve) => {
          function waitForJQuery() {
            if (typeof $ !== 'undefined') {
              $.ajax({
                type: 'POST',
                url: '/vtop/prelogin/setup',
                data: $('#stdForm').serialize(),
                async: false,
                success: function(res) {
                  resolve({ success: true });
                },
                error: function() {
                  resolve({ success: false });
                }
              });
            } else {
              setTimeout(waitForJQuery, 100);
            }
          }
          waitForJQuery();
        });
      })();
    ''';

    try {
      await _webView?.runJavaScriptReturningResult(script);
      // Navigate to login
      await _reloadPage(AuthConstants.loginPagePath, false);
    } catch (e) {
      Logger.e('Auth', 'Open sign in failed', e);
      AuthError.handle(
        AuthError.openSignIn,
        e.toString(),
        () => _reloadPage(AuthConstants.loginPagePath, false),
      );
    }
  }

  // HANDLE LOGIN PAGE
  void _handleLoginPage() {
    _landingPageAttempts = 0;
    Logger.success('Auth', 'Reached login page');
    // Detect captcha type
    _getCaptchaType();
  }

  // GET CAPTCHA TYPE
  Future<void> _getCaptchaType() async {
    const String script = '''
      (function() {
        const response = { captcha_type: 'DEFAULT' };
        if (\$('input[id="gResponse"]').length === 1) {
          response.captcha_type = 'GRECAPTCHA';
        }
        return JSON.stringify(response);
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);

        if (response['captcha_type'] == 'DEFAULT') {
          _captchaType = CaptchaType.defaultCaptcha;
          await _getCaptcha();
        } else {
          _captchaType = CaptchaType.reCaptcha;
          await _executeCaptcha();
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Captcha type detection failed', e);
      AuthError.handle(AuthError.captchaTypeDetection, e.toString(), null);
    }
  }

  // GET CAPTCHA (Default image captcha)
  Future<void> _getCaptcha() async {
    const String script = '''
      (function() {
        return { captcha: \$('#captchaBlock img').get(0).src };
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);
        final captchaUrl = response['captcha'];

        if (captchaUrl != null &&
            captchaUrl.toString().startsWith('data:image')) {
          final base64Data = captchaUrl.toString().split(',')[1];
          _captchaImage = base64Decode(base64Data);

          // Always run OCR (regardless of toggle state)
          // If toggle is ON: auto-submit
          // If toggle is OFF: show dialog with prefilled text
          if (_captchaImage != null) {
            await _processWithOCR(_captchaImage!);
          } else {
            _setState(AuthState.captchaRequired);
          }
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Captcha extraction failed', e);
      AuthError.handle(AuthError.captchaImageExtraction, e.toString(), null);
    }
  }

  // PROCESS WITH OCR PIPELINE (Stage 1 (Accuracy 95%) → Stage 2 (Accuracy 40%) → Manual)
  Future<void> _processWithOCR(Uint8List captchaImage) async {
    Logger.d(
      'Auth',
      'Starting OCR pipeline: Stage 1 (Custom Model) → Stage 2 (Manual Input)',
    );

    try {
      // STAGE 1: Custom Neural Model (90-95% accuracy, 70% confidence threshold)
      Logger.d('Auth', ' Stage 1: Trying custom neural model...');
      final customResult = await CustomCaptchaSolver.instance.solveCaptcha(
        captchaImage,
      );

      if (customResult != null && customResult.meetsThreshold) {
        // Stage 1 Success - High confidence (≥70%)
        Logger.success(
          'Auth',
          ' Stage 1 SUCCESS: "${customResult.text}" (confidence: ${(customResult.averageConfidence * 100).toStringAsFixed(1)}%)',
        );
        _ocrRecognizedText = customResult.text;

        final confidenceValue = customResult.averageConfidence * 100;
        final safeConfidence =
            confidenceValue.isFinite ? confidenceValue.toInt() : 0;

        await AnalyticsService.instance.logAuth(
          AuthEvent.captchaSolved,
          parameters: {
            'method': 'custom_model',
            'confidence': safeConfidence,
            'text_length': customResult.text.length,
          },
        );

        if (_isOCREnabled) {
          // Auto-submit with high confidence
          await solveCaptcha(customResult.text);
        } else {
          // Just fill dialog
          _setState(AuthState.captchaRequired);
        }
        return;
      }

      // STAGE 2: Direct manual input (Stage 1 failed or low confidence)
      // Pre-fill dialog with Stage 1 prediction (if available) for user convenience
      if (customResult != null) {
        Logger.w(
          'Auth',
          ' Stage 1 LOW CONFIDENCE: "${customResult.text}" (${(customResult.averageConfidence * 100).toStringAsFixed(1)}%), showing manual input...',
        );
        _ocrRecognizedText = customResult.text;
      } else {
        Logger.w('Auth', ' Stage 1 FAILED, showing manual input...');
        _ocrRecognizedText = null;
      }

      await AnalyticsService.instance.logAuth(
        AuthEvent.captchaFailed,
        parameters: {
          'reason': 'stage1_low_confidence_or_failed',
          'stage1_confidence': (customResult?.averageConfidence ?? 0.0) * 100,
          'prefilled': customResult != null,
          'requires_manual_input': true,
        },
      );
      _setState(AuthState.captchaRequired);
    } catch (e) {
      Logger.e('Auth', 'OCR pipeline error', e);
      _ocrRecognizedText = null;
      _setState(AuthState.captchaRequired);
    }
  }

  //  EXECUTE CAPTCHA (reCAPTCHA)
  Future<void> _executeCaptcha() async {
    Logger.d('Auth', 'Executing reCAPTCHA');
    _setState(AuthState.captchaRequired);

    // Override the built-in validation function and execute reCAPTCHA
    final script = '''
      function callBuiltValidation(token) {
        if (token && token.length > 20) {
          FlutterCaptcha.postMessage(token);
        }
      }
      
      (function() {
        var attempts = 0;
        var maxAttempts = 5;
        
        function tryExecute() {
          attempts++;
          try {
            if (typeof grecaptcha !== 'undefined' && grecaptcha.execute) {
              console.log('Executing reCAPTCHA attempt', attempts);
              grecaptcha.execute();
              
              // Set up monitoring for the token
              var tokenSent = false;
              var tokenCheckInterval = setInterval(function() {
                if (tokenSent) {
                  clearInterval(tokenCheckInterval);
                  return;
                }
                var tokenField = document.getElementById('g-recaptcha-response');
                if (tokenField && tokenField.value && tokenField.value.length > 20) {
                  var token = tokenField.value;
                  tokenSent = true;
                  clearInterval(tokenCheckInterval);
                  console.log('reCAPTCHA token found:', token.substring(0, 50) + '...');
                  callBuiltValidation(token);
                  return;
                }
              }, 200);
              
              // Timeout for this attempt
              setTimeout(function() {
                clearInterval(tokenCheckInterval);
                if (attempts < maxAttempts) {
                  console.log('reCAPTCHA attempt', attempts, 'timed out, retrying...');
                  setTimeout(tryExecute, 2000);
                } else {
                  console.log('All reCAPTCHA attempts failed');
                  FlutterCaptcha.postMessage('TIMEOUT');
                }
              }, 15000);
            } else {
              console.log('grecaptcha not ready, attempt', attempts);
              if (attempts < maxAttempts) {
                setTimeout(tryExecute, 2000);
              } else {
                FlutterCaptcha.postMessage('GRECAPTCHA_NOT_READY');
              }
            }
          } catch (err) {
            console.log('reCAPTCHA execution error:', err);
            if (attempts < maxAttempts) {
              setTimeout(tryExecute, 2000);
            } else {
              FlutterCaptcha.postMessage('ERROR:' + err.message);
            }
          }
        }
        
        // Start first attempt
        tryExecute();
      })();
    ''';

    try {
      await _webView?.runJavaScript(script);
      Logger.success(
        'Auth',
        'reCAPTCHA script injected, waiting for completion...',
      );
    } catch (e) {
      Logger.e('Auth', 'reCAPTCHA execution failed', e);
      _setState(AuthState.error);
      _errorMessage = 'reCAPTCHA execution failed: ${e.toString()}';
      notifyListeners();
    }
  }

  // SOLVE CAPTCHA (Submit login)
  Future<void> solveCaptcha(String captchaSolution) async {
    _ocrRecognizedText = null;
    _setState(AuthState.loading);

    await _notificationService.showProgressNotification(
      currentStep: 2,
      totalSteps: AuthConstants.totalAuthSteps,
      stepLabel: AuthConstants.authStepAuthenticating,
    );

    // Determine if reCAPTCHA or manual
    final bool isReCaptcha = captchaSolution.length > 100;
    String processedCaptcha;

    if (isReCaptcha) {
      processedCaptcha = captchaSolution; // Use raw token
      Logger.d(
        'Auth',
        'Using reCAPTCHA token (${processedCaptcha.length} chars)',
      );
    } else {
      processedCaptcha =
          captchaSolution
              .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
              .trim()
              .toUpperCase();
      Logger.d('Auth', 'Using manual captcha: "$processedCaptcha"');
    }

    final script = '''
      (function() {
        if (typeof captchaInterval != 'undefined') clearInterval(captchaInterval);
        if (typeof executeInterval != 'undefined') clearInterval(executeInterval);
        
        \$('#vtopLoginForm [name="username"]').val('${_username?.replaceAll("'", "\\\\\\\\'")}');
        \$('#vtopLoginForm [name="password"]').val('${_password?.replaceAll("'", "\\\\\\\\'")}');
        \$('#vtopLoginForm [name="captchaStr"]').val('${processedCaptcha.replaceAll("'", "\\\\\\\\'")}');
        \$('#vtopLoginForm [name="gResponse"]').val('${processedCaptcha.replaceAll("'", "\\\\\\\\'")}');
        
        var response = { authorised: false, error_message: null, error_code: 0 };
        
        \$.ajax({
          type: 'POST',
          url: '/vtop/login',
          data: \$('#vtopLoginForm').serialize(),
          async: false,
          success: function(res) {
            if (res.search('___INTERNAL___RESPONSE___') == -1) {
              \$('#page_outline').html(res);
              if (res.includes('authorizedIDX')) {
                response.authorised = true;
                return;
              }
              
              var pageContent = res.toLowerCase();
              
              // Only check for specific error patterns, don't default to "unknown error"
              if (/invalid\\s*captcha/.test(pageContent)) {
                response.error_message = 'Invalid Captcha';
                response.error_code = 1;
              } else if (/invalid\\s*(user\\s*name|login\\s*id|user\\s*id)\\s*\\/\\s*password/.test(pageContent)) {
                response.error_message = 'Invalid Username / Password';
                response.error_code = 2;
              } else if (/account\\s*is\\s*locked/.test(pageContent)) {
                response.error_message = 'Account is locked';
                response.error_code = 3;
              } else if (/maximum\\s*fail\\s*attempts/.test(pageContent)) {
                response.error_message = 'Maximum login attempts reached';
                response.error_code = 4;
              } else if (pageContent.includes('login') && (pageContent.includes('error') || pageContent.includes('fail'))) {
                // Only report unknown error if page clearly indicates a login error
                response.error_message = 'Login failed';
                response.error_code = 5;
              }
              // If no specific error pattern is found, assume success (page might have JS errors but login worked)
            }
          }
        });
        
        return JSON.stringify(response);
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);

        if (response['authorised'] == true) {
          Logger.success('Auth', 'Login successful');

          // Track login success
          if (_loginStartTime != null) {
            final loginDuration = DateTime.now().difference(_loginStartTime!);
            await AnalyticsService.instance.logAuth(
              AuthEvent.loginSuccess,
              parameters: {
                'duration_ms': loginDuration.inMilliseconds,
                'ocr_used': _isOCREnabled ? 'yes' : 'no',
              },
            );
          }

          await _notificationService.showProgressNotification(
            currentStep: 3,
            totalSteps: AuthConstants.totalAuthSteps,
            stepLabel: AuthConstants.authStepLoginSuccess,
          );

          // Navigate to home
          await _reloadPage(AuthConstants.contentPath, false);
        } else {
          dynamic rawErrorCode = response['error_code'];
          int errorCode;
          if (rawErrorCode == null || rawErrorCode == 0) {
            errorCode = AuthError.unknownError; // Default to 5
          } else {
            errorCode = rawErrorCode as int;
          }

          final errorMessage =
              response['error_message'] ?? AuthError.getMessage(errorCode);
          final errorType = AuthError.getErrorType(errorCode);

          Logger.w('Auth', 'Login failed: $errorMessage (code: $errorCode)');

          // Track login failure
          await CrashlyticsService.recordError(
            Exception(
              'Login failed: $errorMessage (Type: $errorType, Stage: login_submission)',
            ),
            StackTrace.current,
          );
          await AnalyticsService.instance.logAuth(
            AuthEvent.loginFailure,
            parameters: {
              'error_code': errorCode,
              'error_type': errorType,
              'error_message': errorMessage,
            },
          );

          if (errorCode == AuthError.invalidCaptcha) {
            // Reload for new captcha !
            await _reloadPage(AuthConstants.loginPagePath, false);
          } else if (errorCode == AuthError.invalidCredentials) {
            // Invalid credentials - stop retrying and show error
            _errorMessage = errorMessage;
            _isAuthenticating = false;
            _setState(AuthState.error);
            AuthError.handle(errorCode, errorMessage, null);
            return; // Exit immediately to prevent auto-retry
          } else if (errorCode == AuthError.accountLocked ||
              errorCode == AuthError.maxAttempts) {
            // Account locked or max attempts - stop immediately
            _errorMessage = errorMessage;
            _isAuthenticating = false;
            _setState(AuthState.error);
            AuthError.handle(errorCode, errorMessage, null);
            return; // Exit immediately for critical errors
          } else {
            // Other errors - show error but don't stop
            AuthError.handle(errorCode, errorMessage, null);
          }
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Login submission failed', e);
      AuthError.handle(AuthError.loginSubmission, e.toString(), null);
    }
  }

  // HANDLE HOME PAGE
  void _handleHomePage() {
    _landingPageAttempts = 0;
    Logger.success('Auth', 'Reached home page');
    // Extract semesters
    _getSemesters();
  }

  /// 3. Get available semesters
  Future<void> _getSemesters() async {
    await _notificationService.showProgressNotification(
      currentStep: 4,
      totalSteps: AuthConstants.totalAuthSteps,
      stepLabel: AuthConstants.authStepFetchingSemesters,
    );

    const String script = '''
      (function() {
        var data = 'verifyMenu=true&authorizedID=' + \$('#authorizedIDX').val() + 
                   '&_csrf=' + \$('input[name="_csrf"]').val() + 
                   '&nocache=' + new Date().getTime();
        var response = {};
        
        \$.ajax({
          type: 'POST',
          url: 'academics/common/StudentTimeTableChn',
          data: data,
          async: false,
          success: function(res) {
            //  CHECK FOR BLOCKED USER AGENT 
            if (res.toLowerCase().includes('not authorized')) {
              response.error_code = 1;
              response.error_message = 'Unauthorised user agent';
              return;
            }
            
            if (res.toLowerCase().includes('time table')) {
              var doc = new DOMParser().parseFromString(res, 'text/html');
              var semesterSelect = doc.getElementById('semesterSubId');
              if (semesterSelect) {
                var options = semesterSelect.getElementsByTagName('option');
                var semesters = [];
                
                for (var i = 0; i < options.length; ++i) {
                  if (!options[i].value || options[i].value.trim() === '') continue;
                  semesters.push({
                    name: options[i].innerText.trim(),
                    id: options[i].value.trim()
                  });
                }
                response.semesters = semesters;
              }
            }
          }
        });
        
        return JSON.stringify(response);
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);

        // HANDLE BLOCKED USER AGENT
        if (response['error_code'] == 1) {
          Logger.w('Auth', '🚫 User agent blocked, rotating to new one...');

          // Track user agent blocked
          await CrashlyticsService.recordError(
            Exception('User agent blocked by VTOP (stage: semester_fetch)'),
            StackTrace.current,
          );

          final newUA =
              await UserAgentService.instance.handleBlockedUserAgent();
          await _webView?.setUserAgent(newUA);

          // Retry authentication from login
          Logger.i('Auth', 'Retrying authentication with new UA...');
          _reloadPage(AuthConstants.loginPagePath, true);
          return;
        }

        final semestersData = response['semesters'];

        if (semestersData is List && semestersData.isNotEmpty) {
          _semesters.clear();
          List<String> semesterNames = [];

          for (var sem in semestersData) {
            if (sem is Map<String, dynamic>) {
              final name = sem['name']?.toString().trim();
              final id = sem['id']?.toString().trim();
              if (name != null &&
                  id != null &&
                  name.isNotEmpty &&
                  id.isNotEmpty) {
                semesterNames.add(name);
                _semesters[name] = id;
              }
            }
          }

          Logger.d('Auth', 'Found ${semesterNames.length} semesters');

          // Save available semesters to SharedPreferences
          if (semesterNames.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();

            // Save semester names array
            await prefs.setString(
              'available_semesters',
              jsonEncode(semesterNames),
            );

            // Save semester map (name -> id mapping)
            await prefs.setString('semester_map', jsonEncode(_semesters));

            Logger.i(
              'Auth',
              'Saved ${semesterNames.length} semesters to SharedPreferences',
            );
            Logger.d('Auth', 'Semester names: ${semesterNames.join(", ")}');
            Logger.d('Auth', 'Semester IDs: ${_semesters.values.join(", ")}');
          }

          if (semesterNames.isNotEmpty) {
            if (_isAutoSemesterEnabled) {
              // Auto-select first semester (current)
              final currentSemester = semesterNames.first;
              Logger.d('Auth', 'Auto-selecting: $currentSemester');
              await selectSemester(currentSemester);
            } else {
              // Manual selection required - show dialog
              Logger.d('Auth', 'Manual semester selection required');
              _setState(AuthState.semesterSelection);
            }
          } else {
            Logger.w('Auth', 'No valid semesters found');
            _setState(AuthState.error);
          }
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Semester fetch failed', e);
      AuthError.handle(AuthError.semesterFetch, e.toString(), null);
    }
  }

  /// 4. Select semester and start data download
  Future<void> selectSemester(String semesterName) async {
    try {
      _semesterID = _semesters[semesterName];
      if (_semesterID == null) {
        throw Exception('Semester ID not found');
      }

      await AnalyticsService.instance.logAuth(
        AuthEvent.semesterSelected,
        parameters: {
          'semester_name': semesterName,
          'semester_id': _semesterID!,
        },
      );

      await _notificationService.showProgressNotification(
        currentStep: 5,
        totalSteps: AuthConstants.totalAuthSteps,
        stepLabel: AuthConstants.authStepSemesterSelected,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthConstants.keyIsSignedIn, true);
      await prefs.setString(AuthConstants.keySemester, semesterName);

      _setState(AuthState.dataDownloading);

      await _notificationService.showProgressNotification(
        currentStep: 6,
        totalSteps: AuthConstants.totalAuthSteps,
        stepLabel: AuthConstants.authStepDownloadingData,
      );

      await _authHandler.downloadPhase1Data(
        webView: _webView!,
        semesterID: _semesterID!,
      );

      await _notificationService.showProgressNotification(
        currentStep: 7,
        totalSteps: AuthConstants.totalAuthSteps,
        stepLabel: AuthConstants.authStepDataComplete,
      );

      _setState(AuthState.complete);
      _isAuthenticating = false;

      await _notificationService.showProgressNotification(
        currentStep: 8,
        totalSteps: AuthConstants.totalAuthSteps,
        stepLabel: AuthConstants.authStepComplete,
      );

      // Start Phase 2 immediately - AuthHandler has its own stabilization delay
      _authHandler.startPhase2Background(
        webView: _webView!,
        semesterID: _semesterID!,
      );
    } catch (e) {
      Logger.e('Auth', 'Semester selection failed', e);
      CrashlyticsService.recordError(
        Exception('Semester selection failed: ${e.toString()}'),
        StackTrace.current,
      );
      _errorMessage = 'Data sync failed: ${e.toString()}';
      _setState(AuthState.error);
    }
  }

  /// 5. Background sync for home screen refresh
  Future<bool> backgroundSync({
    String? semesterName,
    Function(bool isSyncing)? onSyncStateChanged,
    Function(String error, {String? errorType})? onError,
    Function(String message)? onStatusUpdate,
  }) async {
    return await _authHandler.backgroundSync(
      authenticateCallback: () async {
        final credentials = await _getSavedCredentials();
        final username = credentials['username'];
        final password = credentials['password'];

        if (username == null ||
            password == null ||
            username.isEmpty ||
            password.isEmpty) {
          return false;
        }

        if (_isAuthenticating) return false;

        _isAuthenticating = true;
        _suppressUIUpdates = true; // Prevent UI toggle updates during sync

        final previousOCR = _isOCREnabled;
        final previousAutoSemester = _isAutoSemesterEnabled;

        // Temporarily override for reliable background sync
        _isOCREnabled = true;
        _isAutoSemesterEnabled = false;

        _username = username;
        _password = password;
        _resetState();
        _setState(AuthState.loading);

        await _reloadPage(AuthConstants.openPagePath, true);

        while (true) {
          await Future.delayed(const Duration(seconds: 1));
          if (_authState == AuthState.semesterSelection) {
            final prefs = await SharedPreferences.getInstance();
            final lastSemester = prefs.getString(AuthConstants.keySemester);
            final targetSemester = semesterName ?? lastSemester;

            if (targetSemester != null &&
                _semesters.containsKey(targetSemester)) {
              await selectSemester(targetSemester);
              while (_authState != AuthState.complete &&
                  _authState != AuthState.error) {
                await Future.delayed(const Duration(seconds: 1));
              }
              // Restore original values and re-enable UI updates
              _isOCREnabled = previousOCR;
              _isAutoSemesterEnabled = previousAutoSemester;
              _suppressUIUpdates = false;
              _isAuthenticating = false;
              _forceNotifyListeners(); // Force UI update with correct toggle values
              return _authState == AuthState.complete;
            }
            return false;
          }
          if (_authState == AuthState.error) {
            // Restore original values and re-enable UI updates
            _isOCREnabled = previousOCR;
            _isAutoSemesterEnabled = previousAutoSemester;
            _suppressUIUpdates = false;
            _isAuthenticating = false;
            _forceNotifyListeners(); // Force UI update with correct toggle values
            return false;
          }
        }
      },
      semesterName: semesterName,
      onSyncStateChanged: onSyncStateChanged,
      onError: onError,
      onStatusUpdate: onStatusUpdate,
    );
  }

  // UTILITIES

  void _resetState() {
    _landingPageAttempts = 0;
    _pageState = null;
    _semesters.clear();
  }

  Future<void> _reloadPage(String path, bool destroySession) async {
    try {
      if (_webView == null) {
        Logger.e('Auth', '❌ CRITICAL: WebView is NULL! Initializing now...');
        await initialize();
        if (_webView == null) {
          throw Exception('WebView initialization failed');
        }
      }

      _pageState = null;

      if (destroySession) {
        await _webView!.clearCache();
        await _webView!.clearLocalStorage();
        Logger.d('Auth', 'Session cleared');
      }

      final url = '${AuthConstants.vtopBaseUrl}$path';
      Logger.d('Auth', 'Loading: $url');
      await _webView!.loadRequest(Uri.parse(url));
    } catch (e, stack) {
      Logger.e('Auth', '❌ Page reload failed', e, stack);
      _setState(AuthState.error);
      _errorMessage = 'Failed to connect to VTOP: $e';
      notifyListeners();
    }
  }

  Map<String, dynamic> _parseJS(Object? result) {
    if (result == null) return {};

    String resultString = result.toString();
    if (resultString == 'null') return {};

    if (resultString.startsWith('"') && resultString.endsWith('"')) {
      resultString = resultString.substring(1, resultString.length - 1);
      resultString = resultString.replaceAll('\\"', '"');
      resultString = resultString.replaceAll('\\\\', '\\');
    }

    try {
      return jsonDecode(resultString) as Map<String, dynamic>;
    } catch (e) {
      Logger.e('Auth', 'JS parse failed', e);
      return {};
    }
  }

  void _setState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  Future<Map<String, String?>> _getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(
        key: AuthConstants.keyUsername,
      );
      final password = await _secureStorage.read(
        key: AuthConstants.keyPassword,
      );
      return {'username': username, 'password': password};
    } catch (e) {
      Logger.e('Auth', 'Failed to get credentials', e);
      return {'username': null, 'password': null};
    }
  }

  Future<void> abortAuthentication() async {
    try {
      Logger.w('Auth', 'Authentication aborted');
      _authHandler.cancelAllOperations();
      await _webView?.loadRequest(Uri.parse('about:blank'));
      _resetState();
      _setState(AuthState.idle);
      await _notificationService.dismissNotification();
      notifyListeners();
    } catch (e) {
      Logger.e('Auth', 'Abort failed', e);
    }
  }

  /// 6. Sign out and cleanup
  Future<void> signOut() async {
    try {
      await AnalyticsService.instance.logAuth(AuthEvent.logout);
      _authHandler.cancelAllOperations();

      final prefs = await SharedPreferences.getInstance();

      // 1. Clear authentication flag immediately
      await prefs.setBool(AuthConstants.keyIsSignedIn, false);

      // 2. Clear secure storage (credentials)
      await _secureStorage.deleteAll();

      // 3. Clear ONLY student-specific SharedPreferences keys
      final studentSpecificKeys = {
        'user_session',
        'student_profile',
        'semester',
        'available_semesters',
        'semester_map',
        'cgpa_summary',
        'manual_courses',
        'course_classifications',
        'current_semester_grades',
        'lastSyncTimestamp',
        'preserved_nickname',
        'duePayments',
        'user_agent_cache',
      };

      for (final key in studentSpecificKeys) {
        await prefs.remove(key);
      }

      // 4. Clear VIT Connect Database (all student academic data)
      final db = VitConnectDatabase.instance;
      await db.clearAllData();

      // 5. VitVerse Database - KEEP ALL (no clearing needed)
      // All VitVerse tables contain app-level data that should persist
      // including: calendar_cache, personal_events, selected_calendars,
      // app_preferences, lost_found_cache, cab_ride_cache, custom_themes, events_cache

      // 6. Reset authentication state
      _resetState();
      _setState(AuthState.idle);

      Logger.success('Auth', 'Logout completed successfully');
    } catch (e) {
      Logger.e('Auth', 'Sign out failed', e);
      rethrow;
    }
  }

  Future<void> refreshCaptcha() async {
    if (_captchaType != CaptchaType.defaultCaptcha) return;

    _setState(AuthState.loading);

    const String script = '''
      (function() {
        const xhttp = new XMLHttpRequest();
        return new Promise((resolve) => {
          xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
              const captchaBlock = document.getElementById("captchaBlock");
              if (captchaBlock) {
                captchaBlock.innerHTML = this.responseText;
                const img = document.querySelector('#captchaBlock img');
                resolve({ captcha: img ? img.src : null, success: true });
              }
            }
          };
          xhttp.open("GET", "/vtop/get/new/captcha", true);
          xhttp.send();
        });
      })();
    ''';

    try {
      final result = await _webView?.runJavaScriptReturningResult(script);
      if (result != null) {
        final response = _parseJS(result);
        final captchaUrl = response['captcha'];
        if (captchaUrl != null &&
            captchaUrl.toString().startsWith('data:image')) {
          final base64Data = captchaUrl.toString().split(',')[1];
          _captchaImage = base64Decode(base64Data);
          _ocrRecognizedText = null;
          _setState(AuthState.captchaRequired);
        }
      }
    } catch (e) {
      Logger.e('Auth', 'Captcha refresh failed', e);
    }
  }

  Future<void> setOCREnabled(bool enabled) async {
    try {
      _isOCREnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthConstants.keyOCREnabled, enabled);
      _forceNotifyListeners(); // Always notify UI for preference changes
      Logger.d('Auth', 'OCR enabled: $enabled');
    } catch (e) {
      Logger.e('Auth', 'Failed to set OCR', e);
    }
  }

  Future<bool> isSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AuthConstants.keyIsSignedIn) ?? false;
    } catch (e) {
      Logger.e('Auth', 'Sign-in check failed', e);
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    try {
      final username = await _secureStorage.read(
        key: AuthConstants.keyUsername,
      );
      return username != null && username.isNotEmpty;
    } catch (e) {
      Logger.e('Auth', 'Credential check failed', e);
      return false;
    }
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return await _getSavedCredentials();
  }

  Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: AuthConstants.keyUsername);
      await _secureStorage.delete(key: AuthConstants.keyPassword);
      Logger.d('Auth', 'Credentials cleared');
    } catch (e) {
      Logger.e('Auth', 'Failed to clear credentials', e);
    }
  }

  //  COMPATIBILITY STUBS FOR OTHER FEATURES

  /// Get basic user data - For home_page.dart, home_data_provider.dart, attendance_analytics_logic.dart
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = await _secureStorage.read(
        key: AuthConstants.keyUsername,
      );
      final semester = prefs.getString(AuthConstants.keySemester);

      return {
        'username': username ?? '',
        'registrationNumber': username ?? '',
        'semesterName': semester ?? '',
        'semesterID': _semesterID ?? '',
      };
    } catch (e) {
      Logger.e('Auth', 'Failed to get user data', e);
      return {
        'username': '',
        'registrationNumber': '',
        'semesterName': '',
        'semesterID': '',
      };
    }
  }

  // PREFERENCE TOGGLES
  Future<void> toggleAutoCaptcha(bool enabled) async {
    try {
      _isOCREnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthConstants.keyOCREnabled, enabled);
      Logger.d('Auth', 'Auto-captcha ${enabled ? "enabled" : "disabled"}');
      _forceNotifyListeners(); // Always notify UI for user-initiated toggle changes
    } catch (e) {
      Logger.e('Auth', 'Failed to toggle auto-captcha', e);
    }
  }

  Future<void> toggleAutoSemester(bool enabled) async {
    try {
      _isAutoSemesterEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthConstants.keyAutoSemesterEnabled, enabled);
      Logger.d('Auth', 'Auto-semester ${enabled ? "enabled" : "disabled"}');
      _forceNotifyListeners(); // Always notify UI for user-initiated toggle changes
    } catch (e) {
      Logger.e('Auth', 'Failed to toggle auto-semester', e);
    }
  }

  WebViewController? getWebViewController() => _webView;

  @override
  void notifyListeners() {
    if (!_suppressUIUpdates) {
      super.notifyListeners();
    }
  }

  void _forceNotifyListeners() {
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposeWebViewResources();
    _authHandler.dispose();
    super.dispose();
  }

  /// 7. Dispose WebView and free GPU resources
  void _disposeWebViewResources() {
    if (_webView == null) return;

    try {
      _webView!.loadRequest(Uri.parse('about:blank')).catchError((_) {});
      Future.wait([
            _webView!.clearCache().catchError((_) {}),
            _webView!.clearLocalStorage().catchError((_) {}),
          ])
          .then((_) {
            Logger.d('Auth', 'WebView resources freed');
          })
          .catchError((_) {});
    } catch (e) {
      Logger.w('Auth', 'Error disposing WebView: $e');
    } finally {
      _webView = null;
    }
  }
}
