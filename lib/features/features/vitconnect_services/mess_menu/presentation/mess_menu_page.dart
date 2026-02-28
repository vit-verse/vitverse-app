import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/theme/app_card_styles.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../../../../../firebase/analytics/analytics_service.dart';
import '../models/hostel_preferences.dart';
import '../models/mess_menu_item.dart';
import '../services/hostel_preferences_service.dart';
import '../services/mess_menu_service.dart';
import '../widgets/hostel_preferences_selector.dart';

class MessMenuPage extends StatefulWidget {
  const MessMenuPage({super.key});

  @override
  State<MessMenuPage> createState() => _MessMenuPageState();
}

class _MessMenuPageState extends State<MessMenuPage> {
  static const String _tag = 'MessMenuPage';

  HostelPreferences? _preferences;
  List<MessMenuItem>? _menuItems;
  bool _isLoading = true;
  String? _error;
  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'MessMenu',
      screenClass: 'MessMenuPage',
    );
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await HostelPreferencesService.loadPreferences();

      if (prefs == null || !prefs.isComplete) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _preferences = prefs;
      });

      if (forceRefresh) {
        Logger.i(_tag, 'Force refreshing mess menu');
      }

      final fileName = prefs.getMessMenuFileName();
      final items = await MessMenuService.fetchMessMenu(
        fileName,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _menuItems = items;
        _isLoading = false;
      });

      Logger.i(_tag, 'Menu loaded: ${items.length} items');
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error loading menu: $e', stackTrace);
      setState(() {
        _error = 'Failed to load menu. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onPreferencesSelected(HostelPreferences preferences) async {
    try {
      await HostelPreferencesService.savePreferences(preferences);
      Logger.i(_tag, 'Preferences saved successfully');
      if (mounted) {
        SnackbarUtils.success(context, 'Preferences saved');
      }
      await _loadData(forceRefresh: true);
    } catch (e) {
      Logger.e(_tag, 'Error saving preferences: $e');
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to save preferences');
      }
    }
  }

  Future<void> _openSettings() async {
    final currentPrefs = _preferences;
    if (currentPrefs == null) return;

    final result = await Navigator.push<HostelPreferences>(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Update Preferences'),
                backgroundColor:
                    Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).currentTheme.surface,
              ),
              backgroundColor:
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).currentTheme.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: HostelPreferencesSelector(
                  initialPreferences: currentPrefs,
                  onPreferencesSelected: (prefs) {
                    Navigator.pop(context, prefs);
                  },
                ),
              ),
            ),
      ),
    );

    if (result != null) {
      await _onPreferencesSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Mess Menu'),
        backgroundColor: theme.surface,
        actions: [
          if (_preferences != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: _openSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: theme.text,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            Text('Loading menu...', style: TextStyle(color: theme.muted)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.muted),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.text, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_preferences == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: HostelPreferencesSelector(
          onPreferencesSelected: _onPreferencesSelected,
        ),
      );
    }

    if (_menuItems == null || _menuItems!.isEmpty) {
      return Center(
        child: Text(
          'No menu data available',
          style: TextStyle(color: theme.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: theme.primary,
      child: Column(
        children: [
          _buildMessTypeIndicator(theme),
          _buildDaySelector(theme),
          Expanded(child: _buildMenuContent(theme)),
        ],
      ),
    );
  }

  Widget _buildMessTypeIndicator(theme) {
    if (_preferences == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.muted.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_preferences!.genderDisplay} • ${_preferences!.messTypeDisplay}',
            style: TextStyle(
              fontSize: 12,
              color: theme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(theme) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.muted.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final isSelected = index == _selectedDayIndex;
          final isToday = index == today;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected
                        ? theme.primary
                        : isToday
                        ? theme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                border: Border.all(
                  color:
                      isToday && !isSelected
                          ? theme.primary
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? Colors.white
                            : isToday
                            ? theme.primary
                            : theme.text,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuContent(theme) {
    final selectedItem = _menuItems!.firstWhere(
      (item) => item.dayNumber == _selectedDayIndex,
      orElse: () => _menuItems!.first,
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            setState(() {
              _selectedDayIndex = (_selectedDayIndex + 1) % 7;
            });
          } else if (details.primaryVelocity! > 0) {
            setState(() {
              _selectedDayIndex = (_selectedDayIndex - 1 + 7) % 7;
            });
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealCard(
              'Breakfast',
              selectedItem.breakfast,
              Icons.breakfast_dining,
              theme,
            ),
            const SizedBox(height: 16),
            _buildMealCard(
              'Lunch',
              selectedItem.lunch,
              Icons.lunch_dining,
              theme,
            ),
            const SizedBox(height: 16),
            _buildMealCard(
              'Snacks',
              selectedItem.snacks,
              Icons.fastfood,
              theme,
            ),
            const SizedBox(height: 16),
            _buildMealCard(
              'Dinner',
              selectedItem.dinner,
              Icons.dinner_dining,
              theme,
            ),
            const SizedBox(height: 24),
            _buildLastUpdatedText(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String title, String content, IconData icon, theme) {
    final items =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Map meal type to icon asset and gradient color
    String? iconAsset;
    Color? gradientColor;
    switch (title.toLowerCase()) {
      case 'breakfast':
        iconAsset = 'assets/icons/breakfast.png';
        gradientColor = const Color(0xFFFF9800); // Orange
        break;
      case 'lunch':
        iconAsset = 'assets/icons/lunch.png';
        gradientColor = const Color(0xFFF44336); // Red
        break;
      case 'snacks':
        iconAsset = 'assets/icons/snacks.png';
        gradientColor = const Color(0xFF9C27B0); // Purple
        break;
      case 'dinner':
        iconAsset = 'assets/icons/dinner.png';
        gradientColor = const Color(0xFF3F51B5); // Indigo
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate icon size as 30% of card height
        final cardHeight =
            16.0 + // top padding
            20.0 + // icon row height
            12.0 + // spacing
            (items.length * 50.0) + // approximate item heights
            16.0; // bottom padding
        final iconSize = cardHeight * 0.50;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppCardStyles.compactCardDecoration(
            isDark: theme.isDark,
            customBackgroundColor: theme.surface,
          ),
          child: Stack(
            children: [
              // Gradient overlay in bottom right
              if (gradientColor != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: iconSize * 1.2,
                    height: iconSize * 1.2,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          gradientColor.withValues(alpha: theme.isDark ? 0.08 : 0.06),
                          gradientColor.withValues(alpha: 0.0),
                        ],
                        center: Alignment.bottomRight,
                        radius: 1.0,
                      ),
                    ),
                  ),
                ),
              // Background icon in bottom right
              if (iconAsset != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Opacity(
                    opacity: theme.isDark ? 0.15 : 0.12,
                    child: Image.asset(
                      iconAsset,
                      height: iconSize,
                      width: iconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: theme.primary),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.text,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLastUpdatedText(theme) {
    if (_menuItems == null || _menuItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime latestUpdate = _menuItems![0].updatedAt;
    for (final item in _menuItems!) {
      if (item.updatedAt.isAfter(latestUpdate)) {
        latestUpdate = item.updatedAt;
      }
    }

    final formattedDate =
        '${latestUpdate.day.toString().padLeft(2, '0')}/${latestUpdate.month.toString().padLeft(2, '0')}/${latestUpdate.year}';

    return Center(
      child: Column(
        children: [
          Text(
            'Last Updated: $formattedDate',
            style: TextStyle(
              fontSize: 11,
              color: theme.muted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(
                'https://github.com/Kanishka-Developer/unmessify',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  SnackbarUtils.error(context, 'Could not open link');
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'If this is outdated, please inform us or update it by raising a PR.',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 10, color: theme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
