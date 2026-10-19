import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/services/reading_status_resolver.dart';

void main() {
  group('Book End Date & Finish Date Lifecycle Tracking', () {
    test('ReadingStatus.completed alias maps directly to finished', () {
      expect(ReadingStatus.completed, equals(ReadingStatus.finished));
      expect(ReadingStatus.completed.name, equals('finished'));
    });

    test('Book constructor supports both endDate and finishDate aliases', () {
      final now = DateTime(2026, 10, 17, 12, 0);
      final book1 = Book(
        id: 'b1',
        title: 'Title 1',
        author: 'Author 1',
        description: 'Desc',
        coverUrl: 'http://example.com/cover.jpg',
        totalPages: 300,
        endDate: now,
      );

      expect(book1.endDate, equals(now));
      expect(book1.finishDate, equals(now));

      final book2 = Book(
        id: 'b2',
        title: 'Title 2',
        author: 'Author 2',
        description: 'Desc',
        coverUrl: 'http://example.com/cover.jpg',
        totalPages: 300,
        finishDate: now,
      );

      expect(book2.endDate, equals(now));
      expect(book2.finishDate, equals(now));
    });

    test('Book.copyWith updates endDate and preserves startDate', () {
      final start = DateTime(2026, 10, 1);
      final finish = DateTime(2026, 10, 17);

      final book = Book(
        id: 'b1',
        title: 'Pride & Prejudice',
        author: 'Jane Austen',
        description: 'Classic romance',
        coverUrl: 'http://example.com/cover.jpg',
        totalPages: 400,
        startDate: start,
        status: ReadingStatus.currentlyReading,
      );

      final completedBook = book.copyWith(
        status: ReadingStatus.completed,
        endDate: finish,
        currentPage: book.totalPages,
      );

      expect(completedBook.startDate, equals(start)); // Unwiped!
      expect(completedBook.endDate, equals(finish));
      expect(completedBook.finishDate, equals(finish));
      expect(completedBook.status, equals(ReadingStatus.finished));
      expect(completedBook.progress, equals(1.0));
    });

    test('Book serialization round-trip maintains endDate, finishDate, and multi-genre tags', () {
      final start = DateTime(2026, 9, 15);
      final finish = DateTime(2026, 10, 17);
      final genres = ['Dark Academia', 'Mystery', 'Gothic Fiction'];

      final book = Book(
        id: 'b100',
        title: 'The Secret History',
        author: 'Donna Tartt',
        description: 'Under the influence of their charismatic classics professor...',
        coverUrl: 'http://example.com/secret_history.jpg',
        totalPages: 559,
        currentPage: 559,
        status: ReadingStatus.completed,
        format: BookFormat.paperback,
        genres: genres,
        startDate: start,
        endDate: finish,
      );

      final map = book.toMap();
      expect(map['finishDate'], equals(finish.toIso8601String()));
      expect(map['endDate'], equals(finish.toIso8601String()));
      expect(map['startDate'], equals(start.toIso8601String()));

      // Deserialize via fromMap
      final restored = Book.fromMap(map);
      expect(restored.endDate, equals(finish));
      expect(restored.finishDate, equals(finish));
      expect(restored.startDate, equals(start));
      expect(restored.genres, equals(genres));
      expect(restored.status, equals(ReadingStatus.finished));
    });

    test('Book.fromMap parses endDate or completedDate fallback if finishDate is missing', () {
      final finishStr = '2026-10-17T15:30:00.000';
      final mapWithEndDate = {
        'id': 'b1',
        'title': 'Test Book',
        'author': 'Test Author',
        'endDate': finishStr,
      };

      final book1 = Book.fromMap(mapWithEndDate);
      expect(book1.endDate, equals(DateTime.parse(finishStr)));

      final mapWithCompletedDate = {
        'id': 'b2',
        'title': 'Test Book 2',
        'author': 'Test Author 2',
        'completedDate': finishStr,
      };

      final book2 = Book.fromMap(mapWithCompletedDate);
      expect(book2.endDate, equals(DateTime.parse(finishStr)));
    });

    test('ReadingStatusResolver preserves existingFinishDate and existingStartDate', () {
      final start = DateTime(2026, 10, 1);
      final finish = DateTime(2026, 10, 17);

      // Book with existing finish date but page progress < totalPages must not wipe finish date
      final transition = ReadingStatusResolver.evaluateStatusTransition(
        currentStatus: ReadingStatus.finished,
        currentPage: 50,
        totalPages: 300,
        existingStartDate: start,
        existingFinishDate: finish,
      );

      expect(transition.status, equals(ReadingStatus.finished));
      expect(transition.startDate, equals(start));
      expect(transition.finishDate, equals(finish));
    });

    test('ReadingStatusResolver stamps finishDate when reaching final page', () {
      final start = DateTime(2026, 10, 1);

      final transition = ReadingStatusResolver.evaluateStatusTransition(
        currentStatus: ReadingStatus.currentlyReading,
        currentPage: 300,
        totalPages: 300,
        existingStartDate: start,
        existingFinishDate: null,
      );

      expect(transition.status, equals(ReadingStatus.finished));
      expect(transition.startDate, equals(start));
      expect(transition.finishDate, isNotNull);
    });
  });
}
