import 'dart:ui';
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

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildPage(_currentIndex),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(themeProvider),
    );
  }

  Widget _buildBottomNavigationBar(ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? theme.surface.withValues(alpha: 0.85)
                      : theme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color:
                    isDark
                        ? theme.muted.withValues(alpha: 0.12)
                        : theme.muted.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.text.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 0, themeProvider),
                _buildNavItem(Icons.bar_chart_rounded, 1, themeProvider),
                _buildNavItem(Icons.calendar_month_rounded, 2, themeProvider),
                _buildNavItem(Icons.auto_awesome_rounded, 3, themeProvider),
                _buildNavItem(Icons.person_rounded, 4, themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, ThemeProvider themeProvider) {
    final isActive = index == _currentIndex;
    final theme = themeProvider.currentTheme;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child:
            isActive
                ? _AnimatedIcon(
                  icon: icon,
                  color: Colors.white,
                  primaryColor: theme.primary,
                )
                : Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: theme.muted.withValues(alpha: 0.6),
                  ),
                ),
      ),
    );
  }
}

/// Animated icon widget with pulsing ripple effect
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color primaryColor;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
    required this.primaryColor,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ripple1Scale;
  late Animation<double> _ripple1Opacity;
  late Animation<double> _ripple2Scale;
  late Animation<double> _ripple2Opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // First ripple wave
    _ripple1Scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _ripple1Opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    // Second ripple wave (delayed)
    _ripple2Scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _ripple2Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Second ripple wave
            if (_controller.value > 0.4)
              Transform.scale(
                scale: _ripple2Scale.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.primaryColor.withValues(
                          alpha: _ripple2Opacity.value * 0.8,
                        ),
                        widget.primaryColor.withValues(
                          alpha: _ripple2Opacity.value * 0.4,
                        ),
                        widget.primaryColor.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            // First ripple wave
            Transform.scale(
              scale: _ripple1Scale.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.primaryColor.withValues(
                        alpha: _ripple1Opacity.value,
                      ),
                      widget.primaryColor.withValues(
                        alpha: _ripple1Opacity.value * 0.5,
                      ),
                      widget.primaryColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Solid circle background with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.primaryColor.withValues(alpha: 0.9),
                    widget.primaryColor,
                  ],
                  stops: const [0.0, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            // Icon with subtle pulse
            Transform.scale(
              scale:
                  1.0 +
                  (0.05 * (1 - ((_controller.value * 2) % 1 - 0.5).abs() * 2)),
              child: Icon(widget.icon, size: 24, color: widget.color),
            ),
          ],
        );
      },
    );
  }
}
