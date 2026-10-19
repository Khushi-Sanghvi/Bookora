import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bookora_floral_dialog.dart';

/// Production-ready "Reader's Field Guide / Walkthrough" dialog for Bookora.
/// Honors the Dark Academia aesthetic, dual-theme tokens, illuminated typography,
/// and botanical dialog architecture.
class ReaderWalkthroughModal extends StatelessWidget {
  const ReaderWalkthroughModal({super.key});

  /// Static helper to display the Walkthrough Modal from anywhere in the app.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const ReaderWalkthroughModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Architectural color tokens matching Dark Academia design system
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
    final maxDialogHeight = mediaQuery.size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
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
                  // Botanical flourish painter layer
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: BookoraFloralPainter(isDark: isDark),
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
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

                  // Main Scrollable Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Scrollable Chapters Area
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Botanical Emblem
                                Center(
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          accentAmber.withValues(alpha: 0.25),
                                          accentAmber.withValues(alpha: 0.08),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: accentAmber.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentAmber.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.explore_rounded,
                                        color: accentAmber,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Illuminated Pill Badge
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentAmber.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: accentAmber.withValues(alpha: 0.35),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_stories_outlined, size: 12, color: accentAmber),
                                        const SizedBox(width: 5),
                                        Text(
                                          'SANCTUARY FIELD GUIDE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                            color: accentAmber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Title
                                Text(
                                  "The Reader's Field Guide",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Subtitle
                                Text(
                                  'Mastering your personal reading sanctuary',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Divider(
                                  color: isDark ? const Color(0xFF28303E) : const Color(0xFFE9E0D0),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 14),

                                // Step 1: Building Your Shelves
                                _buildStepCard(
                                  stepNumber: '01',
                                  icon: Icons.shelves,
                                  title: 'Building Your Shelves',
                                  subtitle: 'The Library & Bookshelf Layouts',
                                  body:
                                      'Explore 6 bespoke shelf perspectives: 3D Dark Academia Shelf, 3D Carousel Showcase, Polaroid Scrapbook Gallery, 3D Classic Wooden Shelf, Cover Grid, and Detailed List.\n\nUse shelf tabs (Reading, To Read, Finished, and DNF) to organize and filter your collection in an instant.',
                                  tags: const ['3D Bookshelf', 'Carousel', 'Polaroid', 'Grid & List'],
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),

                                // Step 2: Format & Document Attachment
                                _buildStepCard(
                                  stepNumber: '02',
                                  icon: Icons.attachment_rounded,
                                  title: 'Format & Document Attachment',
                                  subtitle: 'Paperback, Audio, PDF & EPUB',
                                  body:
                                      'Switch formats freely for any title. Selecting PDF or EPUB unlocks the "Attach Document" action—linking local books directly into your built-in sandbox reader with automatic reading progress memory and chapter navigation.',
                                  tags: const ['Paperback', 'Audiobook', 'PDF Reader', 'EPUB Engine'],
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),

                                // Step 3: Story Codex & Narrative Anatomy
                                _buildStepCard(
                                  stepNumber: '03',
                                  icon: Icons.auto_awesome_rounded,
                                  title: 'Story Codex & Narrative Anatomy',
                                  subtitle: 'Tropes, Lore & 5D Flavor Profile',
                                  body:
                                      'Tap the glowing sparkle icon (✨) in any book detail view to unlock deep narrative lore: premise hook, character rosters, setting worldbuilding, trope badges, and the 5D flavor profile (Spice, Fluff, Tears, and Humor).',
                                  tags: ['Premise Hook', 'Tropes', '5D Flavor', 'Character Lore'],
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),

                                // Step 4: Reading Goals & Timers
                                _buildStepCard(
                                  stepNumber: '04',
                                  icon: Icons.flag_rounded,
                                  title: 'Reading Goals & Pacing',
                                  subtitle: 'Streaks & Bento-Grid Insights',
                                  body:
                                      'Set your annual challenge using the interactive goal stepper. Logging sessions and page milestones fuels your daily reading flame, unlocks streak achievements, and builds your vintage desk Bento insights.',
                                  tags: ['Annual Goal', 'Reading Flame', 'Daily Habit', 'Bento Pulse'],
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),

                                // Step 5: Data Sanctuary & Absolute Ownership
                                _buildStepCard(
                                  stepNumber: '05',
                                  icon: Icons.shield_outlined,
                                  title: 'Data Sanctuary & Ownership',
                                  subtitle: '100% Offline & Zero Telemetry',
                                  body:
                                      'Your reading sanctuary belongs solely to you. Zero trackers, zero analytics, and zero required online accounts. Export full CSV reading logs or complete JSON database backups at any moment.',
                                  tags: ['Local SQLite', 'JSON Backup', 'CSV Export', 'Zero Telemetry'],
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentAmber,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Footer Action: Full-width Gradient Pill Button
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFFE27D38), const Color(0xFFC45A18)]
                                  : [const Color(0xFFB8521B), const Color(0xFF9E3E10)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: accentAmber.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Begin Reading',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required IconData icon,
    required String title,
    required String subtitle,
    required String body,
    required List<String> tags,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step badge
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  'STEP $stepNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.25,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
