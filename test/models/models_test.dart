import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/bookshelf_config.dart';
import 'package:between_world/models/book_format_config.dart';
import 'package:between_world/models/audiobook_model.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/models/journal_entry.dart';
import 'package:between_world/models/quote_annotation.dart';

void main() {
  group('Book Model Tests', () {
    test('calculate progress correctly', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Author',
        description: 'Desc',
        coverUrl: '',
        totalPages: 200,
        currentPage: 50,
      );
      expect(book.progress, 0.25);
    });

    test('progress when totalPages is 0 returns 0.0', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Author',
        description: 'Desc',
        coverUrl: '',
        totalPages: 0,
        currentPage: 50,
      );
      expect(book.progress, 0.0);
    });

    test('effectiveTagline extracts explicit or title-based tagline', () {
      final book = Book(
        id: '1',
        title: 'Reminders of Him',
        author: 'Colleen Hoover',
        description: 'Desc',
        coverUrl: '',
        totalPages: 300,
      );
      expect(book.effectiveTagline.isNotEmpty, isTrue);
      expect(book.effectiveTagline.contains('mother seeks redemption'), isTrue);
    });

    test('copyWith creates a new instance with updated properties', () {
      final book = Book(
        id: '1',
        title: 'Original Title',
        author: 'Author',
        description: 'Desc',
        coverUrl: '',
        totalPages: 300,
        currentPage: 10,
      );

      final updated = book.copyWith(
        title: 'Updated Title',
        currentPage: 50,
        status: ReadingStatus.currentlyReading,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.currentPage, 50);
      expect(updated.status, ReadingStatus.currentlyReading);
      expect(updated.id, '1');
    });

    test('toMap and fromMap serialization and deserialization', () {
      final original = Book(
        id: 'book_100',
        title: 'Serial Book',
        author: 'John Doe',
        description: 'A test story',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 400,
        currentPage: 100,
        status: ReadingStatus.finished,
        format: BookFormat.epub,
        genres: ['Fiction', 'Thriller'],
        startDate: DateTime(2026, 1, 1),
        finishDate: DateTime(2026, 1, 10),
      );

      final map = original.toMap();
      final restored = Book.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.author, original.author);
      expect(restored.totalPages, original.totalPages);
      expect(restored.currentPage, original.currentPage);
      expect(restored.status, ReadingStatus.finished);
      expect(restored.format, BookFormat.epub);
      expect(restored.genres, ['Fiction', 'Thriller']);
      expect(restored.startDate, DateTime(2026, 1, 1));
      expect(restored.finishDate, DateTime(2026, 1, 10));
    });
  });

  group('AudiobookModel Tests', () {
    test('generate AudiobookModel from Book creates chapters and calculates progress', () {
      final book = Book(
        id: 'ab_1',
        title: 'God of War',
        author: 'Rina Kent',
        description: 'Romance story',
        coverUrl: 'https://example.com/god_of_war.jpg',
        totalPages: 350,
        currentPage: 175,
      );

      final ab = AudiobookModel.fromBook(book);

      expect(ab.bookId, 'ab_1');
      expect(ab.title, 'God of War');
      expect(ab.chapters.isNotEmpty, isTrue);
      expect(ab.progressPercentage, closeTo(0.5, 0.05));
      expect(ab.getEquivalentPage(350), closeTo(175, 10));
    });

    test('getChapterForPosition returns active chapter for timestamp', () {
      final ab = AudiobookModel(
        bookId: 'ab_2',
        title: 'Audiobook Test',
        author: 'Author',
        coverUrl: '',
        totalDuration: const Duration(hours: 10),
        chapters: [
          AudioChapter(chapterIndex: 0, title: 'Chapter 1', startTimestamp: Duration.zero, endTimestamp: const Duration(hours: 2)),
          AudioChapter(chapterIndex: 1, title: 'Chapter 2', startTimestamp: const Duration(hours: 2), endTimestamp: const Duration(hours: 5)),
        ],
      );

      final activeCh = ab.getChapterForPosition(const Duration(hours: 3));
      expect(activeCh, isNotNull);
      expect(activeCh!.chapterIndex, 1);
      expect(activeCh.title, 'Chapter 2');
    });
  });

  group('BookshelfConfig Model Tests', () {
    test('woodColor and woodHighlightColor for mahogany', () {
      const config = BookshelfConfig(woodFinish: BookshelfWoodFinish.mahogany);
      expect(config.woodColor, const Color(0xFF3E2723));
      expect(config.woodHighlightColor, const Color(0xFF5D4037));
      expect(config.woodName, 'Vintage Mahogany');
    });

    test('copyWith updates config properties', () {
      const config = BookshelfConfig();
      final updated = config.copyWith(
        woodFinish: BookshelfWoodFinish.midnightEbony,
        vineDensity: VineDensity.none,
        candlesEnabled: false,
      );

      expect(updated.woodFinish, BookshelfWoodFinish.midnightEbony);
      expect(updated.vineDensity, VineDensity.none);
      expect(updated.candlesEnabled, isFalse);
      expect(updated.showTrinkets, isTrue);
    });
  });

  group('BookFormatConfig Model Tests', () {
    test('calculate progressPercentage for paperback pages mode', () {
      final config = BookFormatConfig(
        format: BookFormat.paperback,
        paperbackMode: PaperbackTrackingMode.pages,
        totalPages: 300,
        currentPage: 150,
        startDate: DateTime.now(),
      );

      expect(config.progressPercentage, 0.5);
      expect(config.isFinished, isFalse);
    });

    test('isFinished returns true when endDate is set', () {
      final config = BookFormatConfig(
        format: BookFormat.paperback,
        totalPages: 300,
        currentPage: 10,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      expect(config.isFinished, isTrue);
    });
  });

  group('JournalEntry Model Tests', () {
    test('JournalEntry.create generates unique id and current date', () {
      final entry = JournalEntry.create(25, reflection: 'Great chapter');
      expect(entry.id.isNotEmpty, isTrue);
      expect(entry.pagesRead, 25);
      expect(entry.reflection, 'Great chapter');
    });

    test('toMap and fromMap', () {
      final entry = JournalEntry(
        id: 'j_1',
        date: DateTime(2026, 9, 19),
        pagesRead: 30,
        reflection: 'Reflections',
      );

      final map = entry.toMap();
      final restored = JournalEntry.fromMap(map);

      expect(restored.id, 'j_1');
      expect(restored.pagesRead, 30);
      expect(restored.reflection, 'Reflections');
    });
  });

  group('QuoteAnnotation Model Tests', () {
    test('QuoteAnnotation.create and serialization', () {
      final quote = QuoteAnnotation.create(
        quoteText: 'To be or not to be',
        pageNumber: 42,
        note: 'Classic line',
      );

      final map = quote.toMap();
      final restored = QuoteAnnotation.fromMap(map);

      expect(restored.quoteText, 'To be or not to be');
      expect(restored.pageNumber, 42);
      expect(restored.note, 'Classic line');
    });
  });

  group('Enums Tests', () {
    test('ReadingStatus enum values exist', () {
      expect(ReadingStatus.values.length, 5);
      expect(ReadingStatus.values, contains(ReadingStatus.currentlyReading));
    });

    test('BookFormat enum values exist', () {
      expect(BookFormat.values.length, 6);
      expect(BookFormat.values, contains(BookFormat.paperback));
      expect(BookFormat.values, contains(BookFormat.epub));
      expect(BookFormat.values, contains(BookFormat.audiobook));
    });

    test('ShelfLayoutView enum values exist', () {
      expect(ShelfLayoutView.values, contains(ShelfLayoutView.darkAcademiaShelf));
      expect(ShelfLayoutView.values, contains(ShelfLayoutView.carouselShowcase));
    });
  });
}
