import 'package:flutter/material.dart';

/// Rating slider widget for rating parameters
class RatingSlider extends StatelessWidget {
  final String label;
  final String? description;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const RatingSlider({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(value).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRatingColor(value).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _getRatingColor(value),
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRatingColor(value),
            inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.2),
            thumbColor: _getRatingColor(value),
            overlayColor: _getRatingColor(value).withOpacity(0.2),
            valueIndicatorColor: _getRatingColor(value),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 20,
            label: value.toStringAsFixed(1),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            Text(
              '10',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green.shade700;
    if (rating >= 6.0) return Colors.blue.shade700;
    if (rating >= 4.0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
