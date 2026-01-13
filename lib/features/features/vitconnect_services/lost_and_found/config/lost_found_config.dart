/// Lost & Found Feature Configuration
class LostFoundConfig {
  // Date limits
  static const int maxPastDays =
      90; // How far back users can report lost/found items

  // FCM topic
  static const String fcmTopic = 'lost_found_update';
}
