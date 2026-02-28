import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app/app_startup.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/logger.dart';
import 'core/utils/snackbar_utils.dart';
import 'features/authentication/core/auth_service.dart';
import 'features/authentication/utils/auth_states.dart';
import 'features/authentication/ui/login_screen.dart';
import 'features/main_screen.dart';
import 'features/profile/widget_customization/provider/widget_customization_provider.dart';
import 'features/features/routes/feature_routes.dart';
import 'features/profile/student_profile/report_generation/presentation/report_generation_page.dart';
import 'core/database/entities/student_profile.dart';
import 'firebase/analytics/analytics_service.dart';
import 'firebase/crashlytics/crashlytics_service.dart';
import 'firebase/messaging/fcm_service.dart';
import 'firebase/messaging/notification_handler.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/force_update/force_update_screen.dart';
import 'core/services/version_checker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100;

  await AppStartup.initializeCritical();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  FlutterError.onError = (details) {
    Logger.e('FlutterError', details.exceptionAsString());
    CrashlyticsService.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Logger.e('UncaughtError', error.toString(), error, stack);
    CrashlyticsService.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(VitConnectApp(themeProvider: themeProvider));
  AppStartup.initializeBackground();
}

class VitConnectApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const VitConnectApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => VTOPAuthService.instance),
        ChangeNotifierProvider(create: (_) => WidgetCustomizationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'VIT Verse',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getThemeData(),
            darkTheme: themeProvider.getThemeData(),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              FCMService.onNotificationTap = (data) {
                if (context.mounted) {
                  NotificationHandler.handleNotificationTap(context, data);
                }
              };
              return StackedSnackbarManager(child: child!);
            },
            home: const AuthGate(),
            routes: FeatureRoutes.getRoutes(),
            onGenerateRoute: (settings) {
              if (settings.name == '/generate-report') {
                final profile = settings.arguments as StudentProfile?;
                if (profile != null) {
                  return MaterialPageRoute(
                    builder:
                        (context) => ReportGenerationPage(profile: profile),
                  );
                }
              }
              return null;
            },
            navigatorObservers:
                AnalyticsService.observer != null
                    ? [AnalyticsService.observer!]
                    : [],
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  KillSwitchResult? _killSwitchResult;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authService = VTOPAuthService.instance;
      final isSignedIn = await authService.isSignedIn();

      if (mounted) {
        setState(() {
          _isAuthenticated = isSignedIn;
          _isLoading = false;
        });
      }

      authService.addListener(_handleAuthStateChange);
      authService.initialize();
      _checkKillSwitchInBackground();
    } catch (e) {
      Logger.e('AuthGate', 'Initialization failed', e);
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  void _checkKillSwitchInBackground() {
    VersionCheckerService.checkKillSwitch()
        .then((result) {
          if (!mounted) return;
          if (result.isBlocked) {
            setState(() => _killSwitchResult = result);
          }
        })
        .catchError((e) {
          Logger.w(
            'AuthGate',
            'Kill switch background check failed — ignoring: $e',
          );
        });
  }

  void _handleAuthStateChange() {
    final authService = VTOPAuthService.instance;

    switch (authService.authState) {
      case AuthState.complete:
        if (mounted) {
          setState(() => _isAuthenticated = true);
        }
        break;
      case AuthState.idle:
      case AuthState.error:
        if (mounted) {
          setState(() => _isAuthenticated = false);
        }
        break;
      case AuthState.loading:
      case AuthState.captchaRequired:
      case AuthState.semesterSelection:
      case AuthState.dataDownloading:
        break;
    }
  }

  @override
  void dispose() {
    VTOPAuthService.instance.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_killSwitchResult?.isBlocked == true) {
      return ForceUpdateScreen(
        currentVersion: _killSwitchResult!.currentVersion,
        minVersion: _killSwitchResult!.minVersion!,
      );
    }

    return _isAuthenticated ? const MainScreen() : const LoginScreen();
  }
}
