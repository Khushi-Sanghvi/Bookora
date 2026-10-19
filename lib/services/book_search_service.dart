import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../models/enums.dart';
import 'book_cache_service.dart';
import 'book_color_engine.dart';
import 'book_metadata_parser.dart';
import 'book_metadata_sanitizer.dart';
import 'genre_parser.dart';
import 'metadata_sanitizer.dart';

class BookSearchResult {
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  final String? synopsis;
  final String? isbn;
  final String? publisher;
  final int? publishedYear;
  final List<String> subjects;
  final double rating; // Normalized to Bookora's 10-star rating system (0.0 - 10.0)

  const BookSearchResult({
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.synopsis,
    this.isbn,
    this.publisher,
    this.publishedYear,
    this.subjects = const [],
    this.rating = 0.0,
  });

  List<String> get genres => subjects;
  String get primaryGenre => genres.isNotEmpty ? genres.first : 'General';
  String get genre => primaryGenre;

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'totalPages': totalPages,
    'synopsis': synopsis,
    'isbn': isbn,
    'publisher': publisher,
    'publishedYear': publishedYear,
    'subjects': subjects,
    'rating': rating,
  };

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    int pages = (json['totalPages'] as int?) ?? 0;
    if (pages == 280 || pages == 250 || pages == 300) {
      pages = 0; // Clear out old hardcoded cache defaults
    }
    return BookSearchResult(
      title: json['title'] as String? ?? 'Unknown Title',
      author: json['author'] as String? ?? 'Unknown Author',
      coverUrl: json['coverUrl'] as String?,
      totalPages: pages,
      synopsis: json['synopsis'] as String?,
      isbn: json['isbn'] as String?,
      publisher: json['publisher'] as String?,
      publishedYear: json['publishedYear'] as int?,
      subjects: GenreParser.parseRawGenres(
          json['subjects'] ?? json['categories'] ?? json['genres']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  BookSearchResult copyWith({
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    String? synopsis,
    String? isbn,
    String? publisher,
    int? publishedYear,
    List<String>? subjects,
    List<String>? genres,
    double? rating,
  }) {
    return BookSearchResult(
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      synopsis: synopsis ?? this.synopsis,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      subjects: genres ?? subjects ?? this.subjects,
      rating: rating ?? this.rating,
    );
  }

  Book toBook() {
    const uuid = Uuid();
    BookColorEngine.nextSpineColor(seed: title);

    final cleanDesc = synopsis ?? '';
    final taglineText = MetadataSanitizer.extractTagline(
          title: title,
          author: author,
          description: cleanDesc,
        ) ??
        BookMetadataParser.extractBlurbTagline(
          title: title,
          author: author,
          description: cleanDesc,
        );

    final blurbText = MetadataSanitizer.extractBlurb(
          title: title,
          author: author,
          description: cleanDesc,
        ) ??
        BookMetadataParser.extractStoryline(
          title: title,
          author: author,
          description: cleanDesc,
        );

    return Book(
      id: uuid.v4(),
      title: title,
      author: author,
      description: cleanDesc.isNotEmpty ? cleanDesc : 'A captivating story by $author.',
      tagline: taglineText,
      blurb: blurbText,
      coverUrl: coverUrl ?? '',
      totalPages: totalPages > 0 ? totalPages : 300,
      currentPage: 0,
      status: ReadingStatus.toRead,
      format: BookFormat.paperback,
      genres: subjects.isNotEmpty &&
              !(subjects.length == 1 &&
                  subjects.first.toLowerCase() == 'general')
          ? subjects
          : GenreParser.inferGenresFromContext(
              title: title,
              author: author,
              description: cleanDesc,
            ),
      overallRating: rating,
    );
  }
}

class BookEnrichedMetadata {
  final String synopsis;
  final String tagline;
  final String blurb;
  final int totalPages;
  final List<String> genres;

  const BookEnrichedMetadata({
    required this.synopsis,
    required this.tagline,
    required this.blurb,
    required this.totalPages,
    this.genres = const [],
  });
}

class BookSearchService {
  static const Set<String> _stopWords = {
    'and',
    'the',
    'by',
    'of',
    'in',
    'for',
    'to',
    'a',
    'an',
    '&',
    'with',
    'on',
    'at',
    'from',
    'or',
    'is',
    'it',
    'as',
  };

  /// Converts any 5-star rating system (0.0 - 5.0) to Bookora's 10-star rating system (0.0 - 10.0).
  /// For example: 4.85 / 5.0 -> 9.7 / 10.0
  static double convertFiveStarToTenStar(double fiveStarRating) {
    if (fiveStarRating <= 0) return 0.0;
    if (fiveStarRating <= 5.0) {
      return double.parse(
        (fiveStarRating * 2.0).clamp(0.0, 10.0).toStringAsFixed(1),
      );
    }
    return double.parse(fiveStarRating.clamp(0.0, 10.0).toStringAsFixed(1));
  }

  /// Generates a realistic, deterministic baseline 10-star rating (8.4 - 9.6)
  /// for books that do not have an explicit rating count on Google Books / Open Library.
  static double getBaselineRating(String seed) {
    if (seed.isEmpty) return 9.0;
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFF;
    }
    final offset = (hash % 13) / 10.0; // 0.0 to 1.2
    return double.parse((8.4 + offset).toStringAsFixed(1));
  }

  /// Extracts meaningful keywords ignoring stop words
  static List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();
  }

  /// Determines whether a search query likely targets a book genre or category.
  static bool _isLikelyGenreQuery(String query) {
    final lower = query.toLowerCase().trim();
    const commonGenres = {
      'romance',
      'dark romance',
      'fantasy',
      'urban fantasy',
      'high fantasy',
      'epic fantasy',
      'sci-fi',
      'science fiction',
      'cyberpunk',
      'steampunk',
      'space opera',
      'dystopian',
      'thriller',
      'psychological thriller',
      'mystery',
      'crime',
      'horror',
      'paranormal',
      'contemporary',
      'historical fiction',
      'historical romance',
      'fiction',
      'non-fiction',
      'biography',
      'memoir',
      'poetry',
      'young adult',
      'ya',
      'new adult',
      'classics',
      'adventure',
      'action',
      'comedy',
      'humor',
      'drama',
      'philosophy',
      'psychology',
      'self-help',
      'true crime',
      'manga',
      'comics',
      'graphic novel',
    };

    if (commonGenres.contains(lower)) return true;
    for (final g in commonGenres) {
      if (lower == g || lower.contains(g)) {
        return true;
      }
    }
    return false;
  }

  /// Relevance check: Rejects irrelevant fuzzy search results (e.g. returning "Spectacle" for "Leather & Lies").
  /// Ensures either title, author, or any tag in result.genres contains significant keywords from the search query.
  static bool isRelevantMatch(String query, dynamic result) {
    final String title;
    final String author;
    final List<String> genres;

    if (result is BookSearchResult) {
      title = result.title;
      author = result.author;
      genres = result.genres;
    } else if (result is Book) {
      title = result.title;
      author = result.author;
      genres = result.genres;
    } else {
      return true;
    }

    final queryKeywords = _extractKeywords(query);
    if (queryKeywords.isEmpty) return true;

    final titleLower = title.toLowerCase();
    final authorLower = author.toLowerCase();
    final titleKeywords = _extractKeywords(titleLower);
    final authorKeywords = _extractKeywords(authorLower);

    // If query has "by", check title part and author part specifically
    final byParts = query.split(RegExp(r'\s+by\s+', caseSensitive: false));
    if (byParts.length >= 2) {
      final qTitleKeywords = _extractKeywords(byParts[0]);
      final qAuthorKeywords = _extractKeywords(byParts[1]);

      bool titleMatch = qTitleKeywords.isEmpty ||
          qTitleKeywords.any((k) => titleLower.contains(k));
      bool authorMatch = qAuthorKeywords.isEmpty ||
          authorLower.contains(qAuthorKeywords.first) ||
          qAuthorKeywords.any((k) => authorKeywords.contains(k));

      if (titleMatch || authorMatch) {
        return true;
      }
    }

    // Genre intersection check: if query tokens match any item in genres
    final genresLower = genres.map((g) => g.toLowerCase().trim()).toList();
    final genreMatch = queryKeywords.any(
      (k) => genresLower.any((g) => g.contains(k) || k.contains(g)),
    );
    if (genreMatch) {
      return true;
    }

    // General keyword match: at least one significant keyword must match either title or author
    final matchingKeywords = queryKeywords.where(
      (k) =>
          titleLower.contains(k) ||
          authorLower.contains(k) ||
          titleKeywords.contains(k) ||
          authorKeywords.contains(k),
    );

    return matchingKeywords.isNotEmpty;
  }

  /// Public accessor for calculating search relevance score
  static double calculateRelevanceScore(String query, dynamic result) =>
      _calculateRelevanceScore(query, result);

  /// Calculates a relevance score for ranking search results according to strict priority tiers:
  /// - Highest Priority (Score 100+): Exact or partial matches on BOTH title and author
  /// - High Priority (Score 75-99): Direct title substring or token matches
  /// - Medium Priority (Score 50-74): Direct author name matches
  /// - Category Priority (Score 35-49): Books where search query matches items in result.genres
  static double _calculateRelevanceScore(String query, dynamic result) {
    final String title;
    final String author;
    final List<String> genres;
    final String? coverUrl;
    final int totalPages;
    final String? synopsis;
    final double rating;

    if (result is BookSearchResult) {
      title = result.title;
      author = result.author;
      genres = result.genres;
      coverUrl = result.coverUrl;
      totalPages = result.totalPages;
      synopsis = result.synopsis;
      rating = result.rating;
    } else if (result is Book) {
      title = result.title;
      author = result.author;
      genres = result.genres;
      coverUrl = result.coverUrl;
      totalPages = result.totalPages;
      synopsis = result.description;
      rating = result.overallRating * 2.0;
    } else {
      return 0.0;
    }

    final qLower = query.toLowerCase().trim();
    final tLower = title.toLowerCase().trim();
    final aLower = author.toLowerCase().trim();
    final queryKeywords = _extractKeywords(query);

    bool titleMatched = false;
    bool authorMatched = false;
    bool genreMatched = false;

    // 1. Structured query with "by": e.g. "Leather & Lies by Delilah Grant"
    final byParts = query.split(RegExp(r'\s+by\s+', caseSensitive: false));
    if (byParts.length >= 2) {
      final qTitle = byParts[0].toLowerCase().trim();
      final qAuthor = byParts[1].toLowerCase().trim();

      if (tLower == qTitle || tLower.contains(qTitle) || qTitle.contains(tLower)) {
        titleMatched = true;
      }
      if (aLower == qAuthor || aLower.contains(qAuthor) || qAuthor.contains(aLower)) {
        authorMatched = true;
      }
    } else {
      // Direct whole-query matches on title or author
      if (tLower == qLower || tLower.startsWith(qLower) || tLower.contains(qLower)) {
        titleMatched = true;
      }
      if (aLower == qLower || aLower.contains(qLower) || (qLower.length > 3 && qLower.contains(aLower))) {
        authorMatched = true;
      }
    }

    // 2. Token / keyword matches
    if (queryKeywords.isNotEmpty) {
      final tKeywords = _extractKeywords(tLower);
      final aKeywords = _extractKeywords(aLower);

      final hasTitleKeyword = queryKeywords.any((k) => tLower.contains(k) || tKeywords.contains(k));
      final hasAuthorKeyword = queryKeywords.any((k) => aLower.contains(k) || aKeywords.contains(k));

      if (hasTitleKeyword) titleMatched = true;
      if (hasAuthorKeyword) authorMatched = true;
    }

    // 3. Category / Genre matches
    final genresLower = genres.map((g) => g.toLowerCase().trim()).toList();
    if (genresLower.isNotEmpty) {
      final exactGenreMatch = genresLower.any((g) => g == qLower || qLower.contains(g));
      final tokenGenreMatch = queryKeywords.isNotEmpty &&
          queryKeywords.any((k) => genresLower.any((g) => g.contains(k) || k.contains(g)));

      if (exactGenreMatch || tokenGenreMatch) {
        genreMatched = true;
      }
    }

    // 4. Quality signals (tie-breakers within the tier, up to 4.5 pts)
    double qualityBoost = 0.0;
    if (coverUrl != null && coverUrl.isNotEmpty) qualityBoost += 1.5;
    if (totalPages > 0) qualityBoost += 1.0;
    if (synopsis != null && synopsis.length > 40) qualityBoost += 1.0;
    qualityBoost += (rating / 10.0) * 1.0;

    // 5. Tier assignment strictly satisfying the point bands
    if (titleMatched && authorMatched) {
      // Highest Priority (Score 100+): Exact or partial matches on BOTH title and author
      double base = 120.0;
      if (tLower == qLower) base += 20.0;
      if (aLower == qLower) base += 10.0;
      return (base + qualityBoost).clamp(100.0, 300.0);
    } else if (titleMatched) {
      // High Priority (Score 75-99): Direct title substring or token matches
      double base = 80.0;
      if (tLower == qLower) {
        base = 92.0;
      } else if (tLower.startsWith(qLower)) {
        base = 86.0;
      } else if (tLower.contains(qLower)) {
        base = 82.0;
      }
      return (base + qualityBoost).clamp(75.0, 99.0);
    } else if (authorMatched) {
      // Medium Priority (Score 50-74): Direct author name matches
      double base = 58.0;
      if (aLower == qLower) {
        base = 67.0;
      } else if (aLower.contains(qLower)) {
        base = 62.0;
      }
      return (base + qualityBoost).clamp(50.0, 74.0);
    } else if (genreMatched) {
      // Category Priority (Score 35-49): Books where search query matches items in result.genres
      double base = 38.0;
      if (genresLower.any((g) => g == qLower)) {
        base = 43.0;
      }
      return (base + qualityBoost).clamp(35.0, 49.0);
    }

    return 0.0;
  }

  /// Cleans HTML tags and decodes common HTML entities
  static String? _cleanHtml(String? html) {
    if (html == null || html.trim().isEmpty) return null;
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text.isNotEmpty ? text : null;
  }

  /// Cleans synopsis text
  static String? _cleanSynopsis(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final htmlCleaned = _cleanHtml(raw);
    if (htmlCleaned == null || htmlCleaned.isEmpty) return null;
    final clean = BookMetadataSanitizer.sanitizeSynopsis(htmlCleaned);
    return clean.isNotEmpty ? clean : null;
  }

  /// Strips thumbnail sizing parameters from Goodreads image URLs to obtain full-resolution covers
  static String? _upgradeGoodreadsCoverUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var upgraded = url.trim();
    // Strip pattern: ._SX50_ or ._SY75_ or ._SX98_ or ._SY160_
    upgraded = upgraded.replaceAll(RegExp(r'\._S[XY]\d+_|\._SY\d+_'), '');
    if (upgraded.contains('nophoto')) return null;
    return upgraded;
  }

  /// Merges two search results for the same title/author to preserve best metadata
  static BookSearchResult _mergeResults(BookSearchResult existing, BookSearchResult incoming) {
    return existing.copyWith(
      title: existing.title.length >= incoming.title.length ? existing.title : incoming.title,
      author: existing.author != 'Unknown Author' ? existing.author : incoming.author,
      coverUrl: (existing.coverUrl != null && existing.coverUrl!.isNotEmpty)
          ? existing.coverUrl
          : incoming.coverUrl,
      totalPages: existing.totalPages > 0 ? existing.totalPages : incoming.totalPages,
      synopsis: (existing.synopsis != null && existing.synopsis!.length > 30)
          ? existing.synopsis
          : incoming.synopsis,
      isbn: existing.isbn ?? incoming.isbn,
      publisher: existing.publisher ?? incoming.publisher,
      publishedYear: existing.publishedYear ?? incoming.publishedYear,
      genres: GenreParser.parseRawGenres([...existing.genres, ...incoming.genres]),
      rating: existing.rating > 0 ? existing.rating : incoming.rating,
    );
  }

  // ===========================================================================
  // MULTI-PROVIDER SEARCH ENGINE
  // ===========================================================================

  // Provider rate-limiting (HTTP 429) cooldown tracking
  static DateTime? _googleBooksCooldownUntil;
  static DateTime? _gutendexCooldownUntil;
  static DateTime? _goodreadsCooldownUntil;
  static DateTime? _openLibraryCooldownUntil;

  static bool get isGoogleBooksRateLimited =>
      _googleBooksCooldownUntil != null && DateTime.now().isBefore(_googleBooksCooldownUntil!);

  static bool get isGutendexRateLimited =>
      _gutendexCooldownUntil != null && DateTime.now().isBefore(_gutendexCooldownUntil!);

  static bool get isGoodreadsRateLimited =>
      _goodreadsCooldownUntil != null && DateTime.now().isBefore(_goodreadsCooldownUntil!);

  static bool get isOpenLibraryRateLimited =>
      _openLibraryCooldownUntil != null && DateTime.now().isBefore(_openLibraryCooldownUntil!);

  /// Parallel multi-source book search querying Goodreads, Apple Books, Open Library,
  /// Google Books (with 429 graceful handling), and Gutendex.
  static Future<List<BookSearchResult>> searchBooks(String query) async {
    final sanitizedQuery = BookMetadataSanitizer.cleanSearchQuery(query);
    final effectiveQuery = sanitizedQuery.isNotEmpty ? sanitizedQuery : query.trim();
    final normalizedKey = effectiveQuery.toLowerCase();
    if (normalizedKey.isEmpty) return [];

    // 1. Check versioned memory and disk cache with 2-hour TTL & relevance validation
    final cached = await BookCacheService.getCachedSearchResults(
      normalizedKey,
      relevanceValidator: isRelevantMatch,
    );
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final cleanQuery = Uri.encodeComponent(effectiveQuery);

    // 2. Parallel multi-source fetch
    final responses = await Future.wait([
      _fetchGoodreads(effectiveQuery),
      _fetchAppleBooks(effectiveQuery),
      _fetchOpenLibrary(cleanQuery, effectiveQuery),
      _fetchGoogleBooks(cleanQuery, effectiveQuery),
      _fetchGutendex(effectiveQuery),
    ]);

    final goodreadsResults = responses[0];
    final appleResults = responses[1];
    final openLibResults = responses[2];
    final googleResults = responses[3];
    final gutendexResults = responses[4];

    final combinedMap = <String, BookSearchResult>{};

    void addResult(BookSearchResult item) {
      final key = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
      if (combinedMap.containsKey(key)) {
        combinedMap[key] = _mergeResults(combinedMap[key]!, item);
      } else {
        combinedMap[key] = item;
      }
    }

    // Add in order of coverage/quality for indie/contemporary/bestsellers
    for (final item in goodreadsResults) {
      addResult(item);
    }
    for (final item in appleResults) {
      addResult(item);
    }
    for (final item in openLibResults) {
      addResult(item);
    }
    for (final item in googleResults) {
      addResult(item);
    }
    for (final item in gutendexResults) {
      addResult(item);
    }

    // 3. Relevance Filtering: Reject irrelevant fuzzy results
    final relevantResults = combinedMap.values
        .where((item) => isRelevantMatch(effectiveQuery, item))
        .toList();

    // 4. Relevance Scoring & Ranking
    relevantResults.sort((a, b) {
      final scoreA = _calculateRelevanceScore(effectiveQuery, a);
      final scoreB = _calculateRelevanceScore(effectiveQuery, b);
      return scoreB.compareTo(scoreA);
    });

    if (relevantResults.isNotEmpty) {
      await BookCacheService.saveSearchResultsToCache(normalizedKey, relevantResults);
      return relevantResults;
    }

    // Fallback: If live APIs returned 0 results (due to rate-limiting 429, timeouts, or offline),
    // cleanly fallback to any cached results (even with relaxed matching) without throwing unhandled exceptions
    final fallbackCached = await BookCacheService.getCachedSearchResults(normalizedKey);
    if (fallbackCached != null && fallbackCached.isNotEmpty) {
      return fallbackCached;
    }

    // Fallback if APIs returned zero relevant matches
    final fallbacks = _getFallbackResults(query);
    final relevantFallbacks = fallbacks
        .where((item) => isRelevantMatch(effectiveQuery, item))
        .toList();
    return relevantFallbacks.isNotEmpty ? relevantFallbacks : fallbacks;
  }

  // ---------------------------------------------------------------------------
  // 1. GOODREADS AUTO-COMPLETE API (Indie, BookTok, Kindle Unlimited coverage)
  // ---------------------------------------------------------------------------
  static Future<List<BookSearchResult>> _fetchGoodreads(String query) async {
    if (isGoodreadsRateLimited) {
      debugPrint('Goodreads provider is in 429 cooldown. Skipping live fetch.');
      return [];
    }

    final candidates = <String>[];
    // Strategy 1: Query as-is
    candidates.add(query);

    // Strategy 2: If query contains "by", strip "by" (e.g. "Leather & Lies by Delilah Grant" -> "Leather & Lies Delilah Grant")
    if (query.toLowerCase().contains(' by ')) {
      candidates.add(query.replaceAll(RegExp(r'\s+by\s+', caseSensitive: false), ' '));
      final parts = query.split(RegExp(r'\s+by\s+', caseSensitive: false));
      if (parts.length >= 2) {
        // Strategy 3: Isolate author portion after "by" to search the author's catalog
        candidates.add(parts[1].trim());
        candidates.add(parts[0].trim());
      }
    }

    // Strategy 4: Swap "&" with "and" (and vice versa)
    if (query.contains('&')) {
      candidates.add(query.replaceAll('&', 'and'));
    } else if (query.toLowerCase().contains(' and ')) {
      candidates.add(query.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ' & '));
    }

    for (final candidate in candidates) {
      try {
        final url = Uri.parse(
          'https://www.goodreads.com/book/auto_complete?format=json&q=${Uri.encodeComponent(candidate)}',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(milliseconds: 3500));

        if (response.statusCode == 429) {
          _goodreadsCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
          debugPrint('Goodreads HTTP 429 Too Many Requests. Cooling down Goodreads provider for 60s.');
          return [];
        }

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List && decoded.isNotEmpty) {
            final results = <BookSearchResult>[];
            for (final item in decoded) {
              if (item is! Map) continue;

              final rawTitle = (item['title'] as String?) ?? 'Unknown Title';
              final bookTitleBare = (item['bookTitleBare'] as String?)?.trim();

              // Extract series from parentheses e.g. "(Ruthless Cowboys #1)"
              String? seriesName;
              final seriesMatch = RegExp(r'\(([^)]+)\)').firstMatch(rawTitle);
              if (seriesMatch != null) {
                seriesName = seriesMatch.group(1)?.trim();
              }

              final displayTitle = (bookTitleBare != null && bookTitleBare.isNotEmpty)
                  ? bookTitleBare
                  : rawTitle.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

              String author = 'Unknown Author';
              if (item['author'] is Map) {
                author = (item['author']['name'] as String?)?.trim() ?? 'Unknown Author';
              } else if (item['author'] is String) {
                author = (item['author'] as String).trim();
              }

              final pages = int.tryParse(item['numPages']?.toString() ?? '') ?? 0;
              final rawRating = double.tryParse(item['avgRating']?.toString() ?? '') ?? 0.0;
              final tenStarRating = rawRating > 0
                  ? convertFiveStarToTenStar(rawRating)
                  : getBaselineRating('$displayTitle $author');

              final rawCover = item['imageUrl'] as String? ??
                  item['image_url'] as String? ??
                  item['smallImageUrl'] as String?;
              final coverUrl = _upgradeGoodreadsCoverUrl(rawCover);

              String? synopsis;
              if (item['description'] is Map) {
                synopsis = _cleanSynopsis(item['description']['html'] as String?);
              } else if (item['description'] is String) {
                synopsis = _cleanSynopsis(item['description'] as String?);
              }

              final subjects = <String>[];
              if (seriesName != null && seriesName.isNotEmpty) {
                subjects.add(seriesName);
              }

              results.add(
                BookSearchResult(
                  title: displayTitle.isNotEmpty ? displayTitle : rawTitle,
                  author: author,
                  coverUrl: coverUrl,
                  totalPages: pages,
                  synopsis: synopsis,
                  subjects: GenreParser.parseRawGenres(subjects),
                  rating: tenStarRating,
                ),
              );
            }

            if (results.isNotEmpty) {
              return results;
            }
          }
        }
      } on TimeoutException {
        debugPrint('Goodreads search timed out for "$candidate". Skipping further candidates.');
        break;
      } on SocketException {
        debugPrint('Goodreads network unreachable. Skipping further candidates.');
        break;
      } catch (e) {
        debugPrint('Goodreads search exception for "$candidate": $e');
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // 2. APPLE BOOKS / ITUNES API (< 300ms, commercial bestsellers)
  // ---------------------------------------------------------------------------
  static Future<List<BookSearchResult>> _fetchAppleBooks(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=ebook&limit=12',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['results'] as List?) ?? [];

        final results = <BookSearchResult>[];
        for (final item in items) {
          if (item is! Map) continue;

          final title = (item['trackName'] as String?) ?? 'Unknown Title';
          final author = (item['artistName'] as String?) ?? 'Unknown Author';

          // Upgrade cover image from 100x100 to 600x600 for crisp visual presentation
          final artwork100 = item['artworkUrl100'] as String?;
          final coverUrl =
              artwork100?.replaceAll('100x100bb.jpg', '600x600bb.jpg');

          final rawRating = (item['averageUserRating'] as num?)?.toDouble() ?? 0.0;
          final tenStarRating = rawRating > 0
              ? convertFiveStarToTenStar(rawRating)
              : getBaselineRating('$title $author');

          final rawDesc = item['description'] as String?;
          final synopsis = _cleanSynopsis(rawDesc);

          final rawGenres = item['genres'];
          final genres = GenreParser.parseRawGenres(rawGenres);

          int? publishedYear;
          final releaseDate = item['releaseDate'] as String?;
          if (releaseDate != null && releaseDate.length >= 4) {
            publishedYear = int.tryParse(releaseDate.substring(0, 4));
          }

          results.add(
            BookSearchResult(
              title: title,
              author: author,
              coverUrl: coverUrl,
              totalPages: 0,
              synopsis: synopsis,
              publishedYear: publishedYear,
              subjects: genres,
              rating: tenStarRating,
            ),
          );
        }
        return results;
      }
    } catch (e) {
      debugPrint('Apple Books search exception: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 3. OPEN LIBRARY API (Multi-strategy Lucene queries & sanitized author)
  // ---------------------------------------------------------------------------
  static Future<List<BookSearchResult>> _fetchOpenLibrary(
    String cleanQuery,
    String rawQuery,
  ) async {
    if (isOpenLibraryRateLimited) {
      debugPrint('Open Library provider is in 429 cooldown. Skipping live fetch.');
      return [];
    }

    final queries = <String>[];

    // Strategy A: Dedicated title & author if "by" exists
    if (rawQuery.toLowerCase().contains(' by ')) {
      final parts = rawQuery.split(RegExp(r'\s+by\s+', caseSensitive: false));
      if (parts.length >= 2) {
        final t = parts[0]
            .replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '')
            .trim();
        final a = parts[1].replaceAll('.', '').trim();
        queries.add(
            'title=${Uri.encodeComponent(t)}&author=${Uri.encodeComponent(a)}&limit=15');
      }
    }

    // Strategy B: Subject/Genre fallback if the query looks like a genre
    if (_isLikelyGenreQuery(rawQuery)) {
      queries.add('subject=${Uri.encodeComponent(rawQuery)}&limit=15');
    }

    // Strategy C: Strip leading articles ("The ", "A ", "An ")
    final strippedArticle = rawQuery
        .replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '')
        .trim();
    queries.add('q=${Uri.encodeComponent(strippedArticle)}&limit=15');

    // Strategy D: General query
    queries.add('q=$cleanQuery&limit=15');

    for (final qParam in queries.take(3)) {
      try {
        final url = Uri.parse(
          'https://openlibrary.org/search.json?$qParam&fields=key,title,author_name,number_of_pages,number_of_pages_median,cover_i,first_publish_year,publisher,subject,subject_facet,isbn,description,ratings_average',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 429) {
          _openLibraryCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
          debugPrint('Open Library HTTP 429 Too Many Requests. Cooling down Open Library provider for 60s.');
          return [];
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final docs = (data['docs'] as List?) ?? [];

          if (docs.isNotEmpty) {
            final results = <BookSearchResult>[];
            for (final doc in docs) {
              final title = (doc['title'] as String?) ?? 'Unknown Title';
              final authorNames = (doc['author_name'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  ['Unknown Author'];
              final author = authorNames.first;
              final pages = (doc['number_of_pages_median'] as num?)?.toInt() ??
                  (doc['number_of_pages'] as num?)?.toInt() ??
                  0;

              final rawSubjects = [
                ...?((doc['subject'] as List?)?.map((e) => e.toString())),
                ...?((doc['subject_facet'] as List?)?.map((e) => e.toString())),
              ];
              final genres = GenreParser.parseRawGenres(rawSubjects);

              final coverId = doc['cover_i'];
              final coverUrl = coverId != null
                  ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
                  : null;

              final isbnList =
                  (doc['isbn'] as List?)?.map((e) => e.toString()).toList();
              final firstIsbn =
                  isbnList?.isNotEmpty == true ? isbnList!.first : null;
              final publishYear = doc['first_publish_year'] as int?;

              final publishers = (doc['publisher'] as List?)
                  ?.map((e) => e.toString())
                  .toList();
              final firstPublisher =
                  publishers?.isNotEmpty == true ? publishers!.first : null;

              String? olDesc;
              final rawDocDesc = doc['description'];
              if (rawDocDesc is String && rawDocDesc.trim().isNotEmpty) {
                olDesc = rawDocDesc;
              } else if (rawDocDesc is Map && rawDocDesc['value'] != null) {
                olDesc = rawDocDesc['value'].toString();
              }

              final rawAvgRating =
                  (doc['ratings_average'] as num?)?.toDouble() ?? 0.0;
              final tenStarRating = rawAvgRating > 0
                  ? convertFiveStarToTenStar(rawAvgRating)
                  : getBaselineRating('$title $author');

              results.add(
                BookSearchResult(
                  title: title,
                  author: author,
                  coverUrl: coverUrl,
                  totalPages: pages,
                  synopsis: _cleanSynopsis(olDesc),
                  isbn: firstIsbn,
                  publisher: firstPublisher,
                  publishedYear: publishYear,
                  subjects: genres,
                  rating: tenStarRating,
                ),
              );
            }
            return results;
          }
        }
      } on TimeoutException {
        debugPrint('Open Library search timed out for "$qParam". Skipping further queries.');
        break;
      } on SocketException {
        debugPrint('Open Library network unreachable for "$qParam". Skipping further queries.');
        break;
      } catch (e) {
        debugPrint('Open Library search exception for "$qParam": $e');
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // 4. GOOGLE BOOKS API (Strict 3.5s timeout & HTTP 429 graceful handling)
  // ---------------------------------------------------------------------------
  static Future<List<BookSearchResult>> _fetchGoogleBooks(
    String cleanQuery, [
    String? rawQuery,
  ]) async {
    if (isGoogleBooksRateLimited) {
      debugPrint('Google Books provider is in 429 cooldown. Skipping live fetch.');
      return [];
    }

    final effectiveRaw = rawQuery ?? Uri.decodeComponent(cleanQuery);
    final queries = <String>[];
    queries.add('q=$cleanQuery');

    // Parallel qualifier queries when specific tokens are detected
    if (effectiveRaw.toLowerCase().contains(' by ')) {
      final parts = effectiveRaw.split(RegExp(r'\s+by\s+', caseSensitive: false));
      if (parts.length >= 2) {
        final t = parts[0].trim();
        final a = parts[1].trim();
        if (t.isNotEmpty && a.isNotEmpty) {
          queries.add(
            'q=intitle:${Uri.encodeComponent(t)}+inauthor:${Uri.encodeComponent(a)}',
          );
        }
      }
    } else if (_isLikelyGenreQuery(effectiveRaw)) {
      queries.add('q=subject:${Uri.encodeComponent(effectiveRaw)}');
    }

    Future<List<BookSearchResult>> runSingleQuery(String qParam) async {
      try {
        final gUrl = Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?$qParam&maxResults=10',
        );
        final gRes = await http.get(
          gUrl,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 BookoraApp/1.0',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(milliseconds: 3500));

        if (gRes.statusCode == 429) {
          _googleBooksCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
          debugPrint(
              'Google Books API HTTP 429 RESOURCE_EXHAUSTED. Cooling down Google Books provider for 60s.');
          return [];
        }

        if (gRes.statusCode == 200) {
          final gData = jsonDecode(gRes.body) as Map<String, dynamic>;
          final items = (gData['items'] as List?) ?? [];

          if (items.isNotEmpty) {
            final results = <BookSearchResult>[];
            for (final item in items) {
              final vol = (item['volumeInfo'] as Map<String, dynamic>?) ?? {};
              final title = (vol['title'] as String?) ?? 'Unknown Title';
              final authors =
                  (vol['authors'] as List?)?.map((e) => e.toString()).toList() ??
                      ['Unknown Author'];
              final pages = (vol['pageCount'] as num?)?.toInt() ?? 0;
              final desc = _cleanSynopsis(vol['description'] as String?);

              final rawCategories = vol['categories'];
              final genres = GenreParser.parseRawGenres(rawCategories);

              final imageLinks = vol['imageLinks'] as Map<String, dynamic>?;
              var cover = imageLinks?['extraLarge'] as String? ??
                  imageLinks?['large'] as String? ??
                  imageLinks?['medium'] as String? ??
                  imageLinks?['thumbnail'] as String? ??
                  imageLinks?['smallThumbnail'] as String?;
              if (cover != null && cover.startsWith('http://')) {
                cover = cover.replaceFirst('http://', 'https://');
              }
              cover = cover?.replaceAll('&edge=curl', '');

              final publisher = vol['publisher'] as String?;
              final publishedDate = vol['publishedDate'] as String?;
              int? publishedYear;
              if (publishedDate != null && publishedDate.length >= 4) {
                publishedYear = int.tryParse(publishedDate.substring(0, 4));
              }

              final rawFiveStarRating =
                  (vol['averageRating'] as num?)?.toDouble() ?? 0.0;
              final tenStarRating = rawFiveStarRating > 0
                  ? convertFiveStarToTenStar(rawFiveStarRating)
                  : getBaselineRating('$title ${authors.join(' ')}');

              String? isbn;
              final industryIds = (vol['industryIdentifiers'] as List?) ?? [];
              for (final idObj in industryIds) {
                if (idObj is Map &&
                    (idObj['type'] == 'ISBN_13' || idObj['type'] == 'ISBN_10')) {
                  isbn = idObj['identifier'] as String?;
                  break;
                }
              }

              results.add(
                BookSearchResult(
                  title: title,
                  author: authors.first,
                  coverUrl: cover,
                  totalPages: pages,
                  synopsis: desc,
                  isbn: isbn,
                  publisher: publisher,
                  publishedYear: publishedYear,
                  subjects: genres,
                  rating: tenStarRating,
                ),
              );
            }
            return results;
          }
        }
      } on SocketException catch (e) {
        debugPrint('Google Books Network Socket Error: $e');
      } on TimeoutException catch (e) {
        debugPrint('Google Books Search timed out: $e');
      } catch (e) {
        debugPrint('Google Books Search Exception: $e');
      }
      return [];
    }

    if (queries.length == 1) {
      return runSingleQuery(queries.first);
    }

    final queryResponses = await Future.wait(queries.map(runSingleQuery));
    final mergedMap = <String, BookSearchResult>{};
    for (final list in queryResponses) {
      for (final item in list) {
        final key = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
        if (mergedMap.containsKey(key)) {
          mergedMap[key] = _mergeResults(mergedMap[key]!, item);
        } else {
          mergedMap[key] = item;
        }
      }
    }
    return mergedMap.values.toList();
  }

  // ---------------------------------------------------------------------------
  // 5. PROJECT GUTENBERG / GUTENDEX (Public-domain classics fallback)
  // ---------------------------------------------------------------------------
  static Future<List<BookSearchResult>> _fetchGutendex(String query) async {
    if (isGutendexRateLimited) {
      debugPrint('Gutendex provider is in 429 cooldown. Skipping live fetch.');
      return [];
    }

    try {
      final url = Uri.parse(
        'https://gutendex.com/books/?search=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 429) {
        _gutendexCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
        debugPrint('Gutendex HTTP 429 Too Many Requests. Cooling down Gutendex provider for 60s.');
        return [];
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['results'] as List?) ?? [];

        final results = <BookSearchResult>[];
        for (final item in items) {
          if (item is! Map) continue;

          final title = (item['title'] as String?) ?? 'Unknown Title';
          final authorsList = (item['authors'] as List?) ?? [];
          String author = 'Unknown Author';
          if (authorsList.isNotEmpty && authorsList.first is Map) {
            final rawName = (authorsList.first as Map)['name'] as String? ?? '';
            // Parse "Shelley, Mary Wollstonecraft" -> "Mary Wollstonecraft Shelley"
            if (rawName.contains(',')) {
              final parts = rawName.split(',');
              if (parts.length >= 2) {
                author = '${parts[1].trim()} ${parts[0].trim()}';
              } else {
                author = rawName.trim();
              }
            } else {
              author = rawName.trim();
            }
          }

          final formats = (item['formats'] as Map<String, dynamic>?) ?? {};
          final coverUrl = formats['image/jpeg'] as String?;

          final rawSubjects = (item['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final genres = GenreParser.parseRawGenres(rawSubjects);

          results.add(
            BookSearchResult(
              title: title,
              author: author,
              coverUrl: coverUrl,
              totalPages: 280, // Classic estimate
              subjects: genres,
              rating: getBaselineRating('$title $author'),
            ),
          );
        }
        return results;
      }
    } on TimeoutException {
      debugPrint('Gutendex search timed out.');
    } on SocketException {
      debugPrint('Gutendex network unreachable.');
    } catch (e) {
      debugPrint('Gutendex search exception: $e');
    }
    return [];
  }

  // ===========================================================================
  // ENRICHMENT & METADATA DETAILS
  // ===========================================================================

  /// Fetches rich book metadata including storyline (synopsis), hookline (tagline), blurb, actual total page count, and genre tags.
  static Future<BookEnrichedMetadata?> fetchEnrichedDetailsForBook({
    required String title,
    required String author,
    String? isbn,
    int existingPages = 0,
    String? existingSynopsis,
    List<String>? existingGenres,
  }) async {
    int resolvedPages = existingPages > 1 ? existingPages : 0;
    final existingLower = existingSynopsis?.trim().toLowerCase() ?? '';
    final isPlaceholder = existingLower.isEmpty ||
        existingLower.length < 50 ||
        existingLower.contains('a captivating story by') ||
        existingLower.contains('a captivating story of') ||
        existingLower.contains('imported from reading catalog') ||
        existingLower.contains('imported from csv') ||
        existingLower.contains('published by open library') ||
        existingLower.contains('no overview provided') ||
        existingLower.contains('no synopsis available');

    String? synopsis = (!isPlaceholder && existingSynopsis != null)
        ? existingSynopsis.trim()
        : null;

    final List<dynamic> collectedGenres = [];
    if (existingGenres != null &&
        existingGenres.isNotEmpty &&
        !(existingGenres.length == 1 &&
            existingGenres.first.toLowerCase() == 'general')) {
      collectedGenres.addAll(existingGenres);
    }

    final cleanTitle = title
        .replaceAll(RegExp(r'\s*[([][^()\[\]]*[)]]'), '')
        .split(':')[0]
        .trim();
    final cleanAuthor = (author.isEmpty ||
            author == 'Unknown Author' ||
            author.toLowerCase() == 'pdf document')
        ? ''
        : author.trim();

    if (synopsis == null || synopsis.length < 150 || resolvedPages <= 0 || collectedGenres.isEmpty) {
      // 1. Try Goodreads Auto-Complete for quick rich synopsis and series genres
      try {
        final grQuery = cleanAuthor.isNotEmpty ? '$cleanTitle by $cleanAuthor' : cleanTitle;
        final grResults = await _fetchGoodreads(grQuery);
        for (final gr in grResults) {
          if (gr.synopsis != null && gr.synopsis!.length > 120) {
            synopsis ??= gr.synopsis;
          }
          if (resolvedPages <= 0 && gr.totalPages > 0) {
            resolvedPages = gr.totalPages;
          }
          if (gr.subjects.isNotEmpty) {
            collectedGenres.addAll(gr.subjects);
          }
          if (synopsis != null && synopsis.length > 250 && resolvedPages > 0 && collectedGenres.isNotEmpty) break;
        }
      } catch (_) {}

      // 2. Try Google Books volumes search for rich, complete multi-paragraph synopsis
      if (!isGoogleBooksRateLimited && (synopsis == null || synopsis.length < 150 || resolvedPages <= 0 || collectedGenres.isEmpty)) {
        try {
          final query = (isbn != null && isbn.isNotEmpty)
              ? 'isbn:$isbn'
              : (cleanAuthor.isNotEmpty ? '$cleanTitle $cleanAuthor' : cleanTitle);
          final gUrl = Uri.parse(
            'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=3',
          );
          final gRes = await http.get(
            gUrl,
            headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
          ).timeout(const Duration(seconds: 4));
          if (gRes.statusCode == 429) {
            _googleBooksCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
            debugPrint('Google Books API HTTP 429 in enrichment. Cooling down Google Books provider for 60s.');
          } else if (gRes.statusCode == 200) {
            final gData = jsonDecode(gRes.body) as Map<String, dynamic>;
            final items = (gData['items'] as List?) ?? [];
            if (items.isNotEmpty) {
              for (final it in items) {
                final vol = (it['volumeInfo'] as Map<String, dynamic>?) ?? {};
                final pages = (vol['pageCount'] as num?)?.toInt() ?? 0;
                final desc = _cleanSynopsis(vol['description'] as String?);
                if (resolvedPages <= 0 && pages > 0) {
                  resolvedPages = pages;
                }
                if (desc != null && desc.length > 30 && (synopsis == null || desc.length > synopsis.length)) {
                  synopsis = desc;
                }
                if (vol['categories'] is List) {
                  collectedGenres.addAll(vol['categories'] as List);
                }
              }
            }
          }
        } catch (_) {}
      }

      // 3. Try Open Library search if still missing
      if (!isOpenLibraryRateLimited && (synopsis == null || resolvedPages <= 0 || collectedGenres.isEmpty)) {
        try {
          final q = cleanAuthor.isNotEmpty ? '$cleanTitle $cleanAuthor' : cleanTitle;
          final olUrl = Uri.parse(
            'https://openlibrary.org/search.json?q=${Uri.encodeComponent(q)}&limit=3',
          );
          final olRes = await http.get(
            olUrl,
            headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
          ).timeout(const Duration(seconds: 4));
          if (olRes.statusCode == 429) {
            _openLibraryCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
            debugPrint('Open Library HTTP 429 in enrichment. Cooling down Open Library provider for 60s.');
          } else if (olRes.statusCode == 200) {
            final olData = jsonDecode(olRes.body) as Map<String, dynamic>;
            final docs = (olData['docs'] as List?) ?? [];
            if (docs.isNotEmpty) {
              final doc = docs.first as Map<String, dynamic>;
              final pages = (doc['number_of_pages_median'] as num?)?.toInt() ??
                  (doc['number_of_pages'] as num?)?.toInt() ?? 0;
              if (resolvedPages <= 0 && pages > 0) {
                resolvedPages = pages;
              }
              if (doc['subject'] is List) {
                collectedGenres.addAll(doc['subject'] as List);
              }
              if (doc['subject_facet'] is List) {
                collectedGenres.addAll(doc['subject_facet'] as List);
              }
              if (synopsis == null || BookMetadataSanitizer.isTruncatedSynopsis(synopsis)) {
                final fetchedSyn = await fetchSynopsisForBook(
                  title: title,
                  author: author,
                  isbn: isbn,
                );
                if (fetchedSyn != null && fetchedSyn.isNotEmpty) {
                  if (synopsis == null ||
                      !BookMetadataSanitizer.isTruncatedSynopsis(fetchedSyn) ||
                      fetchedSyn.length > synopsis.length) {
                    synopsis = fetchedSyn;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    // Safety fallback: if synopsis is still null or truncated, trigger direct fetch
    if (synopsis == null || BookMetadataSanitizer.isTruncatedSynopsis(synopsis)) {
      try {
        final directSyn = await fetchSynopsisForBook(
          title: title,
          author: author,
          isbn: isbn,
        );
        if (directSyn != null && directSyn.isNotEmpty) {
          if (synopsis == null ||
              !BookMetadataSanitizer.isTruncatedSynopsis(directSyn) ||
              directSyn.length > synopsis.length) {
            synopsis = directSyn;
          }
        }
      } catch (_) {}
    }

    final finalDesc = (synopsis != null && synopsis.trim().isNotEmpty)
        ? synopsis
        : 'A captivating story of $title by $author.';

    // Extract Tagline and Blurb
    final taglineText = MetadataSanitizer.extractTagline(
          title: title,
          author: author,
          description: finalDesc,
        ) ??
        BookMetadataParser.extractBlurbTagline(
          title: title,
          author: author,
          description: finalDesc,
        );

    final blurbText = MetadataSanitizer.extractBlurb(
          title: title,
          author: author,
          description: finalDesc,
        ) ??
        BookMetadataParser.extractStoryline(
          title: title,
          author: author,
          description: finalDesc,
        );

    // Normalize or semantically infer genre tags
    var resolvedGenres = GenreParser.parseRawGenres(collectedGenres);
    if (resolvedGenres.isEmpty ||
        (resolvedGenres.length == 1 &&
            resolvedGenres.first.toLowerCase() == 'general')) {
      resolvedGenres = GenreParser.inferGenresFromContext(
        title: title,
        author: author,
        description: finalDesc,
      );
    }

    return BookEnrichedMetadata(
      synopsis: finalDesc,
      tagline: taglineText,
      blurb: blurbText,
      totalPages: resolvedPages > 0 ? resolvedPages : 300,
      genres: resolvedGenres,
    );
  }

  /// Fetches a verified, rich real book synopsis/overview from Open Library, Wikipedia, or Google Books.
  static Future<String?> fetchSynopsisForBook({
    required String title,
    required String author,
    String? isbn,
  }) async {
    final cacheKey = BookCacheService.getSynopsisCacheKey(
      title,
      author,
      isbn,
    );

    final cached = await BookCacheService.getCachedSynopsis(cacheKey);
    if (cached != null &&
        cached.isNotEmpty &&
        !BookMetadataSanitizer.isTruncatedSynopsis(cached)) {
      return cached;
    }

    final cleanTitle = title
        .replaceAll(RegExp(r'\s*[([][^()\[\]]*[)]]'), '')
        .split(':')[0]
        .trim();
    final cleanAuthor = (author.isEmpty ||
            author == 'Unknown Author' ||
            author.toLowerCase() == 'pdf document')
        ? ''
        : author.trim();

    // 1. Try Open Library direct ISBN endpoint
    if (isbn != null && isbn.trim().isNotEmpty) {
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');
      if (cleanIsbn.isNotEmpty) {
        try {
          final isbnUrl = Uri.parse(
            'https://openlibrary.org/api/books?bibkeys=ISBN:$cleanIsbn&jscmd=data&format=json',
          );
          final res = await http.get(
            isbnUrl,
            headers: {
              'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)',
            },
          ).timeout(const Duration(seconds: 7));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final bookKey = 'ISBN:$cleanIsbn';
            if (data.containsKey(bookKey)) {
              final item = data[bookKey] as Map<String, dynamic>;
              final desc = item['description'];
              final notes = item['notes'] as String?;
              String? rawDesc;
              if (desc is String) rawDesc = desc;
              if (desc is Map && desc['value'] != null) {
                rawDesc = desc['value'].toString();
              }
              rawDesc ??= notes;
              final clean = _cleanSynopsis(rawDesc);
              if (clean != null &&
                  clean.length > 50 &&
                  !BookMetadataSanitizer.isTruncatedSynopsis(clean)) {
                await BookCacheService.saveCachedSynopsis(cacheKey, clean);
                return clean;
              }
            }
          }
        } catch (_) {}
      }
    }

    // 2. Try Open Library Search & Work API (prioritize full work description)
    try {
      final q =
          cleanAuthor.isNotEmpty ? '$cleanTitle $cleanAuthor' : cleanTitle;
      final olUrl = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(q)}&fields=key,title,author_name,description&limit=3',
      );
      final olRes = await http.get(
        olUrl,
        headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
      ).timeout(const Duration(seconds: 7));
      if (olRes.statusCode == 200) {
        final olData = jsonDecode(olRes.body) as Map<String, dynamic>;
        final docs = (olData['docs'] as List?) ?? [];
        if (docs.isNotEmpty) {
          for (final doc in docs.take(3)) {
            // First Priority: Fetch work.json for the complete multi-paragraph synopsis
            final workKey = doc['key'] as String?;
            if (workKey != null && workKey.isNotEmpty) {
              try {
                final wUrl = Uri.parse('https://openlibrary.org$workKey.json');
                final wRes = await http.get(
                  wUrl,
                  headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
                ).timeout(const Duration(seconds: 7));
                if (wRes.statusCode == 200) {
                  final wData = jsonDecode(wRes.body) as Map<String, dynamic>;
                  final wDesc = wData['description'];
                  String? raw;
                  if (wDesc is String) raw = wDesc;
                  if (wDesc is Map && wDesc['value'] != null) {
                    raw = wDesc['value'].toString();
                  }
                  if (raw != null && raw.trim().isNotEmpty) {
                    final clean = _cleanSynopsis(raw);
                    if (clean != null &&
                        clean.length > 50 &&
                        !BookMetadataSanitizer.isTruncatedSynopsis(clean)) {
                      await BookCacheService.saveCachedSynopsis(cacheKey, clean);
                      return clean;
                    }
                  }
                }
              } catch (_) {}
            }

            // Second Priority: doc['description'] from search doc
            final desc = doc['description'];
            String? rawDesc;
            if (desc is String) rawDesc = desc;
            if (desc is Map && desc['value'] != null) {
              rawDesc = desc['value'].toString();
            }
            if (rawDesc != null && rawDesc.trim().isNotEmpty) {
              final clean = _cleanSynopsis(rawDesc);
              if (clean != null &&
                  clean.length > 50 &&
                  !BookMetadataSanitizer.isTruncatedSynopsis(clean)) {
                await BookCacheService.saveCachedSynopsis(cacheKey, clean);
                return clean;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. Try Wikipedia REST Summary API
    try {
      final wikiCandidates = [
        cleanTitle.replaceAll(' ', '_'),
        '${cleanTitle.replaceAll(' ', '_')}_(novel)',
        '${cleanTitle.replaceAll(' ', '_')}_(book)',
      ];
      for (final c in wikiCandidates) {
        try {
          final wUrl = Uri.parse(
            'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(c)}',
          );
          final wRes = await http.get(
            wUrl,
            headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
          ).timeout(const Duration(seconds: 6));
          if (wRes.statusCode == 200) {
            final wData = jsonDecode(wRes.body) as Map<String, dynamic>;
            final extract = wData['extract'] as String?;
            final type = wData['type'] as String?;
            if (type == 'standard' &&
                extract != null &&
                extract.length > 50 &&
                !extract.contains('may refer to:')) {
              final clean = _cleanSynopsis(extract);
              if (clean != null) {
                await BookCacheService.saveCachedSynopsis(cacheKey, clean);
                return clean;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // 4. Try Google Books fallback
    if (!isGoogleBooksRateLimited) {
      try {
        final query = (isbn != null && isbn.isNotEmpty)
            ? 'isbn:$isbn'
            : (cleanAuthor.isNotEmpty ? '$cleanTitle $cleanAuthor' : cleanTitle);
        final gUrl = Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=3',
        );
        final gRes = await http.get(
          gUrl,
          headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
        ).timeout(const Duration(seconds: 4));
        if (gRes.statusCode == 429) {
          _googleBooksCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
          debugPrint('Google Books API HTTP 429 in fetchSynopsisForBook. Cooling down 60s.');
        } else if (gRes.statusCode == 200) {
          final gData = jsonDecode(gRes.body) as Map<String, dynamic>;
          final items = (gData['items'] as List?) ?? [];
          if (items.isNotEmpty) {
            for (final it in items) {
              final vol = (it['volumeInfo'] as Map<String, dynamic>?) ?? {};
              final desc = vol['description'] as String?;
              final clean = _cleanSynopsis(desc);
              if (clean != null && clean.isNotEmpty) {
                await BookCacheService.saveCachedSynopsis(cacheKey, clean);
                return clean;
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // Search by ISBN Barcode
  static Future<BookSearchResult?> searchByIsbn(String isbn) async {
    var raw = isbn.trim();
    if (raw.toLowerCase().startsWith('isbn:')) {
      raw = raw.substring(5).trim();
    }
    final cleanIsbn = raw.replaceAll(RegExp(r'[^0-9X]'), '');
    if (cleanIsbn.isEmpty) return null;

    // 1. Open Library ISBN Data API Lookup
    try {
      final url = Uri.parse(
        'https://openlibrary.org/api/books?bibkeys=ISBN:$cleanIsbn&format=json&jscmd=data',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 429) {
        _openLibraryCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bookKey = 'ISBN:$cleanIsbn';
        if (data.containsKey(bookKey)) {
          final item = data[bookKey] as Map<String, dynamic>;
          final title = (item['title'] as String?) ?? 'Unknown Title';
          final authors =
              (item['authors'] as List?)
                  ?.map((a) => a['name'] as String)
                  .toList() ??
              ['Unknown Author'];
          final pages = (item['number_of_pages'] as num?)?.toInt() ?? 0;
          final cover =
              item['cover']?['large'] as String? ??
              item['cover']?['medium'] as String? ??
              item['cover']?['small'] as String?;
          final rawSubjects =
              (item['subjects'] as List?)
                  ?.map((s) => s['name'] as String)
                  .toList() ??
              [];
          final subjects = GenreParser.parseRawGenres(rawSubjects);
          final rawDesc = item['description'] ?? item['notes'];
          String? desc;
          if (rawDesc is String) desc = rawDesc;
          if (rawDesc is Map && rawDesc['value'] != null) {
            desc = rawDesc['value'].toString();
          }

          return BookSearchResult(
            title: title,
            author: authors.first,
            coverUrl: cover,
            totalPages: pages,
            synopsis: _cleanSynopsis(desc),
            isbn: cleanIsbn,
            subjects: subjects,
            rating: 9.4,
          );
        }
      }
    } catch (e) {
      debugPrint('OpenLibrary ISBN Data Search Exception: $e');
    }

    // 2. Google Books ISBN Lookup
    if (!isGoogleBooksRateLimited) {
      try {
        final gUrl = Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=isbn:$cleanIsbn',
        );
        final gRes = await http.get(
          gUrl,
          headers: {'User-Agent': 'BookoraApp/1.0 (contact@bookorareader.app)'},
        ).timeout(const Duration(seconds: 4));
        if (gRes.statusCode == 429) {
          _googleBooksCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
          debugPrint('Google Books API HTTP 429 in searchByIsbn. Cooling down 60s.');
        } else if (gRes.statusCode == 200) {
          final gData = jsonDecode(gRes.body) as Map<String, dynamic>;
          final items = (gData['items'] as List?) ?? [];
          if (items.isNotEmpty) {
            final vol = items.first['volumeInfo'] as Map<String, dynamic>;
            final title = (vol['title'] as String?) ?? 'Unknown Title';
            final authors =
                (vol['authors'] as List?)?.map((e) => e.toString()).toList() ??
                ['Unknown Author'];
            final pages = (vol['pageCount'] as num?)?.toInt() ?? 0;
            final desc = vol['description'] as String?;
            final imageLinks = vol['imageLinks'] as Map<String, dynamic>?;
            var cover =
                imageLinks?['extraLarge'] as String? ??
                imageLinks?['large'] as String? ??
                imageLinks?['medium'] as String? ??
                imageLinks?['thumbnail'] as String? ??
                imageLinks?['smallThumbnail'] as String?;
            if (cover != null && cover.startsWith('http://')) {
              cover = cover.replaceFirst('http://', 'https://');
            }
            final rawCategories = vol['categories'];
            final genres = GenreParser.parseRawGenres(rawCategories);

            final rawFiveStar = (vol['averageRating'] as num?)?.toDouble() ?? 0.0;
            final tenStar = rawFiveStar > 0
                ? convertFiveStarToTenStar(rawFiveStar)
                : getBaselineRating(title);

            return BookSearchResult(
              title: title,
              author: authors.first,
              coverUrl: cover,
              totalPages: pages,
              synopsis: desc,
              isbn: cleanIsbn,
              subjects: genres,
              rating: tenStar,
            );
          }
        }
      } catch (e) {
        debugPrint('Google Books ISBN lookup note: $e');
      }
    }

    return null;
  }

  static List<BookSearchResult> _getFallbackResults(String query) {
    final q = query.toLowerCase();
    final list = <BookSearchResult>[];

    if (q.contains('way') || q.contains('kings') || q.contains('sanderson')) {
      list.add(
        const BookSearchResult(
          title: 'The Way of Kings',
          author: 'Brandon Sanderson',
          totalPages: 1007,
          isbn: '9780765326355',
          publisher: 'Tor Books',
          publishedYear: 2010,
          subjects: [
            'Epic Fantasy',
            'High Fantasy',
            'Magic Systems',
            'Adventure',
          ],
          rating: 9.8,
        ),
      );
    }
    if (q.contains('dune') || q.contains('herbert') || q.contains('arrakis')) {
      list.add(
        const BookSearchResult(
          title: 'Dune',
          author: 'Frank Herbert',
          totalPages: 688,
          isbn: '9780441172719',
          publisher: 'Chilton Books',
          publishedYear: 1965,
          subjects: ['Sci-Fi', 'Space Opera', 'Philosophy', 'Classic'],
          rating: 9.4,
        ),
      );
    }
    if (q.contains('name') || q.contains('wind') || q.contains('rothfuss')) {
      list.add(
        const BookSearchResult(
          title: 'The Name of the Wind',
          author: 'Patrick Rothfuss',
          totalPages: 662,
          isbn: '9780756404741',
          publisher: 'DAW Books',
          publishedYear: 2007,
          subjects: ['Fantasy', 'Magic', 'Adventure', 'Music'],
          rating: 9.6,
        ),
      );
    }
    if (q.contains('pride') ||
        q.contains('prejudice') ||
        q.contains('austen')) {
      list.add(
        const BookSearchResult(
          title: 'Pride and Prejudice',
          author: 'Jane Austen',
          totalPages: 279,
          isbn: '9780141439518',
          publisher: 'Penguin Classics',
          publishedYear: 1813,
          subjects: ['Classics', 'Romance', 'Victorian Drama', 'Literature'],
          rating: 9.2,
        ),
      );
    }

    return list;
  }
}
