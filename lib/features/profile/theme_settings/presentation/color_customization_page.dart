import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../firebase/analytics/analytics_service.dart';

class ColorCustomizationPage extends StatefulWidget {
  const ColorCustomizationPage({super.key});

  @override
  State<ColorCustomizationPage> createState() => _ColorCustomizationPageState();
}

class _ColorCustomizationPageState extends State<ColorCustomizationPage> {
  late AttendanceColorScheme _attendanceScheme;
  late MarksColorScheme _marksScheme;
  bool _useThemeForFeatureIcons = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ColorCustomization',
      screenClass: 'ColorCustomizationPage',
    );
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _attendanceScheme = themeProvider.attendanceColorScheme;
    _marksScheme = themeProvider.marksColorScheme;
    _loadFeatureIconsPreference();
  }

  Future<void> _loadFeatureIconsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useThemeForFeatureIcons =
          prefs.getBool('use_theme_for_feature_icons') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(title: Text('Color Customization'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        children: [
          const SizedBox(height: ThemeConstants.spacingSm),

          // Attendance Color Section
          _buildSectionHeader(context, 'Attendance Colors', themeProvider),
          const SizedBox(height: ThemeConstants.spacingMd),
          _buildAttendanceColorOptions(themeProvider),
          const SizedBox(height: ThemeConstants.spacingXl),

          // Marks Color Section
          _buildSectionHeader(context, 'Marks Colors', themeProvider),
          const SizedBox(height: ThemeConstants.spacingMd),
          _buildMarksColorOptions(themeProvider),
          const SizedBox(height: ThemeConstants.spacingXl),

          // Feature Icons Section
          _buildSectionHeader(context, 'Feature Icons', themeProvider),
          const SizedBox(height: ThemeConstants.spacingMd),
          _buildFeatureIconsOptions(themeProvider),
          const SizedBox(height: ThemeConstants.spacingXl),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Save all color schemes
                await themeProvider.setAttendanceColorScheme(_attendanceScheme);
                await themeProvider.setMarksColorScheme(_marksScheme);

                // Save feature icons preference
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                  'use_theme_for_feature_icons',
                  _useThemeForFeatureIcons,
                );

                if (context.mounted) {
                  SnackbarUtils.success(context, 'Color customizations saved!');
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
              child: const Text(
                'Save Customizations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingMd),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ThemeProvider themeProvider,
  ) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: themeProvider.currentTheme.text,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAttendanceColorOptions(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Mode Selection
          Text(
            'Color Mode',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),

          // Toggle buttons for color mode selection
          Column(
            children: [
              _buildToggleOption(
                'Color Ranges',
                'Range-based colors',
                _attendanceScheme.useRanges,
                () {
                  setState(() {
                    _attendanceScheme = AttendanceColorScheme.defaultScheme;
                  });
                },
                themeProvider,
              ),
              const SizedBox(height: 8),
              _buildToggleOption(
                'Match App Theme',
                'Use theme color',
                _attendanceScheme.autoMatchTheme,
                () {
                  setState(() {
                    _attendanceScheme = AttendanceColorScheme.autoThemeScheme();
                  });
                },
                themeProvider,
              ),
              const SizedBox(height: 8),
              _buildToggleOption(
                'Custom Color',
                'Single color',
                !_attendanceScheme.useRanges &&
                    !_attendanceScheme.autoMatchTheme,
                () {
                  setState(() {
                    final primaryColor = themeProvider.currentTheme.primary;
                    _attendanceScheme =
                        AttendanceColorScheme.primaryColorScheme(primaryColor);
                  });
                },
                themeProvider,
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),

          // Color Options based on mode
          if (_attendanceScheme.useRanges)
            _buildAttendanceRangeOptions(themeProvider)
          else if (!_attendanceScheme.autoMatchTheme)
            _buildAttendancePrimaryColorOption(themeProvider)
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Auto-matches theme color',
                style: TextStyle(
                  color: themeProvider.currentTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRangeOptions(ThemeProvider themeProvider) {
    return Column(
      children: [
        ..._attendanceScheme.ranges.map((range) {
          final index = _attendanceScheme.ranges.indexOf(range);
          return _buildRangeOption(
            themeProvider,
            'Attendance ${range.min.toInt()}-${range.max == 101 ? 100 : range.max.toInt()}%',
            range.color,
            (color) {
              final newRanges = List<AttendanceColorRange>.from(
                _attendanceScheme.ranges,
              );
              newRanges[index] = AttendanceColorRange(
                min: range.min,
                max: range.max,
                color: color,
              );
              setState(() {
                _attendanceScheme = _attendanceScheme.copyWith(
                  ranges: newRanges,
                );
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildAttendancePrimaryColorOption(ThemeProvider themeProvider) {
    return _buildColorOption(
      themeProvider,
      'Primary Color',
      _attendanceScheme.primaryColor ?? themeProvider.currentTheme.primary,
      (color) {
        setState(() {
          _attendanceScheme = AttendanceColorScheme.primaryColorScheme(color);
        });
      },
    );
  }

  Widget _buildMarksColorOptions(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Mode Selection
          Text(
            'Color Mode',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),

          // Toggle buttons for color mode selection
          Column(
            children: [
              _buildToggleOption(
                'Color Ranges',
                'Range-based colors',
                _marksScheme.useRanges,
                () {
                  setState(() {
                    _marksScheme = MarksColorScheme.defaultScheme;
                  });
                },
                themeProvider,
              ),
              const SizedBox(height: 8),
              _buildToggleOption(
                'Match App Theme',
                'Use theme color',
                _marksScheme.autoMatchTheme,
                () {
                  setState(() {
                    _marksScheme = MarksColorScheme.autoThemeScheme();
                  });
                },
                themeProvider,
              ),
              const SizedBox(height: 8),
              _buildToggleOption(
                'Custom Color',
                'Single color',
                !_marksScheme.useRanges && !_marksScheme.autoMatchTheme,
                () {
                  setState(() {
                    final primaryColor = themeProvider.currentTheme.primary;
                    _marksScheme = MarksColorScheme.primaryColorScheme(
                      primaryColor,
                    );
                  });
                },
                themeProvider,
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMd),

          // Color Options based on mode
          if (_marksScheme.useRanges)
            _buildMarksRangeOptions(themeProvider)
          else if (!_marksScheme.autoMatchTheme)
            _buildMarksPrimaryColorOption(themeProvider)
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Auto-matches theme color',
                style: TextStyle(
                  color: themeProvider.currentTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarksRangeOptions(ThemeProvider themeProvider) {
    return Column(
      children: [
        ..._marksScheme.ranges.map((range) {
          final index = _marksScheme.ranges.indexOf(range);
          return _buildRangeOption(
            themeProvider,
            'Marks ${range.min.toInt()}-${range.max == 101 ? 100 : range.max.toInt()}%',
            range.color,
            (color) {
              final newRanges = List<MarksColorRange>.from(_marksScheme.ranges);
              newRanges[index] = MarksColorRange(
                min: range.min,
                max: range.max,
                color: color,
              );
              setState(() {
                _marksScheme = _marksScheme.copyWith(ranges: newRanges);
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildMarksPrimaryColorOption(ThemeProvider themeProvider) {
    return _buildColorOption(
      themeProvider,
      'Primary Color',
      _marksScheme.primaryColor ?? themeProvider.currentTheme.primary,
      (color) {
        setState(() {
          _marksScheme = MarksColorScheme.primaryColorScheme(color);
        });
      },
    );
  }

  Widget _buildRangeOption(
    ThemeProvider themeProvider,
    String label,
    Color color,
    ValueChanged<Color> onColorChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 8),
          GestureDetector(
            onTap:
                () => _showColorPickerDialog(
                  label,
                  color,
                  onColorChanged,
                  themeProvider,
                ),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: themeProvider.currentTheme.muted.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(
    ThemeProvider themeProvider,
    String label,
    Color color,
    ValueChanged<Color> onColorChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap:
                () => _showColorPickerDialog(
                  label,
                  color,
                  onColorChanged,
                  themeProvider,
                ),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: themeProvider.currentTheme.muted.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
            ),
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
            'Pick $label Color',
            style: TextStyle(color: themeProvider.currentTheme.text),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) => selectedColor = color,
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
              labelTypes: const [],
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

  Widget _buildFeatureIconsOptions(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle for feature icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match App Theme',
                      style: TextStyle(
                        color: themeProvider.currentTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _useThemeForFeatureIcons
                          ? 'Theme colors'
                          : 'Feature-specific colors',
                      style: TextStyle(
                        color: themeProvider.currentTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useThemeForFeatureIcons,
                onChanged: (value) {
                  setState(() {
                    _useThemeForFeatureIcons = value;
                  });
                },
                activeColor: themeProvider.currentTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool isActive,
    VoidCallback onTap,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.currentTheme.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeProvider.currentTheme.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (_) => onTap(),
            activeColor: themeProvider.currentTheme.primary,
          ),
        ],
      ),
    );
  }
}
