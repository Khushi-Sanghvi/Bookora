import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/services/genre_parser.dart';

void main() {
  group('GenreParser Multi-Source Normalization Engine Tests', () {
    test('parseRawGenres normalizes nested hierarchical paths', () {
      final input = ['Fiction / Romance / Contemporary'];
      final result = GenreParser.parseRawGenres(input);

      expect(result, ['Fiction', 'Romance', 'Contemporary']);
    });

    test('parseRawGenres splits on comma, semicolon, slash, and double-hyphen', () {
      const input = "Young Adult, Fantasy; Magic / Paranormal -- Dragons";
      final result = GenreParser.parseRawGenres(input);

      expect(result, ['Young Adult', 'Fantasy', 'Magic', 'Paranormal', 'Dragons']);
    });

    test('parseRawGenres strips noisy metadata and blacklist entries', () {
      final input = [
        'Accessible book',
        'Science Fiction',
        'Protected DAISY',
        'In Library',
        'Lending Library',
        'Dystopian',
      ];
      final result = GenreParser.parseRawGenres(input);

      expect(result, ['Science Fiction', 'Dystopian']);
    });

    test('parseRawGenres deduplicates genres case-insensitively', () {
      final input = ['romance', 'Romance', 'ROMANCE', 'fantasy', 'Fantasy'];
      final result = GenreParser.parseRawGenres(input);

      expect(result, ['Romance', 'Fantasy']);
    });

    test('parseRawGenres handles null, empty list, and empty string gracefully', () {
      expect(GenreParser.parseRawGenres(null), isEmpty);
      expect(GenreParser.parseRawGenres([]), isEmpty);
      expect(GenreParser.parseRawGenres(''), isEmpty);
      expect(GenreParser.parseRawGenres('   '), isEmpty);
      expect(GenreParser.parseRawGenres(['/', ';', '--']), isEmpty);
    });

    test('parseRawGenres correctly title-cases words', () {
      final input = ["children's fiction", "graphic novels", "dark academia"];
      final result = GenreParser.parseRawGenres(input);

      expect(result, ["Children's Fiction", 'Graphic Novels', 'Dark Academia']);
    });
  });

  group('Book Model Genre Serialization & Deserialization Tests', () {
    test('Book.fromJson parses Google Books categories structure', () {
      final json = {
        'id': 'gb_101',
        'title': 'The Song of Achilles',
        'author': 'Madeline Miller',
        'categories': ['Fiction / Romance / Historical', 'Mythology'],
      };

      final book = Book.fromJson(json);

      expect(book.genres, ['Fiction', 'Romance', 'Historical', 'Mythology']);
    });

    test('Book.fromJson parses OpenLibrary subjects structure', () {
      final json = {
        'id': 'ol_202',
        'title': 'Dune',
        'authors': ['Frank Herbert'],
        'subjects': ['Science Fiction', 'Space opera', 'Accessible book'],
      };

      final book = Book.fromJson(json);

      expect(book.genres, ['Science Fiction', 'Space Opera']);
    });

    test('Book.fromJson falls back to ["General"] when genres are empty', () {
      final json = {
        'id': 'gb_empty',
        'title': 'Unknown Adventure',
        'author': 'Anonymous',
        'categories': [],
      };

      final book = Book.fromJson(json);

      expect(book.genres, ['General']);
    });

    test('Book.toMap serializes genres as clean JSON string array', () {
      final book = Book(
        id: 'book_ser_1',
        title: 'Six of Crows',
        author: 'Leigh Bardugo',
        description: 'Fantasy heist',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 465,
        genres: ['Young Adult', 'Fantasy', 'Heist'],
      );

      final map = book.toMap();

      expect(map['genres'], isA<String>());
      final decoded = jsonDecode(map['genres'] as String);
      expect(decoded, ['Young Adult', 'Fantasy', 'Heist']);
    });

    test('Book.fromMap deserializes JSON string array cleanly', () {
      final map = {
        'id': 'book_deser_1',
        'title': 'The Secret History',
        'author': 'Donna Tartt',
        'description': 'Dark academia classic',
        'coverUrl': 'https://example.com/cover.jpg',
        'totalPages': 559,
        'genres': jsonEncode(['Dark Academia', 'Psychological Thriller', 'Literary Fiction']),
      };

      final book = Book.fromMap(map);

      expect(book.genres, ['Dark Academia', 'Psychological Thriller', 'Literary Fiction']);
    });

    test('Book.fromMap preserves backward-compatibility with legacy comma-separated strings', () {
      final legacyMap = {
        'id': 'book_legacy_1',
        'title': '1984',
        'author': 'George Orwell',
        'genres': 'Dystopian, Classic Literature, Political Fiction',
      };

      final book = Book.fromMap(legacyMap);

      expect(book.genres, ['Dystopian', 'Classic Literature', 'Political Fiction']);
    });

    test('Book.fromMap falls back to ["General"] when genres is null or empty', () {
      final emptyMap = {
        'id': 'book_empty_1',
        'title': 'Mystery Book',
        'author': 'John Doe',
      };

      final book = Book.fromMap(emptyMap);

      expect(book.genres, ['General']);
    });

    test('Book.copyWith updates or preserves genres', () {
      final original = Book(
        id: 'book_cw_1',
        title: 'Original Title',
        author: 'Author',
        description: '',
        coverUrl: '',
        totalPages: 200,
        genres: ['Horror'],
      );

      final updated = original.copyWith(genres: ['Horror', 'Gothic']);
      expect(updated.genres, ['Horror', 'Gothic']);

      final unchanged = original.copyWith(currentPage: 50);
      expect(unchanged.genres, ['Horror']);
    });
  });
}
