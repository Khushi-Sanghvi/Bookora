import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enum representing all the customized variants of Bookora SnackBars
/// adhering directly to the Showcase Reference image 2.
enum BookoraSnackBarType {
  success,
  readingGoal,
  bookAdded,
  dbWarning,
  dbSaved,
  dbRestored,
  dataWiped,
  error,
  emptyLibrary,
  copied,
  supportEmail,
  info,
}

class BookoraSnackBar {
  static void show(
    BuildContext context, {
    required BookoraSnackBarType type,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getVariantConfig(type, isDark);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151922) : const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? config.badgeColor.withValues(alpha: 0.35)
                  : config.badgeColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : config.badgeColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Right-side botanical foliage watermark accent
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.05,
                    child: Icon(
                      Icons.eco_rounded,
                      size: 64,
                      color: config.badgeColor,
                    ),
                  ),
                ),

                // Main Row Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      // 1. LEFT: Circular Icon Badge with Status Illumination
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: config.badgeColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: config.badgeColor.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: config.badgeColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            config.icon,
                            size: 20,
                            color: config.badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. CENTER: Headline + Subtitle + Glowing Accent Bar
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFEFE8DC)
                                    : const Color(0xFF2E1E12),
                              ),
                            ),
                            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle.trim(),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF90A4AE)
                                      : const Color(0xFF795548),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            // Accent underline indicator
                            Container(
                              width: 50,
                              height: 2.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    config.badgeColor,
                                    config.badgeColor.withValues(alpha: 0.2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. RIGHT: Trailing Illustrated Graphic + Close Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (config.trailingIcon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: config.badgeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                config.trailingIcon,
                                size: 18,
                                color: config.badgeColor.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          GestureDetector(
                            onTap: () {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFB0BEC5)
                                    : const Color(0xFF8D6E63),
                              ),
                            ),
                          ),
                        ],
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

  static _SnackBarVariantConfig _getVariantConfig(BookoraSnackBarType type, bool isDark) {
    switch (type) {
      case BookoraSnackBarType.success:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF2E7D32), // Forest Green
          icon: Icons.check_circle_rounded,
          trailingIcon: Icons.menu_book_rounded,
        );
      case BookoraSnackBarType.readingGoal:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFFE65100), // Rich Burnt Amber
          icon: Icons.track_changes_rounded,
          trailingIcon: Icons.auto_stories_rounded,
        );
      case BookoraSnackBarType.bookAdded:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF0277BD), // Deep Cerulean
          icon: Icons.menu_book_rounded,
          trailingIcon: Icons.auto_awesome,
        );
      case BookoraSnackBarType.dbWarning:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFFF57C00), // Amber Warning
          icon: Icons.warning_amber_rounded,
          trailingIcon: Icons.folder_open_rounded,
        );
      case BookoraSnackBarType.dbSaved:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF00897B), // Deep Teal
          icon: Icons.cloud_done_rounded,
          trailingIcon: Icons.description_rounded,
        );
      case BookoraSnackBarType.dbRestored:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF2E7D32), // Success Green
          icon: Icons.dns_rounded,
          trailingIcon: Icons.library_books_rounded,
        );
      case BookoraSnackBarType.dataWiped:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFFC62828), // Crimson Red
          icon: Icons.delete_forever_rounded,
          trailingIcon: Icons.air_rounded,
        );
      case BookoraSnackBarType.error:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFFD32F2F), // Error Red
          icon: Icons.cancel_rounded,
          trailingIcon: Icons.error_outline_rounded,
        );
      case BookoraSnackBarType.emptyLibrary:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFFE65100), // Warm terracotta
          icon: Icons.inventory_2_outlined,
          trailingIcon: Icons.all_inbox_rounded,
        );
      case BookoraSnackBarType.copied:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF0288D1), // Cyan/Blue
          icon: Icons.content_copy_rounded,
          trailingIcon: Icons.assignment_turned_in_rounded,
        );
      case BookoraSnackBarType.supportEmail:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF00897B), // Cyan / Teal
          icon: Icons.mark_email_read_rounded,
          trailingIcon: Icons.send_rounded,
        );
      case BookoraSnackBarType.info:
        return const _SnackBarVariantConfig(
          badgeColor: Color(0xFF1976D2), // Info Blue
          icon: Icons.info_rounded,
          trailingIcon: Icons.lightbulb_outline_rounded,
        );
    }
  }
}

class _SnackBarVariantConfig {
  final Color badgeColor;
  final IconData icon;
  final IconData? trailingIcon;

  const _SnackBarVariantConfig({
    required this.badgeColor,
    required this.icon,
    this.trailingIcon,
  });
}
