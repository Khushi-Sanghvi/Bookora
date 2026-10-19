import 'package:flutter/material.dart';

class BookoraOverlayTheme extends ThemeExtension<BookoraOverlayTheme> {
  final Color surfaceBg;
  final Color primaryText;
  final Color secondaryText;
  final Color successAccent;
  final Color destructiveAccent;
  final Color tipAccent;
  final Color hairlineBorder;
  final List<BoxShadow> cardShadows;
  final double borderRadius;

  const BookoraOverlayTheme({
    required this.surfaceBg,
    required this.primaryText,
    required this.secondaryText,
    required this.successAccent,
    required this.destructiveAccent,
    required this.tipAccent,
    required this.hairlineBorder,
    required this.cardShadows,
    required this.borderRadius,
  });

  factory BookoraOverlayTheme.light() {
    return BookoraOverlayTheme(
      surfaceBg: const Color(0xFFFAF7F2),
      primaryText: const Color(0xFF1C1917),
      secondaryText: const Color(0xFF78716C),
      successAccent: const Color(0xFF4E8B56),
      destructiveAccent: const Color(0xFFA84236),
      tipAccent: const Color(0xFFB4713E),
      hairlineBorder: const Color(0xFFEAE3D8),
      cardShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      borderRadius: 24.0,
    );
  }

  factory BookoraOverlayTheme.dark() {
    return BookoraOverlayTheme(
      surfaceBg: const Color(0xFF181513),
      primaryText: const Color(0xFFFAF7F2),
      secondaryText: const Color(0xFFA8A29E),
      successAccent: const Color(0xFF34A853),
      destructiveAccent: const Color(0xFFD94343),
      tipAccent: const Color(0xFFD9822B),
      hairlineBorder: const Color(0xFF2D2622),
      cardShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      borderRadius: 24.0,
    );
  }

  @override
  BookoraOverlayTheme copyWith({
    Color? surfaceBg,
    Color? primaryText,
    Color? secondaryText,
    Color? successAccent,
    Color? destructiveAccent,
    Color? tipAccent,
    Color? hairlineBorder,
    List<BoxShadow>? cardShadows,
    double? borderRadius,
  }) {
    return BookoraOverlayTheme(
      surfaceBg: surfaceBg ?? this.surfaceBg,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      successAccent: successAccent ?? this.successAccent,
      destructiveAccent: destructiveAccent ?? this.destructiveAccent,
      tipAccent: tipAccent ?? this.tipAccent,
      hairlineBorder: hairlineBorder ?? this.hairlineBorder,
      cardShadows: cardShadows ?? this.cardShadows,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  BookoraOverlayTheme lerp(ThemeExtension<BookoraOverlayTheme>? other, double t) {
    if (other is! BookoraOverlayTheme) return this;
    return BookoraOverlayTheme(
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t) ?? surfaceBg,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      successAccent: Color.lerp(successAccent, other.successAccent, t) ?? successAccent,
      destructiveAccent: Color.lerp(destructiveAccent, other.destructiveAccent, t) ?? destructiveAccent,
      tipAccent: Color.lerp(tipAccent, other.tipAccent, t) ?? tipAccent,
      hairlineBorder: Color.lerp(hairlineBorder, other.hairlineBorder, t) ?? hairlineBorder,
      cardShadows: cardShadows,
      borderRadius: borderRadius,
    );
  }
}

extension BookoraOverlayThemeExtension on BuildContext {
  BookoraOverlayTheme get overlayTheme {
    final isLight = Theme.of(this).brightness == Brightness.light;
    return Theme.of(this).extension<BookoraOverlayTheme>() ??
        (isLight ? BookoraOverlayTheme.light() : BookoraOverlayTheme.dark());
  }
}
