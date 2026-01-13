import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/config/app_config.dart';
import '../models/lost_found_item.dart';
import 'lost_found_cache_service.dart';
import '../services/image_compression_service.dart';

/// Lost & Found repository
/// Handles all data operations
class LostFoundRepository {
  static const String _tag = 'LostFoundRepo';

  final SupabaseClient _supabase = SupabaseClientService.client;
  final _cacheService = LostFoundCacheService();

  /// Get items (cache-first approach)
  Future<List<LostFoundItem>> getItems() async {
    try {
      // Try cache first
      final cached = await _cacheService.getCachedItems();
      if (cached.isNotEmpty) {
        Logger.d(_tag, 'Showing ${cached.length} cached items');
        // Fetch in background
        _refreshInBackground();
        return cached;
      }

      // No cache - fetch from Supabase
      return await _fetchFromSupabase();
    } catch (e, stack) {
      Logger.e(_tag, 'Error getting items', e, stack);
      return [];
    }
  }

  /// Get user's posts
  Future<List<LostFoundItem>> getMyPosts(String regNo) async {
    try {
      Logger.d(_tag, 'Fetching my posts for: $regNo');

      final response = await _supabase
          .from('lost_found')
          .select()
          .eq('posted_by_regno', regNo)
          .order('created_at', ascending: false);

      final items =
          (response as List).map((e) => LostFoundItem.fromMap(e)).toList();

      Logger.success(_tag, 'Fetched ${items.length} my posts');
      return items;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching my posts', e, stack);
      rethrow;
    }
  }

  /// Fetch items from Supabase
  Future<List<LostFoundItem>> _fetchFromSupabase() async {
    try {
      Logger.d(_tag, 'Fetching items from Supabase');

      final response = await _supabase
          .from('lost_found')
          .select()
          .order('created_at', ascending: false)
          .limit(500);

      final items =
          (response as List).map((e) => LostFoundItem.fromMap(e)).toList();

      // Cache items locally for offline access
      Logger.d(_tag, 'Clearing old cache...');
      await _cacheService.clearCache();
      Logger.d(_tag, 'Saving ${items.length} items to local cache...');
      await _cacheService.saveItems(items);
      final cacheCount = await _cacheService.getCacheCount();
      Logger.success(
        _tag,
        'Fetched ${items.length} items ($cacheCount cached)',
      );

      return items;
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching from Supabase', e, stack);
      rethrow;
    }
  }

  /// Refresh in background
  void _refreshInBackground() async {
    try {
      final items = await _fetchFromSupabase();
      Logger.d(_tag, 'Background refresh: ${items.length} items');
    } catch (e) {
      Logger.w(_tag, 'Background refresh failed: $e');
    }
  }

  /// Add new item
  Future<void> addItem({
    required String type,
    required String itemName,
    required String place,
    String? description,
    required String contactName,
    required String contactNumber,
    required String postedByName,
    required String postedByRegno,
    XFile? imageFile,
    required bool notifyAll,
    required Function(double) onProgress,
  }) async {
    try {
      Logger.d(_tag, 'Adding item: $itemName');

      // Step 1: Compress and upload image if provided
      onProgress(0.2);
      String? imagePath;
      String? imageUrl;

      if (imageFile != null) {
        // Compress image first
        final compressedFile = await ImageCompressionService.compressImage(
          imageFile,
        );

        onProgress(0.4);

        // Upload to Supabase
        imagePath = await _uploadImage(compressedFile);
        imageUrl =
            '${AppConfig.supabaseUrl}/storage/v1/object/public/lost-found-images/$imagePath';

        Logger.success(_tag, 'Image uploaded: $imagePath');
      }

      onProgress(0.6);

      // Step 2: Insert to Supabase DB
      await _supabase.from('lost_found').insert({
        'type': type,
        'item_name': itemName,
        'place': place,
        'description': description,
        'contact_name': contactName,
        'contact_number': contactNumber,
        'posted_by_name': postedByName,
        'posted_by_regno': postedByRegno,
        'image_path': imagePath,
        'notify_all': notifyAll,
      });

      Logger.success(_tag, 'Item inserted to DB');

      onProgress(0.8);

      // Step 3: Send notification if enabled (Firebase Function)
      if (notifyAll) {
        await _sendNotificationViaFirebase(
          type: type,
          itemName: itemName,
          place: place,
          imageUrl: imageUrl,
        );
      }

      onProgress(1.0);

      // Clear cache to force refresh
      await _cacheService.clearCache();

      Logger.success(_tag, 'Item added successfully');
    } catch (e, stack) {
      Logger.e(_tag, 'Error adding item', e, stack);
      rethrow;
    }
  }

