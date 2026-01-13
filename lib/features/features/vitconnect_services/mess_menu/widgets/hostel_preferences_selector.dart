import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/utils/logger.dart';
import '../models/hostel_preferences.dart';

/// Widget for step-by-step hostel preference selection
class HostelPreferencesSelector extends StatefulWidget {
  final Function(HostelPreferences) onPreferencesSelected;
  final HostelPreferences? initialPreferences;

  const HostelPreferencesSelector({
    super.key,
    required this.onPreferencesSelected,
    this.initialPreferences,
  });

  @override
  State<HostelPreferencesSelector> createState() =>
      _HostelPreferencesSelectorState();
}

class _HostelPreferencesSelectorState extends State<HostelPreferencesSelector> {
  static const String _tag = 'HostelPreferencesSelector';

  String? _selectedGender;
  String? _selectedBlock;
  String? _selectedMessType;
  String? _caterer;
  int? _roomNumber;

  final _roomNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialPreferences();
  }

  void _loadInitialPreferences() {
    final prefs = widget.initialPreferences;
    if (prefs != null) {
      _selectedGender = prefs.gender;
      _selectedBlock = _reverseMapBlockForDisplay(prefs.gender, prefs.block);
      _selectedMessType = prefs.messType;
      _caterer = prefs.caterer;
      _roomNumber = prefs.roomNumber;
      if (prefs.roomNumber != null) {
        _roomNumberController.text = prefs.roomNumber.toString();
      }
      Logger.d(
        _tag,
        'Loaded preferences: gender=${prefs.gender}, block=${prefs.block}, display_block=$_selectedBlock, messType=${prefs.messType}',
      );
    }
  }

  String _reverseMapBlockForDisplay(String gender, String storedBlock) {
    if (storedBlock == 'CB' && gender == 'M') {
      return 'C';
    }
    if (storedBlock == 'CG' && gender == 'W') {
      return 'C';
    }
    return storedBlock;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    if (_selectedGender == null ||
        _selectedBlock == null ||
        _selectedMessType == null) {
      return;
    }

    // Map C block to CB or CG based on gender
    final mappedBlock = HostelPreferences.mapBlockToFileName(
      _selectedGender!,
      _selectedBlock!,
    );

    final preferences = HostelPreferences(
      gender: _selectedGender!,
      block: mappedBlock,
      messType: _selectedMessType!,
      caterer: _caterer,
      roomNumber: _roomNumber,
    );

    Logger.i(_tag, 'Preferences selected: ${preferences.toJson()}');
    widget.onPreferencesSelected(preferences);
  }

  bool get _canContinue {
    return _selectedGender != null &&
        _selectedBlock != null &&
        _selectedMessType != null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.muted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Setup Hostel Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your hostel details',
            style: TextStyle(fontSize: 14, color: theme.muted),
          ),
          const SizedBox(height: 24),

          // Gender Selection
          _buildSelectionSection(
            title: 'Gender',
            options: [
              _SelectOption(value: 'M', label: 'Men', icon: Icons.male),
              _SelectOption(value: 'W', label: 'Women', icon: Icons.female),
            ],
            selectedValue: _selectedGender,
            onSelect: (value) {
              setState(() {
                _selectedGender = value;
                _selectedBlock = null; // Reset block when gender changes
              });
            },
            theme: theme,
          ),

          // Block Selection (only show if gender is selected)
          if (_selectedGender != null) ...[
            const SizedBox(height: 20),
            _buildSelectionSection(
              title: 'Hostel Block',
              options:
                  HostelPreferences.getAvailableBlocks(_selectedGender!)
                      .map(
                        (block) => _SelectOption(
                          value: block,
                          label: 'Block $block',
                          icon: Icons.business,
                        ),
                      )
                      .toList(),
              selectedValue: _selectedBlock,
              onSelect: (value) {
                setState(() {
                  _selectedBlock = value;
                });
              },
              theme: theme,
            ),
          ],

          // Mess Type Selection (only show if block is selected)
          if (_selectedBlock != null) ...[
            const SizedBox(height: 20),
            _buildSelectionSection(
              title: 'Mess Type',
              options: [
                _SelectOption(value: 'V', label: 'Vegetarian', icon: Icons.eco),
                _SelectOption(
                  value: 'N',
                  label: 'Non-Veg',
                  icon: Icons.restaurant,
                ),
                _SelectOption(value: 'S', label: 'Special', icon: Icons.star),
              ],
              selectedValue: _selectedMessType,
              onSelect: (value) {
                setState(() {
                  _selectedMessType = value;
                });
              },
              theme: theme,
            ),
          ],

          // Optional: Room Number (only show if mess type is selected)
          if (_selectedMessType != null) ...[
            const SizedBox(height: 20),
            Text(
              'Room Number (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: 'Enter room number',
                hintStyle: TextStyle(color: theme.muted),
                filled: true,
                fillColor: theme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.muted.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.muted.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _roomNumber = value.isEmpty ? null : int.tryParse(value);
                });
              },
            ),
          ],

          // Continue Button
          if (_canContinue) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionSection({
    required String title,
    required List<_SelectOption> options,
    required String? selectedValue,
    required Function(String) onSelect,
    required theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              options.map((option) {
                final isSelected = selectedValue == option.value;
                return InkWell(
                  onTap: () => onSelect(option.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.primary.withValues(alpha: 0.1)
                              : theme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.primary
                                : theme.muted.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected ? theme.primary : theme.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color: isSelected ? theme.primary : theme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _SelectOption {
  final String value;
  final String label;
  final IconData icon;

  _SelectOption({required this.value, required this.label, required this.icon});
}
