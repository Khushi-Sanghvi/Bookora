import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:between_world/screens/settings_screen.dart';
import 'package:between_world/theme/app_theme.dart';
import 'package:between_world/widgets/reader_walkthrough_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReaderWalkthroughModal UI & UX Tests', () {
    testWidgets('renders all 5 walkthrough steps and headers in dark mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.midnightLibrary(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => ReaderWalkthroughModal.show(ctx),
                  child: const Text('Open Guide'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Guide'));
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text("The Reader's Field Guide"), findsOneWidget);
      expect(find.text('Mastering your personal reading sanctuary'), findsOneWidget);
      expect(find.text('SANCTUARY FIELD GUIDE'), findsOneWidget);

      // Steps verification
      expect(find.text('Building Your Shelves'), findsOneWidget);
      expect(find.text('Format & Document Attachment'), findsOneWidget);
      expect(find.text('Story Codex & Narrative Anatomy'), findsOneWidget);
      expect(find.text('Reading Goals & Pacing'), findsOneWidget);
      expect(find.text('Data Sanctuary & Ownership'), findsOneWidget);

      // Step badges
      expect(find.text('STEP 01'), findsOneWidget);
      expect(find.text('STEP 02'), findsOneWidget);
      expect(find.text('STEP 03'), findsOneWidget);
      expect(find.text('STEP 04'), findsOneWidget);
      expect(find.text('STEP 05'), findsOneWidget);

      // Footer button
      expect(find.text('Begin Reading'), findsOneWidget);

      // Tap Begin Reading closes the modal
      await tester.tap(find.text('Begin Reading'));
      await tester.pumpAndSettle();
      expect(find.text("The Reader's Field Guide"), findsNothing);
    });

    testWidgets('renders pixel-perfect dual theme in parchment light mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.parchmentIvory(),
          home: const Scaffold(
            body: ReaderWalkthroughModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("The Reader's Field Guide"), findsOneWidget);
      expect(find.text('Building Your Shelves'), findsOneWidget);
      expect(find.text('Begin Reading'), findsOneWidget);
    });

    testWidgets('renders full untruncated titles on narrow mobile screens', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.parchmentIvory(),
          home: const Scaffold(
            body: ReaderWalkthroughModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Building Your Shelves'), findsOneWidget);
      expect(find.text('Format & Document Attachment'), findsOneWidget);
      expect(find.text('Story Codex & Narrative Anatomy'), findsOneWidget);
      expect(find.text('Reading Goals & Pacing'), findsOneWidget);
      expect(find.text('Data Sanctuary & Ownership'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays Sanctuary Guide tile and opens modal on tap', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.midnightLibrary(),
            home: const SettingsScreen(),
          ),
        ),
      );
      // Scroll until section is in view
      final guideHeader = find.text('SANCTUARY GUIDE & WALKTHROUGH');
      await tester.scrollUntilVisible(guideHeader, 500);
      await tester.pumpAndSettle();

      // Check section header and tile
      expect(guideHeader, findsOneWidget);
      expect(find.text('How to Use Bookora'), findsOneWidget);
      expect(find.text('A quick walkthrough for your reading sanctuary'), findsOneWidget);
      expect(find.text('5 Steps'), findsOneWidget);

      // Tap on the tile to open modal
      await tester.tap(find.text('How to Use Bookora'));
      await tester.pumpAndSettle();

      expect(find.text("The Reader's Field Guide"), findsOneWidget);
      expect(find.text('Building Your Shelves'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Begin Reading'));
      await tester.pumpAndSettle();
      expect(find.text("The Reader's Field Guide"), findsNothing);
    });
  });
}
