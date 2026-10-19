import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bookora_notification_theme.dart';
import '../widgets/bookora_notification_card.dart';
import '../widgets/book_added_notification_card.dart';
import '../widgets/profile_updated_notification_card.dart';
import '../widgets/total_pages_updated_notification_card.dart';
import '../widgets/bookmark_saved_notification_card.dart';
import '../widgets/epub_loaded_notification_card.dart';
import '../widgets/pdf_loaded_notification_card.dart';
import '../widgets/audiobook_attached_notification_card.dart';

enum NotificationType {
  success,
  info,
  warning,
  error,
  added,
  updated,
}

enum ConfirmationType {
  removeBook,
  removeQuote,
  generic,
}

class BookoraNotificationService {
  /// Category 2 & 3: Floating Toast / SnackBars (Update / Save / Success / Added)
  static void showToast(
    BuildContext context, {
    required NotificationType type,
    required String title,
    String? subtitle,
    String? coverUrl,
    VoidCallback? onUndo,
    String undoText = 'Undo',
  }) {
    final theme = BookoraNotificationTheme(isDark: Theme.of(context).brightness == Brightness.dark);
    
    IconData icon;
    Color badgeColor;
    NotificationBadgeType badgeType = NotificationBadgeType.icon;

    switch (type) {
      case NotificationType.success:
      case NotificationType.added:
        icon = Icons.check_circle_rounded;
        badgeColor = theme.successGreen;
        if (coverUrl != null) badgeType = NotificationBadgeType.cover;
        break;
      case NotificationType.info:
      case NotificationType.updated:
        icon = Icons.info_outline_rounded;
        badgeColor = theme.infoBlue;
        break;
      case NotificationType.warning:
        icon = Icons.warning_rounded;
        badgeColor = theme.warningAmber;
        break;
      case NotificationType.error:
        icon = Icons.error_outline_rounded;
        badgeColor = theme.errorRed;
        break;
    }

    // Overrides for specific messages based on title (matching design specs)
    if (title.toLowerCase().contains('quote')) {
      icon = Icons.format_quote_rounded;
      badgeColor = theme.quoteAmber;
    } else if (title.toLowerCase().contains('bookmark')) {
      icon = Icons.bookmark_rounded;
      badgeColor = theme.warningAmber;
    } else if (title.toLowerCase().contains('highlight') || title.toLowerCase().contains('note')) {
      icon = Icons.edit_note_rounded;
      badgeColor = theme.highlightPurple;
    } else if (title.toLowerCase().contains('pdf')) {
      icon = Icons.picture_as_pdf_rounded;
      badgeColor = theme.infoBlue;
    } else if (title.toLowerCase().contains('epub')) {
      icon = Icons.menu_book_rounded;
      badgeColor = theme.highlightPurple;
    } else if (title.toLowerCase().contains('ambiance') || title.toLowerCase().contains('theme')) {
      icon = Icons.nightlight_round;
      badgeColor = theme.highlightPurple;
    } else if (title.toLowerCase().contains('document') || title.toLowerCase().contains('attached')) {
      icon = Icons.attach_file_rounded;
      badgeColor = const Color(0xFFE07A5F); // Rose
    } else if (title.toLowerCase().contains('profile')) {
      icon = Icons.person_rounded;
      badgeColor = theme.successGreen;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: BookoraNotificationCard(
          title: title,
          subtitle: subtitle,
          badgeType: badgeType,
          icon: icon,
          badgeColor: badgeColor,
          coverUrl: coverUrl,
          onUndo: onUndo,
          undoText: undoText,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showBookAddedToast(BuildContext context, {required String bookTitle}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: BookAddedNotificationCard(
          bookTitle: bookTitle,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showProfileUpdatedToast(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: ProfileUpdatedNotificationCard(
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showTotalPagesUpdatedToast(BuildContext context, {required int totalPages}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: TotalPagesUpdatedNotificationCard(
          totalPages: totalPages,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showBookmarkSavedToast(BuildContext context, {required int pageNum}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: BookmarkSavedNotificationCard(
          pageNum: pageNum,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showEpubLoadedToast(BuildContext context, {required String fileName}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: EpubLoadedNotificationCard(
          fileName: fileName,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showPdfLoadedToast(BuildContext context, {required String fileName}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: PdfLoadedNotificationCard(
          fileName: fileName,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  static void showAudiobookAttachedToast(BuildContext context, {required String fileName}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: AudiobookAttachedNotificationCard(
          fileName: fileName,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Category 1: Destructive Confirmations (Delete & Removal)
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required ConfirmationType type,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Remove',
  }) {
    final theme = BookoraNotificationTheme(isDark: Theme.of(context).brightness == Brightness.dark);
    
    IconData icon;
    Color iconColor = theme.errorRed;

    switch (type) {
      case ConfirmationType.removeBook:
        icon = Icons.delete_outline_rounded;
        break;
      case ConfirmationType.removeQuote:
        icon = Icons.format_quote_rounded;
        break;
      default:
        icon = Icons.warning_amber_rounded;
    }

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.isDark ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Botanical Watermark (using painter or just simple positioned element if we wanted)
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: BotanicalDecoPainter(color: iconColor, isDark: theme.isDark),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 28, color: iconColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.textSecondary),
                          onPressed: () => Navigator.pop(context, false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textPrimary,
                              side: BorderSide(color: theme.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// Category 1 (Success Variant): Book Removed Toast (Dialog Card)
  static Future<void> showSuccessModal(
    BuildContext context, {
    required String title,
    required String message,
    String? coverUrl,
  }) {
    final theme = BookoraNotificationTheme(isDark: Theme.of(context).brightness == Brightness.dark);
    final primaryColor = theme.warningAmber;

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.isDark ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: BotanicalDecoPainter(color: primaryColor, isDark: theme.isDark),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.successGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, size: 28, color: theme.successGreen),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}