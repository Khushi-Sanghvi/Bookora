import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

enum DialogVariant { success, confirmation, error, tip }

class BookoraDialogCard extends StatefulWidget {
  final DialogVariant variant;
  final String title;
  final String message;
  final String? coverUrl;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onDismiss;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const BookoraDialogCard({
    super.key,
    required this.variant,
    required this.title,
    required this.message,
    this.coverUrl,
    required this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.onDismiss,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 3),
  });

  @override
  State<BookoraDialogCard> createState() => _BookoraDialogCardState();
}

class _BookoraDialogCardState extends State<BookoraDialogCard> with SingleTickerProviderStateMixin {
  AnimationController? _progressController;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismiss) {
      _progressController = AnimationController(
        vsync: this,
        duration: widget.autoDismissDuration,
      )..forward();

      Timer(widget.autoDismissDuration, () {
        if (mounted) {
          if (widget.onDismiss != null) {
            widget.onDismiss!();
          } else {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Design Tokens & Colors
    final cardBg = isLight ? const Color(0xFFFAF7F0) : const Color(0xFF1E1A17);
    final borderColor = isLight ? const Color(0xFFE6DFC8) : const Color(0xFF382F28);
    final shadowColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black54;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Decorative Leaf/Botanical Watermark Accent (For Confirmation Dialogs)
            if (widget.variant == DialogVariant.confirmation)
              Positioned(
                bottom: 12,
                right: 12,
                child: Opacity(
                  opacity: isLight ? 0.22 : 0.15,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Icon(Icons.eco, color: Color(0xFF8D6E63), size: 36),
                        Icon(Icons.grass, color: Color(0xFF8D6E63), size: 28),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Right Close Button
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: () {
                  if (widget.onDismiss != null) {
                    widget.onDismiss!();
                  } else {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            // Main Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Badge / Thumbnail Illustration
                      _buildLeftBadge(colors, isLight),
                      const SizedBox(width: 14),

                      // Center Title, Message & Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.crimsonPro(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Illustration (for Error and Tip variants)
                      if (widget.variant == DialogVariant.error)
                        _buildCatOnBooksIllustration(isLight)
                      else if (widget.variant == DialogVariant.tip)
                        _buildTipBookStackIllustration(isLight),
                    ],
                  ),

                  // Action Buttons Row (if present)
                  if (widget.secondaryButtonText != null || widget.variant != DialogVariant.success) ...[
                    const SizedBox(height: 20),
                    _buildActionButtonsRow(colors, isLight),
                  ],

                  // Success Variant Progress Indicator Bar
                  if (widget.variant == DialogVariant.success && _progressController != null) ...[
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _progressController!,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressController!.value,
                            minHeight: 4,
                            backgroundColor: colors.borderSubtle,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.accentSage),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Left Badge Slot ---
  Widget _buildLeftBadge(ReadingAppColors colors, bool isLight) {
    switch (widget.variant) {
      case DialogVariant.success:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            BookCoverImage(
              coverUrl: widget.coverUrl ?? '',
              title: widget.title,
              author: '',
              width: 50,
              height: 72,
              borderRadius: BorderRadius.circular(6),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: -4,
              left: -6,
              child: Icon(Icons.auto_awesome, size: 14, color: colors.streakAmber),
            ),
          ],
        );

      case DialogVariant.confirmation:
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFC62828).withValues(alpha: isLight ? 0.12 : 0.25),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.delete_outline_rounded,
              size: 26,
              color: Color(0xFFE53935),
            ),
          ),
        );

      case DialogVariant.error:
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withValues(alpha: isLight ? 0.15 : 0.28),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.priority_high_rounded,
              size: 26,
              color: Color(0xFFFF5252),
            ),
          ),
        );

      case DialogVariant.tip:
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withValues(alpha: isLight ? 0.2 : 0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.lightbulb_outlined,
              size: 26,
              color: colors.streakAmber,
            ),
          ),
        );
    }
  }

  // --- Right Cat On Books Stack Illustration (Error Variant) ---
  Widget _buildCatOnBooksIllustration(bool isLight) {
    return Container(
      width: 85,
      height: 75,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Stacked Books
          Positioned(
            bottom: 0,
            child: Container(
              width: 70,
              height: 14,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFD6C8B4) : const Color(0xFF382F28),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              width: 64,
              height: 14,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFF8D6E63) : const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Sleeping/Curled Cat
          Positioned(
            bottom: 24,
            child: Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFF3E2723) : const Color(0xFF4A3B32),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: Radius.circular(8),
                ),
              ),
              child: const Icon(Icons.pets, size: 16, color: Color(0xFFD7CCC8)),
            ),
          ),
          // Tangled Yarn Ball Icon
          Positioned(
            top: -2,
            right: 0,
            child: Icon(Icons.gesture_rounded, size: 18, color: Colors.deepOrange[300]),
          ),
        ],
      ),
    );
  }

  // --- Right Tip Book Stack Illustration (Tip Variant) ---
  Widget _buildTipBookStackIllustration(bool isLight) {
    return Container(
      width: 95,
      height: 85,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Stacked Pastel Books
          Positioned(
            bottom: 0,
            child: Container(
              width: 76,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          Positioned(
            bottom: 13,
            child: Container(
              height: 15,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF81C784),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            child: Container(
              height: 15,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          // Potted Greenery Plant on Top
          Positioned(
            bottom: 39,
            child: Icon(Icons.eco, size: 20, color: Colors.green[700]),
          ),
          // Sparkles
          Positioned(
            top: 0,
            left: 2,
            child: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFFB74D)),
          ),
          // Handwritten Script Micro-Note
          Positioned(
            bottom: -18,
            right: 0,
            child: Text(
              'Progress\nlooks good on you ♥',
              style: GoogleFonts.dancingScript(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLight ? const Color(0xFF8D6E63) : const Color(0xFFE0C898),
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Buttons Row ---
  Widget _buildActionButtonsRow(ReadingAppColors colors, bool isLight) {
    if (widget.variant == DialogVariant.confirmation) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (widget.onSecondaryPressed != null) {
                  widget.onSecondaryPressed!();
                } else {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.borderSubtle, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.secondaryButtonText ?? 'Cancel',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                if (widget.onPrimaryPressed != null) {
                  widget.onPrimaryPressed!();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.primaryButtonText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default Single Action Button (Error / Tip)
    final btnBg = widget.variant == DialogVariant.error
        ? const Color(0xFFC62828)
        : const Color(0xFFB76E28);

    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (widget.onPrimaryPressed != null) {
            widget.onPrimaryPressed!();
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 42),
          backgroundColor: btnBg,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          widget.primaryButtonText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
