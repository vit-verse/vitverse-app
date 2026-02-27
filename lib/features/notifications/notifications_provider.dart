import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase/core/supabase_client.dart';
import '../../core/utils/logger.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String title;
  final String description;
  final String? button1Label;
  final String? button1Url;
  final String? button2Label;
  final String? button2Url;
  final int displayOrder;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    this.button1Label,
    this.button1Url,
    this.button2Label,
    this.button2Url,
    this.displayOrder = 0,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      button1Label: json['button1_label'] as String?,
      button1Url: json['button1_url'] as String?,
      button2Label: json['button2_label'] as String?,
      button2Url: json['button2_url'] as String?,
      displayOrder: (json['display_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get hasButton1 =>
      (button1Label?.isNotEmpty ?? false) && (button1Url?.isNotEmpty ?? false);

  bool get hasButton2 =>
      (button2Label?.isNotEmpty ?? false) && (button2Url?.isNotEmpty ?? false);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Fetches notifications fresh from Supabase; read state is local-only.
class NotificationsProvider extends ChangeNotifier {
  static const String _tag = 'Notifications';
  static const String _prefsKey = 'read_notification_ids';
  static const String _table = 'notifications';

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Set<int> _readIds = {};

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationsProvider() {
    fetchNotifications();
  }

  /// Always fetches fresh — no local data cache.
  Future<void> fetchNotifications() async {
    if (!SupabaseClientService.isInitialized) {
      Logger.w(_tag, 'Supabase not initialized — skipping notifications fetch');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadReadIds();

      final data = await SupabaseClientService.client
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      final fetched =
          (data as List)
              .map(
                (json) =>
                    AppNotification.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      for (final n in fetched) {
        n.isRead = _readIds.contains(n.id);
      }

      _notifications = fetched;
      Logger.i(_tag, 'Fetched ${_notifications.length} notifications');
    } catch (e) {
      Logger.e(_tag, 'Failed to fetch notifications', e);
      _error = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    _readIds.add(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
    await _persistReadIds();
  }

  Future<void> markAllRead() async {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        _readIds.add(n.id);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _persistReadIds();
    }
  }

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      _readIds = raw.map(int.parse).toSet();
    } catch (e) {
      Logger.e(_tag, 'Failed to load read IDs from prefs', e);
      _readIds = {};
    }
  }

  Future<void> _persistReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        _readIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to persist read IDs', e);
    }
  }
}
