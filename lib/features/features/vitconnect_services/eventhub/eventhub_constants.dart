class EventHubConstants {
  static const String baseUrl = 'https://eventhubcc.vit.ac.in';
  static const String eventsEndpoint = '/EventHub/';

  static const String cacheKey = 'eventhub_events_cache';
  static const String timestampKey = 'eventhub_last_refresh';
  static const int cacheExpiryHours = 1;

  static const int networkTimeoutSeconds = 30;
  static const int addToCalendarDurationHours = 2;

  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}
