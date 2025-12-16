import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

class FCMService {
  static const String _tag = 'FCM';
  static FCMService? _instance;
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;

  FCMService._();

  static FCMService get instance => _instance ??= FCMService._();

  /// Initialize FCM service
  static Future<void> initialize(FirebaseMessaging messaging) async {
    try {
      _messaging = messaging;
      _instance = FCMService._();

      await _initializeLocalNotifications();

      await _requestPermissions();

      await _subscribeToTopics();

      await _setupMessageHandlers();

      await _getFCMToken();

      Logger.success(_tag, 'FCM service initialized');
    } catch (e) {
      Logger.e(_tag, 'FCM service initialization failed', e);
    }
  }

  static Future<void> _subscribeToTopics() async {
    try {
      Logger.d(_tag, 'Subscribing to notification topics...');

      // Subscribe to "all_users" topic - ALL users get notifications sent to this topic
      await _messaging?.subscribeToTopic('all_users');
      Logger.success(_tag, 'Subscribed to: all_users');

      // Subscribe to "lost_found_update" topic - Lost & Found notifications (check preference)
      final lostFoundEnabled = await _getNotificationPreference(
        'lost_found_notifications',
        true,
      );
      if (lostFoundEnabled) {
        await _messaging?.subscribeToTopic('lost_found_update');
        Logger.success(_tag, 'Subscribed to: lost_found_update');
      } else {
        Logger.d(_tag, 'Skipped lost_found_update (disabled by user)');
      }

      // Subscribe to "cab_share_updates" topic - Cab Share notifications (check preference)
      final cabShareEnabled = await _getNotificationPreference(
        'cab_share_notifications',
        true,
      );
      if (cabShareEnabled) {
        await _messaging?.subscribeToTopic('cab_share_updates');
        Logger.success(_tag, 'Subscribed to: cab_share_updates');
      } else {
        Logger.d(_tag, 'Skipped cab_share_updates (disabled by user)');
      }

      Logger.d(_tag, 'Topic subscription complete');
    } catch (e, stack) {
      Logger.e(_tag, 'Failed to subscribe to topics', e, stack);
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications?.initialize(initSettings);
      await _createFCMNotificationChannel();

      Logger.d(_tag, 'Local notifications initialized');
    } catch (e) {
      Logger.e(_tag, 'Local notifications init failed', e);
    }
  }

  /// Create FCM notification channel
  static Future<void> _createFCMNotificationChannel() async {
    try {
      final androidImplementation =
          _localNotifications
              ?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation == null) return;

      const channel = AndroidNotificationChannel(
        'vit_connect_default_channel',
        'VIT Verse Notifications',
        description: 'General notifications from VIT Verse',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
    } catch (e) {
      Logger.e(_tag, 'Channel creation failed', e);
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      Logger.d(_tag, 'Permission: ${settings?.authorizationStatus}');
    } catch (e) {
      Logger.e(_tag, 'Permission request failed', e);
    }
  }

  /// Setup message handlers
  static Future<void> _setupMessageHandlers() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      Logger.e(_tag, 'Message handlers setup failed', e);
    }
  }

  /// Get FCM token
  static Future<String?> _getFCMToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        Logger.d(_tag, 'FCM Token: ${token.substring(0, 20)}...');
        return token;
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to get FCM token', e);
    }
    return null;
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      Logger.d(_tag, 'Foreground: ${message.messageId}');
      await _showLocalNotification(message);
    } catch (e) {
      Logger.e(_tag, 'Foreground handler failed', e);
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Check if notification has an image (for Lost & Found)
      final imageUrl = message.data['imageUrl'] as String?;
      final hasImage = imageUrl != null && imageUrl.isNotEmpty;

      AndroidNotificationDetails androidDetails;

      if (hasImage) {
        // Lost & Found notification with image
        try {
          androidDetails = AndroidNotificationDetails(
            'vit_connect_default_channel',
            'VIT Verse Notifications',
            channelDescription: 'General notifications from VIT Verse',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/ic_launcher',
              ),
              contentTitle: notification.title,
              summaryText: notification.body,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            ),
          );
        } catch (e) {
          // Fallback to regular notification if image loading fails
          Logger.w(_tag, 'Image notification failed, using regular: $e');
          androidDetails = const AndroidNotificationDetails(
            'vit_connect_default_channel',
            'VIT Verse Notifications',
            channelDescription: 'General notifications from VIT Verse',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
          );
        }
      } else {
        // Regular notification without image
        androidDetails = const AndroidNotificationDetails(
          'vit_connect_default_channel',
          'VIT Verse Notifications',
          channelDescription: 'General notifications from VIT Verse',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
        );
      }

      final details = NotificationDetails(android: androidDetails);

      await _localNotifications?.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      Logger.e(_tag, 'Notification display failed', e);
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      Logger.d(_tag, 'Subscribed: $topic');
    } catch (e) {
      Logger.e(_tag, 'Subscribe failed: $topic', e);
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      Logger.d(_tag, 'Unsubscribed: $topic');
    } catch (e) {
      Logger.e(_tag, 'Unsubscribe failed: $topic', e);
    }
  }

  /// Subscribe to Lost & Found topic
  static Future<void> subscribeLostFoundTopic() async {
    try {
      await _messaging?.subscribeToTopic('lost_found_update');
      Logger.success(_tag, 'Subscribed to: lost_found_update');
    } catch (e) {
      Logger.e(_tag, 'Subscribe failed: lost_found_update', e);
    }
  }

  /// Unsubscribe from Lost & Found topic
  static Future<void> unsubscribeLostFoundTopic() async {
    try {
      await _messaging?.unsubscribeFromTopic('lost_found_update');
      Logger.d(_tag, 'Unsubscribed from: lost_found_update');
    } catch (e) {
      Logger.e(_tag, 'Unsubscribe failed: lost_found_update', e);
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      Logger.e(_tag, 'Failed to get current token', e);
      return null;
    }
  }

  /// Get notification preference from SharedPreferences
  static Future<bool> _getNotificationPreference(
    String key,
    bool defaultValue,
  ) async {
    try {
      // Import shared_preferences dynamically to avoid circular imports
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      Logger.w(
        _tag,
        'Failed to get preference $key, using default: $defaultValue - Error: $e',
      );
      return defaultValue;
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _messaging?.deleteToken();
      Logger.d(_tag, 'FCM token deleted');
    } catch (e) {
      Logger.e(_tag, 'Failed to delete token', e);
    }
  }
}
