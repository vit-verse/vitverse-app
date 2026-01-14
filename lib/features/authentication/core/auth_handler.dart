import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/services/vtop_data_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/sync_notifier.dart';

/// 1. Authentication data handler - coordinates data sync and notifications
class VTOPAuthHandler extends ChangeNotifier {
  static VTOPAuthHandler? _instance;
  static VTOPAuthHandler get instance => _instance ??= VTOPAuthHandler._();

  VTOPAuthHandler._();

  final NotificationService _notificationService = NotificationService();

  bool _isPhase2Running = false;
  bool _isBackgroundSyncing = false;
  String? _currentPhase;
  int _progress = 0;

  bool get isPhase2Running => _isPhase2Running;
  bool get isBackgroundSyncing => _isBackgroundSyncing;
  String? get currentSyncPhase => _currentPhase;
  int get progress => _progress;

  /// 2. Initialize notification service
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      Logger.d('AuthHandler', 'Initialized successfully');
    } catch (e) {
      Logger.e('AuthHandler', 'Initialization failed', e);
      rethrow;
    }
  }

  /// 3. Download Phase 1 data (essential - blocking)
  Future<void> downloadPhase1Data({
    required WebViewController webView,
    required String semesterID,
    int retryCount = 0,
  }) async {
    try {
      Logger.d(
        'AuthHandler',
        'Starting Phase 1 data download (attempt ${retryCount + 1})',
      );

      _currentPhase = 'P1';
      notifyListeners();

      final dataService = VTOPDataService(webView);

      dataService.onProgress = (current, total, stepName) {
        _progress = current;
        _notificationService.showProgressNotification(
          currentStep: current,
          totalSteps: total,
          stepLabel: stepName,
        );
        notifyListeners();
      };

      await dataService.executePhase1(semesterID);

      Logger.success('AuthHandler', 'Phase 1 complete');

      await _notificationService.showCompletionNotification(
        success: true,
        message: 'Phase 1 Completed (Updated Courses, Attendance, Timetable)',
      );

      SyncNotifier.instance.notifySyncComplete();
    } catch (e) {
      Logger.e(
        'AuthHandler',
        'Phase 1 download failed (attempt ${retryCount + 1})',
        e,
      );

      if (retryCount == 0) {
        Logger.w('AuthHandler', 'Retrying Phase 1 after 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        return downloadPhase1Data(
          webView: webView,
          semesterID: semesterID,
          retryCount: 1,
        );
      }

      _currentPhase = null;
      notifyListeners();
      rethrow;
    }
  }

  /// 4. Start Phase 2 in background (secondary data - non-blocking)
  void startPhase2Background({
    required WebViewController webView,
    required String semesterID,
  }) {
    Logger.d('AuthHandler', 'Starting Phase 2 in background');
    _isPhase2Running = true;
    _currentPhase = 'P2';
    notifyListeners();

    Future.microtask(() async {
      try {
        // Extended delay to ensure WebView and page are fully loaded after Phase 1
        Logger.d(
          'AuthHandler',
          'Waiting for WebView to stabilize after Phase 1...',
        );
        await Future.delayed(const Duration(seconds: 8));

        // Validate WebView session before starting Phase 2
        Logger.d('AuthHandler', 'Starting session validation...');
        final isSessionValid = await _validateWebViewSession(webView);
        if (!isSessionValid) {
          Logger.e('AuthHandler', 'WebView session invalid - Phase 2 aborted');
          _isPhase2Running = false;
          _currentPhase = null;
          notifyListeners();

          // Show notification that Phase 2 was skipped
          await _notificationService.showCompletionNotification(
            success: false,
            message: 'Phase 2 Skipped - Session validation failed',
          );
          return;
        }

        Logger.success(
          'AuthHandler',
          'Session validation passed - starting Phase 2',
        );
        final dataService = VTOPDataService(webView);

        dataService.onProgress = (current, total, stepName) {
          Logger.progress('AuthHandler', current, total, 'Phase 2: $stepName');
          _notificationService.showProgressNotification(
            currentStep: current,
            totalSteps: total,
            stepLabel: 'Phase 2: $stepName',
          );
        };

        dataService.onComplete = () async {
          Logger.success('AuthHandler', 'Phase 2 complete');
          _isPhase2Running = false;
          _currentPhase = null;
          notifyListeners();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'lastSyncTimestamp',
            DateTime.now().millisecondsSinceEpoch,
          );

          SyncNotifier.instance.notifySyncComplete();
          await _scheduleNotificationsAfterSync();

          await _notificationService.showCompletionNotification(
            success: true,
            message: 'Phase 2 Completed (All Data Updated)',
          );
        };

        await dataService.executePhase2(semesterID);
      } catch (e) {
        Logger.e('AuthHandler', 'Phase 2 failed: $e');
        _isPhase2Running = false;
        _currentPhase = null;
        notifyListeners();

        // Show error notification for Phase 2 failure
        await _notificationService.showCompletionNotification(
          success: false,
          message: 'Phase 2 Failed - Some data may be incomplete',
        );
      }
    });
  }

  /// 5. Background sync for home screen refresh
  Future<bool> backgroundSync({
    required Future<bool> Function() authenticateCallback,
    String? semesterName,
    Function(bool isSyncing)? onSyncStateChanged,
    Function(String error, {String? errorType})? onError,
    Function(String message)? onStatusUpdate,
  }) async {
    try {
      Logger.i('AuthHandler', 'Starting background sync');

      _isBackgroundSyncing = true;
      _currentPhase = 'A';
      notifyListeners();

      onSyncStateChanged?.call(true);
      onStatusUpdate?.call('Authenticating...');

      await _notificationService.showProgressNotification(
        currentStep: 1,
        totalSteps: 5,
        stepLabel: 'Authenticating...',
      );

      final authSuccess = await authenticateCallback();
      if (!authSuccess) {
        _currentPhase = null;
        _isBackgroundSyncing = false;
        notifyListeners();
        onError?.call('Authentication failed', errorType: 'AUTH_FAILED');
        onSyncStateChanged?.call(false);
        return false;
      }

      await _notificationService.showProgressNotification(
        currentStep: 4,
        totalSteps: 5,
        stepLabel: 'Downloading...',
      );

      onStatusUpdate?.call('Sync complete');
      _isBackgroundSyncing = false;
      notifyListeners();
      onSyncStateChanged?.call(false);

      return true;
    } catch (e) {
      Logger.e('AuthHandler', 'Background sync exception', e);
      _currentPhase = null;
      _isBackgroundSyncing = false;
      notifyListeners();
      onError?.call('Sync failed: $e', errorType: 'EXCEPTION');
      onSyncStateChanged?.call(false);
      return false;
    }
  }

  /// 6. Schedule notifications after data sync completes
  Future<void> _scheduleNotificationsAfterSync() async {
    try {
      Logger.d(
        'AuthHandler',
        'Scheduling notifications after Phase 2 complete',
      );

      await _notificationService.rescheduleOnSync();

      Logger.success('AuthHandler', 'Notifications scheduled successfully');
    } catch (e) {
      Logger.e('AuthHandler', 'Failed to schedule notifications after sync', e);
    }
  }

  /// 7. Cancel all operations and notifications
  void cancelAllOperations() {
    _notificationService.cancelAllNotifications();
    _isPhase2Running = false;
    _isBackgroundSyncing = false;
    _currentPhase = null;
    notifyListeners();
  }

  /// 8. Validate WebView session before Phase 2
  Future<bool> _validateWebViewSession(WebViewController webView) async {
    try {
      Logger.d('AuthHandler', 'Validating WebView session for Phase 2');

      // First, ensure we're on the right page and wait for it to load
      await _ensurePageReady(webView);

      // Try multiple validation approaches with retries
      for (int attempt = 1; attempt <= 5; attempt++) {
        Logger.d('AuthHandler', 'Session validation attempt $attempt/5');

        final jsCode = '''
          (function() {
            try {
              var currentUrl = window.location.href;
              var result = {
                isOnVtopDomain: currentUrl.includes('vtopcc.vit.ac.in'),
                isLoggedIn: currentUrl.includes('/vtop/content'),
                currentUrl: currentUrl,
                hasJQuery: typeof \$ !== 'undefined',
                documentReady: document.readyState === 'complete'
              };
              
              // Always try vanilla JS first (most reliable)
              var authorizedIDElement = document.getElementById('authorizedIDX');
              var csrfElement = document.querySelector('input[name="_csrf"]');
              
              if (authorizedIDElement && csrfElement) {
                var authorizedID = authorizedIDElement.value || '';
                var csrf = csrfElement.value || '';
                result.hasAuthorizedID = authorizedID.length > 0;
                result.hasCsrf = csrf.length > 0;
                result.authorizedID = authorizedID || 'missing';
                result.csrf = csrf || 'missing';
                result.method = 'vanilla_js';
                result.success = true;
              } else {
                // Elements not found - check if page is still loading
                if (document.readyState !== 'complete') {
                  result.error = 'Page still loading (readyState: ' + document.readyState + ')';
                  result.method = 'page_loading';
                } else {
                  result.error = 'Session elements not found in DOM';
                  result.method = 'elements_missing';
                }
              }
              
              return JSON.stringify(result);
            } catch (e) {
              return JSON.stringify({ 
                error: e.message, 
                method: 'exception',
                currentUrl: window.location.href,
                documentReady: document.readyState
              });
            }
          })();
        ''';

        final result = await webView.runJavaScriptReturningResult(jsCode);
        String cleanResult = result.toString();

        // Properly clean the result
        if (cleanResult.startsWith('"') && cleanResult.endsWith('"')) {
          cleanResult = cleanResult.substring(1, cleanResult.length - 1);
        }

        cleanResult = cleanResult
            .replaceAll('\\"', '"')
            .replaceAll('\\\\', '\\');

        Logger.d(
          'AuthHandler',
          'Raw session validation response: $cleanResult',
        );

        if (cleanResult.isNotEmpty && cleanResult != 'null') {
          final data = jsonDecode(cleanResult);

          // Check if we're on the right domain and logged in
          final onRightPage =
              data['isOnVtopDomain'] == true && data['isLoggedIn'] == true;

          if (!onRightPage) {
            Logger.w(
              'AuthHandler',
              'Not on VTOP content page: ${data['currentUrl']}',
            );
            return false;
          }

          // Check if validation was successful
          if (data['success'] == true) {
            final hasValidSession =
                data['hasAuthorizedID'] == true && data['hasCsrf'] == true;

            Logger.d(
              'AuthHandler',
              'Session validation result (attempt $attempt): $hasValidSession',
            );
            Logger.d('AuthHandler', 'Session method: ${data['method']}');
            Logger.d('AuthHandler', 'Document ready: ${data['documentReady']}');
            Logger.d('AuthHandler', 'Has jQuery: ${data['hasJQuery']}');

            if (hasValidSession) {
              Logger.success('AuthHandler', 'Session validation successful');
              return true;
            } else {
              Logger.w(
                'AuthHandler',
                'Session elements found but invalid (authorizedID: ${data['authorizedID']}, csrf: ${data['csrf']})',
              );
            }
          } else if (data.containsKey('error')) {
            Logger.w(
              'AuthHandler',
              'Session validation error (attempt $attempt): ${data['error']}',
            );

            // If page is still loading or elements missing, wait and retry
            if (data['method'] == 'page_loading' ||
                data['method'] == 'elements_missing' ||
                data['error'].toString().contains('loading')) {
              if (attempt < 5) {
                Logger.d(
                  'AuthHandler',
                  'Page/elements not ready, waiting 3 seconds before retry...',
                );
                await Future.delayed(const Duration(seconds: 3));
                continue;
              }
            }
          }

          // If session is invalid or error, wait and retry
          if (attempt < 5) {
            Logger.d(
              'AuthHandler',
              'Session validation failed, waiting before retry...',
            );
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
        }

        // If we get here, validation failed for this attempt
        if (attempt < 5) {
          Logger.d('AuthHandler', 'Validation failed, waiting before retry...');
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      Logger.w('AuthHandler', 'Session validation failed after 5 attempts');
      return false;
    } catch (e) {
      Logger.e('AuthHandler', 'Session validation failed', e);
      return false;
    }
  }

  /// Ensure the WebView page is ready for Phase 2
  Future<void> _ensurePageReady(WebViewController webView) async {
    try {
      Logger.d('AuthHandler', 'Ensuring WebView page is ready...');

      // Check current URL and wait for page to be ready
      for (int i = 0; i < 5; i++) {
        final urlCheck = '''
          (function() {
            return JSON.stringify({
              url: window.location.href,
              readyState: document.readyState,
              hasJQuery: typeof \$ !== 'undefined',
              hasAuthorizedID: !!document.getElementById('authorizedIDX'),
              hasCsrfInput: !!document.querySelector('input[name="_csrf"]')
            });
          })();
        ''';

        final result = await webView.runJavaScriptReturningResult(urlCheck);
        String cleanResult = result.toString();

        if (cleanResult.startsWith('"') && cleanResult.endsWith('"')) {
          cleanResult = cleanResult.substring(1, cleanResult.length - 1);
        }

        cleanResult = cleanResult
            .replaceAll('\\"', '"')
            .replaceAll('\\\\', '\\');

        if (cleanResult.isNotEmpty && cleanResult != 'null') {
          final data = jsonDecode(cleanResult);
          Logger.d('AuthHandler', 'Page readiness check ${i + 1}/5: $data');

          // If we're on about:blank, navigate back to VTOP content
          if (data['url'].toString().contains('about:blank')) {
            Logger.w(
              'AuthHandler',
              'WebView on about:blank, navigating to VTOP content...',
            );
            await webView.loadRequest(
              Uri.parse('https://vtopcc.vit.ac.in/vtop/content'),
            );
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }

          // Check if we're on the right page with required elements
          final onContentPage = data['url'].toString().contains(
            '/vtop/content',
          );
          final documentReady = data['readyState'] == 'complete';
          final hasRequiredElements =
              data['hasAuthorizedID'] == true && data['hasCsrfInput'] == true;

          if (onContentPage && documentReady && hasRequiredElements) {
            Logger.success(
              'AuthHandler',
              'Page is ready for Phase 2 (all elements present)',
            );
            return;
          }

          // Log what's missing
          if (!onContentPage) {
            Logger.d('AuthHandler', 'Not on content page yet: ${data['url']}');
          } else if (!documentReady) {
            Logger.d(
              'AuthHandler',
              'Document not ready: ${data['readyState']}',
            );
          } else if (!hasRequiredElements) {
            Logger.d(
              'AuthHandler',
              'Required elements missing (authorizedID: ${data['hasAuthorizedID']}, csrf: ${data['hasCsrfInput']})',
            );
          }
        }

        Logger.d('AuthHandler', 'Page not ready, waiting 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }

      Logger.w(
        'AuthHandler',
        'Page readiness timeout after 5 attempts, proceeding anyway',
      );
    } catch (e) {
      Logger.w('AuthHandler', 'Page readiness check failed: $e');
    }
  }

  /// 9. Cleanup resources and dispose properly
  @override
  void dispose() {
    cancelAllOperations();
    _isPhase2Running = false;
    _isBackgroundSyncing = false;
    _currentPhase = null;
    super.dispose();
  }
}
