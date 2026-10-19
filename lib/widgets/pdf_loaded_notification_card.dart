import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfLoadedNotificationCard extends StatelessWidget {
  final String fileName;
  final VoidCallback? onDismiss;

  const PdfLoadedNotificationCard({
    super.key,
    required this.fileName,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color tokens
    final bgColor = isDark ? const Color(0xFF1F0A12) : const Color(0xFFFFF1F2);
    final borderColor = isDark
        ? const Color(0xFFE11D48).withValues(alpha: 0.40)
        : const Color(0xFFFDA4AF).withValues(alpha: 0.40);
    final titleColor = isDark ? const Color(0xFFFFF1F2) : const Color(0xFF881337);
    final highlightColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    final subtitleColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF9F1239);
    final closeIconColor = isDark ? const Color(0xFFFFF1F2).withValues(alpha: 0.80) : const Color(0xFF881337);
    final progressColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);

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
                ? const Color(0xFFE11D48).withValues(alpha: 0.25)
                : const Color(0xFFE11D48).withValues(alpha: 0.12),
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
            // Custom Painter Layer (Notebook, Floating Hearts, Cherry Blossom Petals)
            Positioned.fill(
              child: CustomPaint(
                painter: _SakuraPdfPainter(isDark: isDark),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, top: 11, bottom: 11),
              child: Row(
                children: [
                  // Left Badge Slot
                  _buildPdfBadge(isDark),
                  const SizedBox(width: 14),

                  // Typography & Progress Line
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PDF Loaded',
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
                                text: ' as PDF source!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Decorative Sleek Progress Line
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

  Widget _buildPdfBadge(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          // Outer Aura Ring
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFFFB7185).withValues(alpha: 0.20)
                  : const Color(0xFFFFE4E6),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFB7185).withValues(alpha: 0.35),
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
                          Color(0xFF9F1239),
                          Color(0xFFE11D48),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE11D48),
                          Color(0xFFF43F5E),
                        ],
                      ),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    bottom: 9,
                    child: Text(
                      'PDF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFBE123C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coral/Magenta Checkmark Badge Micro-Indicator (bottom right)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE11D48),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F0A12) : Colors.white,
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

class _SakuraPdfPainter extends CustomPainter {
  final bool isDark;

  _SakuraPdfPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft Rose Background Ambient Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDA4AF).withValues(alpha: 0.30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 35, size.height - 25), radius: 85));
    canvas.drawCircle(Offset(size.width - 35, size.height - 25), 85, ambientPaint);

    // 2. Open Pink Spiral Notebook on Right Side
    _drawSpiralNotebook(canvas, Offset(size.width - 45, 42), isDark: false);

    // 3. Floating Outline Heart (♡)
    _drawOutlineHeart(canvas, Offset(size.width - 98, 26), 14, 13, const Color(0xFFFB7185));

    // 4. Blossoming Cherry Flowers & Falling Sakura Petals
    _drawCherryBlossom(canvas, Offset(size.width - 82, 58), 10, const Color(0xFFFB7185));
    _drawCherryBlossom(canvas, Offset(size.width - 66, 66), 8, const Color(0xFFFDA4AF));

    _drawPetal(canvas, Offset(size.width - 105, 52), 6, -0.6, const Color(0xFFFB7185));
    _drawPetal(canvas, Offset(size.width - 25, 68), 5, 0.4, const Color(0xFFFDA4AF));

    // 5. Sparkles (✦)
    _drawSparkle(canvas, Offset(size.width - 35, 20), 5.5, const Color(0xFFFB7185));
    _drawSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFFFB7185));
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // 1. Luminous Neon Magenta Ambient Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE11D48).withValues(alpha: 0.35),
          const Color(0xFF881337).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 35, size.height - 25), radius: 85));
    canvas.drawCircle(Offset(size.width - 35, size.height - 25), 85, ambientPaint);

    // 2. Glowing Open Spiral Notebook
    _drawSpiralNotebook(canvas, Offset(size.width - 45, 42), isDark: true);

    // 3. Floating Glowing Outline Heart (♡)
    _drawGlowingOutlineHeart(canvas, Offset(size.width - 98, 26), 14, 13, const Color(0xFFFB7185));

    // 4. Glowing Cherry Blossoms & Floating Petals
    _drawCherryBlossom(canvas, Offset(size.width - 82, 58), 10, const Color(0xFFFB7185));
    _drawCherryBlossom(canvas, Offset(size.width - 66, 66), 8, const Color(0xFFF43F5E));

    _drawPetal(canvas, Offset(size.width - 105, 52), 6, -0.6, const Color(0xFFFB7185));
    _drawPetal(canvas, Offset(size.width - 25, 68), 5, 0.4, const Color(0xFFFB7185));

    // 5. Glowing Neon Sparkles (✦)
    _drawGlowingSparkle(canvas, Offset(size.width - 35, 20), 5.5, const Color(0xFFFB7185));
    _drawGlowingSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFFFB7185));
  }

  void _drawSpiralNotebook(Canvas canvas, Offset center, {required bool isDark}) {
    final double cx = center.dx;
    final double cy = center.dy;

    // Notebook Shadow / Glow
    final shadowPaint = Paint()
      ..color = (isDark ? const Color(0xFFE11D48) : const Color(0xFFFB7185)).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 20, cy - 22, 42, 44), const Radius.circular(4)), shadowPaint);

    // Notebook Pages
    final Rect pageRect = Rect.fromLTWH(cx - 20, cy - 22, 42, 44);
    final Paint pagePaint = Paint()
      ..color = isDark ? const Color(0xFFFFF1F2) : const Color(0xFFFFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(pageRect, const Radius.circular(4)), pagePaint);

    // Rule Lines on Notebook
    final Paint rulePaint = Paint()
      ..color = const Color(0xFFFDA4AF).withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    for (double y = cy - 14; y <= cy + 14; y += 6) {
      canvas.drawLine(Offset(cx - 12, y), Offset(cx + 16, y), rulePaint);
    }

    // Spiral Binder Rings along left edge
    final Paint spiralPaint = Paint()
      ..color = isDark ? const Color(0xFFE11D48) : const Color(0xFF9F1239)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (double y = cy - 18; y <= cy + 18; y += 8) {
      canvas.drawCircle(Offset(cx - 20, y), 2.2, spiralPaint);
    }

    // Red PDF Tag Badge on Notebook Cover
    final Rect pdfBadgeRect = Rect.fromLTWH(cx + 2, cy + 4, 16, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(pdfBadgeRect, const Radius.circular(2)), Paint()..color = const Color(0xFFE11D48));
  }

  void _drawOutlineHeart(Canvas canvas, Offset center, double width, double height, Color color) {
    final Path path = _createHeartPath(center, width, height);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, paint);
  }

  void _drawGlowingOutlineHeart(Canvas canvas, Offset center, double width, double height, Color color) {
    final Path path = _createHeartPath(center, width, height);

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, paint);
  }

  void _drawCherryBlossom(Canvas canvas, Offset center, double radius, Color color) {
    for (int i = 0; i < 5; i++) {
      final double angle = (i * 72) * 3.14159 / 180;
      final Offset petalCenter = Offset(
        center.dx + radius * 0.6 * (angle == 0 ? 1 : (angle > 0 ? 0.8 : -0.8)),
        center.dy + radius * 0.6 * (angle > 1.5 ? 0.8 : -0.8),
      );
      _drawPetal(canvas, petalCenter, radius * 0.8, angle, color);
    }
    canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
  }

  void _drawPetal(Canvas canvas, Offset center, double length, double angle, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Path petal = Path()
      ..moveTo(0, -length / 2)
      ..quadraticBezierTo(length * 0.6, 0, 0, length / 2)
      ..quadraticBezierTo(-length * 0.6, 0, 0, -length / 2)
      ..close();

    canvas.drawPath(petal, Paint()..color = color);
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

  Path _createHeartPath(Offset center, double width, double height) {
    final Path path = Path();
    final double left = center.dx - width / 2;
    final double top = center.dy - height / 2;

    path.moveTo(left + width / 2, top + height * 0.28);
    path.cubicTo(
      left + width * 0.85, top - height * 0.05,
      left + width * 1.05, top + height * 0.45,
      left + width / 2, top + height * 0.95,
    );
    path.cubicTo(
      left - width * 0.05, top + height * 0.45,
      left + width * 0.15, top - height * 0.05,
      left + width / 2, top + height * 0.28,
    );
    path.close();
    return path;
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
  bool shouldRepaint(covariant _SakuraPdfPainter oldDelegate) => oldDelegate.isDark != isDark;
}
