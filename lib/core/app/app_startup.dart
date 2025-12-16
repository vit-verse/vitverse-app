import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/logger.dart';
import '../config/env_config.dart';
import '../config/app_version.dart';
import '../database/database.dart';
import '../database_vitverse/database.dart';
import '../../firebase/core/firebase_initializer.dart';
import '../../features/profile/widget_customization/data/widget_preferences_service.dart';
import '../../features/profile/widget_customization/data/calendar_home_service.dart';
import '../../features/features/vitconnect_services/faculty_rating/services/faculty_rating_api_service.dart';
import '../../features/authentication/core/auth_service.dart';

/// App startup initialization service
class AppStartup {
  static bool _initialized = false;

  static Future<void> initializeCritical() async {
    if (_initialized) return;

    try {
      await Future.wait([
        AppVersion.initialize(),
        Future(() {
          tz.initializeTimeZones();
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        }),
      ]);

      if (!EnvConfig.isConfigured) {
        Logger.w(
          'AppStartup',
          'Missing env vars: ${EnvConfig.getMissingVars().join(", ")}',
        );
      }

      _initialized = true;
    } catch (e, stack) {
      Logger.e('AppStartup', 'Critical startup failed', e, stack);
      rethrow;
    }
  }

  static void initializeBackground() {
    if (!_initialized) {
      Logger.w('AppStartup', 'Critical init not complete');
      return;
    }

    Future.microtask(() async {
      try {
        await Future.wait([
          _initializeDatabase(),
          _initializeWidgetPreferences(),
        ]);

        await _initializeApiServices();
        await _initializeCalendarServices();
        _initializeFirebaseLazy();
      } catch (e) {
        Logger.e('AppStartup', 'Background init failed', e);
      }
    });
  }

  static Future<void> initializeAuthService() async {
    try {
      final authService = VTOPAuthService.instance;
      await authService.initialize();
    } catch (e) {
      Logger.e('AppStartup', 'Auth service init failed', e);
    }
  }

  static void _initializeFirebaseLazy() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await FirebaseInitializer.initialize();
      } catch (e) {
        Logger.e('AppStartup', 'Firebase init failed', e);
      }
    });
  }

  static Future<void> _initializeDatabase() async {
    try {
      final db = VitConnectDatabase.instance;
      await db.database;

      final vitVerseDb = VitVerseDatabase.instance;
      await vitVerseDb.initialize();
    } catch (e) {
      Logger.e('AppStartup', 'Database init failed', e);
      rethrow;
    }
  }

  static Future<void> _initializeWidgetPreferences() async {
    try {
      await WidgetPreferencesService.instance.init();
    } catch (e) {
      Logger.e('AppStartup', 'Widget preferences init failed', e);
    }
  }

  static Future<void> _initializeApiServices() async {
    try {
      await Future.wait([_initCabShare(), _initFacultyRating()]);
    } catch (e) {
      Logger.e('AppStartup', 'API services init failed', e);
    }
  }

  static Future<void> _initCabShare() async {
    try {
      // Cab Share uses Supabase directly, no separate API service needed
      Logger.d('AppStartup', 'Cab Share uses Supabase integration');
    } catch (e) {
      Logger.w('AppStartup', 'CabShare init failed: $e');
    }
  }

  static Future<void> _initFacultyRating() async {
    try {
      final url = EnvConfig.facultyRatingScriptUrl;
      if (url.isNotEmpty) {
        FacultyRatingApiService.initialize(url);
      }
    } catch (e) {
      Logger.w('AppStartup', 'Faculty Rating init failed: $e');
    }
  }

  static Future<void> _initializeCalendarServices() async {
    try {
      await CalendarHomeService.instance.init();
      Logger.d('AppStartup', 'Calendar home service initialized');
    } catch (e) {
      Logger.w('AppStartup', 'Calendar home service init failed: $e');
    }
  }
}
