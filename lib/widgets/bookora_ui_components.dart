import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/reading_app_colors.dart';
import '../services/bookora_notification_service.dart';
import '../services/bookora_dialog_service.dart';
import 'book_cover_image.dart';

/// Centralized UI Notification & Message System for Bookora
/// Matching the Light & Dark Theme Pixel-Perfect Design System Specs
class BookoraSnackBar {
  static void show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
    required Color lightBgColor,
    required Color darkBgColor,
    String? coverUrl,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBgColor : lightBgColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1611);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5D4A3E);
    final borderColor = accentColor.withValues(alpha: isDark ? 0.4 : 0.3);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Leaf Decorative Accent
              Positioned(
                right: 32,
                bottom: -6,
                child: Opacity(
                  opacity: isDark ? 0.25 : 0.18,
                  child: Icon(Icons.eco, color: accentColor, size: 36),
                ),
              ),

              Row(
                children: [
                  // Book Cover or Icon Badge
                  if (coverUrl != null && coverUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BookCoverImage(
                        coverUrl: coverUrl,
                        title: title,
                        author: '',
                        width: 32,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Text Content
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.sansita(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Optional Action Button
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  const SizedBox(width: 6),
                  // Close 'X' Button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    child: Icon(Icons.close_rounded, size: 16, color: subTextColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Convenience Notification Constructors matching Reference UI Specs ---

  static void showBookAdded(BuildContext context, {required String bookTitle, String? coverUrl}) {
    show(
      context: context,
      title: 'Added "$bookTitle"',
      subtitle: 'to your shelf!',
      icon: Icons.bookmark_add_rounded,
      coverUrl: coverUrl,
      accentColor: const Color(0xFF2ECC71),
      lightBgColor: const Color(0xFFE8F5E9),
      darkBgColor: const Color(0xFF0D2D1B),
    );
  }

  static void showBookmarkSaved(BuildContext context, {required int pageNumber}) {
    show(
      context: context,
      title: 'Bookmark saved!',
      subtitle: '(Page $pageNumber)',
      icon: Icons.bookmark_rounded,
      accentColor: const Color(0xFFF39C12),
      lightBgColor: const Color(0xFFFFF8E1),
      darkBgColor: const Color(0xFF33210C),
    );
  }

  static void showQuoteAdded(BuildContext context) {
    show(
      context: context,
      title: 'Quote added',
      subtitle: 'to book!',
      icon: Icons.format_quote_rounded,
      accentColor: const Color(0xFFE67E22),
      lightBgColor: const Color(0xFFFFF3E0),
      darkBgColor: const Color(0xFF381F0A),
    );
  }

  static void showHighlightSaved(BuildContext context) {
    show(
      context: context,
      title: 'Highlight saved!',
      icon: Icons.edit_note_rounded,
      accentColor: const Color(0xFF9B59B6),
      lightBgColor: const Color(0xFFF3E5F5),
      darkBgColor: const Color(0xFF2A0E38),
    );
  }

  static void showNoteSaved(BuildContext context) {
    show(
      context: context,
      title: 'Note saved!',
      icon: Icons.note_alt_outlined,
      accentColor: const Color(0xFFE74C3C),
      lightBgColor: const Color(0xFFFCE4EC),
      darkBgColor: const Color(0xFF360F1E),
    );
  }

  static void showProfileUpdated(BuildContext context) {
    BookoraNotificationService.showProfileUpdatedToast(context);
  }

  static void showTotalPagesUpdated(BuildContext context, {required int totalPages}) {
    show(
      context: context,
      title: 'Updated total pages',
      subtitle: 'to $totalPages',
      icon: Icons.auto_stories_rounded,
      accentColor: const Color(0xFF3498DB),
      lightBgColor: const Color(0xFFE3F2FD),
      darkBgColor: const Color(0xFF0B273D),
    );
  }

  static void showAmbianceSwitched(BuildContext context, {required String modeName}) {
    show(
      context: context,
      title: 'Switched ambiance',
      subtitle: 'to $modeName',
      icon: Icons.nightlight_round_rounded,
      accentColor: const Color(0xFF5C6BC0),
      lightBgColor: const Color(0xFFE8EAF6),
      darkBgColor: const Color(0xFF17183B),
    );
  }

  static void showDocumentAttached(BuildContext context, {required String fileName}) {
    show(
      context: context,
      title: 'Attached "$fileName"',
      subtitle: 'to book!',
      icon: Icons.attach_file_rounded,
      accentColor: const Color(0xFFE91E63),
      lightBgColor: const Color(0xFFFCE4EC),
      darkBgColor: const Color(0xFF360F1E),
    );
  }

  static void showEpubLoaded(BuildContext context, {required String fileName}) {
    BookoraDialogService.showEpubLoadedToast(context, fileName: fileName);
  }

  static void showPdfLoaded(BuildContext context, {required String fileName}) {
    BookoraDialogService.showPdfLoadedToast(context, fileName: fileName);
  }

  static void showBackupCopied(BuildContext context) {
    show(
      context: context,
      title: 'Backup JSON copied',
      subtitle: 'to clipboard!',
      icon: Icons.assignment_turned_in_rounded,
      accentColor: const Color(0xFF27AE60),
      lightBgColor: const Color(0xFFE8F5E9),
      darkBgColor: const Color(0xFF0D2D1B),
    );
  }

  static void showBackupRestored(BuildContext context, {required int bookCount}) {
    show(
      context: context,
      title: 'Restored $bookCount books',
      subtitle: 'successfully!',
      icon: Icons.restore_rounded,
      accentColor: const Color(0xFF2980B9),
      lightBgColor: const Color(0xFFE3F2FD),
      darkBgColor: const Color(0xFF0B273D),
    );
  }

  static void showDataReset(BuildContext context, {VoidCallback? onUndo}) {
    show(
      context: context,
      title: 'All app data and books reset.',
      icon: Icons.refresh_rounded,
      accentColor: const Color(0xFFE74C3C),
      lightBgColor: const Color(0xFFFFEBEE),
      darkBgColor: const Color(0xFF3B0E11),
      actionLabel: 'Undo',
      onAction: onUndo,
    );
  }

  static void showSuccess(BuildContext context, {required String message}) {
    show(
      context: context,
      title: message,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xFF2ECC71),
      lightBgColor: const Color(0xFFE8F5E9),
      darkBgColor: const Color(0xFF0D2D1B),
    );
  }

  static void showWarning(BuildContext context, {required String message}) {
    show(
      context: context,
      title: message,
      icon: Icons.warning_rounded,
      accentColor: const Color(0xFFF39C12),
      lightBgColor: const Color(0xFFFFF8E1),
      darkBgColor: const Color(0xFF33210C),
    );
  }

  static void showError(BuildContext context, {required String message}) {
    show(
      context: context,
      title: message,
      icon: Icons.error_rounded,
      accentColor: const Color(0xFFE74C3C),
      lightBgColor: const Color(0xFFFFEBEE),
      darkBgColor: const Color(0xFF3B0E11),
    );
  }
}

/// Centralized Confirmation Dialogs matching Reference UI Specs
class BookoraDialog {
  static Future<bool?> showRemoveBookConfirmation(
    BuildContext context, {
    required String bookTitle,
  }) {
    return _showConfirmationDialog(
      context,
      title: 'Remove Book?',
      message: 'Remove "$bookTitle" from your library?',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE74C3C),
      confirmButtonText: 'Remove',
      confirmButtonColor: const Color(0xFFE74C3C),
    );
  }

  static Future<bool?> showRemoveQuoteConfirmation(
    BuildContext context,
  ) {
    return _showConfirmationDialog(
      context,
      title: 'Remove Quote?',
      message: 'Remove this quote from the book?',
      icon: Icons.format_quote_rounded,
      iconColor: const Color(0xFFE74C3C),
      confirmButtonText: 'Remove',
      confirmButtonColor: const Color(0xFFE74C3C),
    );
  }

  static void showBookRemovedToast(
    BuildContext context, {
    required String bookTitle,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF221C18) : const Color(0xFFFAF6F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E1611);
    final borderColor = isDark ? const Color(0xFF382E28) : const Color(0xFFEAE0D8);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 20, color: Colors.white),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Book Removed',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$bookTitle" has been removed from your library.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? colors.streakAmber : const Color(0xFF6D4C41),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String confirmButtonText,
    required Color confirmButtonColor,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF221C18) : const Color(0xFFFAF6F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E1611);
    final borderColor = isDark ? const Color(0xFF382E28) : const Color(0xFFEAE0D8);

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context, false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(confirmButtonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