  /// Upload image to Supabase storage
  Future<String> _uploadImage(File imageFile) async {
    try {
      final filePath = 'lost_found/${const Uuid().v4()}.jpg';

      await _supabase.storage
          .from('lost-found-images')
          .uploadBinary(filePath, await imageFile.readAsBytes());

      return filePath;
    } catch (e, stack) {
      Logger.e(_tag, 'Error uploading image', e, stack);
      rethrow;
    }
  }

  /// Send notification via Firebase Callable Function
  Future<void> _sendNotificationViaFirebase({
    required String type,
    required String itemName,
    required String place,
    String? imageUrl,
  }) async {
    try {
      final title =
          type == 'lost' ? 'Lost Item Reported' : 'Found Item Reported';
      final message = '$itemName near $place';

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions
          .httpsCallable('sendLostFoundNotification')
          .call({
            'title': title,
            'message': message,
            'itemName': itemName,
            'place': place,
            'type': type,
            'imageUrl': imageUrl,
          });

      if (result.data['success'] == true) {
        Logger.success(_tag, 'Notification sent via Firebase');
      } else {
        Logger.w(_tag, 'Notification failed: ${result.data}');
      }
    } catch (e) {
      Logger.w(_tag, 'Notification sending failed: $e');
      // Don't throw - item was already added
    }
  }

  /// Delete item (delete image first, then DB row)
  Future<void> deleteItem(
    String itemId,
    String myRegNo, {
    String? imagePath,
  }) async {
    try {
      Logger.d(_tag, 'Deleting item: $itemId');

      // Step 1: Delete image if exists
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          await _supabase.storage.from('lost-found-images').remove([imagePath]);
          Logger.success(_tag, 'Image deleted: $imagePath');
        } catch (e) {
          Logger.w(_tag, 'Image delete failed (may not exist): $e');
        }
      }

      // Step 2: Delete DB row (with safety check)
      Logger.d(_tag, 'Attempting Supabase delete: ID=$itemId, RegNo=$myRegNo');

      // First, verify the item exists and check posted_by_regno
      final checkResponse =
          await _supabase
              .from('lost_found')
              .select('id, posted_by_regno')
              .eq('id', itemId)
              .maybeSingle();

      Logger.d(_tag, 'Item verification: $checkResponse');

      if (checkResponse == null) {
        throw Exception('Item not found in Supabase: $itemId');
      }

      final actualRegNo = checkResponse['posted_by_regno'] as String;
      Logger.d(_tag, 'Item posted by: $actualRegNo, Current user: $myRegNo');

      if (actualRegNo != myRegNo) {
        throw Exception(
          'Cannot delete: Item posted by $actualRegNo but trying to delete as $myRegNo',
        );
      }

      // Now delete the item
      final deleteResponse = await _supabase
          .from('lost_found')
          .delete()
          .eq('id', itemId);

      Logger.success(_tag, 'Supabase delete successful for item: $itemId');
      Logger.d(_tag, 'Delete response: $deleteResponse');

      // Step 3: Clear local cache to force fresh data on next load
      await _cacheService.clearCache();
      Logger.d(_tag, 'Local cache cleared');

      Logger.success(_tag, ' Item deleted completely: $itemId');
    } catch (e, stack) {
      Logger.e(_tag, 'Error deleting item', e, stack);
      rethrow;
    }
  }

  /// Force refresh
  Future<List<LostFoundItem>> forceRefresh() async {
    try {
      return await _fetchFromSupabase();
    } catch (e, stack) {
      Logger.e(_tag, 'Force refresh failed', e, stack);
      rethrow;
    }
  }
}
