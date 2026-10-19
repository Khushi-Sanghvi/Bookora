import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/reading_app_colors.dart';

class ExpandableBookHookText extends StatelessWidget {
  final String hookText;
  final ReadingAppColors colors;

  const ExpandableBookHookText({
    super.key,
    required this.hookText,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (hookText.trim().isEmpty) return const SizedBox.shrink();

    return Text(
      '“${hookText.trim()}”',
      style: GoogleFonts.crimsonPro(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: colors.quoteGold,
        height: 1.35,
      ),
      maxLines: null, // Fully expands to as many lines as the text requires
    );
  }
}
