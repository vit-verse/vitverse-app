import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';

class CalculatorInputCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final TextEditingController controller;
  final String? suffixText;
  final double? minValue;
  final double? maxValue;
  final Function(String)? onChanged;
  final bool enabled;

  const CalculatorInputCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.controller,
    this.suffixText,
    this.minValue,
    this.maxValue,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
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
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: theme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
            decoration: InputDecoration(
              suffixText: suffixText,
              suffixStyle: TextStyle(
                fontSize: 14,
                color: theme.muted,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.border.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              if (onChanged != null) {
                onChanged!(value);
              }
            },
          ),
          if (minValue != null && maxValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Range: ${minValue?.toStringAsFixed(1) ?? "0.0"} - ${maxValue?.toStringAsFixed(1) ?? "10.0"}',
                style: TextStyle(fontSize: 11, color: theme.muted),
              ),
            ),
        ],
      ),
    );
  }
}
