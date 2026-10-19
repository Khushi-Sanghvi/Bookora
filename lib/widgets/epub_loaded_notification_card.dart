import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpubLoadedNotificationCard extends StatelessWidget {
  final String fileName;
  final VoidCallback? onDismiss;

  const EpubLoadedNotificationCard({
    super.key,
    required this.fileName,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme tokens
    final bgColor = isDark ? const Color(0xFF1A0F08) : const Color(0xFFFFF7ED);
    final borderColor = isDark
        ? const Color(0xFFD97706).withValues(alpha: 0.35)
        : const Color(0xFFFDBA74).withValues(alpha: 0.40);
    final titleColor = isDark ? const Color(0xFFFEF3C7) : const Color(0xFF382414);
    final highlightColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFC2410C);
    final subtitleColor = isDark ? const Color(0xFFD6D3D1) : const Color(0xFF78350F);
    final closeIconColor = isDark ? const Color(0xFFFEF3C7).withValues(alpha: 0.80) : const Color(0xFF52341C);
    final progressColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFC2410C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFD97706).withValues(alpha: 0.22)
                : const Color(0xFFC2410C).withValues(alpha: 0.12),
            blurRadius: isDark ? 18 : 16,
            spreadRadius: isDark ? 1 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Custom Painter Layer (Cozy Reading Books & Coffee / Warm Library Shelf)
            Positioned.fill(
              child: CustomPaint(
                painter: _CozyReadingEpubPainter(isDark: isDark),
              ),
            ),

            // Main Content Layout
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, top: 11, bottom: 11),
              child: Row(
                children: [
                  // Left Badge Slot
                  _buildEpubBadge(isDark),
                  const SizedBox(width: 14),

                  // Typography & Progress Line
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EPUB Loaded',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Loaded ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                              TextSpan(
                                text: '"$fileName"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: highlightColor,
                                ),
                              ),
                              TextSpan(
                                text: ' as EPUB source!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Decorative Progress Line Underline
                        Container(
                          width: 100,
                          height: 2.2,
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: progressColor.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: closeIconColor,
                        ),
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

  Widget _buildEpubBadge(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          // Outer Aura & Inner Circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                  : const Color(0xFFFFEDD5),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD97706),
                          Color(0xFFF59E0B),
                        ],
                      )
                    : null,
                color: isDark ? null : const Color(0xFFEA580C),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    bottom: 9,
                    child: Text(
                      'EPUB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFB45309) : const Color(0xFFEA580C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orange Checkmark Badge Micro-Indicator (bottom right)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEA580C),
                border: Border.all(
                  color: isDark ? const Color(0xFF1A0F08) : Colors.white,
                  width: 1.8,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CozyReadingEpubPainter extends CustomPainter {
  final bool isDark;

  _CozyReadingEpubPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft Warm Background Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDBA74).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 35, size.height - 25), radius: 80));
    canvas.drawCircle(Offset(size.width - 35, size.height - 25), 80, ambientPaint);

    // 2. Stack of 3 Leather Antique Books
    final double rightX = size.width - 70;
    final double baseY = size.height - 14;

    // Bottom Book
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX - 35, baseY - 12, 60, 12), const Radius.circular(2)),
      Paint()..color = const Color(0xFFC2410C),
    );
    // Middle Book
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX - 32, baseY - 22, 54, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFFD97706),
    );
    // Top Book
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX - 28, baseY - 31, 48, 9), const Radius.circular(2)),
      Paint()..color = const Color(0xFF78350F),
    );

    // 3. Steaming Coffee/Tea Ceramic Mug
    final double mugX = size.width - 28;
    final double mugY = size.height - 20;

    // Mug Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(mugX - 8, mugY - 12, 16, 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFF4A2E1B),
    );
    // Mug Handle
    canvas.drawArc(
      Rect.fromLTWH(mugX + 5, mugY - 8, 8, 10),
      -1.5,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFF4A2E1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Steam Swirls
    final steamPaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final Path steam1 = Path();
    steam1.moveTo(mugX - 3, mugY - 14);
    steam1.quadraticBezierTo(mugX - 6, mugY - 22, mugX - 2, mugY - 28);
    canvas.drawPath(steam1, steamPaint);

    final Path steam2 = Path();
    steam2.moveTo(mugX + 3, mugY - 14);
    steam2.quadraticBezierTo(mugX, mugY - 20, mugX + 4, mugY - 26);
    canvas.drawPath(steam2, steamPaint);

    // 4. Botanical Leaf Sprigs
    _drawLeaf(canvas, Offset(rightX - 42, baseY - 18), 12, 6, -0.5, const Color(0xFFC2410C));
    _drawLeaf(canvas, Offset(rightX - 46, baseY - 28), 10, 5, -0.8, const Color(0xFFD97706));

    // 5. Sparkles (✦)
    _drawSparkle(canvas, Offset(size.width - 45, 22), 5.5, const Color(0xFFFDBA74));
    _drawSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFFFDBA74));
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // 1. Ambient Warm Hearth Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          const Color(0xFFD97706).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 32, size.height - 22), radius: 80));
    canvas.drawCircle(Offset(size.width - 32, size.height - 22), 80, ambientPaint);

    // 2. Wooden Library Shelf
    final shelfY = size.height - 12;
    final Path shelf = Path()
      ..moveTo(size.width - 150, shelfY)
      ..lineTo(size.width, shelfY)
      ..lineTo(size.width, shelfY + 5)
      ..lineTo(size.width - 150, shelfY + 5)
      ..close();
    canvas.drawPath(shelf, Paint()..color = const Color(0xFF3D2312));

    // 3. Vintage Hardcover Books Row
    final bookColors = [
      const Color(0xFF8D4B20),
      const Color(0xFF155E38),
      const Color(0xFFB45309),
      const Color(0xFF6B21A8),
      const Color(0xFF854D0E)
    ];
    final heights = [32.0, 36.0, 30.0, 34.0, 28.0];
    final widths = [10.0, 11.0, 9.0, 12.0, 9.0];

    double currentX = size.width - 110;
    for (int i = 0; i < 5; i++) {
      final double w = widths[i];
      final double h = heights[i];
      final Rect bookRect = Rect.fromLTWH(currentX, shelfY - h, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(bookRect, const Radius.circular(2)), Paint()..color = bookColors[i]);

      final linePaint = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.70)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(currentX + 2, shelfY - h + 6), Offset(currentX + w - 2, shelfY - h + 6), linePaint);
      canvas.drawLine(Offset(currentX + 2, shelfY - 8), Offset(currentX + w - 2, shelfY - 8), linePaint);

      currentX += w + 2;
    }

    // 4. Amber Glass Candle Lantern
    _drawLantern(canvas, Offset(size.width - 28, shelfY));

    // 5. Molten Gold Sparkles (✦)
    _drawGlowingSparkle(canvas, Offset(size.width - 55, 22), 5.5, const Color(0xFFFBBF24));
    _drawGlowingSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFFFBBF24));
  }

  void _drawLantern(Canvas canvas, Offset shelfBase) {
    final double cx = shelfBase.dx;
    final double cy = shelfBase.dy;

    final Rect baseRect = Rect.fromLTWH(cx - 10, cy - 4, 20, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(1)), Paint()..color = const Color(0xFFD97706));

    final Rect glassRect = Rect.fromLTWH(cx - 8, cy - 26, 16, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(glassRect, const Radius.circular(3)), Paint()..color = const Color(0xFFFEF3C7).withValues(alpha: 0.35));

    final Rect capRect = Rect.fromLTWH(cx - 9, cy - 30, 18, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(1)), Paint()..color = const Color(0xFFD97706));

    // Flame Core
    final Path flamePath = Path()
      ..moveTo(cx, cy - 20)
      ..quadraticBezierTo(cx + 3, cy - 14, cx, cy - 10)
      ..quadraticBezierTo(cx - 3, cy - 14, cx, cy - 20)
      ..close();
    canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFFFBEB));
  }

  void _drawLeaf(Canvas canvas, Offset center, double length, double width, double angle, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Path leaf = Path()
      ..moveTo(0, -length / 2)
      ..quadraticBezierTo(width, 0, 0, length / 2)
      ..quadraticBezierTo(-width, 0, 0, -length / 2)
      ..close();

    canvas.drawPath(leaf, Paint()..color = color);
    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final Path path = _createSparklePath(center, radius);
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawGlowingSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final Path path = _createSparklePath(center, radius);

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, Paint()..color = color);
  }

  Path _createSparklePath(Offset center, double radius) {
    final Path path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CozyReadingEpubPainter oldDelegate) => oldDelegate.isDark != isDark;
}
