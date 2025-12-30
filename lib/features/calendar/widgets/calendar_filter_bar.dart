import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_provider.dart';

class CalendarFilterBar extends StatelessWidget {
  const CalendarFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final options = provider.getCalendarFilterOptions();

        if (options.length <= 1) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = provider.selectedCalendarFilter == option;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  height: 44, // Fixed height for all buttons
                  child: FilterChip(
                    label: SizedBox(
                      height: 32,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDisplayName(option),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (option != 'all')
                            Text(
                              _getLastSyncText(provider, option),
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color:
                                    isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withValues(alpha: 0.9)
                                        : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),

                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (s) => provider.setCalendarFilter(option),

                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withValues(alpha: 0.3),

                    side: BorderSide(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.4),
                      width: 1,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getDisplayName(String option) {
    if (option == 'all') return 'All';
    if (option == 'personal') return 'Personal';

    // Extract class group name from calendar ID
    final parts = option.split('_');
    if (parts.length >= 2) {
      return parts.last;
    }

    return option;
  }

  String _getLastSyncText(CalendarProvider provider, String calendarId) {
    // Personal calendar is local only, no sync needed
    if (calendarId == 'personal') {
      return 'N/A';
    }

    final lastSync = provider.getLastSyncTime(calendarId);
    if (lastSync == null) return 'Not synced';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }
}
