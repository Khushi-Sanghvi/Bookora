import 'package:flutter/material.dart';
import '../widgets/bookora_dialog_card.dart';
import '../widgets/epub_loaded_notification_card.dart';
import '../widgets/pdf_loaded_notification_card.dart';
import '../widgets/audiobook_attached_notification_card.dart';
import '../widgets/bookora_notification_banner.dart';

class BookoraDialogService {
  /// Displays a floating "Updated total pages to $val" toast card
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.amberProgress,
          leadingIcon: const Icon(Icons.description_rounded),
          message: 'Total pages updated to $totalPages',
          isToast: true,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays a floating "Bookmark saved! (Page $pageNum)" toast card
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.coralBookmark,
          leadingIcon: const Icon(Icons.bookmark_rounded),
          message: 'Bookmark saved at page $pageNum',
          isToast: true,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays a floating "EPUB Loaded" toast card
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

  /// Displays a floating "PDF Loaded" toast card
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

  /// Displays a floating "Audiobook file attached" toast card
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

  /// Displays a simple green success toast
  static void showSuccessToast(BuildContext context, {required String message}) {
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.emeraldSuccess,
          leadingIcon: const Text('🎉', style: TextStyle(fontSize: 20)),
          message: message.replaceAll('🎉 ', '').replaceAll('🎉', '').trim(),
          isToast: true,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays a Date Updated SnackBar
  static void showDateUpdatedSnackBar(BuildContext context, {required String dateText, required bool isStart}) {
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.calendarDate,
          leadingIcon: const Icon(Icons.calendar_month_rounded),
          message: '${isStart ? 'Start Date' : 'End Date'} updated to $dateText!',
          isToast: false,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays an Ambiance Switched SnackBar
  static void showAmbianceSwitchedSnackBar(BuildContext context, {required String ambianceName}) {
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.ambianceSwitch,
          leadingIcon: const Icon(Icons.nightlight_round),
          message: 'Switched ambiance to $ambianceName',
          isToast: false,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays an Outline Jump SnackBar
  static void showOutlineJumpSnackBar(BuildContext context, {required String title, String? subtitle}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final message = subtitle != null && subtitle.isNotEmpty 
        ? 'Jumped to $title ($subtitle)!' 
        : 'Jumped to $title!';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        content: BookoraNotificationBanner(
          tone: NotificationTone.outlineJump,
          leadingIcon: const Icon(Icons.format_list_bulleted_rounded),
          message: message,
          isToast: false,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays Quote & Annotation Saved SnackBar
  static void showQuoteSavedSnackBar(BuildContext context) {
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.quoteSaved,
          leadingIcon: const Icon(Icons.format_quote_rounded),
          message: 'Quote & Annotation saved!',
          isToast: false,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays Bookmark Removed Destructive SnackBar
  static void showBookmarkRemovedSnackBar(BuildContext context) {
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
        content: BookoraNotificationBanner(
          tone: NotificationTone.destructiveRemove,
          leadingIcon: const Icon(Icons.delete_outline_rounded),
          message: 'Bookmark removed',
          isToast: false,
          onDismiss: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  /// Displays an auto-dismissing 3-second Success Toast / Modal Card
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? coverUrl,
    VoidCallback? onDismiss,
  }) {
    return _showAnimatedDialog(
      context: context,
      builder: (ctx) {
        return BookoraDialogCard(
          variant: DialogVariant.success,
          title: title,
          message: message,
          coverUrl: coverUrl,
          primaryButtonText: 'OK',
          autoDismiss: true,
          autoDismissDuration: const Duration(seconds: 3),
          onDismiss: () {
            Navigator.of(ctx, rootNavigator: true).pop();
            if (onDismiss != null) onDismiss();
          },
        );
      },
    );
  }

  /// Displays a Destructive Confirmation Dialog with Cancel and Remove buttons
  static Future<void> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Remove',
    String cancelText = 'Cancel',
  }) {
    return _showAnimatedDialog(
      context: context,
      builder: (ctx) {
        return BookoraDialogCard(
          variant: DialogVariant.confirmation,
          title: title,
          message: message,
          primaryButtonText: confirmText,
          onPrimaryPressed: onConfirm,
          secondaryButtonText: cancelText,
        );
      },
    );
  }

  /// Displays an Error / Network Alert Dialog with "Try Again"
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    String buttonText = 'Try Again',
  }) {
    return _showAnimatedDialog(
      context: context,
      builder: (ctx) {
        return BookoraDialogCard(
          variant: DialogVariant.error,
          title: title,
          message: message,
          primaryButtonText: buttonText,
          onPrimaryPressed: onRetry,
        );
      },
    );
  }

  /// Displays a Cozy Reading Tip / Info Modal
  static Future<void> showTip(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Got it!',
    VoidCallback? onPressed,
  }) {
    return _showAnimatedDialog(
      context: context,
      builder: (ctx) {
        return BookoraDialogCard(
          variant: DialogVariant.tip,
          title: title,
          message: message,
          primaryButtonText: buttonText,
          onPrimaryPressed: onPressed,
        );
      },
    );
  }

  /// Custom animated dialog wrapper (Fade + Scale transition from 0.95 to 1.0)
  static Future<void> _showAnimatedDialog({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => builder(context),
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
