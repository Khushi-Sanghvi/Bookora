import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/theme/app_theme.dart';
import 'package:between_world/widgets/about_app_dialog.dart';

Widget createTestableWidget(Widget child, {ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? AppTheme.midnightLibrary(),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AboutAppDialog.show(context),
            child: const Text('Open About'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutAppDialog UI & UX Tests', () {
    testWidgets('renders all Dark Academia headers, philosophy, and feature tiles in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SizedBox(),
        theme: AppTheme.midnightLibrary(),
      ));

      // Open dialog
      await tester.tap(find.text('Open About'));
      await tester.pumpAndSettle();

      // 1. Header elements
      expect(find.text('Bookora'), findsOneWidget);
      expect(find.text('Your stories, your space.'), findsOneWidget);
      expect(find.text('The Obsidian Edition • Version 1.0.0 (Build 1)'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

      // 2. Narrative philosophy
      expect(find.text('Bookora was built differently.'), findsOneWidget);

      // 3. Four Feature Highlights
      expect(find.text('Local Sanctuary & Zero Telemetry'), findsOneWidget);
      expect(find.text('Story Codex & Narrative Anatomy'), findsOneWidget);
      expect(find.text('Bento Insights & Reading Pulse'), findsOneWidget);
      expect(find.text('Uncompromising Ownership'), findsOneWidget);

      // 4. Colophon & Dedication
      expect(
        find.text('Built with love for book lovers, daydreamers, and nocturnal readers.'),
        findsOneWidget,
      );
      expect(find.text('ark.dev.support@gmail.com'), findsOneWidget);
      expect(find.text('“A few pages today bring a brighter tomorrow.”'), findsOneWidget);

      // 5. Close Button
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Bookora'), findsNothing);
    });

    testWidgets('renders pixel-perfect dual theme in parchment light mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SizedBox(),
        theme: AppTheme.parchmentIvory(),
      ));

      // Open dialog
      await tester.tap(find.text('Open About'));
      await tester.pumpAndSettle();

      expect(find.text('Bookora'), findsOneWidget);
      expect(find.text('Your stories, your space.'), findsOneWidget);
      expect(find.text('The Obsidian Edition • Version 1.0.0 (Build 1)'), findsOneWidget);

      // Top corner close icon button dismissal
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Bookora'), findsNothing);
    });

    testWidgets('tapping support email copies to clipboard and displays BookoraSnackBar', (WidgetTester tester) async {
      String? copiedString;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedString = (methodCall.arguments as Map)['text'] as String?;
        }
        return null;
      });

      await tester.pumpWidget(createTestableWidget(
        const SizedBox(),
        theme: AppTheme.midnightLibrary(),
      ));

      await tester.tap(find.text('Open About'));
      await tester.pumpAndSettle();

      // Scroll into view and tap support email tile
      await tester.scrollUntilVisible(
        find.text('ark.dev.support@gmail.com'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ark.dev.support@gmail.com'));
      await tester.pump();

      expect(copiedString, 'ark.dev.support@gmail.com');
      expect(find.text('Support email copied to clipboard!'), findsOneWidget);
    });
  });
}
