import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/database/entities/student_profile.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../../../../../core/utils/logger.dart';
import '../../logic/lost_found_provider.dart';
import '../../widgets/lost_found_grid_card.dart';
import '../../widgets/lost_found_detail_dialog.dart';
import '../../widgets/empty_state.dart';

/// Me tab (user's posts)
class MeTab extends StatefulWidget {
  final String searchQuery;

  const MeTab({super.key, this.searchQuery = ''});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  static const String _tag = 'MeTab';
  StudentProfile? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndPosts();
  }

  Future<void> _loadProfileAndPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson != null && profileJson.isNotEmpty) {
        final profile = StudentProfile.fromJson(jsonDecode(profileJson));
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });

        // Load posts
        if (mounted) {
          final provider = Provider.of<LostFoundProvider>(
            context,
            listen: false,
          );
          await provider.loadMyPosts(profile.registerNumber);
        }
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading profile', e);
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _onRefresh() async {
    if (_profile != null) {
      final provider = Provider.of<LostFoundProvider>(context, listen: false);
      await provider.loadMyPosts(_profile!.registerNumber);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    String? imagePath,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text(
              'This item will be permanently removed. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<LostFoundProvider>(context, listen: false);
      final success = await provider.deleteItem(
        itemId,
        _profile!.registerNumber,
        imagePath: imagePath,
      );

      if (mounted) {
        if (success) {
          SnackbarUtils.success(context, 'Item deleted successfully');
        } else {
          SnackbarUtils.error(context, 'Failed to delete item');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<LostFoundProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingMyPosts) {
          return const Center(child: CircularProgressIndicator());
        }

        var myPosts = provider.myPosts;

        // Filter by search query
        if (widget.searchQuery.isNotEmpty) {
          myPosts =
              myPosts.where((item) {
                return item.itemName.toLowerCase().contains(
                      widget.searchQuery,
                    ) ||
                    item.place.toLowerCase().contains(widget.searchQuery) ||
                    (item.description?.toLowerCase().contains(
                          widget.searchQuery,
                        ) ??
                        false);
              }).toList();
        }

        if (myPosts.isEmpty) {
          return LostFoundEmptyState(
            message:
                widget.searchQuery.isEmpty
                    ? "You haven't posted anything yet"
                    : 'No items match your search',
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: myPosts.length,
            itemBuilder: (context, index) {
              final item = myPosts[index];
              return LostFoundGridCard(
                item: item,
                onTap: () => LostFoundDetailDialog.show(context, item),
                showDeleteButton: true,
                onDelete:
                    () => _confirmDelete(context, item.id, item.imagePath),
              );
            },
          ),
        );
      },
    );
  }
}
