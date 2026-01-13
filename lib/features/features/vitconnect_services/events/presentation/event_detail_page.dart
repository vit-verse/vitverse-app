import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/event_model.dart';
import '../models/event_comment_model.dart';
import '../logic/events_provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/widgets/themed_lottie_widget.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/logger.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;
  final EventsProvider provider;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.provider,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  List<EventComment> _comments = [];
  bool _isLoadingComments = false;
  late Event _currentEvent;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadComments();
    _loadCurrentUserId();
    widget.provider.addListener(_updateEventFromProvider);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_updateEventFromProvider);
    _commentController.dispose();
    super.dispose();
  }

  void _updateEventFromProvider() {
    final updatedEvent = widget.provider.events.firstWhere(
      (e) => e.id == widget.event.id,
      orElse: () => _currentEvent,
    );
    if (mounted && updatedEvent != _currentEvent) {
      Logger.d(
        'EventDetail',
        'Event updated - Likes: ${updatedEvent.likesCount}, Comments: ${updatedEvent.commentsCount}, IsLiked: ${updatedEvent.isLikedByMe}',
      );
      setState(() => _currentEvent = updatedEvent);
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('student_profile');
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        setState(() {
          _currentUserId = json['registerNumber'] as String?;
        });
      }
    } catch (e) {
      Logger.e('EventDetail', 'Failed to load current user ID', e);
    }
  }

  Future<String?> _getUserRegNo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('student_profile');
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json['registerNumber'] as String?;
      }
    } catch (e) {
      Logger.e('EventDetail', 'Failed to get user reg no', e);
    }
    return null;
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await widget.provider.fetchComments(widget.event.id);
      Logger.d(
        'EventDetail',
        'Loaded ${comments.length} comments for event ${widget.event.id}',
      );
      setState(() => _comments = comments);
    } catch (e) {
      Logger.e('EventDetail', 'Failed to load comments', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load comments');
      }
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    final regNo = await _getUserRegNo();
    if (regNo == null || regNo.isEmpty) {
      if (mounted) {
        SnackbarUtils.error(
          context,
          'Please login to VTOP first to like events',
        );
      }
      return;
    }

    final wasLiked = _currentEvent.isLikedByMe;
    try {
      await widget.provider.toggleLike(widget.event.id, regNo);
      if (mounted) {
        SnackbarUtils.success(context, wasLiked ? 'Removed like' : 'Liked!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update like');
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('student_profile');
    if (jsonString == null || jsonString.isEmpty) {
      if (mounted) {
        SnackbarUtils.error(
          context,
          'Please login to VTOP first to comment on events',
        );
      }
      return;
    }

    String userName = 'Anonymous';
    String userId = 'guest';
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      userName = json['name'] as String? ?? 'Anonymous';
      userId = json['registerNumber'] as String? ?? 'guest';
    } catch (e) {
      Logger.e('EventDetail', 'Failed to parse user profile', e);
    }

    try {
      await widget.provider.addComment(
        widget.event.id,
        userId,
        userName,
        _commentController.text,
      );
      _commentController.clear();
      await _loadComments();
      if (mounted) {
        SnackbarUtils.success(context, 'Comment added');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to add comment');
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
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

    if (confirmed == true) {
      try {
        await widget.provider.deleteComment(commentId);
        await _loadComments();
        if (mounted) {
          SnackbarUtils.success(context, 'Comment deleted');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to delete comment');
        }
      }
    }
  }

  void _shareEvent() {
    String eventUrl = '';

    if (widget.event.source == 'official') {
      eventUrl = 'https://eventhubcc.vit.ac.in/EventHub/';
    } else if (widget.event.eventLink != null &&
        widget.event.eventLink!.isNotEmpty) {
      eventUrl = widget.event.eventLink!;
    }

    final posterUrl = widget.event.posterUrl ?? '';

    final text = '''
${widget.event.title}

📅 ${widget.event.formattedDate}
📍 ${widget.event.venue}
💰 ${widget.event.formattedEntryFee}

${widget.event.description}

${eventUrl.isNotEmpty ? '🔗 $eventUrl' : ''}
${posterUrl.isNotEmpty ? '🖼️ $posterUrl' : ''}
''';
    Share.share(text.trim());
  }

  Future<void> _downloadPoster() async {
    if (widget.event.posterUrl == null || widget.event.posterUrl!.isEmpty) {
      if (mounted) {
        SnackbarUtils.error(context, 'No poster available to download');
      }
      return;
    }

    try {
      // Show loading
      if (mounted) {
        SnackbarUtils.info(context, 'Downloading poster...');
      }

      // Download image
      final response = await http.get(Uri.parse(widget.event.posterUrl!));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to gallery
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'VITVerse_Event_${widget.event.id}_$timestamp.jpg';

      final result = await ImageGallerySaverPlus.saveImage(
        response.bodyBytes,
        name: fileName,
        quality: 100,
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          SnackbarUtils.success(context, 'Poster saved to gallery');
        } else {
          SnackbarUtils.error(context, 'Failed to save poster');
        }
      }
    } catch (e) {
      Logger.e('EventDetail', 'Failed to download poster', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to download poster');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.background,
        resizeToAvoidBottomInset: true,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(theme),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventDetails(theme),
                  const Divider(height: 32),
                  _buildCommentSection(theme),
                  const SizedBox(height: 16),
                  _buildBottomActions(theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(theme) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: theme.surface,
      iconTheme: IconThemeData(color: theme.text),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.background,
            child: Stack(
              children: [
                Center(child: _buildPosterImage()),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Download button
                      if (widget.event.posterUrl != null &&
                          widget.event.posterUrl!.isNotEmpty)
                        GestureDetector(
                          onTap: _downloadPoster,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      if (widget.event.posterUrl != null &&
                          widget.event.posterUrl!.isNotEmpty)
                        const SizedBox(width: 12),
                      // Like button
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentEvent.isLikedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _currentEvent.isLikedByMe
                                    ? Colors.red
                                    : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Share button
                      GestureDetector(
                        onTap: _shareEvent,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchEventUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackbarUtils.error(context, 'Cannot open link');
        }
      }
    } catch (e) {
      Logger.e('EventDetail', 'Failed to launch URL', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to open link');
      }
    }
  }

  Widget _buildPosterImage() {
    if (widget.event.posterUrl != null && widget.event.posterUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.event.posterUrl!,
        fit: BoxFit.contain,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: ThemedLottieWidget(
                  assetPath: 'assets/lottie/loading1.lottie',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.event, size: 80)),
            ),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.event, size: 80)),
    );
  }

  Widget _buildEventDetails(theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
              ),
              if (widget.event.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Posted by user info (for user-posted events)
          if (widget.event.source == 'user' &&
              widget.event.userNameRegno != null &&
              widget.event.userNameRegno!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: theme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Posted by: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.event.userNameRegno!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Event Info
          _buildInfoRow(
            Icons.calendar_today,
            widget.event.formattedDate,
            theme,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, widget.event.venue, theme),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.attach_money,
            widget.event.formattedEntryFee,
            theme,
          ),
          if (widget.event.category.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category, widget.event.category, theme),
          ],
          const SizedBox(height: 16),

          // Description
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.description,
            style: TextStyle(fontSize: 14, color: theme.muted, height: 1.5),
          ),

          // Contact Info
          if (widget.event.contactInfo != null &&
              widget.event.contactInfo!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.contactInfo!,
              style: TextStyle(fontSize: 14, color: theme.muted),
            ),
          ],

          // Event Links
          const SizedBox(height: 16),

          // EventHub button for official events
          if (widget.event.source == 'official')
            _buildEventLinkButton(
              onPressed:
                  () =>
                      _launchEventUrl('https://eventhubcc.vit.ac.in/EventHub/'),
              emoji: '🌐',
              label: 'Visit EventHub',
              backgroundColor: theme.primary,
              theme: theme,
            ),

          // User event link button
          if (widget.event.source == 'user' &&
              widget.event.eventLink != null &&
              widget.event.eventLink!.isNotEmpty) ...[
            if (widget.event.source == 'official') const SizedBox(height: 12),
            _buildEventLinkButton(
              onPressed: () => _launchEventUrl(widget.event.eventLink!),
              emoji: '🌐',
              label: 'Visit Event Link',
              backgroundColor: theme.primary,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: theme.muted)),
        ),
      ],
    );
  }

  Widget _buildEventLinkButton({
    required VoidCallback onPressed,
    required String emoji,
    required String label,
    required Color backgroundColor,
    required dynamic theme,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection(theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${_comments.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingComments)
            const Center(child: CircularProgressIndicator())
          else if (_comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: TextStyle(color: theme.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._comments.map((comment) => _buildCommentItem(comment, theme)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(EventComment comment, theme) {
    final isOwnComment =
        _currentUserId != null && _currentUserId == comment.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.primary.withValues(alpha: 0.2),
                child: Text(
                  comment.userName.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: theme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comment.userName} (${comment.userId})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      _formatCommentTime(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: theme.muted),
                    ),
                  ],
                ),
              ),
              if (isOwnComment)
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteComment(comment.id),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.comment,
            style: TextStyle(fontSize: 14, color: theme.text),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.muted.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: theme.muted),
              const SizedBox(width: 4),
              Text(
                '${_currentEvent.likesCount}',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 16, color: theme.muted),
              const SizedBox(width: 4),
              Text(
                '${_currentEvent.commentsCount}',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: theme.muted),
                    filled: true,
                    fillColor: theme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: theme.text),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _currentEvent.isLikedByMe
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _currentEvent.isLikedByMe ? Colors.red : theme.primary,
                ),
                onPressed: _toggleLike,
              ),
              IconButton(
                icon: Icon(Icons.send, color: theme.primary),
                onPressed: _addComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour =
          istDateTime.hour > 12
              ? istDateTime.hour - 12
              : (istDateTime.hour == 0 ? 12 : istDateTime.hour);
      final amPm = istDateTime.hour >= 12 ? 'PM' : 'AM';
      return '${istDateTime.day} ${months[istDateTime.month - 1]} ${istDateTime.year}, $hour:${istDateTime.minute.toString().padLeft(2, '0')} $amPm IST';
    }
  }
}
