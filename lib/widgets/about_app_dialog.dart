import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bookora_floral_dialog.dart';
import 'bookora_snack_bar.dart';

/// Production-ready "About Bookora" dialog honoring the Dark Academia design
/// system, dual-theme tokens, illuminated typography, and floral popup architecture.
class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  /// Static helper to display the About dialog from anywhere in the app.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const AboutAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Architectural color tokens matching Dark Academia specification
    final bgColor = isDark ? const Color(0xFF13161C) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFE6D5B8);
    final textPrimary = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final textSecondary = isDark ? const Color(0xFF9E988F) : const Color(0xFF6B6057);
    final accentAmber = isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);
    final cardBg = isDark ? const Color(0xFF1B1E26) : const Color(0xFFF7F2E8);
    final cardBorder = isDark ? const Color(0xFF28303E) : const Color(0xFFE9E0D0);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.70)
        : const Color(0xFF2E1E12).withValues(alpha: 0.15);

    final mediaQuery = MediaQuery.of(context);
    final maxDialogHeight = mediaQuery.size.height * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: maxDialogHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23.0),
              child: Stack(
                children: [
                  // Subtle botanical flourish painter layer
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: BookoraFloralPainter(isDark: isDark),
                      ),
                    ),
                  ),

                  // Close button at top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Dialog Layout
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- 1. HEADER SECTION ---
                        Center(
                          child: _buildIlluminatedEmblem(accentAmber, isDark),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          'Bookora',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Tagline
                        Text(
                          'Your stories, your space.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: accentAmber,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle Pill
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentAmber.withValues(alpha: isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentAmber.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'The Obsidian Edition • Version 1.0.0 (Build 1)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentAmber,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- 2. SCROLLABLE BODY CONTENT ---
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Core Philosophy Narrative Card
                                _buildPhilosophyCard(cardBg, cardBorder, textPrimary, textSecondary, accentAmber, isDark),
                                const SizedBox(height: 18),

                                // Feature Highlights Header
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 14, color: accentAmber),
                                    const SizedBox(width: 6),
                                    Text(
                                      'KEY CAPABILITIES',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                        color: accentAmber,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? const Color(0xFF28303E) : const Color(0xFFE9E0D0),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Feature Highlights Cards
                                _buildFeatureTile(
                                  emoji: '🕯️',
                                  title: 'Local Sanctuary & Zero Telemetry',
                                  description: 'Local-first, offline persistence. Your data never leaves your device.',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildFeatureTile(
                                  emoji: '📖',
                                  title: 'Story Codex & Narrative Anatomy',
                                  description: 'Deep metadata tracking tropes, setting, character rosters, and 5D flavor profiles.',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildFeatureTile(
                                  emoji: '🏛️',
                                  title: 'Bento Insights & Reading Pulse',
                                  description: 'Aesthetic, stress-free statistics designed like a vintage study desk.',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildFeatureTile(
                                  emoji: '💾',
                                  title: 'Uncompromising Ownership',
                                  description: 'Full CSV and JSON data export and restore at any time.',
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),

                                // --- 3. COLOPHON & SUPPORT SECTION ---
                                _buildColophonSection(
                                  context: context,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),

                                // Closing quote
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        '✦  ✦  ✦',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: accentAmber.withValues(alpha: 0.5),
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '“A few pages today bring a brighter tomorrow.”',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 12.5,
                                          fontStyle: FontStyle.italic,
                                          color: textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- 4. ACTION BUTTON ---
                        BookoraPillButton.primary(
                          text: 'Close',
                          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the illuminated open book emblem with subtle ambient glow
  Widget _buildIlluminatedEmblem(Color accentColor, bool isDark) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accentColor.withValues(alpha: isDark ? 0.28 : 0.20),
            accentColor.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: accentColor,
          size: 28,
        ),
      ),
    );
  }

  /// Builds the narrative philosophy card
  Widget _buildPhilosophyCard(
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most modern trackers treat reading like an algorithm—chasing streaks, optimizing metrics, and selling your reading habits to advertisers.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.2,
              height: 1.55,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bookora was built differently.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Designed with a cozy, dark-academia soul, Bookora is a personal sanctuary for bibliophiles. Whether you are cataloging worn paperbacks, parsing tropes in high-fantasy epics, or diving deep into a narrative\'s anatomy through the Story Codex, this space belongs entirely to you.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.2,
              height: 1.55,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an itemized feature highlight card
  Widget _buildFeatureTile({
    required String emoji,
    required String title,
    required String description,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: isDark ? 0.70 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.2,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the colophon and support contact section with tap-to-copy
  Widget _buildColophonSection({
    required BuildContext context,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    const supportEmail = 'ark.dev.support@gmail.com';

    return Column(
      children: [
        // Dedication note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, size: 12, color: accentColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Built with love for book lovers, daydreamers, and nocturnal readers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.2,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Support Contact Tap-to-Copy Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: supportEmail));
              HapticFeedback.lightImpact();
              BookoraSnackBar.show(
                context,
                type: BookoraSnackBarType.supportEmail,
                title: 'Support email copied to clipboard!',
                subtitle: supportEmail,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.30),
                  width: 1.0,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      supportEmail,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 10,
                            color: accentColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Copy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
