import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom painter for floral and botanical flourishes on dialog corners and borders.
/// Light mode: Warm autumn leaves, marigolds, and warm foliage.
/// Dark mode: Nocturnal ivy, night-blooming vines, golden leaves, and glowing embers.
class BookoraFloralPainter extends CustomPainter {
  final bool isDark;

  BookoraFloralPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkBotanicals(canvas, size);
    } else {
      _paintLightBotanicals(canvas, size);
    }
  }

  void _paintLightBotanicals(Canvas canvas, Size size) {
    // Warm palette: marigold, terracotta, amber, olive sage
    final marigold = const Color(0xFFE76F51).withValues(alpha: 0.65);
    final amber = const Color(0xFFE9C46A).withValues(alpha: 0.70);
    final terracotta = const Color(0xFFD4A373).withValues(alpha: 0.60);
    final sage = const Color(0xFF8A9A5B).withValues(alpha: 0.50);

    // Top-Left corner flourish
    _drawLeafFlourish(canvas, const Offset(6, 6), 1.0, 1.0, marigold, sage, amber);
    // Top-Right corner flourish
    _drawLeafFlourish(canvas, Offset(size.width - 6, 6), -1.0, 1.0, terracotta, sage, marigold);
    // Bottom-Left corner flourish
    _drawLeafFlourish(canvas, Offset(6, size.height - 6), 1.0, -1.0, sage, marigold, amber);
    // Bottom-Right corner flourish
    _drawLeafFlourish(canvas, Offset(size.width - 6, size.height - 6), -1.0, -1.0, amber, terracotta, sage);

    // Subtle golden ember dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    dotPaint.color = amber.withValues(alpha: 0.4);
    canvas.drawCircle(const Offset(38, 14), 2.0, dotPaint);
    canvas.drawCircle(const Offset(14, 38), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 38, 14), 2.0, dotPaint);
    canvas.drawCircle(Offset(size.width - 14, 38), 1.5, dotPaint);
    canvas.drawCircle(Offset(38, size.height - 14), 1.8, dotPaint);
    canvas.drawCircle(Offset(size.width - 38, size.height - 14), 2.0, dotPaint);
  }

  void _paintDarkBotanicals(Canvas canvas, Size size) {
    // Nocturnal palette: night ivy teal, enchanted gold, deep emerald, warm ember
    final nightTeal = const Color(0xFF2A9D8F).withValues(alpha: 0.60);
    final gold = const Color(0xFFE9C46A).withValues(alpha: 0.75);
    final ember = const Color(0xFFF4A261).withValues(alpha: 0.65);
    final emerald = const Color(0xFF264653).withValues(alpha: 0.50);

    // Top-Left corner flourish
    _drawLeafFlourish(canvas, const Offset(6, 6), 1.0, 1.0, nightTeal, gold, ember);
    // Top-Right corner flourish
    _drawLeafFlourish(canvas, Offset(size.width - 6, 6), -1.0, 1.0, gold, nightTeal, emerald);
    // Bottom-Left corner flourish
    _drawLeafFlourish(canvas, Offset(6, size.height - 6), 1.0, -1.0, ember, nightTeal, gold);
    // Bottom-Right corner flourish
    _drawLeafFlourish(canvas, Offset(size.width - 6, size.height - 6), -1.0, -1.0, gold, ember, nightTeal);

    // Glowing enchanted embers
    final emberPaint = Paint()..style = PaintingStyle.fill;
    emberPaint.color = gold.withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(36, 12), 2.2, emberPaint);
    canvas.drawCircle(const Offset(12, 36), 1.6, emberPaint);
    canvas.drawCircle(Offset(size.width - 36, 12), 2.2, emberPaint);
    canvas.drawCircle(Offset(size.width - 12, 36), 1.6, emberPaint);
    canvas.drawCircle(Offset(36, size.height - 12), 1.8, emberPaint);
    canvas.drawCircle(Offset(size.width - 36, size.height - 12), 2.2, emberPaint);
  }

  void _drawLeafFlourish(
    Canvas canvas,
    Offset origin,
    double scaleX,
    double scaleY,
    Color c1,
    Color c2,
    Color c3,
  ) {
    final paint1 = Paint()
      ..color = c1
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = c2
      ..style = PaintingStyle.fill;
    final flowerPaint = Paint()
      ..color = c3
      ..style = PaintingStyle.fill;

    // Vine curve
    final vinePaint = Paint()
      ..color = c1.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final vinePath = Path();
    vinePath.moveTo(origin.dx, origin.dy + (scaleY * 26));
    vinePath.quadraticBezierTo(
      origin.dx + (scaleX * 12),
      origin.dy + (scaleY * 12),
      origin.dx + (scaleX * 26),
      origin.dy,
    );
    canvas.drawPath(vinePath, vinePaint);

    // Primary leaf 1
    final leaf1 = Path();
    leaf1.moveTo(origin.dx + (scaleX * 6), origin.dy + (scaleY * 18));
    leaf1.quadraticBezierTo(
      origin.dx + (scaleX * 14),
      origin.dy + (scaleY * 24),
      origin.dx + (scaleX * 20),
      origin.dy + (scaleY * 18),
    );
    leaf1.quadraticBezierTo(
      origin.dx + (scaleX * 14),
      origin.dy + (scaleY * 14),
      origin.dx + (scaleX * 6),
      origin.dy + (scaleY * 18),
    );
    canvas.drawPath(leaf1, paint1);

    // Primary leaf 2
    final leaf2 = Path();
    leaf2.moveTo(origin.dx + (scaleX * 18), origin.dy + (scaleY * 6));
    leaf2.quadraticBezierTo(
      origin.dx + (scaleX * 24),
      origin.dy + (scaleY * 14),
      origin.dx + (scaleX * 18),
      origin.dy + (scaleY * 20),
    );
    leaf2.quadraticBezierTo(
      origin.dx + (scaleX * 14),
      origin.dy + (scaleY * 14),
      origin.dx + (scaleX * 18),
      origin.dy + (scaleY * 6),
    );
    canvas.drawPath(leaf2, paint2);

    // Marigold / Blossom center dot
    canvas.drawCircle(
      Offset(origin.dx + (scaleX * 13), origin.dy + (scaleY * 13)),
      3.2,
      flowerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BookoraFloralPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// The base decorative container for Bookora Dialogs matching the showcase reference.
class BookoraFloralDialog extends StatelessWidget {
  final Widget? headerIcon;
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const BookoraFloralDialog({
    super.key,
    this.headerIcon,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.maxWidth = 420,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Architectural color tokens strictly adhering to specification
    final bgColor = isDark ? const Color(0xFF13161C) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFE6D5B8);
    final titleColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final subtitleColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFC85A17);
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.65) : const Color(0xFF2E1E12).withValues(alpha: 0.12);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
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
                  if (showCloseButton)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: onClose ?? () => Navigator.of(context, rootNavigator: true).pop(),
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

                  // Main Content Layout
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header icon emblem
                        if (headerIcon != null) ...[
                          Center(child: headerIcon!),
                          const SizedBox(height: 14),
                        ],

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                            letterSpacing: 0.2,
                          ),
                        ),

                        // Subtitle
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: subtitleColor,
                              height: 1.35,
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Dialog Body Content
                        Flexible(
                          child: SingleChildScrollView(
                            child: content,
                          ),
                        ),

                        // Actions Row
                        if (actions != null && actions!.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions!.map((act) {
                              if (act is SizedBox) return act;
                              return Expanded(child: act);
                            }).toList(),
                          ),
                        ],
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
}

