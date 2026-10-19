import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reading_app_colors.dart';

class AppTheme {
  // Theme A: Midnight Library (Dark)
  static ThemeData midnightLibrary() {
    const colors = ReadingAppColors.midnightLibrary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.scaffoldBg,
      colorScheme: ColorScheme.dark(
        surface: colors.cardBg,
        primary: colors.streakAmber,
        secondary: colors.quoteGold,
        onSurface: colors.textPrimary,
        outline: colors.borderSubtle,
      ),
      extensions: const [colors],
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actionsIconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colors.quoteGold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBg,
        selectedItemColor: colors.streakAmber,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.cardBgSecondary,
        labelStyle: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        selectedColor: colors.streakAmber,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  // Theme B: Parchment & Ivory (Light)
  static ThemeData parchmentIvory() {
    const colors = ReadingAppColors.parchmentIvory;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.scaffoldBg,
      colorScheme: ColorScheme.light(
        surface: colors.cardBg,
        primary: colors.streakAmber,
        secondary: colors.quoteGold,
        onSurface: colors.textPrimary,
        outline: colors.borderSubtle,
      ),
      extensions: const [colors],
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actionsIconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colors.quoteGold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBg,
        selectedItemColor: colors.streakAmber,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 2,
        shadowColor: const Color(0x122D221A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.cardBgSecondary,
        labelStyle: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        selectedColor: colors.streakAmber,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }
}
