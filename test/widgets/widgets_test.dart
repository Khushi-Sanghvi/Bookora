import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/theme/app_theme.dart';
import 'package:between_world/widgets/book_metadata_summary_bar.dart';
import 'package:between_world/widgets/editable_date_tile.dart';
import 'package:between_world/widgets/flickering_candle_widget.dart';
import 'package:between_world/widgets/layout_switcher.dart';
import 'package:between_world/widgets/realistic_book_spine_widget.dart';
import 'package:between_world/widgets/story_codex_view.dart';
import 'package:between_world/widgets/streak_badge.dart';

Widget createTestableWidget(Widget child, {ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? AppTheme.midnightLibrary(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookMetadataSummaryBar Widget Tests', () {
    testWidgets('renders format, total pages, start date and "-" for null end date', (WidgetTester tester) async {
      final book = Book(
        id: '1',
        title: 'Metadata Test',
        author: 'Author',
        description: 'Desc',
        coverUrl: '',
        totalPages: 384,
        format: BookFormat.paperback,
        startDate: DateTime(2026, 9, 19),
        finishDate: null,
      );

      await tester.pumpWidget(createTestableWidget(BookMetadataSummaryBar(book: book)));

      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Paperback'), findsOneWidget);
      expect(find.text('Total Pages'), findsOneWidget);
      expect(find.text('384 Pages'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Sep 19, 2026'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });
  });

  group('StreakBadge Widget Tests', () {
    testWidgets('renders streak icon and badge text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const StreakBadge()));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });

  group('LayoutSwitcher Widget Tests', () {
    testWidgets('renders layout switcher popup button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const LayoutSwitcher()));

      final button = find.byType(PopupMenuButton<ShelfLayoutView>);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('3D Dark Academia Shelf'), findsOneWidget);
      expect(find.text('3D Carousel Showcase'), findsOneWidget);
    });
  });

  group('RealisticBookSpineWidget Tests', () {
    testWidgets('renders title and author vertically on spine', (WidgetTester tester) async {
      final book = Book(
        id: 'spine_1',
        title: 'Twisted Lies',
        author: 'Ana Huang',
        description: 'Desc',
        coverUrl: '',
        totalPages: 480,
      );

      final spine = RealisticBookSpineWidget.fromBook(book);
      await tester.pumpWidget(createTestableWidget(spine));

      expect(find.text('TWISTED LIES'), findsOneWidget);
      expect(find.text('ANA HUANG'), findsOneWidget);
    });
  });

  group('FlickeringCandleWidget Tests', () {
    testWidgets('renders candlestick and flame', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        const FlickeringCandleWidget(height: 40, animate: false),
      ));

      expect(find.byType(FlickeringCandleWidget), findsOneWidget);
    });
  });

  group('EditableDateTile Tests', () {
    testWidgets('renders label and formatted date or placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        EditableDateTile(
          label: 'Start Date',
          date: DateTime(2026, 9, 19),
          icon: Icons.play_circle_outline,
          onDateChanged: (_) {},
        ),
      ));

      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('19 Sep, 2026'), findsOneWidget);
    });
  });

  group('StoryCodexView & bookDetailProvider Tests', () {
    testWidgets('renders Story Codex badges, hook and 5D flavor profile', (WidgetTester tester) async {
      final book = Book(
        id: 'codex_test_1',
        title: 'Hyperion',
        author: 'Dan Simmons',
        description: 'Together in one volume for the first time, the first two novels of the Hyperion Cantos.',
        tagline: 'Together in one volume for the first time...',
        genres: ['Sci-fi', 'Far Future'],
        coverUrl: '',
        totalPages: 482,
        spiceRating: 2.0,
        fluffRating: 3.5,
        tearRating: 4.0,
        humorRating: 3.0,
      );

      await tester.pumpWidget(createTestableWidget(
        SingleChildScrollView(child: StoryCodexView(book: book)),
      ));
      await tester.pump();

      expect(find.text('STORY CODEX • NARRATIVE ANATOMY'), findsOneWidget);
      expect(find.text('Hyperion'), findsWidgets);
      expect(find.text('by Dan Simmons'), findsOneWidget);
      expect(find.text('Sci-fi'), findsOneWidget);
      expect(find.text('5D NARRATIVE FLAVOR PROFILE'), findsOneWidget);
      expect(find.text('Spice Level'), findsOneWidget);
      expect(find.text('Fluff & Warmth'), findsOneWidget);
      expect(find.text('Tears & Drama'), findsOneWidget);
      expect(find.text('Humor & Wit'), findsOneWidget);
      expect(find.text('Suspense & Stakes'), findsOneWidget);
    });
  });
}
