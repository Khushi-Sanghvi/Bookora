import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:between_world/models/reading_calendar_entry.dart';
import 'package:between_world/repositories/reading_calendar_repository.dart';
import 'package:between_world/widgets/dual_view_reading_calendar.dart';

void main() {
  group('ReadingCalendarEntry Model & Multi-String Parsing Tests', () {
    test('parses JSON string array correctly', () {
      const jsonStr = '["The Hobbit", "Dune: Part One", "Dune: Part One"]';
      final list = ReadingCalendarEntry.parseBookStrings(jsonStr);

      expect(list.length, equals(2));
      expect(list, contains('The Hobbit'));
      expect(list, contains('Dune: Part One'));
    });

    test('handles legacy single raw string seamlessly with backward compatibility', () {
      const legacyRaw = 'A Court of Thorns and Roses';
      final list = ReadingCalendarEntry.parseBookStrings(legacyRaw);

      expect(list.length, equals(1));
      expect(list.first, equals('A Court of Thorns and Roses'));
    });

    test('handles comma-separated string seamlessly', () {
      const commaSeparated = 'Six of Crows, Crooked Kingdom';
      final list = ReadingCalendarEntry.parseBookStrings(commaSeparated);

      expect(list.length, equals(2));
      expect(list, contains('Six of Crows'));
      expect(list, contains('Crooked Kingdom'));
    });

    test('safely returns empty list for null or empty strings', () {
      expect(ReadingCalendarEntry.parseBookStrings(null), isEmpty);
      expect(ReadingCalendarEntry.parseBookStrings(''), isEmpty);
      expect(ReadingCalendarEntry.parseBookStrings('   '), isEmpty);
    });

    test('toMap and fromMap roundtrip preserves multiple book strings', () {
      final now = DateTime(2026, 10, 19);
      final entry = ReadingCalendarEntry(
        date: now,
        bookStrings: ['Fourth Wing', 'Iron Flame'],
      );

      final map = entry.toMap();
      expect(map['date'], contains('2026-10-19'));
      expect(map['bookStrings'], equals('["Fourth Wing","Iron Flame"]'));

      final restored = ReadingCalendarEntry.fromMap(map);
      expect(restored.date.year, equals(2026));
      expect(restored.bookStrings, equals(['Fourth Wing', 'Iron Flame']));
    });
  });

  group('ReadingCalendarRepository Tests', () {
    late ReadingCalendarRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = ReadingCalendarRepositoryImpl();
    });

    test('addBookStringToDate appends without overwriting and deduplicates', () async {
      final date = DateTime(2026, 10, 19);

      await repository.addBookStringToDate(date, 'God of Malice');
      await repository.addBookStringToDate(date, 'God of Ruin');
      // Duplicate addition should be ignored
      await repository.addBookStringToDate(date, 'God of Malice');

      final books = await repository.getBookStringsForDate(date);
      expect(books.length, equals(2));
      expect(books, contains('God of Malice'));
      expect(books, contains('God of Ruin'));
    });

    test('removeBookStringFromDate removes target and preserves others', () async {
      final date = DateTime(2026, 10, 19);

      await repository.addBookStringToDate(date, 'Twisted Love');
      await repository.addBookStringToDate(date, 'Twisted Games');
      await repository.addBookStringToDate(date, 'Twisted Hate');

      await repository.removeBookStringFromDate(date, 'Twisted Games');

      final books = await repository.getBookStringsForDate(date);
      expect(books.length, equals(2));
      expect(books, contains('Twisted Love'));
      expect(books, contains('Twisted Hate'));
      expect(books.contains('Twisted Games'), isFalse);
    });
  });

  group('BookSpanInfo Backward-Compatibility Tests', () {
    test('defaults bookStrings to [bookTitle] when null', () {
      final span = BookSpanInfo(
        id: '1',
        bookTitle: 'The Cruel Prince',
        coverUrl: '',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 10),
        color: Colors.amber,
      );

      expect(span.bookStrings, equals(['The Cruel Prince']));
    });

    test('accepts JSON string array or List<String> in bookStrings', () {
      final span1 = BookSpanInfo(
        id: '1',
        bookTitle: 'The Cruel Prince',
        coverUrl: '',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 10),
        color: Colors.amber,
        bookStrings: '["The Cruel Prince", "Hardcover Edition", "Chapter 1-12"]',
      );

      expect(span1.bookStrings.length, equals(3));
      expect(span1.bookStrings, contains('Hardcover Edition'));

      final span2 = BookSpanInfo(
        id: '2',
        bookTitle: 'The Wicked King',
        coverUrl: '',
        startDate: DateTime(2026, 10, 11),
        endDate: DateTime(2026, 10, 20),
        color: Colors.blue,
        bookStrings: ['The Wicked King', 'EPUB', 'Evening Session'],
      );

      expect(span2.bookStrings.length, equals(3));
      expect(span2.bookStrings, contains('Evening Session'));
    });
  });
}
