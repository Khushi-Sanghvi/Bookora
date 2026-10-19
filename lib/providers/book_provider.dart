import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../models/quote_annotation.dart';
import '../repositories/book_repository.dart';
import '../services/database_service.dart';

export '../repositories/book_repository.dart'
    show bookRepositoryProvider, BookRepository, BookRepositoryImpl;

final databaseServiceProvider = Provider((ref) => DatabaseService());

class BookNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRepository _repository;

  BookNotifier(dynamic repoOrDb)
      : _repository = repoOrDb is BookRepository
            ? repoOrDb
            : BookRepositoryImpl(databaseService: repoOrDb as DatabaseService?),
        super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await _repository.getAllBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshBooks() => loadBooks();

  Future<void> addBook(Book book) async {
    await _repository.insertBook(book);
    await loadBooks();
  }

  Future<void> addBooks(List<Book> books) async {
    if (books.isEmpty) return;
    await _repository.insertBooks(books);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _repository.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _repository.deleteBook(id);
    await loadBooks();
  }

  Future<void> addJournalEntry(String bookId, JournalEntry entry) async {
    await _repository.insertJournalEntry(bookId, entry);
    await loadBooks();
  }

  Future<void> addQuote(String bookId, QuoteAnnotation quote) async {
    await _repository.insertQuote(bookId, quote);
    await loadBooks();
  }

  Future<void> deleteQuote(String bookId, String quoteId) async {
    await _repository.deleteQuote(quoteId);
    await loadBooks();
  }

  /// Centralized Book Completion Service Method
  Future<void> markBookCompleted({
    required String bookId,
    DateTime? customFinishDate,
  }) async {
    await _repository.markBookCompleted(
      bookId: bookId,
      customFinishDate: customFinishDate,
    );
    await loadBooks();
  }
}

final bookProvider =
    StateNotifierProvider<BookNotifier, AsyncValue<List<Book>>>((ref) {
      final repository = ref.watch(bookRepositoryProvider);
      return BookNotifier(repository);
    });

/// Alias for bookProvider for semantic clarity and API compatibility
final booksProvider = bookProvider;

/// Single book detail provider for reactive state binding by book id
final bookDetailProvider = Provider.family<Book?, String>((ref, bookId) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.whenOrNull(
    data: (books) {
      final idx = books.indexWhere((b) => b.id == bookId);
      return idx != -1 ? books[idx] : null;
    },
  );
});

enum ShelfCategory {
  all,
  reading,
  toRead,
  finished,
  abandoned,
  wishlist,
  favorites,
}

final shelfCategoryProvider = StateProvider<ShelfCategory>(
  (ref) => ShelfCategory.all,
);
final searchQueryProvider = StateProvider<String>((ref) => '');

enum ProgressFilterRange { all, notStarted, inProgress, completed }

enum BookSortOption {
  recentlyAdded,
  recentlyUpdated,
  titleAZ,
  authorAZ,
  progress,
}

class AdvancedFilterState {
  final Set<BookFormat> formats;
  final ProgressFilterRange progressRange;
  final Set<String> genres;
  final double minRating;
  final BookSortOption sortOption;

  const AdvancedFilterState({
    this.formats = const {},
    this.progressRange = ProgressFilterRange.all,
    this.genres = const {},
    this.minRating = 0.0,
    this.sortOption = BookSortOption.recentlyAdded,
  });

  bool get isActive =>
      formats.isNotEmpty ||
      progressRange != ProgressFilterRange.all ||
      genres.isNotEmpty ||
      minRating > 0.0 ||
      sortOption != BookSortOption.recentlyAdded;

