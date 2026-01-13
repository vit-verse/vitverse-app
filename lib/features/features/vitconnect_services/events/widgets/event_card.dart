import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/event_model.dart';
import '../presentation/event_detail_page.dart';
import '../logic/events_provider.dart';
import '../../../../../core/widgets/themed_lottie_widget.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/logger.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.showDeleteButton = false,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    final currentEvent = eventsProvider.events.firstWhere(
      (e) => e.id == widget.event.id,
      orElse: () => widget.event,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EventDetailPage(
                  event: currentEvent,
                  provider: eventsProvider,
                ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildPoster()],
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 9,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.event.formattedDate,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        // Venue
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 9,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.venue,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        // Entry fee
                        Row(
                          children: [
                            Text(
                              widget.event.formattedEntryFee,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Like and comment counts (very small)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 10,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${currentEvent.likesCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.comment,
                                size: 10,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${currentEvent.commentsCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Today/Tomorrow tag
                        if (_getEventDayTag() != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getEventDayTag() == 'TODAY'
                                      ? Colors.green.withValues(alpha: 0.8)
                                      : Colors.blue.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getEventDayTag()!,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final jsonString = prefs.getString('student_profile');
                          if (jsonString == null || jsonString.isEmpty) {
                            if (context.mounted) {
                              SnackbarUtils.error(
                                context,
                                'Please login to VTOP first to like events',
                              );
                            }
                            return;
                          }

                          final json =
                              jsonDecode(jsonString) as Map<String, dynamic>;
                          final regNo = json['registerNumber'] as String?;
                          if (regNo == null || regNo.isEmpty) {
                            if (context.mounted) {
                              SnackbarUtils.error(
                                context,
                                'Please login to VTOP first to like events',
                              );
                            }
                            return;
                          }

                          final wasLiked = currentEvent.isLikedByMe;
                          await eventsProvider.toggleLike(
                            currentEvent.id,
                            regNo,
                          );
                          if (context.mounted) {
                            SnackbarUtils.success(
                              context,
                              wasLiked ? 'Removed like' : 'Liked!',
                            );
                          }
                        } catch (e) {
                          Logger.e('EventCard', 'Failed to toggle like', e);
                          if (context.mounted) {
                            SnackbarUtils.error(
                              context,
                              'Failed to update like',
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentEvent.isLikedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color:
                              currentEvent.isLikedByMe
                                  ? Colors.red
                                  : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  // Verified badge
                  if (widget.event.isVerified)
                    Positioned(
                      top: 8,
                      left: 50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Delete button full width
            if (widget.showDeleteButton && widget.onDelete != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDelete,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
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
                            style: TextStyle(
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

  String? _getEventDayTag() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(
      widget.event.eventDate.year,
      widget.event.eventDate.month,
      widget.event.eventDate.day,
    );

    if (eventDay.isAtSameMomentAs(today)) {
      return 'TODAY';
    } else if (eventDay.isAtSameMomentAs(tomorrow)) {
      return 'TOMORROW';
    }
    return null;
  }

  Widget _buildPoster() {
    if (widget.event.posterUrl != null && widget.event.posterUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.event.posterUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          // Only show loader if image hasn't been loaded yet
          if (!_imageLoaded) {
            return Container(
              height: 180,
              color: Colors.grey[300],
              child: const Center(
                child: ThemedLottieWidget(
                  assetPath: 'assets/lottie/loading1.lottie',
                  width: 60,
                  height: 60,
                ),
              ),
            );
          }
          // If image was loaded before, show a subtle placeholder
          return Container(
            height: 180,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          );
        },
        errorWidget:
            (context, url, error) => Container(
              height: 180,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.event, size: 60)),
            ),
        imageBuilder: (context, imageProvider) {
          // Mark as loaded when image successfully loads
          if (!_imageLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _imageLoaded = true);
              }
            });
          }
          return Container(
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    return Container(
      height: 180,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.event, size: 60)),
    );
  }
}
