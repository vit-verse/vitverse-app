import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';
import '../core/services/notification_service.dart';
import '../core/utils/logger.dart';
import 'home/presentation/home_page.dart';
import 'performance/lazy_performance_page.dart';
import 'calendar/lazy_calendar_page.dart';
import 'features/lazy_features_page.dart';
import 'profile/profile_page.dart';

/// Main navigation screen with bottom tab bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isNavigating = false;
  final Map<int, Widget> _pageCache = {};

  Widget _buildPage(int index) {
    if (_pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const LazyPerformancePage();
        break;
      case 2:
        page = const LazyCalendarPage();
        break;
      case 3:
        page = const LazyFeaturesPage();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        page = const HomePage();
    }

    _pageCache[index] = page;
    return page;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildPage(0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().scheduleNotificationsDeferred();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (e) {
        Logger.e('MainScreen', 'Error clearing image cache', e);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index || _isNavigating) return;

    _isNavigating = true;

    setState(() {
      _currentIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildPage(_currentIndex),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(themeProvider),
    );
  }

  Widget _buildBottomNavigationBar(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        boxShadow: [
          BoxShadow(
            color: themeProvider.currentTheme.text.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _buildNavItem(
                Icons.home_rounded,
                'Home',
                0,
                themeProvider,
                false,
              ),
              _buildNavItem(
                Icons.bar_chart_rounded,
                'Performance',
                1,
                themeProvider,
                false,
              ),
              _buildNavItem(
                Icons.calendar_month_rounded,
                'Calendar',
                2,
                themeProvider,
                false,
              ),
              _buildNavItem(
                Icons.auto_awesome_rounded,
                'Features',
                3,
                themeProvider,
                false,
              ),
              _buildNavItem(
                Icons.person_rounded,
                'Profile',
                4,
                themeProvider,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    ThemeProvider themeProvider,
    bool hasNotification,
  ) {
    final isActive = index == _currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? themeProvider.currentTheme.primary.withOpacity(
                                0.15,
                              )
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color:
                          isActive
                              ? themeProvider.currentTheme.primary
                              : themeProvider.currentTheme.muted,
                    ),
                  ),
                  if (hasNotification && !isActive)
                    Positioned(
                      right: 8,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
