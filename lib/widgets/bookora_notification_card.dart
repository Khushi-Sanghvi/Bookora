import 'package:flutter/material.dart';
import '../theme/bookora_notification_theme.dart';
import 'book_cover_image.dart';

enum NotificationBadgeType {
  icon,
  cover,
  undo,
}

class BookoraNotificationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final NotificationBadgeType badgeType;
  final IconData? icon;
  final Color? badgeColor;
  final String? coverUrl;
  final VoidCallback? onDismiss;
  final VoidCallback? onUndo;
  final String undoText;

  const BookoraNotificationCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeType = NotificationBadgeType.icon,
    this.icon,
    this.badgeColor,
    this.coverUrl,
    this.onDismiss,
    this.onUndo,
    this.undoText = 'Undo',
  });

  @override
  Widget build(BuildContext context) {
    final theme = BookoraNotificationTheme(isDark: Theme.of(context).brightness == Brightness.dark);
    final effectiveBadgeColor = badgeColor ?? theme.successGreen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: BotanicalDecoPainter(color: effectiveBadgeColor, isDark: theme.isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _buildBadge(theme, effectiveBadgeColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onUndo != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onUndo,
                    style: TextButton.styleFrom(
                      foregroundColor: effectiveBadgeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      undoText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BookoraNotificationTheme theme, Color effectiveColor) {
    if (badgeType == NotificationBadgeType.cover && coverUrl != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: BookCoverImage(
              coverUrl: coverUrl!,
              title: title,
              author: '',
              width: 32,
              height: 48,
            ),
          ),
          if (icon != null)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: theme.isDark ? 0.2 : 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.info_outline,
        color: effectiveColor,
        size: 18,
      ),
    );
  }
}
