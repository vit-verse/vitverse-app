import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/theme_constants.dart';

/// Widget for entering target attendance percentage manually
class TargetAttendanceInput extends StatefulWidget {
  final double targetPercentage;
  final Function(double) onChanged;

  const TargetAttendanceInput({
    super.key,
    required this.targetPercentage,
    required this.onChanged,
  });

  @override
  State<TargetAttendanceInput> createState() => _TargetAttendanceInputState();
}

class _TargetAttendanceInputState extends State<TargetAttendanceInput> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.targetPercentage.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(TargetAttendanceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetPercentage != oldWidget.targetPercentage) {
      _controller.text = widget.targetPercentage.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndUpdate(String value) {
    if (value.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a value';
      });
      return;
    }

    final number = double.tryParse(value);
    if (number == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
      });
      return;
    }

    if (number < 0 || number > 100) {
      setState(() {
        _errorMessage = 'Value must be between 0 and 100';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });
    widget.onChanged(number);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Row(
      children: [
        // Compact label
        Text(
          'Target:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: ThemeConstants.spacingSm),
        // Smaller input field
        SizedBox(
          width: 100,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.text,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '75',
              suffixText: '%',
              suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: theme.muted,
                fontWeight: FontWeight.w600,
              ),
              errorText: _errorMessage,
              filled: true,
              fillColor: theme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.spacingSm,
                vertical: ThemeConstants.spacingSm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide(
                  color: theme.muted.withOpacity(0.2),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide(
                  color: theme.muted.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide(color: theme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide(
                  color:
                      theme.isDark
                          ? const Color(0xFFEF5350)
                          : const Color(0xFFE53935),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                borderSide: BorderSide(
                  color:
                      theme.isDark
                          ? const Color(0xFFEF5350)
                          : const Color(0xFFE53935),
                  width: 2,
                ),
              ),
            ),
            onChanged: _validateAndUpdate,
            onSubmitted: _validateAndUpdate,
          ),
        ),
      ],
    );
  }
}
