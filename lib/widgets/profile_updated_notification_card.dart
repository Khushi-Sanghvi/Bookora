import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bookora_floral_dialog.dart';

class ProfileUpdatedNotificationCard extends StatelessWidget {
  final VoidCallback? onDismiss;

  const ProfileUpdatedNotificationCard({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Architectural color tokens matching reference showcase
    final bgColor = isDark ? const Color(0xFF13161C) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : const Color(0xFFE6D5B8);
    final titleColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final subtitleColor = isDark ? const Color(0xFFFFA726) : const Color(0xFF8D6E63);
    final checkColor = isDark ? const Color(0xFFFFB300) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 82),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.22)
                : const Color(0xFF2E1E12).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Floral & Botanical Corner Painter
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BookoraFloralPainter(isDark: isDark),
                ),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Left Glowing Book Emblem
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFFFFB74D), Color(0xFFE65100)]
                            : const [Color(0xFFFFCC80), Color(0xFFEF6C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Center Headline & Subtitle & Indicator
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Updated!',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your changes have been saved.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 80,
                          height: 2.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                checkColor,
                                checkColor.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right-anchored Green/Golden Checkmark Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checkColor.withValues(alpha: 0.15),
                      border: Border.all(color: checkColor, width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: checkColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Subtle dismiss button
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
