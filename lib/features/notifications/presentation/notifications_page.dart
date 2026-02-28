import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../notifications_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String _tag = 'NotificationsPage';

  @override
  void initState() {
    super.initState();
    // Always fresh fetch when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsProvider>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.text),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (provider.unreadCount > 0)
            GestureDetector(
              onTap: () {
                provider.markAllRead();
                Logger.i(_tag, 'Marked all notifications as read');
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(provider, theme),
    );
  }

  Widget _buildBody(NotificationsProvider provider, AppTheme theme) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load notifications',
              style: TextStyle(color: theme.muted, fontSize: 15),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => provider.fetchNotifications(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 40,
                    color: theme.muted,
                    height: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up.",
              style: TextStyle(fontSize: 13, color: theme.muted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(),
      color: theme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _NotificationCard(
            notification: notification,
            onRead: () => provider.markAsRead(notification.id),
          );
        },
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onRead;

  const _NotificationCard({required this.notification, required this.onRead});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _expanded = false;
  static const int _descThreshold = 120;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final n = widget.notification;
    final dateStr = DateFormat('MMM dd, yyyy').format(n.createdAt.toLocal());
    final isLong = n.description.length > _descThreshold;

    return GestureDetector(
      onTap: widget.onRead,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.surface,
            // Non-uniform border is valid here because ClipRRect above
            // handles rounding — no borderRadius on BoxDecoration needed.
            border: Border(
              left: BorderSide(
                color: n.isRead ? Colors.transparent : theme.primary,
                width: 3,
              ),
              top: BorderSide(
                color: theme.muted.withValues(alpha: 0.12),
                width: 1,
              ),
              right: BorderSide(
                color: theme.muted.withValues(alpha: 0.12),
                width: 1,
              ),
              bottom: BorderSide(
                color: theme.muted.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + NEW badge ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (!n.isRead) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Divider ───────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 1,
                  color: theme.muted.withValues(alpha: 0.12),
                ),

                // ── Description ───────────────────────────────────────────────
                Text(
                  n.description,
                  maxLines: _expanded ? null : 3,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.muted,
                    height: 1.55,
                  ),
                ),

                // ── Show more / less toggle ───────────────────────────────────
                if (isLong) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ],

                // ── Action buttons ─────────────────────────────────────────────
                if (n.hasButton1 || n.hasButton2) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (n.hasButton1)
                        Expanded(
                          child: _ActionButton(
                            label: n.button1Label!,
                            url: n.button1Url!,
                            theme: theme,
                          ),
                        ),
                      if (n.hasButton1 && n.hasButton2)
                        const SizedBox(width: 10),
                      if (n.hasButton2)
                        Expanded(
                          child: _ActionButton(
                            label: n.button2Label!,
                            url: n.button2Url!,
                            theme: theme,
                          ),
                        ),
                    ],
                  ),
                ],

                // ── Date ───────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.muted.withValues(alpha: 0.55),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final String url;
  final AppTheme theme;

  static const String _tag = 'NotifActionButton';

  const _ActionButton({
    required this.label,
    required this.url,
    required this.theme,
  });

  Future<void> _launch() async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Logger.w(_tag, 'Cannot launch url: $url');
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to launch url: $url', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primary.withValues(alpha: 0.35)),
          color: theme.primary.withValues(alpha: 0.06),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
