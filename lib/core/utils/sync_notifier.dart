import 'dart:async';

/// Simple singleton to notify widgets when a sync completes successfully
class SyncNotifier {
  static final SyncNotifier _instance = SyncNotifier._internal();
  static SyncNotifier get instance => _instance;

  SyncNotifier._internal();

  final _syncCompleteController = StreamController<void>.broadcast();

  /// Stream that widgets can listen to for sync completion events
  Stream<void> get onSyncComplete => _syncCompleteController.stream;

  /// Call this after a successful sync to notify all listeners
  void notifySyncComplete() {
    _syncCompleteController.add(null);
  }

  /// Dispose the stream controller (call in app dispose if needed)
  void dispose() {
    _syncCompleteController.close();
  }
}
