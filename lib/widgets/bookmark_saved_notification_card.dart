import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarkSavedNotificationCard extends StatelessWidget {
  final int pageNum;
  final VoidCallback? onDismiss;

  const BookmarkSavedNotificationCard({
    super.key,
    required this.pageNum,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color tokens
    final bgColor = isDark ? const Color(0xFF0B1F14) : const Color(0xFFF4F9F4);
    final borderColor = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.30)
        : const Color(0xFFC8DEC8);
    final primaryTextColor = isDark ? const Color(0xFFF3FAF5) : const Color(0xFF1A3826);
    final prefixTextColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF3D5C45);
    final valColor = isDark ? const Color(0xFF34D399) : const Color(0xFF1B5E20);
    final closeIconColor = isDark ? const Color(0xFFF3FAF5).withValues(alpha: 0.75) : const Color(0xFF2C4A35);

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
                ? const Color(0xFF10B981).withValues(alpha: 0.20)
                : const Color(0xFF2E6F40).withValues(alpha: 0.12),
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
            // Custom Painter Layer (Bookshelf, Potted Plant, Candle Lantern, Sparkles)
            Positioned.fill(
              child: CustomPaint(
                painter: BookshelfLanternPainter(isDark: isDark),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, top: 12, bottom: 12),
              child: Row(
                children: [
                  // Left Badge Slot
                  _buildAvatarBadge(isDark),
                  const SizedBox(width: 14),

                  // Typography
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Bookmark saved!\n',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: primaryTextColor,
                            ),
                          ),
                          TextSpan(
                            text: '(Page ',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: prefixTextColor,
                            ),
                          ),
                          TextSpan(
                            text: '$pageNum',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: valColor,
                            ),
                          ),
                          TextSpan(
                            text: ')',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: prefixTextColor,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAvatarBadge(bool isDark) {
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
                  ? const Color(0xFF10B981).withValues(alpha: 0.20)
                  : const Color(0xFFE2EFE4),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
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
                          Color(0xFF059669),
                          Color(0xFF10B981),
                        ],
                      )
                    : null,
                color: isDark ? null : const Color(0xFF2E6F40),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Micro Checkmark Indicator Badge (bottom right)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981),
                border: Border.all(
                  color: isDark ? const Color(0xFF0B1F14) : Colors.white,
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

class BookshelfLanternPainter extends CustomPainter {
  final bool isDark;

  BookshelfLanternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft Background Mint Gradient
    final bgGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFFE1EFE3).withValues(alpha: 0.50),
          const Color(0xFFD4E8D7).withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.6, size.height));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.6, size.height), bgGradient);

    // 2. Wooden Bookshelf Plank
    final shelfY = size.height - 12;
    final shelfPath = Path();
    shelfPath.moveTo(size.width - 150, shelfY);
    shelfPath.lineTo(size.width, shelfY);
    shelfPath.lineTo(size.width, shelfY + 5);
    shelfPath.lineTo(size.width - 150, shelfY + 5);
    shelfPath.close();

    final shelfPaint = Paint()..color = const Color(0xFF8D5B3A);
    canvas.drawPath(shelfPath, shelfPaint);

    // 3. Potted Houseplant (Left of Books)
    _drawPottedPlant(canvas, Offset(size.width - 132, shelfY), isDark: false);

    // 4. Row of Vintage Hardcover Books
    _drawBooksRow(canvas, Offset(size.width - 105, shelfY), isDark: false);

    // 5. Potted Houseplant #2 (Right of Books)
    _drawPottedPlant(canvas, Offset(size.width - 32, shelfY), isDark: false);

    // 6. Sparkle Stars (✦)
    _drawSparkle(canvas, Offset(size.width - 48, 22), 5.5, const Color(0xFF81C784));
    _drawSparkle(canvas, Offset(size.width - 138, 28), 4.5, const Color(0xFF81C784).withValues(alpha: 0.8));
    _drawSparkle(canvas, const Offset(132, 22), 4.0, const Color(0xFF81C784).withValues(alpha: 0.9));
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // 1. Ambient Candle Hearth Glow in Bottom Right
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          const Color(0xFF10B981).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width - 28, size.height - 22),
        radius: 75,
      ));
    canvas.drawCircle(Offset(size.width - 28, size.height - 22), 75, ambientPaint);

    // 2. Wooden Bookshelf Plank
    final shelfY = size.height - 12;
    final shelfPath = Path();
    shelfPath.moveTo(size.width - 160, shelfY);
    shelfPath.lineTo(size.width, shelfY);
    shelfPath.lineTo(size.width, shelfY + 5);
    shelfPath.lineTo(size.width - 160, shelfY + 5);
    shelfPath.close();

    final shelfPaint = Paint()..color = const Color(0xFF3D2312);
    canvas.drawPath(shelfPath, shelfPaint);

    // 3. Potted Houseplant (Left of Books)
    _drawPottedPlant(canvas, Offset(size.width - 142, shelfY), isDark: true);

    // 4. Row of Vintage Hardcover Books
    _drawBooksRow(canvas, Offset(size.width - 118, shelfY), isDark: true);

    // 5. Amber Glass Candle Lantern (Right of Books)
    _drawCandleLantern(canvas, Offset(size.width - 28, shelfY));

    // 6. Floating Ambient Dust Sparkles (✦)
    _drawGlowingSparkle(canvas, Offset(size.width - 55, 22), 5.5, const Color(0xFFFBBF24));
    _drawGlowingSparkle(canvas, Offset(size.width - 148, 28), 4.5, const Color(0xFF34D399));
    _drawGlowingSparkle(canvas, const Offset(132, 22), 4.0, const Color(0xFF34D399));
  }

  void _drawPottedPlant(Canvas canvas, Offset shelfBase, {required bool isDark}) {
    final double potX = shelfBase.dx;
    final double potY = shelfBase.dy;

    // Pot
    final Path potPath = Path();
    potPath.moveTo(potX - 8, potY - 14);
    potPath.lineTo(potX + 8, potY - 14);
    potPath.lineTo(potX + 6, potY);
    potPath.lineTo(potX - 6, potY);
    potPath.close();

    final potPaint = Paint()
      ..color = isDark ? const Color(0xFF8D5B3A) : const Color(0xFFD97706);
    canvas.drawPath(potPath, potPaint);

    // Leaves
    final Color leafColor = isDark ? const Color(0xFF10B981) : const Color(0xFF2E6F40);
    final Color accentLeafColor = isDark ? const Color(0xFF34D399) : const Color(0xFF40916C);

    _drawLeaf(canvas, Offset(potX - 4, potY - 22), 12, 6, -0.4, leafColor, isDark);
    _drawLeaf(canvas, Offset(potX + 4, potY - 24), 13, 7, 0.4, accentLeafColor, isDark);
    _drawLeaf(canvas, Offset(potX, potY - 28), 14, 7, 0.0, leafColor, isDark);
  }

  void _drawBooksRow(Canvas canvas, Offset shelfBase, {required bool isDark}) {
    final double startX = shelfBase.dx;
    final double baseY = shelfBase.dy;

    final bookColors = isDark
        ? [const Color(0xFF8D4B20), const Color(0xFF155E38), const Color(0xFFB45309), const Color(0xFF6B21A8), const Color(0xFF854D0E)]
        : [const Color(0xFFA0522D), const Color(0xFF2E6F40), const Color(0xFFD97706), const Color(0xFF7E22CE), const Color(0xFFB45309)];

    final heights = [32.0, 36.0, 30.0, 34.0, 28.0];
    final widths = [10.0, 11.0, 9.0, 12.0, 9.0];

    double currentX = startX;

    for (int i = 0; i < 5; i++) {
      final double w = widths[i];
      final double h = heights[i];

      final Rect bookRect = Rect.fromLTWH(currentX, baseY - h, w, h);
      final Paint bookPaint = Paint()..color = bookColors[i];
      canvas.drawRRect(RRect.fromRectAndRadius(bookRect, const Radius.circular(2)), bookPaint);

      // Gold Foil Lines on Spine
      final Paint linePaint = Paint()
        ..color = (isDark ? const Color(0xFFFBBF24) : const Color(0xFFFFD700)).withValues(alpha: 0.70)
        ..strokeWidth = 1.0;

      canvas.drawLine(Offset(currentX + 2, baseY - h + 6), Offset(currentX + w - 2, baseY - h + 6), linePaint);
      canvas.drawLine(Offset(currentX + 2, baseY - h + 10), Offset(currentX + w - 2, baseY - h + 10), linePaint);
      canvas.drawLine(Offset(currentX + 2, baseY - 8), Offset(currentX + w - 2, baseY - 8), linePaint);

      currentX += w + 2;
    }
  }

  void _drawCandleLantern(Canvas canvas, Offset shelfBase) {
    final double cx = shelfBase.dx;
    final double cy = shelfBase.dy;

    // Lantern Base
    final Rect baseRect = Rect.fromLTWH(cx - 10, cy - 4, 20, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(1)), Paint()..color = const Color(0xFFD97706));

    // Glass Cylinder
    final Rect glassRect = Rect.fromLTWH(cx - 8, cy - 26, 16, 22);
    final Paint glassPaint = Paint()..color = const Color(0xFFFEF3C7).withValues(alpha: 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(glassRect, const Radius.circular(3)), glassPaint);

    // Brass Cap & Top Ring
    final Rect capRect = Rect.fromLTWH(cx - 9, cy - 30, 18, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(1)), Paint()..color = const Color(0xFFD97706));

    final Path ringPath = Path();
    ringPath.addOval(Rect.fromCircle(center: Offset(cx, cy - 32), radius: 3));
    canvas.drawPath(ringPath, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Flame & Inner Glow
    final Offset flameCenter = Offset(cx, cy - 15);

    // Inner Flame Glow
    final Paint flameGlow = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(flameCenter, 6, flameGlow);

    // Flame Core
    final Path flamePath = Path();
    flamePath.moveTo(cx, cy - 20);
    flamePath.quadraticBezierTo(cx + 3, cy - 14, cx, cy - 10);
    flamePath.quadraticBezierTo(cx - 3, cy - 14, cx, cy - 20);
    flamePath.close();

    canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFFFBEB));
  }

  void _drawLeaf(Canvas canvas, Offset center, double length, double width, double angle, Color color, bool isDark) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Path leaf = Path();
    leaf.moveTo(0, -length / 2);
    leaf.quadraticBezierTo(width, 0, 0, length / 2);
    leaf.quadraticBezierTo(-width, 0, 0, -length / 2);
    leaf.close();

    if (isDark) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(leaf, glowPaint);
    }

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
  bool shouldRepaint(covariant BookshelfLanternPainter oldDelegate) => oldDelegate.isDark != isDark;
}
