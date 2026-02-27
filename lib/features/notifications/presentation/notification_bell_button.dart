import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifications_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'notifications_page.dart';

/// Hidden when no notifications exist; shows bell + unread badge otherwise.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final provider = context.watch<NotificationsProvider>();

    // Hide entirely when there are no notifications
    if (provider.notifications.isEmpty) return const SizedBox.shrink();

    final count = provider.unreadCount;
    final hasUnread = count > 0;
    final label = count > 99 ? '99+' : '$count';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
        if (context.mounted) {
          context.read<NotificationsProvider>().fetchNotifications();
        }
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      hasUnread
                          ? theme.primary.withValues(alpha: 0.10)
                          : theme.muted.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasUnread
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  size: 20,
                  color: hasUnread ? theme.primary : theme.muted,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: label.length > 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
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
}
