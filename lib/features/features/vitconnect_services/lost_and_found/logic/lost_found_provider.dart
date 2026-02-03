import 'package:flutter/foundation.dart';
import '../models/lost_found_item.dart';
import '../data/lost_found_repository.dart';
import '../../../../../core/utils/logger.dart';

/// Lost & Found provider
/// State management for Lost & Found feature
class LostFoundProvider extends ChangeNotifier {
  static const String _tag = 'LostFoundProvider';

  final _repository = LostFoundRepository();

  List<LostFoundItem> _allItems = [];
  List<LostFoundItem> _myPosts = [];
  bool _isLoading = false;
  bool _isLoadingMyPosts = false;
  bool _isDeleting = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastRefreshTime;

  List<LostFoundItem> get allItems => _allItems;
  List<LostFoundItem> get myPosts => _myPosts;
  bool get isLoading => _isLoading;
  bool get isLoadingMyPosts => _isLoadingMyPosts;
  bool get isDeleting => _isDeleting;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefreshTime => _lastRefreshTime;

  /// Get lost items
  List<LostFoundItem> get lostItems =>
      _allItems.where((item) => item.isLost).toList();

  /// Get found items
  List<LostFoundItem> get foundItems =>
      _allItems.where((item) => item.isFound).toList();

  /// Load items
  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allItems = await _repository.getItems();
      Logger.d(_tag, 'Loaded ${_allItems.length} items');
    } catch (e) {
      Logger.e(_tag, 'Error loading items', e);
      _errorMessage = 'Failed to load items';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load my posts
  Future<void> loadMyPosts(String regNo) async {
    _isLoadingMyPosts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myPosts = await _repository.getMyPosts(regNo);
      Logger.d(_tag, 'Loaded ${_myPosts.length} my posts');
    } catch (e) {
      Logger.e(_tag, 'Error loading my posts', e);
      _errorMessage = 'Failed to load your posts';
    } finally {
      _isLoadingMyPosts = false;
      notifyListeners();
    }
  }

  /// Delete item
  Future<bool> deleteItem(
    String itemId,
    String regNo, {
    String? imagePath,
  }) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.d(_tag, 'Provider: Starting delete for item: $itemId');

      // Delete from Supabase (this will also clear cache)
      await _repository.deleteItem(itemId, regNo, imagePath: imagePath);
      Logger.success(
        _tag,
        'Provider: Successfully deleted from Supabase: $itemId',
      );

      // Remove from local lists ONLY after successful Supabase deletion
      final allItemsCount = _allItems.length;
      final myPostsCount = _myPosts.length;

      _allItems.removeWhere((item) => item.id == itemId);
      _myPosts.removeWhere((item) => item.id == itemId);

      Logger.d(
        _tag,
        'Provider: Removed from local lists (all: ${allItemsCount - _allItems.length}, my: ${myPostsCount - _myPosts.length})',
      );

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      Logger.e(_tag, 'Provider: Error deleting item', e, stack);
      _errorMessage = 'Failed to delete item: ${e.toString()}';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh items
  Future<void> refresh() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      _allItems = await _repository.forceRefresh();
      _lastRefreshTime = DateTime.now();
      Logger.d(_tag, 'Refreshed ${_allItems.length} items');
    } catch (e) {
      Logger.e(_tag, 'Error refreshing items', e);
      _errorMessage = 'Failed to refresh items';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
