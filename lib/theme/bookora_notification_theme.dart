import 'package:flutter/material.dart';
import 'dart:math' as math;

class BookoraNotificationTheme {
  final bool isDark;

  const BookoraNotificationTheme({required this.isDark});

  // Background
  Color get background => isDark ? const Color(0xFF1B1917) : const Color(0xFFFFFDF9);
  Color get backgroundSecondary => isDark ? const Color(0xFF161412) : const Color(0xFFFAF6F0);
  
  // Borders
  Color get border => isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE7DFD5);
  
  // Typography
  Color get textPrimary => isDark ? const Color(0xFFFAF7F2) : const Color(0xFF292524);
  Color get textSecondary => isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);

  // Status Colors
  Color get errorRed => isDark ? const Color(0xFFE53935) : const Color(0xFFEF4444);
  Color get warningAmber => isDark ? const Color(0xFFE07A5F) : const Color(0xFFD97706);
  Color get successGreen => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get infoBlue => isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  Color get quoteAmber => isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
  Color get highlightPurple => isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED);

  // Decoration Opacity
  double get decoOpacity => isDark ? 0.15 : 0.4;
}

class BotanicalDecoPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  BotanicalDecoPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.25)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final sparklePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.3 : 0.5)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Translate to bottom right for leaves
    canvas.translate(size.width, size.height);

    // Draw some simple stylized leaf shapes
    // Leaf 1
    canvas.save();
    canvas.rotate(-math.pi / 4);
    _drawLeaf(canvas, paint, const Offset(-30, -10), 30, 15);
    canvas.restore();

    // Leaf 2
    canvas.save();
    canvas.rotate(-math.pi / 6);
    _drawLeaf(canvas, paint, const Offset(-10, -40), 25, 12);
    canvas.restore();
    
    // Leaf 3
    canvas.save();
    canvas.rotate(-math.pi / 3);
    _drawLeaf(canvas, paint, const Offset(-50, 10), 20, 10);
    canvas.restore();

    canvas.restore();

    // Draw sparkles
    canvas.save();
    canvas.translate(size.width - 20, 15);
    _drawSparkle(canvas, sparklePaint, 4);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width - 50, size.height - 10);
    _drawSparkle(canvas, sparklePaint, 2.5);
    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset center, double length, double width) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.quadraticBezierTo(center.dx - width / 2, center.dy - length / 2, center.dx, center.dy - length);
    path.quadraticBezierTo(center.dx + width / 2, center.dy - length / 2, center.dx, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(size / 3, -size / 3, size, 0);
    path.quadraticBezierTo(size / 3, size / 3, 0, size);
    path.quadraticBezierTo(-size / 3, size / 3, -size, 0);
    path.quadraticBezierTo(-size / 3, -size / 3, 0, -size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BotanicalDecoPainter oldDelegate) => color != oldDelegate.color || isDark != oldDelegate.isDark;
}
