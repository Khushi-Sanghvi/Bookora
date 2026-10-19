import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudiobookAttachedNotificationCard extends StatelessWidget {
  final String fileName;
  final VoidCallback? onDismiss;

  const AudiobookAttachedNotificationCard({
    super.key,
    required this.fileName,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme tokens
    final bgColor = isDark ? const Color(0xFF0B1F14) : const Color(0xFFF4F9F4);
    final borderColor = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.30)
        : const Color(0xFFC8DEC8).withValues(alpha: 0.40);
    final titleColor = isDark ? const Color(0xFFF3FAF5) : const Color(0xFF1A3826);
    final highlightColor = isDark ? const Color(0xFF34D399) : const Color(0xFF1B5E20);
    final subtitleColor = isDark ? const Color(0xFFD1FAE5) : const Color(0xFF3D5C45);
    final closeIconColor = isDark ? const Color(0xFFF3FAF5).withValues(alpha: 0.80) : const Color(0xFF2C4A35);
    final progressColor = isDark ? const Color(0xFF34D399) : const Color(0xFF1B5E20);

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
            // Custom Painter Layer (Headphones, Open Book, Foliage, Acoustic Equalizer)
            Positioned.fill(
              child: CustomPaint(
                painter: _AcousticAudiobookPainter(isDark: isDark),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, top: 11, bottom: 11),
              child: Row(
                children: [
                  // Left Badge Slot
                  _buildAudioBadge(isDark),
                  const SizedBox(width: 14),

                  // Typography & Progress Line
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Audiobook file attached',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 14.5,
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
                                text: 'Attached ',
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
                                text: ' to book!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Decorative Sleek Emerald Progress Line
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

  Widget _buildAudioBadge(bool isDark) {
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
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.headphones_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'AUDIO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 5.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Emerald Checkmark Badge Micro-Indicator (bottom right)
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

class _AcousticAudiobookPainter extends CustomPainter {
  final bool isDark;

  _AcousticAudiobookPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft Mint Background Ambient Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 35, size.height - 25), radius: 85));
    canvas.drawCircle(Offset(size.width - 35, size.height - 25), 85, ambientPaint);

    // 2. Soundwave Acoustic Equalizer Bars (|||l||l|||)
    _drawEqualizerBars(canvas, Offset(size.width - 122, size.height - 24), isDark: false);

    // 3. Open Hardcover Book & Headphones Artwork
    _drawBookAndHeadphones(canvas, Offset(size.width - 50, size.height - 22), isDark: false);

    // 4. Botanical Foliage & Leaves
    _drawBotanicalLeaves(canvas, size, isDark: false);

    // 5. Golden / Mint Sparkles (✦)
    _drawSparkle(canvas, Offset(size.width - 35, 20), 5.5, const Color(0xFF10B981));
    _drawSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFF10B981));
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // 1. Luminous Neon Emerald Ambient Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.32),
          const Color(0xFF059669).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width - 35, size.height - 25), radius: 85));
    canvas.drawCircle(Offset(size.width - 35, size.height - 25), 85, ambientPaint);

    // 2. Neon Luminous Soundwave Equalizer Bars (|||l||l|||)
    _drawEqualizerBars(canvas, Offset(size.width - 122, size.height - 24), isDark: true);

    // 3. Glowing Open Book & Neon-Edged Headphones Artwork
    _drawBookAndHeadphones(canvas, Offset(size.width - 50, size.height - 22), isDark: true);

    // 4. Botanical Forest Foliage
    _drawBotanicalLeaves(canvas, size, isDark: true);

    // 5. Glowing Neon Mint Sparkles (✦)
    _drawGlowingSparkle(canvas, Offset(size.width - 35, 20), 5.5, const Color(0xFF34D399));
    _drawGlowingSparkle(canvas, const Offset(132, 20), 4.0, const Color(0xFF34D399));
  }

  void _drawEqualizerBars(Canvas canvas, Offset start, {required bool isDark}) {
    final Color barColor = isDark ? const Color(0xFF34D399) : const Color(0xFF2E6F40);
    final heights = [8.0, 14.0, 20.0, 12.0, 22.0, 16.0, 10.0, 18.0, 12.0];
    const double barWidth = 1.8;
    const double barSpacing = 2.8;

    final Paint paint = Paint()
      ..color = barColor.withValues(alpha: isDark ? 0.85 : 0.60)
      ..style = PaintingStyle.fill;

    if (isDark) {
      final Paint glowPaint = Paint()
        ..color = barColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      for (int i = 0; i < heights.length; i++) {
        final double x = start.dx + i * (barWidth + barSpacing);
        final double h = heights[i];
        final Rect r = Rect.fromLTWH(x, start.dy - h / 2, barWidth, h);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1)), glowPaint);
      }
    }

    for (int i = 0; i < heights.length; i++) {
      final double x = start.dx + i * (barWidth + barSpacing);
      final double h = heights[i];
      final Rect r = Rect.fromLTWH(x, start.dy - h / 2, barWidth, h);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1)), paint);
    }
  }

  void _drawBookAndHeadphones(Canvas canvas, Offset center, {required bool isDark}) {
    final double cx = center.dx;
    final double cy = center.dy;

    // Open Book Pages
    final Path leftPage = Path()
      ..moveTo(cx - 1, cy - 10)
      ..quadraticBezierTo(cx - 15, cy - 16, cx - 28, cy - 8)
      ..quadraticBezierTo(cx - 29, cy + 4, cx - 27, cy + 10)
      ..quadraticBezierTo(cx - 15, cy + 4, cx - 1, cy + 12)
      ..close();

    final Path rightPage = Path()
      ..moveTo(cx + 1, cy - 10)
      ..quadraticBezierTo(cx + 15, cy - 16, cx + 28, cy - 8)
      ..quadraticBezierTo(cx + 29, cy + 4, cx + 27, cy + 10)
      ..quadraticBezierTo(cx + 15, cy + 4, cx + 1, cy + 12)
      ..close();

    final Paint pagePaint = Paint()
      ..color = isDark ? const Color(0xFFFFF3E0) : const Color(0xFFFFFDF9);

    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);

    // Book Cover Underneath
    final Path cover = Path()
      ..moveTo(cx - 30, cy + 11)
      ..quadraticBezierTo(cx, cy + 17, cx + 30, cy + 11)
      ..lineTo(cx + 28, cy + 14)
      ..quadraticBezierTo(cx, cy + 20, cx - 28, cy + 14)
      ..close();
    canvas.drawPath(cover, Paint()..color = const Color(0xFF4A2E1B));

    // Modern Green Headphones
    final Color phoneColor = isDark ? const Color(0xFF10B981) : const Color(0xFF2E6F40);

    if (isDark) {
      final Paint phoneGlow = Paint()
        ..color = const Color(0xFF34D399).withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final Path glowArch = Path()
        ..addArc(Rect.fromLTWH(cx - 22, cy - 32, 44, 38), 3.14, 3.14);
      canvas.drawPath(glowArch, phoneGlow);
    }

    // Headband Arch
    final Path headArch = Path()
      ..addArc(Rect.fromLTWH(cx - 22, cy - 32, 44, 38), 3.14, 3.14);
    canvas.drawPath(
      headArch,
      Paint()
        ..color = phoneColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Earcups resting on sides of book
    final Rect leftCup = Rect.fromCenter(center: Offset(cx - 21, cy + 1), width: 10, height: 18);
    final Rect rightCup = Rect.fromCenter(center: Offset(cx + 21, cy + 1), width: 10, height: 18);

    canvas.drawRRect(RRect.fromRectAndRadius(leftCup, const Radius.circular(4)), Paint()..color = phoneColor);
    canvas.drawRRect(RRect.fromRectAndRadius(rightCup, const Radius.circular(4)), Paint()..color = phoneColor);

    // Earcup Inner Cushions
    final Paint cushionPaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawRRect(RRect.fromRectAndRadius(leftCup.deflate(2), const Radius.circular(2)), cushionPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightCup.deflate(2), const Radius.circular(2)), cushionPaint);
  }

  void _drawBotanicalLeaves(Canvas canvas, Size size, {required bool isDark}) {
    final Color leafColor = isDark ? const Color(0xFF10B981) : const Color(0xFF2E6F40);
    final Color accentColor = isDark ? const Color(0xFF34D399) : const Color(0xFF40916C);

    _drawLeaf(canvas, Offset(size.width - 85, size.height - 18), 12, 6, -0.4, leafColor);
    _drawLeaf(canvas, Offset(size.width - 15, size.height - 22), 14, 7, 0.5, accentColor);
    _drawLeaf(canvas, Offset(size.width - 22, size.height - 42), 11, 5, -0.2, leafColor);
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
  bool shouldRepaint(covariant _AcousticAudiobookPainter oldDelegate) => oldDelegate.isDark != isDark;
}
