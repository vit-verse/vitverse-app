import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_provider.dart';

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<CalendarViewType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CalendarViewType>(
                      value: CalendarViewType.month,
                      label: Text('Month View'),
                    ),
                    ButtonSegment<CalendarViewType>(
                      value: CalendarViewType.timeline,
                      label: Text('Timeline'),
                    ),
                  ],
                  selected: {provider.viewType},
                  onSelectionChanged: (Set<CalendarViewType> newSelection) {
                    provider.setViewType(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
