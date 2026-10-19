import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookoraToast {
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData? icon,
    Color? accentColor,
    bool isSuccess = true,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final effectiveIsError = isError || !isSuccess;
    final effectiveAccent = accentColor ??
        (effectiveIsError
            ? Colors.redAccent
            : const Color(0xFFE27D38)); // Candle Amber

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1715), // Dark Academia Midnight
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: effectiveIsError
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.4), // Antique gold border
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: effectiveAccent,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEDE6DD), // Warm parchment text
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle.trim(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFFA89F91), // Sepia muted
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

