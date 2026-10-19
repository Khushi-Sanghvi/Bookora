import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/enums.dart';

void main() {
  group('Book Model - Atomic Audiobook Deletion & Path Nulling Tests', () {
    test('copyWith with clearLocalFilePath: true resets localFilePath and audioFilePath to null', () {
      final initialBook = Book(
        id: 'book-1',
        title: 'The Secret History',
        author: 'Donna Tartt',
        description: 'A classic dark academia novel.',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 550,
        currentPage: 120,
        format: BookFormat.audiobook,
        localFilePath: '/data/user/0/com.bookora/cache/secret_history.mp3',
      );

      expect(initialBook.localFilePath, isNotNull);
      expect(initialBook.audioFilePath, isNotNull);

      final updatedBook = initialBook.copyWith(
        audioFilePath: null,
        localFilePath: null,
        clearLocalFilePath: true,
      );

      expect(updatedBook.localFilePath, isNull);
      expect(updatedBook.audioFilePath, isNull);
      expect(updatedBook.title, equals('The Secret History'));
      expect(updatedBook.author, equals('Donna Tartt'));
      expect(updatedBook.currentPage, equals(120));
      expect(updatedBook.totalPages, equals(550));
      expect(updatedBook.format, equals(BookFormat.audiobook));

      final map = updatedBook.toMap();
      expect(map['localFilePath'], isNull);
    });

    test('copyWith with explicit null localFilePath resets localFilePath and audioFilePath to null', () {
      final initialBook = Book(
        id: 'book-2',
        title: 'Babel',
        author: 'R.F. Kuang',
        description: 'An arcane history.',
        coverUrl: 'https://example.com/babel.jpg',
        totalPages: 400,
        format: BookFormat.audiobook,
        localFilePath: '/storage/emulated/0/Download/babel.m4b',
      );

      final updatedBook = initialBook.copyWith(
        localFilePath: null,
      );

      expect(updatedBook.localFilePath, isNull);
      expect(updatedBook.audioFilePath, isNull);
    });

    test('copyWith without specifying localFilePath preserves existing path', () {
      final initialBook = Book(
        id: 'book-3',
        title: 'If We Were Villains',
        author: 'M.L. Rio',
        description: 'Shakespearean tragedy.',
        coverUrl: 'https://example.com/villains.jpg',
        totalPages: 360,
        format: BookFormat.audiobook,
        localFilePath: '/storage/emulated/0/Download/villains.mp3',
      );

      final updatedBook = initialBook.copyWith(
        currentPage: 50,
      );

      expect(updatedBook.localFilePath, equals('/storage/emulated/0/Download/villains.mp3'));
      expect(updatedBook.audioFilePath, equals('/storage/emulated/0/Download/villains.mp3'));
      expect(updatedBook.currentPage, equals(50));
    });
  });

  group('Book Model - Atomic EPUB & PDF Document Deletion & Path Nulling Tests', () {
    test('copyWith with clearLocalFilePath: true resets localFilePath and epubFilePath to null for EPUB format', () {
      final epubBook = Book(
        id: 'book-epub-1',
        title: 'The Picture of Dorian Gray',
        author: 'Oscar Wilde',
        description: 'Philosophical gothic fiction.',
        coverUrl: 'https://example.com/dorian.jpg',
        totalPages: 250,
        currentPage: 45,
        format: BookFormat.epub,
        localFilePath: '/storage/emulated/0/Download/dorian_gray.epub',
      );

      expect(epubBook.localFilePath, isNotNull);
      expect(epubBook.epubFilePath, equals('/storage/emulated/0/Download/dorian_gray.epub'));

      final updated = epubBook.copyWith(
        epubFilePath: null,
        localFilePath: null,
        clearLocalFilePath: true,
      );

      expect(updated.localFilePath, isNull);
      expect(updated.epubFilePath, isNull);
      expect(updated.title, equals('The Picture of Dorian Gray'));
      expect(updated.currentPage, equals(45));
      expect(updated.totalPages, equals(250));
      expect(updated.format, equals(BookFormat.epub));

      final map = updated.toMap();
      expect(map['localFilePath'], isNull);
    });

    test('copyWith with clearLocalFilePath: true resets localFilePath and pdfFilePath to null for PDF format', () {
      final pdfBook = Book(
        id: 'book-pdf-1',
        title: 'Frankenstein',
        author: 'Mary Shelley',
        description: 'Gothic science fiction masterpiece.',
        coverUrl: 'https://example.com/frankenstein.jpg',
        totalPages: 310,
        currentPage: 88,
        format: BookFormat.pdf,
        localFilePath: '/storage/emulated/0/Download/frankenstein.pdf',
      );

      expect(pdfBook.localFilePath, isNotNull);
      expect(pdfBook.pdfFilePath, equals('/storage/emulated/0/Download/frankenstein.pdf'));

      final updated = pdfBook.copyWith(
        pdfFilePath: null,
        localFilePath: null,
        clearLocalFilePath: true,
      );

      expect(updated.localFilePath, isNull);
      expect(updated.pdfFilePath, isNull);
      expect(updated.title, equals('Frankenstein'));
      expect(updated.currentPage, equals(88));
      expect(updated.totalPages, equals(310));
      expect(updated.format, equals(BookFormat.pdf));

      final map = updated.toMap();
      expect(map['localFilePath'], isNull);
    });

    test('copyWith preserving document paths when editing pages or status', () {
      final docBook = Book(
        id: 'book-pdf-2',
        title: 'Dracula',
        author: 'Bram Stoker',
        description: 'Vampire horror classic.',
        coverUrl: 'https://example.com/dracula.jpg',
        totalPages: 418,
        currentPage: 10,
        format: BookFormat.pdf,
        localFilePath: '/storage/emulated/0/Download/dracula.pdf',
      );

      final updated = docBook.copyWith(
        currentPage: 50,
        status: ReadingStatus.currentlyReading,
      );

      expect(updated.localFilePath, equals('/storage/emulated/0/Download/dracula.pdf'));
      expect(updated.pdfFilePath, equals('/storage/emulated/0/Download/dracula.pdf'));
      expect(updated.currentPage, equals(50));
      expect(updated.status, equals(ReadingStatus.currentlyReading));
    });
  });
}
