/// Cab Share Feature Configuration
class CabShareConfig {
  // Predefined locations for quick selection
  static const List<String> predefinedLocations = [
    'VIT Chennai Campus',
    'Chennai Airport (MAA)',
    'Chennai Central Railway Station (MGR)',
    'Tambaram',
    'Other',
  ];

  // Seat limits
  static const int maxSeats = 10;
  static const int minSeats = 1;

  // Date limits
  static const int maxFutureDays = 90; // How far ahead users can post rides

  // Cache management
  static const int cacheCleanupDays =
      7; // Auto-delete cached rides older than this

  // FCM topic
  static const String fcmTopic = 'cab_share_updates';
}
