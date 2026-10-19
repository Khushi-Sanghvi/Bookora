import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TotalPagesUpdatedNotificationCard extends StatelessWidget {
  final int totalPages;
  final VoidCallback? onDismiss;

  const TotalPagesUpdatedNotificationCard({
    super.key,
    required this.totalPages,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme tokens
    final bgColor = isDark ? const Color(0xFF1E130B) : const Color(0xFFFFF8F0);
    final borderColor = isDark
        ? const Color(0xFFD97706).withValues(alpha: 0.35)
        : const Color(0xFFEEDCC6);
    final primaryTextColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF382A1D);
    final valColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
    final closeIconColor = isDark ? const Color(0xFFFDFBF7).withValues(alpha: 0.70) : const Color(0xFF5D4836);

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
                ? const Color(0xFFD97706).withValues(alpha: 0.20)
                : const Color(0xFFC68B59).withValues(alpha: 0.15),
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
            // Custom Painter Layer (Open Grimoire, Botanical Branches, Sparkles)
            Positioned.fill(
              child: CustomPaint(
                painter: OpenBookBotanicalPainter(isDark: isDark),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.only(left: 115, right: 10, top: 14, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Updated total\n',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: primaryTextColor,
                            ),
                          ),
                          TextSpan(
                            text: 'pages to ',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          TextSpan(
                            text: '$totalPages',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: valColor,
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
}

class OpenBookBotanicalPainter extends CustomPainter {
  final bool isDark;

  OpenBookBotanicalPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft Shadow under Grimoire
    final shadowRect = Rect.fromCenter(center: const Offset(60, 68), width: 85, height: 16);
    final shadowPaint = Paint()
      ..color = const Color(0xFF8C5A2B).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(shadowRect, shadowPaint);

    // 2. Left Botanical Foliage Branch
    _drawBotanicalBranch(
      canvas,
      start: const Offset(14, 76),
      control: const Offset(8, 42),
      end: const Offset(26, 12),
      leafColor: const Color(0xFFC68B59),
      accentLeafColor: const Color(0xFFD49A5E),
      isDark: false,
    );

    // 3. Open Grimoire Book
    _drawOpenGrimoire(canvas, center: const Offset(60, 48), isDark: false);

    // 4. Right Bottom Botanical Foliage Branch
    _drawRightFoliage(canvas, size, isDark: false);

    // 5. Golden Sparkles (✦)
    _drawSparkle(canvas, Offset(size.width - 45, 22), 5.5, const Color(0xFFE5A93C));
    _drawSparkle(canvas, Offset(size.width - 22, 58), 4.5, const Color(0xFFE5A93C).withValues(alpha: 0.85));
    _drawSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFFE5A93C).withValues(alpha: 0.90));
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // 1. Ambient Warm Hearth / Candlelight Glow behind Grimoire
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          const Color(0xFFD97706).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(60, 48), radius: 65));
    canvas.drawCircle(const Offset(60, 48), 65, ambientPaint);

    // 2. Radiant Golden Left Botanical Branch
    _drawBotanicalBranch(
      canvas,
      start: const Offset(14, 76),
      control: const Offset(8, 42),
      end: const Offset(26, 12),
      leafColor: const Color(0xFFF59E0B),
      accentLeafColor: const Color(0xFFFBBF24),
      isDark: true,
    );

    // 3. Luminous Open Grimoire Book
    _drawOpenGrimoire(canvas, center: const Offset(60, 48), isDark: true);

    // 4. Right Bottom Illuminated Golden Foliage
    _drawRightFoliage(canvas, size, isDark: true);

    // 5. Molten Gold Glowing Sparkles (✦)
    _drawGlowingSparkle(canvas, Offset(size.width - 45, 22), 6.0, const Color(0xFFFBBF24));
    _drawGlowingSparkle(canvas, Offset(size.width - 22, 58), 4.5, const Color(0xFFFBBF24));
    _drawGlowingSparkle(canvas, const Offset(132, 20), 4.2, const Color(0xFFFBBF24));
  }

  void _drawOpenGrimoire(Canvas canvas, {required Offset center, required bool isDark}) {
    final double cx = center.dx;
    final double cy = center.dy;

    // Leather Cover Backing
    final coverPath = Path();
    coverPath.moveTo(cx - 42, cy + 18);
    coverPath.quadraticBezierTo(cx - 2, cy + 26, cx + 42, cy + 18);
    coverPath.lineTo(cx + 40, cy + 22);
    coverPath.quadraticBezierTo(cx - 2, cy + 28, cx - 40, cy + 22);
    coverPath.close();

    final coverPaint = Paint()
      ..color = isDark ? const Color(0xFF543213) : const Color(0xFF7C4A21);
    canvas.drawPath(coverPath, coverPaint);

    // Deckle-Edge Page Block Stacks (3D depth)
    final stackPath = Path();
    stackPath.moveTo(cx - 39, cy + 12);
    stackPath.lineTo(cx - 39, cy + 19);
    stackPath.quadraticBezierTo(cx - 2, cy + 25, cx + 39, cy + 19);
    stackPath.lineTo(cx + 39, cy + 12);
    stackPath.quadraticBezierTo(cx - 2, cy + 18, cx - 39, cy + 12);
    stackPath.close();

    final stackPaint = Paint()
      ..color = isDark ? const Color(0xFF9A622A) : const Color(0xFFC6935C);
    canvas.drawPath(stackPath, stackPaint);

    // Left Page
    final leftPage = Path();
    leftPage.moveTo(cx - 1, cy - 14);
    leftPage.quadraticBezierTo(cx - 20, cy - 22, cx - 39, cy - 12);
    leftPage.quadraticBezierTo(cx - 40, cy + 4, cx - 38, cy + 13);
    leftPage.quadraticBezierTo(cx - 20, cy + 5, cx - 1, cy + 16);
    leftPage.close();

    // Right Page
    final rightPage = Path();
    rightPage.moveTo(cx + 1, cy - 14);
    rightPage.quadraticBezierTo(cx + 20, cy - 22, cx + 39, cy - 12);
    rightPage.quadraticBezierTo(cx + 40, cy + 4, cx + 38, cy + 13);
    rightPage.quadraticBezierTo(cx + 20, cy + 5, cx + 1, cy + 16);
    rightPage.close();

    final pageFill = Paint()
      ..color = isDark ? const Color(0xFFFFF3E0) : const Color(0xFFFFFDF9);

    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(rightPage, pageFill);

    // Spine Crease Shadow
    final creasePath = Path();
    creasePath.moveTo(cx - 3, cy - 14);
    creasePath.lineTo(cx + 3, cy - 14);
    creasePath.lineTo(cx + 3, cy + 16);
    creasePath.lineTo(cx - 3, cy + 16);
    creasePath.close();

    final creasePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: isDark ? 0.35 : 0.20),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(cx - 3, cy - 14, cx + 3, cy + 16));
    canvas.drawPath(creasePath, creasePaint);

    // Page Lines (faint text representation)
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFFB48356) : const Color(0xFFC6A27E)).withValues(alpha: 0.45)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Left page rule lines
    canvas.drawLine(Offset(cx - 32, cy - 4), Offset(cx - 10, cy - 7), linePaint);
    canvas.drawLine(Offset(cx - 31, cy + 2), Offset(cx - 10, cy - 1), linePaint);
    canvas.drawLine(Offset(cx - 30, cy + 8), Offset(cx - 12, cy + 5), linePaint);

    // Right page rule lines
    canvas.drawLine(Offset(cx + 10, cy - 7), Offset(cx + 32, cy - 4), linePaint);
    canvas.drawLine(Offset(cx + 10, cy - 1), Offset(cx + 31, cy + 2), linePaint);
    canvas.drawLine(Offset(cx + 12, cy + 5), Offset(cx + 30, cy + 8), linePaint);
  }

  void _drawBotanicalBranch(
    Canvas canvas, {
    required Offset start,
    required Offset control,
    required Offset end,
    required Color leafColor,
    required Color accentLeafColor,
    required bool isDark,
  }) {
    // Stem
    final Path stem = Path();
    stem.moveTo(start.dx, start.dy);
    stem.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final stemPaint = Paint()
      ..color = leafColor.withValues(alpha: isDark ? 0.90 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    if (isDark) {
      final glowPaint = Paint()
        ..color = leafColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(stem, glowPaint);
    }
    canvas.drawPath(stem, stemPaint);

    // Leaves along stem
    final leaves = [
      _LeafInfo(const Offset(18, 62), 12, 6, -0.6, leafColor),
      _LeafInfo(const Offset(10, 50), 14, 7, 0.4, accentLeafColor),
      _LeafInfo(const Offset(16, 38), 13, 6, -0.5, leafColor),
      _LeafInfo(const Offset(14, 25), 11, 5, 0.3, accentLeafColor),
      _LeafInfo(const Offset(24, 15), 10, 5, -0.2, leafColor),
    ];

    for (final leaf in leaves) {
      _drawSingleLeaf(canvas, leaf.center, leaf.length, leaf.width, leaf.angle, leaf.color, isDark);
    }
  }

  void _drawRightFoliage(Canvas canvas, Size size, {required bool isDark}) {
    final Color leafColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFC68B59);
    final Color accentColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD49A5E);

    final leaves = [
      _LeafInfo(Offset(size.width - 24, size.height - 10), 18, 9, -0.4, leafColor),
      _LeafInfo(Offset(size.width - 12, size.height - 22), 16, 8, -0.8, accentColor),
      _LeafInfo(Offset(size.width - 32, size.height - 28), 15, 7, 0.2, leafColor),
      _LeafInfo(Offset(size.width - 20, size.height - 42), 13, 6, -0.3, accentColor),
    ];

    for (final leaf in leaves) {
      _drawSingleLeaf(canvas, leaf.center, leaf.length, leaf.width, leaf.angle, leaf.color, isDark);
    }
  }

  void _drawSingleLeaf(Canvas canvas, Offset center, double length, double width, double angle, Color color, bool isDark) {
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

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf, fillPaint);

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final Path path = _createSparklePath(center, radius);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawGlowingSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final Path path = _createSparklePath(center, radius);

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
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
  bool shouldRepaint(covariant OpenBookBotanicalPainter oldDelegate) => oldDelegate.isDark != isDark;
}

class _LeafInfo {
  final Offset center;
  final double length;
  final double width;
  final double angle;
  final Color color;

  _LeafInfo(this.center, this.length, this.width, this.angle, this.color);
}
