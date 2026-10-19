import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'bookora_floral_dialog.dart';

class ThemeSelectorView extends ConsumerWidget {
  const ThemeSelectorView({super.key});

  static Future<void> showSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13161C) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFE6D5B8);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black87 : const Color(0xFF2E1E12).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                child: Stack(
                  children: [
                    // Corner botanicals
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: BookoraFloralPainter(isDark: isDark),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: SingleChildScrollView(
                        child: const ThemeSelectorView(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final handleColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFDED2BD);

    final themes = [
      _ThemeOption(
        name: 'Parchment & Ivory',
        tagline: 'Ivory Light',
        mode: ThemeMode.light,
        previewBg: const Color(0xFFF7F4EC),
        previewCard: const Color(0xFFFFFFFF),
        accentColor: const Color(0xFFB8521B),
        textColor: const Color(0xFF2E1E12),
        icon: Icons.menu_book_rounded,
      ),
      _ThemeOption(
        name: 'Midnight Library',
        tagline: 'Dark Academia',
        mode: ThemeMode.dark,
        previewBg: const Color(0xFF141210),
        previewCard: const Color(0xFF221E1B),
        accentColor: const Color(0xFFE27D38),
        textColor: const Color(0xFFEFE8DC),
        icon: Icons.nightlight_round,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose Your Theme',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 1x2 Grid of Theme Preview Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: themes.length,
          itemBuilder: (ctx, index) {
            final theme = themes[index];
            final activeSelected = theme.mode == currentThemeMode;

            return GestureDetector(
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(theme.mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.previewBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeSelected
                        ? const Color(0xFFFFB300)
                        : (isDark ? const Color(0xFF2A3442) : const Color(0xFFE6D5B8)),
                    width: activeSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: activeSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mini preview container
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.previewCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            theme.icon,
                            color: theme.accentColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Label & Subtitle & Checkmark
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          theme.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          theme.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: theme.textColor.withValues(alpha: 0.65),
                          ),
                        ),
                        if (activeSelected) ...[
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: Color(0xFFFFB300),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ThemeOption {
  final String name;
  final String tagline;
  final ThemeMode mode;
  final Color previewBg;
  final Color previewCard;
  final Color accentColor;
  final Color textColor;
  final IconData icon;

  const _ThemeOption({
    required this.name,
    required this.tagline,
    required this.mode,
    required this.previewBg,
    required this.previewCard,
    required this.accentColor,
    required this.textColor,
    required this.icon,
  });
}
