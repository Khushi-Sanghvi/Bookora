import 'package:flutter/material.dart';

@immutable
class ReadingAppColors extends ThemeExtension<ReadingAppColors> {
  final Color scaffoldBg;
  final Color cardBg;
  final Color cardBgSecondary;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color streakAmber;
  final Color quoteGold;
  final Color shelfWood;
  final Color accentSage;
  final Color accentAmethyst;
  final Color accentOcean;
  final Color heatmapInactive;
  final Color heatmapLevel1;
  final Color heatmapLevel2;
  final Color heatmapLevel3;

  const ReadingAppColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.cardBgSecondary,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.streakAmber,
    required this.quoteGold,
    required this.shelfWood,
    required this.accentSage,
    required this.accentAmethyst,
    required this.accentOcean,
    required this.heatmapInactive,
    required this.heatmapLevel1,
    required this.heatmapLevel2,
    required this.heatmapLevel3,
  });

  @override
  ReadingAppColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? cardBgSecondary,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? streakAmber,
    Color? quoteGold,
    Color? shelfWood,
    Color? accentSage,
    Color? accentAmethyst,
    Color? accentOcean,
    Color? heatmapInactive,
    Color? heatmapLevel1,
    Color? heatmapLevel2,
    Color? heatmapLevel3,
  }) {
    return ReadingAppColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      cardBgSecondary: cardBgSecondary ?? this.cardBgSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      streakAmber: streakAmber ?? this.streakAmber,
      quoteGold: quoteGold ?? this.quoteGold,
      shelfWood: shelfWood ?? this.shelfWood,
      accentSage: accentSage ?? this.accentSage,
      accentAmethyst: accentAmethyst ?? this.accentAmethyst,
      accentOcean: accentOcean ?? this.accentOcean,
      heatmapInactive: heatmapInactive ?? this.heatmapInactive,
      heatmapLevel1: heatmapLevel1 ?? this.heatmapLevel1,
      heatmapLevel2: heatmapLevel2 ?? this.heatmapLevel2,
      heatmapLevel3: heatmapLevel3 ?? this.heatmapLevel3,
    );
  }

  @override
  ReadingAppColors lerp(ThemeExtension<ReadingAppColors>? other, double t) {
    if (other is! ReadingAppColors) return this;
    return ReadingAppColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBgSecondary: Color.lerp(cardBgSecondary, other.cardBgSecondary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      streakAmber: Color.lerp(streakAmber, other.streakAmber, t)!,
      quoteGold: Color.lerp(quoteGold, other.quoteGold, t)!,
      shelfWood: Color.lerp(shelfWood, other.shelfWood, t)!,
      accentSage: Color.lerp(accentSage, other.accentSage, t)!,
      accentAmethyst: Color.lerp(accentAmethyst, other.accentAmethyst, t)!,
      accentOcean: Color.lerp(accentOcean, other.accentOcean, t)!,
      heatmapInactive: Color.lerp(heatmapInactive, other.heatmapInactive, t)!,
      heatmapLevel1: Color.lerp(heatmapLevel1, other.heatmapLevel1, t)!,
      heatmapLevel2: Color.lerp(heatmapLevel2, other.heatmapLevel2, t)!,
      heatmapLevel3: Color.lerp(heatmapLevel3, other.heatmapLevel3, t)!,
    );
  }

  static const midnightLibrary = ReadingAppColors(
    scaffoldBg: Color(0xFF141210),
    cardBg: Color(0xFF221E1B),
    cardBgSecondary: Color(0xFF1A1715),
    borderSubtle: Color(0xFF3B342E),
    textPrimary: Color(0xFFEDE6DD),
    textSecondary: Color(0xFF9C948B),
    streakAmber: Color(0xFFE27D38),
    quoteGold: Color(0xFFE0A96D),
    shelfWood: Color(0xFF3E2723),
    accentSage: Color(0xFF629677),
    accentAmethyst: Color(0xFF7E6B8F),
    accentOcean: Color(0xFF4D7A97),
    heatmapInactive: Color(0xFF2A2522),
    heatmapLevel1: Color(0xFF7A4A28),
    heatmapLevel2: Color(0xFFC86226),
    heatmapLevel3: Color(0xFFE27D38),
  );

  static const parchmentIvory = ReadingAppColors(
    scaffoldBg: Color(0xFFF7F4EC), // Crisp Warm Linen
    cardBg: Color(0xFFFFFFFF), // Alabaster Porcelain
    cardBgSecondary: Color(0xFFEFE8DD), // Soft Book Page Tint
    borderSubtle: Color(0xFFE0D6C8), // Chamois Thread Tint
    textPrimary: Color(0xFF1B1613), // Rich Espresso Charcoal Ink
    textSecondary: Color(0xFF6B6057), // Distressed Leather Slate
    streakAmber: Color(0xFFB8521B), // Cinnamon Copper Foil
    quoteGold: Color(0xFF8D4015), // Warm Leather Mahogany
    shelfWood: Color(0xFF8D6E63), // Aged Oak Wood
    accentSage: Color(0xFF2E5A3C), // Deep Forest Leaf
    accentAmethyst: Color(0xFF5C3D6A), // Deep Vintage Plum
    accentOcean: Color(0xFF23445A), // Navy Bookmark Blue
    heatmapInactive: Color(0xFFE8E0D4), // Warm Muted Tile
    heatmapLevel1: Color(0xFFE6A374), // Light Copper Tint
    heatmapLevel2: Color(0xFFCE6A30), // Medium Copper Tint
    heatmapLevel3: Color(0xFFB8521B), // Peak Copper
  );
}

extension ReadingAppColorsExtension on BuildContext {
  ReadingAppColors get appColors =>
      Theme.of(this).extension<ReadingAppColors>() ??
      ReadingAppColors.midnightLibrary;
}

class AppColors {
  static const candleAmber = Color(0xFFE27D38);
  static const antiqueGold = Color(0xFFD4AF37);
  static const goldAccent = Color(0xFFD4AF37);
  static const goldGlow = Color(0xFFF39C12);
  static const warmParchment = Color(0xFFEDE6DD);
  static const sepiaLight = Color(0xFFEDE6DD);
  static const sepiaMuted = Color(0xFF9C948B);
  static const candleGlow = Color(0xFFF5D6A7);
  static const warmOrange = Color(0xFFD35400);
  static const plantGreen = Color(0xFF27AE60);
  static const plantGreenLight = Color(0xFF2ECC71);
  static const midnightBlack = Color(0xFF141210);
  static const oledBlack = Color(0xFF000000);
  static const oledCard = Color(0xFF141210);
  static const slateCard = Color(0xFF1E1A17);
  static const slateBorder = Color(0xFF332B25);
  static const oledBorderHighlight = Color(0xFF2A241F);
}