  AdvancedFilterState copyWith({
    Set<BookFormat>? formats,
    ProgressFilterRange? progressRange,
    Set<String>? genres,
    double? minRating,
    BookSortOption? sortOption,
  }) {
    return AdvancedFilterState(
      formats: formats ?? this.formats,
      progressRange: progressRange ?? this.progressRange,
      genres: genres ?? this.genres,
      minRating: minRating ?? this.minRating,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class AdvancedFilterNotifier extends StateNotifier<AdvancedFilterState> {
  AdvancedFilterNotifier() : super(const AdvancedFilterState());

  void setFilter(AdvancedFilterState filter) {
    state = filter;
  }

  void reset() {
    state = const AdvancedFilterState();
  }
}

final advancedFilterProvider =
    StateNotifierProvider<AdvancedFilterNotifier, AdvancedFilterState>((ref) {
      return AdvancedFilterNotifier();
    });

final filteredBookProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final bookState = ref.watch(bookProvider);
  final shelfCategory = ref.watch(shelfCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final advFilter = ref.watch(advancedFilterProvider);

  return bookState.whenData((books) {
    var result = List<Book>.from(books);

    // 1. Shelf Category Filter (All, Reading, To Read, Finished, Abandoned, Wishlist, Favorites)
    switch (shelfCategory) {
      case ShelfCategory.all:
        break;
      case ShelfCategory.reading:
        result = result
            .where((b) => b.status == ReadingStatus.currentlyReading)
            .toList();
        break;
      case ShelfCategory.toRead:
        result = result.where((b) => b.status == ReadingStatus.toRead).toList();
        break;
      case ShelfCategory.finished:
        result = result
            .where((b) => b.status == ReadingStatus.finished)
            .toList();
        break;
      case ShelfCategory.abandoned:
        result = result
            .where((b) => b.status == ReadingStatus.abandoned)
            .toList();
        break;
      case ShelfCategory.wishlist:
        result = result
            .where((b) => b.status == ReadingStatus.wishlist)
            .toList();
        break;
      case ShelfCategory.favorites:
        result = result.where((b) => b.isFavorite).toList();
        break;
    }

    // 2. Search Query Filter
    if (query.isNotEmpty) {
      result = result
          .where(
            (b) =>
                b.title.toLowerCase().contains(query) ||
                b.author.toLowerCase().contains(query) ||
                b.genres.any((g) => g.toLowerCase().contains(query)),
          )
          .toList();
    }

    // 3. Format Filter
    if (advFilter.formats.isNotEmpty) {
      result = result
          .where((b) => advFilter.formats.contains(b.format))
          .toList();
    }

    // 4. Progress Range Filter
    if (advFilter.progressRange == ProgressFilterRange.notStarted) {
      result = result.where((b) => b.currentPage == 0).toList();
    } else if (advFilter.progressRange == ProgressFilterRange.inProgress) {
      result = result
          .where((b) => b.currentPage > 0 && b.progress < 1.0)
          .toList();
    } else if (advFilter.progressRange == ProgressFilterRange.completed) {
      result = result
          .where((b) => b.status == ReadingStatus.finished || b.progress >= 1.0)
          .toList();
    }

    // 5. Genre Filter
    if (advFilter.genres.isNotEmpty) {
      result = result
          .where((b) => b.genres.any((g) => advFilter.genres.contains(g)))
          .toList();
    }

    // 6. Rating Filter
    if (advFilter.minRating > 0.0) {
      result = result
          .where((b) => b.overallRating >= advFilter.minRating)
          .toList();
    }

    // 7. Sorting
    switch (advFilter.sortOption) {
      case BookSortOption.recentlyAdded:
        break;
      case BookSortOption.recentlyUpdated:
        result.sort((a, b) {
          final dateA = a.finishDate ?? a.startDate ?? DateTime(2020);
          final dateB = b.finishDate ?? b.startDate ?? DateTime(2020);
          return dateB.compareTo(dateA);
        });
        break;
      case BookSortOption.titleAZ:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case BookSortOption.authorAZ:
        result.sort((a, b) => a.author.compareTo(b.author));
        break;
      case BookSortOption.progress:
        result.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }

    return result;
  });
});

final bookFilterProvider = StateProvider<ReadingStatus?>((ref) => null);
