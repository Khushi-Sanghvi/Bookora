import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../models/quote_annotation.dart';
import '../services/book_cache_service.dart';
import '../services/book_search_service.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';

/// Single source of truth repository for Book entities and persistence.
abstract class BookRepository {
  Future<List<Book>> getAllBooks({bool forceRefresh = false});
  Future<Book?> getBookById(String id);
  Future<void> insertBook(Book book);
  Future<void> insertBooks(List<Book> books);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
  Future<void> insertJournalEntry(String bookId, JournalEntry entry);
  Future<void> insertQuote(String bookId, QuoteAnnotation quote);
  Future<void> deleteQuote(String quoteId);
  Future<void> markBookCompleted({
    required String bookId,
    DateTime? customFinishDate,
  });
  Future<List<BookSearchResult>> searchOnline(
    String query, {
    bool forceRefresh = false,
  });
  Future<String> getDatabasePath();
  Future<void> closeDatabase();
  Future<void> wipeAllData();
}

/// Concrete implementation coordinating SQLite database, memory/LRU caches, and search services.
class BookRepositoryImpl implements BookRepository {
  final DatabaseService _db;
  final CacheService _cache;

  BookRepositoryImpl({
    DatabaseService? databaseService,
    CacheService? cacheService,
  })  : _db = databaseService ?? DatabaseService(),
        _cache = cacheService ?? CacheService();

  @override
  Future<List<Book>> getAllBooks({bool forceRefresh = false}) async {
    final books = await _db.getAllBooks();
    for (final b in books) {
      _cache.cacheBook(b);
    }
    return books;
  }

  @override
  Future<Book?> getBookById(String id) async {
    // 1. Cache-first lookup
    final cached = _cache.getCachedBook(id);
    if (cached != null) return cached;

    // 2. Fall back to local SQLite database
    final book = await _db.getBookById(id);
    if (book != null) {
      _cache.cacheBook(book);
    }
    return book;
  }

  @override
  Future<void> insertBook(Book book) async {
    _cache.cacheBook(book);
    await _db.insertBook(book);
  }

  @override
  Future<void> insertBooks(List<Book> books) async {
    if (books.isEmpty) return;
    for (final b in books) {
      _cache.cacheBook(b);
    }
    await _db.insertBooks(books);
  }

  @override
  Future<void> updateBook(Book book) async {
    _cache.cacheBook(book);
    await _db.updateBook(book);
  }

  @override
  Future<void> deleteBook(String id) async {
    _cache.removeBook(id);
    await _db.deleteBook(id);
  }

  @override
  Future<void> insertJournalEntry(String bookId, JournalEntry entry) async {
    await _db.insertJournalEntry(bookId, entry);
    final updated = await _db.getBookById(bookId);
    if (updated != null) {
      _cache.cacheBook(updated);
    }
  }

  @override
  Future<void> insertQuote(String bookId, QuoteAnnotation quote) async {
    await _db.insertQuote(bookId, quote);
    final updated = await _db.getBookById(bookId);
    if (updated != null) {
      _cache.cacheBook(updated);
    }
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
    await _db.deleteQuote(quoteId);
  }

  @override
  Future<void> markBookCompleted({
    required String bookId,
    DateTime? customFinishDate,
  }) async {
    final finishDate = customFinishDate ?? DateTime.now();

    Book? book = await getBookById(bookId);
    if (book == null) return;

    final effectiveStartDate = book.startDate ?? finishDate;
    final totalPages = book.totalPages > 0 ? book.totalPages : 1;

    final updatedBook = book.copyWith(
      status: ReadingStatus.completed,
      startDate: effectiveStartDate,
      finishDate: finishDate,
      endDate: finishDate,
      currentPage: totalPages,
    );

    await updateBook(updatedBook);
  }

  @override
  Future<List<BookSearchResult>> searchOnline(
    String query, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = BookCacheService.getMemoryCachedSearchResults(query);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }
    final results = await BookSearchService.searchBooks(query);
    BookCacheService.saveMemorySearchResults(query, results);
    return results;
  }

  @override
  Future<String> getDatabasePath() => _db.getDatabasePath();

  @override
  Future<void> closeDatabase() => _db.closeDatabase();

  @override
  Future<void> wipeAllData() async {
    _cache.clear();
    await _db.wipeAllData();
  }
}

/// Riverpod provider for BookRepository
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl(
    databaseService: DatabaseService(),
    cacheService: CacheService(),
  );
});
