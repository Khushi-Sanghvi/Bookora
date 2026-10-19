import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/services/book_analyzer_service.dart';
import 'package:between_world/services/book_metadata_sanitizer.dart';
import 'package:between_world/services/book_color_engine.dart';
import 'package:between_world/services/book_search_service.dart';
import 'package:between_world/services/book_cache_service.dart';

void main() {
  group('BookMetadataSanitizer Tests', () {
    test('cleanSearchQuery strips subtitles, edition noise, and watermarks', () {
      const raw = 'Twisted Games: a Forbidden Royal Bodyguard Romance (Cat and Mouse Duet Book 1) [EPUB] [OceanofPDF.com] ARC';
      final cleaned = BookMetadataSanitizer.cleanSearchQuery(raw);
      expect(cleaned, 'Twisted Games');
    });

    test('sanitizeSynopsis decodes HTML entities and strips Markdown links & URLs', () {
      const rawHtml = 'Check out **Haunting Adeline** [Haunting Adeline pdf](https://bookrenzo.com/book) at https://oceanofpdf.com';
      final clean = BookMetadataSanitizer.sanitizeSynopsis(rawHtml);
      expect(clean, contains('Haunting Adeline'));
      expect(clean, isNot(contains('https://')));
      expect(clean, isNot(contains('oceanofpdf')));
    });

    test('isTruncatedSynopsis detects trailing D... and dangling incomplete sentences', () {
      const truncated = 'From USA Today bestselling author Rina Kent comes a new STANDALONE dark romance about a villain and his new obsession.\n\nI caught the attention of a monster.\nI didn\'t ask for it.\nD...';
      expect(BookMetadataSanitizer.isTruncatedSynopsis(truncated), isTrue);

      const complete = 'From USA Today bestselling author Rina Kent comes a new STANDALONE dark romance about a villain and his new obsession.\n\nI caught the attention of a monster.\nI didn\'t ask for it.\nDidn\'t even see it coming.';
      expect(BookMetadataSanitizer.isTruncatedSynopsis(complete), isFalse);
    });

    test('sanitizeSynopsis strips trailing broken cut-off fragments like D...', () {
      const truncated = 'I caught the attention of a monster.\nI didn\'t ask for it.\nD...';
      final cleaned = BookMetadataSanitizer.sanitizeSynopsis(truncated);
      expect(cleaned, isNot(contains('D...')));
      expect(cleaned, endsWith("I didn't ask for it."));
    });

    test('sanitizeTags filters machine identifiers and deduplicates tags', () {
      final rawTags = ['collectionid:1234', 'Fiction / Fantasy / Dark Fantasy', 'general', 'read', 'Dark Fantasy'];
      final cleaned = BookMetadataSanitizer.sanitizeTags(rawTags);
      expect(cleaned, contains('Dark Fantasy'));
      expect(cleaned, isNot(contains('collectionid:1234')));
      expect(cleaned, isNot(contains('general')));
    });
  });

  group('BookColorEngine Tests', () {
    test('nextSpineColor generates chromatic diversity', () {
      final color1 = BookColorEngine.nextSpineColor(seed: 'Book Title 1');
      final color2 = BookColorEngine.nextSpineColor(seed: 'Book Title 2');
      expect(color1, isNotEmpty);
      expect(color2, isNotEmpty);
      expect(color1, isNot(equals(color2)));
    });

    test('parseColor converts hex string to Color', () {
      final color = BookColorEngine.parseColor('C0392B');
      expect(color.toARGB32(), 0xFFC0392B);
    });
  });

  group('BookSearchService Rating & Serialization Tests', () {
    test('convertFiveStarToTenStar converts 4.85 to 9.7', () {
      final rating = BookSearchService.convertFiveStarToTenStar(4.85);
      expect(rating, 9.7);
    });

    test('getBaselineRating returns deterministic rating between 8.4 and 9.6', () {
      final rating = BookSearchService.getBaselineRating('The Way of Kings Brandon Sanderson');
      expect(rating, greaterThanOrEqualTo(8.4));
      expect(rating, lessThanOrEqualTo(9.6));
    });

    test('BookSearchResult converts to Book model correctly', () {
      const result = BookSearchResult(
        title: 'Dune',
        author: 'Frank Herbert',
        totalPages: 688,
        synopsis: 'A science fiction masterpiece.',
        rating: 9.4,
        subjects: ['Sci-Fi', 'Space Opera'],
      );

      final book = result.toBook();
      expect(book.title, 'Dune');
      expect(book.author, 'Frank Herbert');
      expect(book.totalPages, 688);
      expect(book.overallRating, 9.4);
      expect(book.genres, contains('Sci-Fi'));
    });
  });

  group('BookAnalyzerService Story Codex Analysis Tests', () {
    test('analyze detects Dark Romance tropes and calculates thematic heat scores', () {
      final book = Book(
        id: 'test_101',
        title: 'Twisted Games',
        author: 'Ana Huang',
        description: 'A possessive bodyguard and a royal princess in a dark romance.',
        coverUrl: '',
        totalPages: 420,
        currentPage: 80,
      );

      final analysis = BookAnalyzerService.analyze(book);

      expect(analysis.dominantGenre, contains('Dark Romance'));
      expect(analysis.tropesAndThemes, contains('Morally Grey Hero'));
      expect(analysis.thematicScores['🌶️ Spice'], greaterThan(0.5));
      expect(analysis.estimatedRemainingHours, greaterThan(0.0));
      expect(analysis.estimatedFinishDateText, isNotEmpty);
    });
  });

  group('Relevance Filtering & Scoring Engine Tests', () {
    test('isRelevantMatch accepts exact and partial title/author matches', () {
      const match1 = BookSearchResult(
        title: 'Leather & Lies (Ruthless Cowboys #1)',
        author: 'Delilah Grant',
        totalPages: 350,
      );
      expect(
        BookSearchService.isRelevantMatch('Leather & Lies by Delilah Grant', match1),
        isTrue,
      );

      const match2 = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'L. Steele',
        totalPages: 320,
      );
      expect(
        BookSearchService.isRelevantMatch('The Unwanted Wife by L. Steele', match2),
        isTrue,
      );

      const match3 = BookSearchResult(
        title: 'As You Wish',
        author: 'Danika Brown',
        totalPages: 280,
      );
      expect(
        BookSearchService.isRelevantMatch('As You Wish by Danika Brown', match3),
        isTrue,
      );
    });

    test('isRelevantMatch rejects irrelevant fuzzy matches', () {
      const irrelevant1 = BookSearchResult(
        title: 'Spectacle',
        author: 'Jodie Leith',
        totalPages: 400,
      );
      expect(
        BookSearchService.isRelevantMatch('Leather & Lies by Delilah Grant', irrelevant1),
        isFalse,
      );

      const irrelevant2 = BookSearchResult(
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        totalPages: 180,
      );
      expect(
        BookSearchService.isRelevantMatch('The Unwanted Wife by L. Steele', irrelevant2),
        isFalse,
      );
    });

    test('isRelevantMatch accepts genre-based search queries intersecting with genres array', () {
      const romanceBook = BookSearchResult(
        title: 'Haunting Adeline',
        author: 'H. D. Carlton',
        totalPages: 580,
        subjects: ['Dark Romance', 'Romantic Suspense'],
      );
      expect(
        BookSearchService.isRelevantMatch('Dark Romance', romanceBook),
        isTrue,
      );
      expect(
        BookSearchService.isRelevantMatch('romance', romanceBook),
        isTrue,
      );

      const cyberpunkBook = BookSearchResult(
        title: 'Neuromancer',
        author: 'William Gibson',
        totalPages: 271,
        subjects: ['Cyberpunk', 'Science Fiction'],
      );
      expect(
        BookSearchService.isRelevantMatch('Cyberpunk', cyberpunkBook),
        isTrue,
      );

      final bookModel = Book(
        id: 'model_1',
        title: 'Fourth Wing',
        author: 'Rebecca Yarros',
        description: 'A thrilling fantasy novel with dragons.',
        totalPages: 520,
        currentPage: 0,
        coverUrl: '',
        genres: ['Fantasy', 'Dragons', 'Romance'],
      );
      expect(
        BookSearchService.isRelevantMatch('Fantasy', bookModel),
        isTrue,
      );
    });

    test('calculateRelevanceScore strictly respects priority tiers and ranking', () {
      // 1. Highest Priority (Score 100+): Exact/partial matches on BOTH title and author
      const bothMatch = BookSearchResult(
        title: 'Leather & Lies',
        author: 'Delilah Grant',
        totalPages: 320,
        subjects: ['Cowboy Romance', 'Western'],
      );
      final scoreBoth = BookSearchService.calculateRelevanceScore(
        'Leather & Lies by Delilah Grant',
        bothMatch,
      );
      expect(scoreBoth, greaterThanOrEqualTo(100.0));

      // 2. High Priority (Score 75-99): Direct title substring or token matches
      const titleMatchOnly = BookSearchResult(
        title: 'Fourth Wing',
        author: 'Unknown Author',
        totalPages: 500,
        subjects: ['Fiction'],
      );
      final scoreTitle = BookSearchService.calculateRelevanceScore(
        'Fourth Wing',
        titleMatchOnly,
      );
      expect(scoreTitle, greaterThanOrEqualTo(75.0));
      expect(scoreTitle, lessThanOrEqualTo(99.0));

      // 3. Medium Priority (Score 50-74): Direct author name matches
      const authorMatchOnly = BookSearchResult(
        title: 'Reminders of Him',
        author: 'Colleen Hoover',
        totalPages: 330,
        subjects: ['Fiction'],
      );
      final scoreAuthor = BookSearchService.calculateRelevanceScore(
        'Colleen Hoover',
        authorMatchOnly,
      );
      expect(scoreAuthor, greaterThanOrEqualTo(50.0));
      expect(scoreAuthor, lessThanOrEqualTo(74.0));

      // 4. Category Priority (Score 35-49): Books matching items in result.genres
      const genreMatchOnly = BookSearchResult(
        title: 'Something Else',
        author: 'Some Author',
        totalPages: 250,
        subjects: ['Dark Romance', 'Suspense'],
      );
      final scoreGenre = BookSearchService.calculateRelevanceScore(
        'Dark Romance',
        genreMatchOnly,
      );
      expect(scoreGenre, greaterThanOrEqualTo(35.0));
      expect(scoreGenre, lessThanOrEqualTo(49.0));

      // Hierarchy assertion: Highest > High > Medium > Category
      expect(scoreBoth, greaterThan(scoreTitle));
      expect(scoreTitle, greaterThan(scoreAuthor));
      expect(scoreAuthor, greaterThan(scoreGenre));
    });

    test('UI Deduplication merges multiple genres and preserves richer metadata', () {
      final list = <BookSearchResult>[];

      const bookA = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'L. Steele',
        coverUrl: 'https://example.com/coverA.jpg',
        totalPages: 340,
        synopsis: 'Short synopsis',
        subjects: ['Contemporary Romance', 'Billionaire'],
      );

      const bookB = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'L. Steele',
        coverUrl: null,
        totalPages: 340,
        synopsis: 'A significantly longer and more detailed synopsis of the novel.',
        subjects: ['Dark Romance', 'Enemies to Lovers'],
      );

      void addWithMerge(BookSearchResult item) {
        final key = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
        final existingIndex = list.indexWhere(
          (r) => '${r.title.toLowerCase().trim()}|${r.author.toLowerCase().trim()}' == key,
        );

        if (existingIndex == -1) {
          list.add(item);
        } else {
          final existing = list[existingIndex];
          final combinedGenres = {...existing.genres, ...item.genres}.toList();
          list[existingIndex] = existing.copyWith(
            genres: combinedGenres,
            coverUrl: existing.coverUrl ?? item.coverUrl,
            synopsis: (existing.synopsis?.length ?? 0) > (item.synopsis?.length ?? 0)
                ? existing.synopsis
                : item.synopsis,
          );
        }
      }

      addWithMerge(bookA);
      addWithMerge(bookB);

      expect(list.length, equals(1));
      final merged = list.first;
      expect(merged.genres, contains('Contemporary Romance'));
      expect(merged.genres, contains('Billionaire'));
      expect(merged.genres, contains('Dark Romance'));
      expect(merged.genres, contains('Enemies to Lovers'));
      expect(merged.coverUrl, equals('https://example.com/coverA.jpg'));
      expect(merged.synopsis, equals('A significantly longer and more detailed synopsis of the novel.'));
    });

    test('UI Deduplication preserves different books sharing same title by different authors', () {
      final list = <BookSearchResult>[];

      const bookA = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'Natasha Anders',
        totalPages: 310,
      );
      const bookB = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'L. Steele',
        totalPages: 340,
      );
      const bookDuplicate = BookSearchResult(
        title: 'The Unwanted Wife',
        author: 'L. Steele',
        totalPages: 340,
      );

      void addDeduplicated(BookSearchResult item) {
        final key = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
        final existingIndex = list.indexWhere(
          (r) => '${r.title.toLowerCase().trim()}|${r.author.toLowerCase().trim()}' == key,
        );
        if (existingIndex == -1) {
          list.add(item);
        } else {
          final existing = list[existingIndex];
          final combinedGenres = {...existing.genres, ...item.genres}.toList();
          list[existingIndex] = existing.copyWith(genres: combinedGenres);
        }
      }

      addDeduplicated(bookA);
      addDeduplicated(bookB);
      addDeduplicated(bookDuplicate);

      expect(list.length, equals(2));
      expect(list[0].author, equals('Natasha Anders'));
      expect(list[1].author, equals('L. Steele'));
    });
  });

  group('BookCacheService LRU & Memory Cache Tests', () {
    test('saveMemorySearchResults and getMemoryCachedSearchResults stores and retrieves', () {
      BookCacheService.clearMemoryCache();
      const items = [
        BookSearchResult(title: 'Dune', author: 'Frank Herbert', totalPages: 688),
      ];

      BookCacheService.saveMemorySearchResults('dune', items);
      final retrieved = BookCacheService.getMemoryCachedSearchResults('dune');

      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(1));
      expect(retrieved.first.title, equals('Dune'));

      BookCacheService.clearMemoryCache();
      final afterClear = BookCacheService.getMemoryCachedSearchResults('dune');
      expect(afterClear, isNull);
    });
  });
}
