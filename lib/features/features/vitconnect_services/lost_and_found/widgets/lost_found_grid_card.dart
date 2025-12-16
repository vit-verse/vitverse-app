import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/widgets/themed_lottie_widget.dart';
import '../models/lost_found_item.dart';

/// Compact grid card for Lost & Found items
class LostFoundGridCard extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onTap;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const LostFoundGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showDeleteButton = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large image section
            Expanded(flex: 3, child: _buildImageThumbnail(theme)),

            // Compact text section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item name + badge in same row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildTypeBadge(theme),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Date
                  Text(
                    _formatDate(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Delete button full width
            if (showDeleteButton && onDelete != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(ThemeData theme) {
    final hasImage = item.imagePath != null && item.imagePath!.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: 120,
        width: double.infinity,
        color: theme.colorScheme.primary.withOpacity(0.05),
        child:
            hasImage
                ? CachedNetworkImage(
                  imageUrl:
                      '${AppConfig.supabaseUrl}/storage/v1/object/public/lost-found-images/${item.imagePath}',
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Center(
                        child: ThemedLottieWidget(
                          assetPath: 'assets/lottie/lostFound.lottie',
                          width: 60,
                          height: 60,
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Center(
                        child: ThemedLottieWidget(
                          assetPath: 'assets/lottie/lostFound.lottie',
                          width: 60,
                          height: 60,
                        ),
                      ),
                )
                : Center(
                  child: ThemedLottieWidget(
                    assetPath: 'assets/lottie/lostFound.lottie',
                    width: 60,
                    height: 60,
                  ),
                ),
      ),
    );
  }

  Widget _buildTypeBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            item.isLost
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isLost ? Colors.orange : Colors.green,
          width: 0.5,
        ),
      ),
      child: Text(
        item.type.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: item.isLost ? Colors.orange[700] : Colors.green[700],
          fontWeight: FontWeight.w600,
          fontSize: 8,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
