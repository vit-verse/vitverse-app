import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../firebase/analytics/analytics_service.dart';
import '../../../../core/database_vitverse/database.dart';
import '../widgets/theme_selector_card.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  int _selectedTab = 0;
  late PageController _pageController;
  late TextEditingController _themeNameController;

  String? _selectedBaseThemeId;
  Color _customPrimary = const Color(0xFF6366F1);
  Color _customBackground = const Color(0xFF0F172A);
  Color _customSurface = const Color(0xFF1E293B);
  Color _customText = const Color(0xFFFFFFFF);
  Color _customMuted = const Color(0xFF94A3B8);
  bool _customIsDark = true;
  String _customThemeName = 'My Theme 1';
  List<AppTheme> _customThemes = [];

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ThemeSettings',
      screenClass: 'ThemeSettingsPage',
    );
    _pageController = PageController();
    _themeNameController = TextEditingController(text: _customThemeName);
    _loadCustomThemes();
    _loadSavedCustomTheme();
  }

  Future<void> _loadCustomThemes() async {
    try {
      final db = VitVerseDatabase.instance;
      final themes = await db.customThemeDao.getAllCustomThemes();
      if (mounted) {
        setState(() {
          _customThemes = themes;
          // Generate next theme name based on count
          final nextNumber = _customThemes.length + 1;
          _customThemeName = 'My Theme $nextNumber';
          _themeNameController.text = _customThemeName;
        });
      }
    } catch (e) {
      // If database not initialized, use default
      if (mounted) {
        setState(() {
          _customThemes = [];
        });
      }
    }
  }

  void _loadSavedCustomTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final customTheme = themeProvider.customTheme;
    final currentTheme = themeProvider.currentTheme;
    final themeToLoad = customTheme ?? currentTheme;

    setState(() {
      _customPrimary = themeToLoad.primary;
      _customBackground = themeToLoad.background;
      _customSurface = themeToLoad.surface;
      _customText = themeToLoad.text;
      _customMuted = themeToLoad.muted;
      _customIsDark = themeToLoad.isDark;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _themeNameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _selectedTab = index);

  void _onNavButtonTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  TextStyle _getGoogleFontStyle(
    String fontFamily, {
    required double fontSize,
    required Color color,
    FontWeight? fontWeight,
  }) {
    switch (fontFamily.toLowerCase()) {
      case 'inter':
        return GoogleFonts.inter(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'dm sans':
        return GoogleFonts.dmSans(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'space grotesk':
        return GoogleFonts.spaceGrotesk(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'outfit':
        return GoogleFonts.outfit(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'sora':
        return GoogleFonts.sora(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'plus jakarta sans':
        return GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'rubik':
        return GoogleFonts.rubik(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'urbanist':
        return GoogleFonts.urbanist(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'cabin':
        return GoogleFonts.cabin(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      case 'exo 2':
        return GoogleFonts.exo2(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      default:
        return GoogleFonts.inter(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(title: Text('Theme & Style'), centerTitle: false),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(ThemeConstants.spacingMd),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.surface,
              borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
            ),
            child: Row(
              children: [
                _buildNavButton(
                  'Themes',
                  Icons.palette_outlined,
                  0,
                  themeProvider,
                ),
                _buildNavButton(
                  'Fonts',
                  Icons.font_download_outlined,
                  1,
                  themeProvider,
                ),
                _buildNavButton(
                  'Custom',
                  Icons.tune_outlined,
                  2,
                  themeProvider,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildThemesTab(themeProvider),
                _buildFontsTab(themeProvider),
                _buildCustomTab(themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    String label,
    IconData icon,
    int index,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavButtonTap(index),
        child: AnimatedContainer(
          duration: ThemeConstants.durationNormal,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? themeProvider.currentTheme.primary
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected
                        ? (themeProvider.currentTheme.isDark
                            ? Colors.black
                            : Colors.white)
                        : themeProvider.currentTheme.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
                          ? (themeProvider.currentTheme.isDark
                              ? Colors.black
                              : Colors.white)
                          : themeProvider.currentTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemesTab(ThemeProvider themeProvider) {
    final lightThemes = AppThemes.allThemes.where((t) => !t.isDark).toList();
    final darkThemes = AppThemes.allThemes.where((t) => t.isDark).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ThemeConstants.spacingSm),

          Row(
            children: [
              Icon(
                Icons.light_mode,
                color: themeProvider.currentTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Light Themes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.currentTheme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: ThemeConstants.spacingMd,
              mainAxisSpacing: ThemeConstants.spacingMd,
            ),
            itemCount: lightThemes.length,
            itemBuilder: (context, index) {
              final appTheme = lightThemes[index];
              final isSelected = themeProvider.currentTheme.id == appTheme.id;
              return ThemeSelectorCard(
                theme: appTheme,
                isSelected: isSelected,
                isCompact: false,
                onTap: () async {
                  await themeProvider.setTheme(appTheme);
                  if (mounted)
                    SnackbarUtils.success(
                      context,
                      '${appTheme.name} theme applied',
                    );
                },
              );
            },
          ),

          const SizedBox(height: ThemeConstants.spacingXl),

          Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: themeProvider.currentTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dark Themes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.currentTheme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: ThemeConstants.spacingMd,
              mainAxisSpacing: ThemeConstants.spacingMd,
            ),
            itemCount: darkThemes.length,
            itemBuilder: (context, index) {
              final appTheme = darkThemes[index];
              final isSelected = themeProvider.currentTheme.id == appTheme.id;
              return ThemeSelectorCard(
                theme: appTheme,
                isSelected: isSelected,
                isCompact: false,
                onTap: () async {
                  await themeProvider.setTheme(appTheme);
                  if (mounted)
                    SnackbarUtils.success(
                      context,
                      '${appTheme.name} theme applied',
                    );
                },
              );
            },
          ),

          // Custom Themes Section
          if (_customThemes.isNotEmpty) ...[
            const SizedBox(height: ThemeConstants.spacingXl),
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: themeProvider.currentTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Custom Themes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeConstants.spacingMd),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: ThemeConstants.spacingMd,
                mainAxisSpacing: ThemeConstants.spacingMd,
              ),
              itemCount: _customThemes.length,
              itemBuilder: (context, index) {
                final customTheme = _customThemes[index];
                final isSelected =
                    themeProvider.currentTheme.id == customTheme.id;
                return Stack(
                  children: [
                    ThemeSelectorCard(
                      theme: customTheme,
                      isSelected: isSelected,
                      isCompact: false,
                      onTap: () async {
                        await themeProvider.setTheme(customTheme);
                        if (mounted)
                          SnackbarUtils.success(
                            context,
                            '${customTheme.name} theme applied',
                          );
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _deleteCustomTheme(customTheme),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: ThemeConstants.spacingMd),
        ],
      ),
    );
  }

  Future<void> _deleteCustomTheme(AppTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Theme'),
            content: Text('Are you sure you want to delete "${theme.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final db = VitVerseDatabase.instance;
        final success = await db.customThemeDao.deleteCustomTheme(theme.id);
        if (success) {
          await _loadCustomThemes();
          if (mounted) {
            SnackbarUtils.success(context, 'Theme "${theme.name}" deleted');
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to delete theme');
        }
      }
    }
  }

  Widget _buildFontsTab(ThemeProvider themeProvider) {
    return ListView(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      children: [
        const SizedBox(height: ThemeConstants.spacingSm),
        ...AppFonts.allFonts.map((font) {
          final isSelected = themeProvider.currentFont == font.family;
          return Container(
            margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.surface,
              borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
              border: Border.all(
                color:
                    isSelected
                        ? themeProvider.currentTheme.primary
                        : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
                onTap: () async {
                  await themeProvider.setFont(font.family);
                  if (mounted)
                    SnackbarUtils.success(context, '${font.name} font applied');
                },
                child: Padding(
                  padding: const EdgeInsets.all(ThemeConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.name,
                                  style: _getGoogleFontStyle(
                                    font.family,
                                    fontSize: 16,
                                    color: themeProvider.currentTheme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  font.description,
                                  style: _getGoogleFontStyle(
                                    font.family,
                                    fontSize: 11,
                                    color: themeProvider.currentTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: themeProvider.currentTheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: ThemeConstants.spacingMd),
                      Text(
                        'A quick brown fox jumps over the lazy dog',
                        style: _getGoogleFontStyle(
                          font.family,
                          fontSize: 14,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCustomTab(ThemeProvider themeProvider) {
    return ListView(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      children: [
        Text(
          'Create Custom Theme',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeProvider.currentTheme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingLg),

        _buildInputField(
          label: 'Theme Name',
          value: _customThemeName,
          onChanged: (value) => setState(() => _customThemeName = value),
          themeProvider: themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingMd),

        _buildBaseThemeSelector(themeProvider),
        const SizedBox(height: ThemeConstants.spacingLg),

        Text(
          'Theme Colors',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeProvider.currentTheme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: ThemeConstants.spacingMd),

        _buildColorPicker(
          'Primary Color',
          _customPrimary,
          (color) => setState(() => _customPrimary = color),
          themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingMd),
        _buildColorPicker(
          'Background Color',
          _customBackground,
          (color) => setState(() => _customBackground = color),
          themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingMd),
        _buildColorPicker(
          'Surface Color',
          _customSurface,
          (color) => setState(() => _customSurface = color),
          themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingMd),
        _buildColorPicker(
          'Text Color',
          _customText,
          (color) => setState(() => _customText = color),
          themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingMd),
        _buildColorPicker(
          'Muted Color',
          _customMuted,
          (color) => setState(() => _customMuted = color),
          themeProvider,
        ),
        const SizedBox(height: ThemeConstants.spacingXl),

        _buildPreviewSection(themeProvider),
        const SizedBox(height: ThemeConstants.spacingXl),

        _buildSaveButton(themeProvider),
        const SizedBox(height: ThemeConstants.spacingMd),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          TextField(
            controller: _themeNameController,
            onChanged: onChanged,
            style: TextStyle(color: themeProvider.currentTheme.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: themeProvider.currentTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.spacingMd,
                vertical: ThemeConstants.spacingSm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseThemeSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: themeProvider.currentTheme.primary,
                size: 20,
              ),
              const SizedBox(width: ThemeConstants.spacingSm),
              Text(
                'Start from Existing Theme',
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          Text(
            'Copy colors from a preset theme to customize',
            style: TextStyle(
              color: themeProvider.currentTheme.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          DropdownButtonFormField<String>(
            value: _selectedBaseThemeId,
            dropdownColor: themeProvider.currentTheme.surface,
            decoration: InputDecoration(
              filled: true,
              fillColor: themeProvider.currentTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.spacingMd,
                vertical: ThemeConstants.spacingSm,
              ),
            ),
            hint: Text(
              'Select a theme...',
              style: TextStyle(color: themeProvider.currentTheme.muted),
            ),
            items:
                AppThemes.allThemes.map((theme) {
                  return DropdownMenuItem<String>(
                    value: theme.id,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: ThemeConstants.spacingSm),
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: themeProvider.currentTheme.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                final theme = AppThemes.allThemes.firstWhere(
                  (t) => t.id == value,
                );
                setState(() {
                  _selectedBaseThemeId = value;
                  _customPrimary = theme.primary;
                  _customBackground = theme.background;
                  _customSurface = theme.surface;
                  _customText = theme.text;
                  _customMuted = theme.muted;
                  _customIsDark = theme.isDark;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color color,
    ValueChanged<Color> onColorChanged,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  border: Border.all(
                    color: themeProvider.currentTheme.muted.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                    text:
                        color.value
                            .toRadixString(16)
                            .substring(2)
                            .toUpperCase(),
                  ),
                  style: TextStyle(
                    color: themeProvider.currentTheme.text,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeProvider.currentTheme.background,
                    prefixText: '#',
                    prefixStyle: TextStyle(
                      color: themeProvider.currentTheme.muted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ThemeConstants.radiusMd,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ThemeConstants.spacingMd,
                      vertical: ThemeConstants.spacingSm,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    if (value.length == 6) {
                      try {
                        final newColor = Color(
                          int.parse('FF$value', radix: 16),
                        );
                        onColorChanged(newColor);
                      } catch (e) {}
                    }
                  },
                ),
              ),
              const SizedBox(width: ThemeConstants.spacingSm),
              ElevatedButton(
                onPressed:
                    () => _showColorPickerDialog(
                      label,
                      color,
                      onColorChanged,
                      themeProvider,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstants.spacingMd,
                    vertical: ThemeConstants.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusMd,
                    ),
                  ),
                ),
                child: const Text('Pick'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPickerDialog(
    String label,
    Color initialColor,
    ValueChanged<Color> onColorChanged,
    ThemeProvider themeProvider,
  ) async {
    Color selectedColor = initialColor;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.currentTheme.surface,
          title: Text(
            'Pick $label',
            style: TextStyle(color: themeProvider.currentTheme.text),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                  pickerAreaHeightPercent: 0.8,
                  displayThumbColor: true,
                  enableAlpha: false,
                  labelTypes: const [],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.currentTheme.muted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onColorChanged(selectedColor);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_outlined,
                color: themeProvider.currentTheme.primary,
                size: 20,
              ),
              const SizedBox(width: ThemeConstants.spacingSm),
              Text(
                'Theme Preview',
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
          Container(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            decoration: BoxDecoration(
              color: _customBackground,
              borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              border: Border.all(
                color: themeProvider.currentTheme.muted.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(ThemeConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: _customSurface,
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusSm,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _customPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: ThemeConstants.spacingSm),
                      Text(
                        'App Preview',
                        style: TextStyle(
                          color: _customText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ThemeConstants.spacingSm),
                Container(
                  padding: const EdgeInsets.all(ThemeConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: _customSurface,
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusSm,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Text',
                        style: TextStyle(
                          color: _customText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is how your text will look',
                        style: TextStyle(color: _customMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ThemeConstants.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstants.spacingMd,
                    vertical: ThemeConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: _customPrimary,
                    borderRadius: BorderRadius.circular(
                      ThemeConstants.radiusSm,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Primary Button',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final customTheme = AppTheme(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: _customThemeName,
            primary: _customPrimary,
            background: _customBackground,
            surface: _customSurface,
            text: _customText,
            muted: _customMuted,
            isDark: _customIsDark,
          );

          // Save to database
          try {
            final db = VitVerseDatabase.instance;
            await db.customThemeDao.saveCustomTheme(customTheme);

            // Apply the theme
            await themeProvider.setTheme(customTheme);

            // Reload the list to show the new theme
            await _loadCustomThemes();

            if (mounted) {
              SnackbarUtils.success(
                context,
                'Theme "$_customThemeName" saved and applied!',
              );
              // Switch to themes tab to show the saved theme
              _onNavButtonTap(0);
            }
          } catch (e) {
            if (mounted) {
              SnackbarUtils.error(context, 'Failed to save theme: $e');
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.currentTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: ThemeConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Apply Custom Theme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
