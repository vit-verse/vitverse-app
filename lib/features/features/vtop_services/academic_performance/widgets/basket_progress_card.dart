import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../models/basket_with_progress.dart';

/// Basket Progress Card
/// Shows earned/in-progress/required credits for elective baskets
class BasketProgressCard extends StatelessWidget {
  final BasketWithProgress basket;

  const BasketProgressCard({super.key, required this.basket});

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
          // Title with checkmark and warning
          Row(
            children: [
              Expanded(
                child: Text(
                  basket.basketTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (basket.isExceeding)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message:
                        'Basket credits exceed required amount. Please verify.',
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                )
              else if (basket.isComplete)
                Icon(Icons.check_circle, size: 20, color: theme.primary),
            ],
          ),
          const SizedBox(height: 12),

          // Credits Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCreditInfo(theme, 'Earned', basket.earnedCredits),
              _buildCreditInfo(theme, 'In Progress', basket.inProgressCredits),
              _buildCreditInfo(theme, 'Required', basket.requiredCredits),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar (dual layer, clamped to 100%)
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Earned Progress (clamped)
              FractionallySizedBox(
                widthFactor: basket.earnedPercentageClamped / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        basket.isExceeding
                            ? Colors.red.shade400
                            : theme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Total Progress (earned + in-progress, clamped)
              FractionallySizedBox(
                widthFactor: basket.totalProgressPercentageClamped / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        basket.isExceeding
                            ? Colors.red.shade400.withValues(alpha: 0.4)
                            : theme.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status and Progress Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  basket.status,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        basket.isExceeding ? Colors.red.shade400 : theme.muted,
                    fontWeight:
                        basket.isExceeding
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ),
              // Progress percentage (earned% + added%) - clamped display
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${basket.earnedPercentageClamped.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            basket.isExceeding
                                ? Colors.red.shade400
                                : theme.text,
                      ),
                    ),
                    if (basket.inProgressCredits > 0)
                      TextSpan(
                        text:
                            ' +${(basket.totalProgressPercentageClamped - basket.earnedPercentageClamped).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              basket.isExceeding
                                  ? Colors.red.shade300
                                  : theme.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo(dynamic theme, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.muted)),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
      ],
    );
  }
}