/// Pill Action Buttons strictly matching the showcase aesthetics.
class BookoraPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const BookoraPillButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : isDestructive = false,
        isOutlined = false;

  const BookoraPillButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : isDestructive = true,
        isOutlined = false;

  const BookoraPillButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : isDestructive = false,
        isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isOutlined) {
      final borderColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFDED2BD);
      final textColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF5D4037);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: textColor),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            maxLines: 1,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    // Gradients for Primary and Destructive
    final List<Color> gradientColors = isDestructive
        ? const [Color(0xFFD32F2F), Color(0xFFC2185B)]
        : isDark
            ? const [Color(0xFFFF8F00), Color(0xFFE65100)]
            : const [Color(0xFFE65100), Color(0xFFD84315)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                text,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Pill Input Field for Bookora Dialogs
class BookoraPillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? helperText;

  const BookoraPillTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
    final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);
    final textColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final labelColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFB45309);
    final hintColor = isDark ? const Color(0xFF78909C) : const Color(0xFFA89F91);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: hintColor,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: labelColor)
                : null,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
            filled: true,
            fillColor: fillColor,
            counterStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: hintColor,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 12 : 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 22),
              borderSide: BorderSide(color: borderColor, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 22),
              borderSide: BorderSide(color: labelColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
