import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookAddedNotificationCard extends StatelessWidget {
  final String bookTitle;
  final VoidCallback? onDismiss;

  const BookAddedNotificationCard({
    super.key,
    required this.bookTitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme values based on specifications
    final bgColor = isDark ? const Color(0xFF1E1813) : const Color(0xFFFFF4F2);
    final borderColor = isDark ? const Color(0xFFD97706).withValues(alpha: 0.25) : const Color(0xFFFBDCD6);
    
    // Left Badge values
    final badgeBgColor = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFFBDCD6);
    final iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFC24135);
    
    // Typography values
    final titleColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF292524);
    final subtitleColor = isDark ? const Color(0xFFD6C7B2) : const Color(0xFF78716C);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient light (Dark Mode)
          if (isDark)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD97706).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
          // Right-side Custom Illustrated Book Stack
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            width: 140, // Width for the illustration area
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: CustomPaint(
                painter: _BookStackIllustrationPainter(isDark: isDark),
              ),
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Left Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    shape: BoxShape.circle,
                    border: isDark ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1) : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner squircle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Book icon
                      Icon(
                        Icons.menu_book_rounded,
                        color: isDark ? const Color(0xFF241C16) : Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // Text Content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Added to Library!',
                        style: GoogleFonts.playfairDisplay(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$bookTitle"',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Spacing to keep text away from close button
                const SizedBox(width: 24),
              ],
            ),
          ),
          
          // Close Button
          if (onDismiss != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isDark ? const Color(0xFFD6C7B2) : const Color(0xFF78716C),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom Painter to draw the 3-tier book stack and sparkles without needing heavy image assets
class _BookStackIllustrationPainter extends CustomPainter {
  final bool isDark;
  
  _BookStackIllustrationPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Colors matching the design specs
    final redBook = isDark ? const Color(0xFFB53F3A) : const Color(0xFFC75D53);
    final tealBook = isDark ? const Color(0xFF2C6B6F) : const Color(0xFF4C8D91);
    final goldBook = isDark ? const Color(0xFFD3A25A) : const Color(0xFFE2BA7B);
    final pageColor = isDark ? const Color(0xFFDCD2C6) : const Color(0xFFFAF2E6);
    final sparkleColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFF39C12);
    
    canvas.save();
    
    // Shift slightly depending on size
    canvas.translate(size.width - 90, size.height - 15);
    
    // Draw background leaf/watermark if light mode
    if (!isDark) {
      final paint = Paint()
        ..color = const Color(0xFFFBDCD6)
        ..style = PaintingStyle.fill;
        
      final path = Path();
      path.moveTo(-20, 0);
      path.quadraticBezierTo(-30, -10, -25, -20);
      path.quadraticBezierTo(-15, -15, -20, 0);
      canvas.drawPath(path, paint);
      
      path.reset();
      path.moveTo(60, 0);
      path.quadraticBezierTo(70, -15, 65, -25);
      path.quadraticBezierTo(50, -20, 60, 0);
      canvas.drawPath(path, paint);
    }
    
    // Base shadows
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.5 : 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -5, 75, 10), const Radius.circular(2)), shadowPaint);
    
    // Book 3 (Bottom - Gold/Teal)
    _drawBook(canvas, const Offset(0, 0), 65, 12, tealBook, pageColor, isDark);
    
    // Book 2 (Middle - Gold)
    _drawBook(canvas, const Offset(5, -12), 60, 11, goldBook, pageColor, isDark);
    
    // Book 1 (Top - Red)
    _drawBook(canvas, const Offset(2, -23), 55, 10, redBook, pageColor, isDark);
    
    // If Dark Mode, draw a little candle glow on the left
    if (isDark) {
      // Candle body
      final candlePaint = Paint()..color = const Color(0xFFE8DCCF);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-25, -15, 12, 15), const Radius.circular(2)), candlePaint);
      
      // Flame glow
      final glowPaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(const Offset(-19, -20), 10, glowPaint);
      
      // Flame core
      final flamePaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(-19, -18), 3, flamePaint);
      final orangeFlame = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawCircle(const Offset(-19, -17), 2, orangeFlame);
    }

    // Sparkles
    final sPaint = Paint()..color = sparkleColor;
    _drawSparkle(canvas, sPaint, const Offset(40, -35), 6); // Big top sparkle
    _drawSparkle(canvas, sPaint, const Offset(-10, -45), 3); // Little left sparkle
    if (!isDark) {
      _drawSparkle(canvas, sPaint, const Offset(20, -10), 2.5); // Little middle sparkle
    }

    canvas.restore();
  }
  
  void _drawBook(Canvas canvas, Offset offset, double width, double height, Color coverColor, Color pageColor, bool isDark) {
    // Main spine/cover
    final coverPaint = Paint()..color = coverColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx, offset.dy, width, height),
      const Radius.circular(3)
    );
    canvas.drawRRect(rrect, coverPaint);
    
    // Spine highlight/shadow for depth
    final depthPaint = Paint()..color = isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2);
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy + 2, width, 2), depthPaint);
    
    // Pages
    final pagesPaint = Paint()..color = pageColor;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx + 5, offset.dy + 2, width - 10, height - 4),
      const Radius.circular(1)
    ), pagesPaint);
    
    // Spine detail (gold lines)
    final detailPaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(offset.dx + 8, offset.dy, 2, height), detailPaint);
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx + size/3, center.dy - size/3, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx + size/3, center.dy + size/3, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx - size/3, center.dy + size/3, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx - size/3, center.dy - size/3, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
