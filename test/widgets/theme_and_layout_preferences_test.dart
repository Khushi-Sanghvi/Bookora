import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/providers/layout_provider.dart';
import 'package:between_world/screens/settings_screen.dart';
import 'package:between_world/theme/app_theme.dart';
import 'package:between_world/widgets/theme_selector_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Visual Theme Preferences Tests', () {
    testWidgets('ThemeSelectorView renders both authentic themes and toggles selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.parchmentIvory(),
            darkTheme: AppTheme.midnightLibrary(),
            home: const Scaffold(
              body: ThemeSelectorView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Theme'), findsOneWidget);
      expect(find.text('Parchment & Ivory'), findsOneWidget);
      expect(find.text('Midnight Library'), findsOneWidget);
      expect(find.text('Ivory Light'), findsOneWidget);
      expect(find.text('Dark Academia'), findsOneWidget);

      // Verify tapping Midnight Library switches mode
      await tester.tap(find.text('Midnight Library'));
      await tester.pumpAndSettle();
    });

    testWidgets('SettingsScreen displays 2 themes and 6 library layouts', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.parchmentIvory(),
            darkTheme: AppTheme.midnightLibrary(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 2 themes
      expect(find.text('App Visual Theme'), findsOneWidget);
      expect(find.text('Midnight Library'), findsOneWidget);
      expect(find.text('Parchment & Ivory'), findsOneWidget);

      // Verify "More Palette" button is removed
      expect(find.text('More Palette'), findsNothing);

      // Verify all 6 bookshelf layouts
      expect(find.text('3D Dark Academia Shelf'), findsOneWidget);
      expect(find.text('3D Carousel Showcase'), findsOneWidget);
      expect(find.text('Polaroid Scrapbook Gallery'), findsOneWidget);
      expect(find.text('3D Classic Wooden Shelf'), findsOneWidget);
      expect(find.text('Cover Grid'), findsOneWidget);
      expect(find.text('Detailed List'), findsOneWidget);

      // Test tapping layout chips updates layoutProvider
      await tester.tap(find.text('3D Carousel Showcase'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.carouselShowcase);

      await tester.tap(find.text('Polaroid Scrapbook Gallery'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.polaroidScrapbook);

      await tester.tap(find.text('3D Classic Wooden Shelf'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.skeuomorphicShelf);

      await tester.tap(find.text('Cover Grid'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.coverGrid);

      await tester.tap(find.text('Detailed List'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.detailedList);

      await tester.tap(find.text('3D Dark Academia Shelf'));
      await tester.pumpAndSettle();
      expect(container.read(layoutProvider), ShelfLayoutView.darkAcademiaShelf);
    });
  });
}
