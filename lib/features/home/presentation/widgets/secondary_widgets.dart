import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/utils/logger.dart';
import '../../logic/home_logic.dart';
import '../../../profile/widget_customization/provider/widget_customization_provider.dart';
import 'secondary_widget_types.dart';

/// Container for rotating secondary widgets based on user preferences
class SecondaryWidgets extends StatefulWidget {
  static const String _tag = 'SecondaryWidgets';

  final HomeLogic homeLogic;

  const SecondaryWidgets({super.key, required this.homeLogic});

  @override
  State<SecondaryWidgets> createState() => _SecondaryWidgetsState();
}

class _SecondaryWidgetsState extends State<SecondaryWidgets>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'SecondaryWidgets';

  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoRotation();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentIndex) {
        setState(() {
          _currentIndex = page;
        });

        // Restart auto-rotation after manual swipe
        _startAutoRotation();
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();

    final widgetProvider = context.read<WidgetCustomizationProvider>();
    final selectedWidgets = widgetProvider.homeSecondaryWidgets;

    if (selectedWidgets.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          final nextIndex = (_currentIndex + 1) % selectedWidgets.length;
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final widgetProvider = context.watch<WidgetCustomizationProvider>();
    final selectedWidgets = widgetProvider.homeSecondaryWidgets;

    // Get widget builders
    final widgets =
        selectedWidgets.map((type) {
          return SecondaryWidgetTypes.buildWidget(
            type,
            widget.homeLogic,
            themeProvider,
          );
        }).toList();

    // Handle empty widgets
    if (widgets.isEmpty) {
      return AppCard(
        child: Center(
          child: Text(
            'No widgets selected',
            style: TextStyle(color: themeProvider.currentTheme.muted),
          ),
        ),
      );
    }

    // Clamp current index
    if (_currentIndex >= widgets.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });

          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }

          _startAutoRotation();
        }
      });
    }

    return AppCard(
      child: Stack(
        children: [
          // Page view with widgets
          PageView(
            controller: _pageController,
            children: widgets,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          ),

          // Page indicators
          if (widgets.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widgets.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? themeProvider.currentTheme.text
                              : themeProvider.currentTheme.muted.withValues(
                                alpha: 0.3,
                              ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
