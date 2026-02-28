import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/logger.dart';
import '../config/env_config.dart';
import '../config/app_version.dart';
import '../database/database.dart';
import '../database_vitverse/database.dart';
import '../services/notification_service.dart';
import '../../firebase/core/firebase_initializer.dart';
import '../../features/profile/widget_customization/data/widget_preferences_service.dart';
import '../../features/profile/widget_customization/data/calendar_home_service.dart';
import '../../supabase/core/supabase_client.dart';
import '../../supabase/core/supabase_events_client.dart';

class AppStartup {
  static bool _initialized = false;
  static SharedPreferences? _sharedPreferences;

  static SharedPreferences? get sharedPreferences => _sharedPreferences;

  static Future<void> initializeCritical() async {
    if (_initialized) return;

    try {
      await Future.wait([
        AppVersion.initialize(),
        SharedPreferences.getInstance().then((prefs) {
          _sharedPreferences = prefs;
        }),
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
        final startTime = DateTime.now();

        await Future.wait([
          FirebaseInitializer.initializeCore(),
          _initializeDatabase(),
          _initializeWidgetPreferences(),
          _initializeCalendarServices(),
        ]);

        await Future.wait([
          _initializeSupabase(),
          _initializeSupabaseEvents(),
          _activateAppCheck(),
          _initializeNotifications(),
        ]);

        _initializeFirebaseServices();

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        Logger.success(
          'AppStartup',
          'Background init complete in ${duration}ms',
        );
      } catch (e) {
        Logger.e('AppStartup', 'Background init failed', e);
      }
    });
  }

  static Future<void> _initializeSupabase() async {
    try {
      if (SupabaseClientService.isConfigured) {
        await SupabaseClientService.initialize();
      }
    } catch (e) {
      Logger.e('AppStartup', 'Supabase init failed', e);
    }
  }

  static Future<void> _initializeSupabaseEvents() async {
    try {
      if (SupabaseEventsClient.isConfigured) {
        await SupabaseEventsClient.initialize();
      }
    } catch (e) {
      Logger.e('AppStartup', 'Supabase Events init failed', e);
    }
  }

  static Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      Logger.success('AppStartup', 'Firebase App Check activated');
    } catch (e) {
      Logger.e('AppStartup', 'App Check activation failed', e);
    }
  }

  static Future<void> _initializeNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.scheduleTodayClassNotifications();
    } catch (e) {
      Logger.e('AppStartup', 'Notification init failed', e);
    }
  }

  static void _initializeFirebaseServices() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        await FirebaseInitializer.initialize();
      } catch (e) {
        Logger.e('AppStartup', 'Firebase services init failed', e);
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

  static Future<void> _initializeCalendarServices() async {
    try {
      await CalendarHomeService.instance.init();
    } catch (e) {
      Logger.w('AppStartup', 'Calendar home service init failed: $e');
    }
  }
}
