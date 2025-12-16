import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../logic/calendar_provider.dart';
import '../models/calendar_metadata.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../firebase/analytics/analytics_service.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'calenderSettings',
      screenClass: 'calenderSettingsPage',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar Settings')),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFetchCalendarsSection(provider),
                const SizedBox(height: 32),
                _buildPersonalCalendarSection(provider),
                const SizedBox(height: 32),
                _buildInfoSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFetchCalendarsSection(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Calendars',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Fetch available calendars from GitHub',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),

        // Fetch button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isFetching ? null : () => _fetchAvailableCalendars(provider),
            child:
                _isFetching
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Fetching...'),
                      ],
                    )
                    : const Text('Fetch Available Calendars'),
          ),
        ),

        const SizedBox(height: 16),

        // Available calendars
        if (provider.metadata != null) _buildAvailableCalendarsList(provider),
      ],
    );
  }

  Widget _buildAvailableCalendarsList(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Calendars',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        ...provider.metadata!.semesters.map(
          (semester) => _buildSemesterCard(provider, semester),
        ),
      ],
    );
  }

  Widget _buildSemesterCard(CalendarProvider provider, Semester semester) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(
          semester.semesterName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${semester.classGroupCount} class groups available',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children:
            semester.classGroups
                .map(
                  (classGroup) =>
                      _buildClassGroupTile(provider, semester, classGroup),
                )
                .toList(),
      ),
    );
  }

  Widget _buildClassGroupTile(
    CalendarProvider provider,
    Semester semester,
    ClassGroup classGroup,
  ) {
    final calendarId = '${semester.semesterName}_${classGroup.classGroup}';
    final isSelected = provider.selectedCalendars.contains(calendarId);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (selected) {
        if (selected == true) {
          provider.addSelectedCalendar(calendarId);
          SnackbarUtils.success(context, 'Calendar added');
        } else {
          provider.removeSelectedCalendar(calendarId);
          SnackbarUtils.info(context, 'Calendar removed');
        }
      },
      title: Text(
        classGroup.classGroup,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last updated: ${classGroup.lastUpdated}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Months: ${classGroup.months}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Total events: ${classGroup.totalEvents} (${classGroup.totalEventDays} days)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCalendarSection(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Calendar',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your personal events using the "Add Event" button in the calendar view. All events are stored locally on your device.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About Academic Calendar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The academic calendar is community-maintained. If you find any event missing or updated, '
              'use the VIT Verse Extension to automatically fetch the latest calendar and raise a GitHub PR. '
              'Updates go live within seconds.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openGitHubRepository(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Update Calendar on GitHub'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAvailableCalendars(CalendarProvider provider) async {
    setState(() {
      _isFetching = true;
    });

    try {
      await provider.fetchMetadata(forceRefresh: true);
      if (mounted) {
        SnackbarUtils.success(context, 'Calendar data fetched from GitHub');
        Logger.i('CalendarSettings', 'Successfully fetched calendar metadata');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Connection error to GitHub');
        Logger.e('CalendarSettings', 'Failed to fetch calendar metadata', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _openGitHubRepository() async {
    try {
      const url = 'https://github.com/vit-verse/vit-academic-calendar';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.i('CalendarSettings', 'Opened GitHub repository: $url');
      } else {
        if (mounted) {
          SnackbarUtils.error(context, 'Could not open GitHub repository');
        }
      }
    } catch (e) {
      Logger.e('CalendarSettings', 'Failed to open GitHub repository', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to open GitHub repository');
      }
    }
  }
}
