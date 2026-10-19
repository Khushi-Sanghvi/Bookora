import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/theme/app_theme.dart';
import 'package:between_world/theme/reading_app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadingAppColors Extension Tests', () {
    test('midnightLibrary dark theme color extension properties', () {
      const colors = ReadingAppColors.midnightLibrary;

      expect(colors.scaffoldBg, const Color(0xFF141210));
      expect(colors.cardBg, const Color(0xFF221E1B));
      expect(colors.streakAmber, const Color(0xFFE27D38));
      expect(colors.quoteGold, const Color(0xFFE0A96D));
    });

    test('parchmentIvory light theme color extension properties', () {
      const colors = ReadingAppColors.parchmentIvory;

      expect(colors.scaffoldBg, const Color(0xFFF7F4EC));
      expect(colors.cardBg, const Color(0xFFFFFFFF));
      expect(colors.streakAmber, const Color(0xFFB8521B));
    });

    test('copyWith creates modified color extension', () {
      const original = ReadingAppColors.midnightLibrary;
      final modified = original.copyWith(
        scaffoldBg: Colors.black,
        streakAmber: Colors.orange,
      );

      expect(modified.scaffoldBg, Colors.black);
      expect(modified.streakAmber, Colors.orange);
      expect(modified.cardBg, original.cardBg);
    });

    test('lerp interpolates theme extension colors', () {
      const dark = ReadingAppColors.midnightLibrary;
      const light = ReadingAppColors.parchmentIvory;

      final lerped = dark.lerp(light, 0.5);

      expect(lerped.scaffoldBg, isNot(dark.scaffoldBg));
      expect(lerped.scaffoldBg, isNot(light.scaffoldBg));
    });
  });

  group('AppTheme Configuration Tests', () {
    testWidgets('midnightLibrary configures dark ThemeData with extension', (WidgetTester tester) async {
      final theme = AppTheme.midnightLibrary();

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<ReadingAppColors>(), isNotNull);
      expect(theme.extension<ReadingAppColors>()!.scaffoldBg, ReadingAppColors.midnightLibrary.scaffoldBg);
    });

    testWidgets('parchmentIvory configures light ThemeData with extension', (WidgetTester tester) async {
      final theme = AppTheme.parchmentIvory();

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<ReadingAppColors>(), isNotNull);
      expect(theme.extension<ReadingAppColors>()!.scaffoldBg, ReadingAppColors.parchmentIvory.scaffoldBg);
    });
  });
}
