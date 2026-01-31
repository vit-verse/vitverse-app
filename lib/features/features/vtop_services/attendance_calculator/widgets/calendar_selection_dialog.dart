import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_constants.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../calendar/data/calendar_cache_service.dart';
import '../../../../calendar/data/calendar_repository.dart';
import '../../../../calendar/models/calendar_event.dart';

class CalendarSelectionDialog extends StatefulWidget {
  final Function(
    String calendarId,
    String calendarName,
    CalendarData calendarData,
  )
  onCalendarSelected;

  const CalendarSelectionDialog({super.key, required this.onCalendarSelected});

  @override
  State<CalendarSelectionDialog> createState() =>
      _CalendarSelectionDialogState();
}

class _CalendarSelectionDialogState extends State<CalendarSelectionDialog> {
  final CalendarCacheService _cacheService = CalendarCacheService();
  final CalendarRepository _repository = CalendarRepository();

  bool _isLoading = true;
  List<CalendarItem> _calendars = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _cacheService.initialize();
      await _repository.initialize();

      final metadata = await _repository.fetchMetadata(useCache: true);

      if (metadata == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load calendars';
        });
        return;
      }

      final calendars = <CalendarItem>[];
      for (final semester in metadata.semesters) {
        for (final classGroup in semester.classGroups) {
          final calendarData = await _cacheService.getCachedCalendarData(
            classGroup.filePath,
          );
          if (calendarData != null) {
            calendars.add(
              CalendarItem(
                id: '${semester.semesterFolder}_${classGroup.classGroup}',
                name: '${semester.semesterName} - ${classGroup.classGroup}',
                semesterName: semester.semesterName,
                classGroup: classGroup.classGroup,
                filePath: classGroup.filePath,
                data: calendarData,
              ),
            );
          }
        }
      }

      setState(() {
        _calendars = calendars;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.e(
        'CalendarSelectionDialog',
        'Failed to load calendars',
        e,
        stackTrace,
      );
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load calendars: ${e.toString()}';
      });
    }
  }

  int _countTotalEvents(CalendarData calendarData) {
    int count = 0;
    for (final month in calendarData.months.values) {
      for (final day in month.events.days) {
        count += day.events.length;
      }
    }
    return count;
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(ThemeConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Calendar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: ThemeConstants.spacingSm),
            Container(
              padding: const EdgeInsets.all(ThemeConstants.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: ThemeConstants.spacingXs),
                  Expanded(
                    child: Text(
                      'If your calendar is not shown here, go to Calendar Settings and fetch calendar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeConstants.spacingMd),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: ThemeConstants.spacingSm),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ThemeConstants.spacingMd),
                      ElevatedButton.icon(
                        onPressed: _loadCalendars,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_calendars.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: ThemeConstants.spacingSm),
                      Text(
                        'No calendars available',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ThemeConstants.spacingXs),
                      Text(
                        'Please fetch calendars from Settings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = _calendars[index];
                    final totalEvents = _countTotalEvents(calendar.data);
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: ThemeConstants.spacingSm,
                      ),
                      child: InkWell(
                        onTap: () {
                          widget.onCalendarSelected(
                            calendar.id,
                            calendar.name,
                            calendar.data,
                          );
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(
                          ThemeConstants.radiusSm,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            ThemeConstants.spacingSm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.calendar_month,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: ThemeConstants.spacingSm,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          calendar.classGroup,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          calendar.semesterName,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              const SizedBox(height: ThemeConstants.spacingSm),
                              Container(
                                padding: const EdgeInsets.all(
                                  ThemeConstants.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    ThemeConstants.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoChip(
                                      theme,
                                      Icons.event,
                                      '$totalEvents Events',
                                    ),
                                    _buildInfoChip(
                                      theme,
                                      Icons.update,
                                      calendar.data.lastUpdated.split('at')[0],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CalendarItem {
  final String id;
  final String name;
  final String semesterName;
  final String classGroup;
  final String filePath;
  final CalendarData data;

  CalendarItem({
    required this.id,
    required this.name,
    required this.semesterName,
    required this.classGroup,
    required this.filePath,
    required this.data,
  });
}
