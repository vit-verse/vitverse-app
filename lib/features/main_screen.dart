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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isNavigating = false;
  final Map<int, Widget> _pageCache = {};
  
  // Animation controller for smooth tab transitions
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
  // Ripple animation controller for active tab glow
  late AnimationController _rippleController;

  static const int _itemCount = 5;

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
    
    // Initialize tab animation controller
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeOutBack,
    );
    
    // Initialize ripple/glow animation controller
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    // Start at completed state for initial load
    _tabAnimationController.value = 1.0;

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
    _tabAnimationController.dispose();
    _rippleController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index || _isNavigating) return;

    _isNavigating = true;
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animate the indicator
    _tabAnimationController.reset();
    _tabAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _isNavigating = false;
    });
  }
  
  void _onSwipeLeft() {
    if (_currentIndex < _itemCount - 1) {
      _onTabTapped(_currentIndex + 1);
    }
  }
  
  void _onSwipeRight() {
    if (_currentIndex > 0) {
      _onTabTapped(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          // Swipe left (positive velocity means finger moved right to left)
          if (details.primaryVelocity! < -300) {
            _onSwipeLeft();
          }
          // Swipe right (negative velocity means finger moved left to right)
          else if (details.primaryVelocity! > 300) {
            _onSwipeRight();
          }
        },
        child: SafeArea(
          top: false,
          bottom: false,
          child: _buildPage(_currentIndex),
        ),
      ),
      bottomNavigationBar: _buildAnimatedBottomNavigationBar(themeProvider),
    );
  }

  Widget _buildAnimatedBottomNavigationBar(ThemeProvider themeProvider) {
    final theme = themeProvider.currentTheme;
    final isDark = themeProvider.isDarkMode;
    
    // Get system navigation bar height to prevent overlap with 3-button navigation
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    const itemWidth = 48.0;
    const navBarHeight = 65.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: navBarHeight,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final spacing = (totalWidth - (_itemCount * itemWidth)) / (_itemCount + 1);
                
                return AnimatedBuilder(
                  animation: Listenable.merge([_tabAnimation, _rippleController]),
                  builder: (context, child) {
                    // Calculate positions
                    final previousX = spacing + (_previousIndex * (itemWidth + spacing));
                    final currentX = spacing + (_currentIndex * (itemWidth + spacing));
                    
                    // Lerp between previous and current position
                    final indicatorX = lerpDouble(previousX, currentX, _tabAnimation.value)!;
                    
                    // Ripple animation values
                    final rippleScale1 = 1.0 + (0.8 * _rippleController.value);
                    final rippleOpacity1 = 0.6 * (1 - _rippleController.value);
                    final rippleScale2 = 1.0 + (0.8 * ((_rippleController.value + 0.4) % 1.0));
                    final rippleOpacity2 = 0.4 * (1 - ((_rippleController.value + 0.4) % 1.0));
                    
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple glow effect 2 (delayed)
                        if (_rippleController.value > 0.4 || _rippleController.value < 0.6)
                          Positioned(
                            left: indicatorX - (itemWidth * (rippleScale2 - 1) / 2),
                            top: (navBarHeight - itemWidth * rippleScale2) / 2,
                            child: Container(
                              width: itemWidth * rippleScale2,
                              height: itemWidth * rippleScale2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    theme.primary.withValues(alpha: rippleOpacity2 * 0.8),
                                    theme.primary.withValues(alpha: rippleOpacity2 * 0.4),
                                    theme.primary.withValues(alpha: 0),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        // Ripple glow effect 1
                        Positioned(
                          left: indicatorX - (itemWidth * (rippleScale1 - 1) / 2),
                          top: (navBarHeight - itemWidth * rippleScale1) / 2,
                          child: Container(
                            width: itemWidth * rippleScale1,
                            height: itemWidth * rippleScale1,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.primary.withValues(alpha: rippleOpacity1),
                                  theme.primary.withValues(alpha: rippleOpacity1 * 0.5),
                                  theme.primary.withValues(alpha: 0),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Animated sliding pill indicator (solid circle)
                        Positioned(
                          left: indicatorX,
                          top: (navBarHeight - itemWidth) / 2,
                          child: Container(
                            width: itemWidth,
                            height: itemWidth,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.primary.withValues(alpha: 0.9),
                                  theme.primary,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Nav items row - centered vertically
                        SizedBox(
                          height: navBarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_itemCount, (index) {
                              return _buildAnimatedNavItem(
                                _getIconForIndex(index),
                                index,
                                themeProvider,
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.home_rounded;
      case 1: return Icons.bar_chart_rounded;
      case 2: return Icons.calendar_month_rounded;
      case 3: return Icons.auto_awesome_rounded;
      case 4: return Icons.person_rounded;
      default: return Icons.home_rounded;
    }
  }

  Widget _buildAnimatedNavItem(IconData icon, int index, ThemeProvider themeProvider) {
    final isActive = index == _currentIndex;
    final wasActive = index == _previousIndex;
    final theme = themeProvider.currentTheme;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 65, // Match navbar height for proper centering
        child: AnimatedBuilder(
          animation: _tabAnimation,
          builder: (context, child) {
            // Calculate icon color and scale based on animation
            double scale = 1.0;
            Color iconColor = theme.muted.withValues(alpha: 0.6);
            
            if (isActive) {
              // Animating to active
              scale = lerpDouble(1.0, 1.1, _tabAnimation.value)!;
              iconColor = Color.lerp(
                theme.muted.withValues(alpha: 0.6),
                Colors.white,
                _tabAnimation.value,
              )!;
            } else if (wasActive) {
              // Animating from active
              scale = lerpDouble(1.1, 1.0, _tabAnimation.value)!;
              iconColor = Color.lerp(
                Colors.white,
                theme.muted.withValues(alpha: 0.6),
                _tabAnimation.value,
              )!;
            }
            
            return Center(
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
