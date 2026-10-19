import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:between_world/models/models.dart';
import 'package:between_world/services/book_search_service.dart';
import 'package:between_world/repositories/repositories.dart';
import 'package:between_world/providers/book_provider.dart';
import 'package:between_world/providers/story_codex_provider.dart';

class MockBookRepository implements BookRepository {
  final Map<String, Book> _store = {};

  @override
  Future<List<Book>> getAllBooks({bool forceRefresh = false}) async {
    return _store.values.toList();
  }

  @override
  Future<Book?> getBookById(String id) async {
    return _store[id];
  }

  @override
  Future<void> insertBook(Book book) async {
    _store[book.id] = book;
  }

  @override
  Future<void> insertBooks(List<Book> books) async {
    for (final b in books) {
      _store[b.id] = b;
    }
  }

  @override
  Future<void> updateBook(Book book) async {
    _store[book.id] = book;
  }

  @override
  Future<void> deleteBook(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> insertJournalEntry(String bookId, JournalEntry entry) async {
    final book = _store[bookId];
    if (book != null) {
      _store[bookId] = book.copyWith(
        journalEntries: [...book.journalEntries, entry],
      );
    }
  }

  @override
  Future<void> insertQuote(String bookId, QuoteAnnotation quote) async {
    final book = _store[bookId];
    if (book != null) {
      _store[bookId] = book.copyWith(
        quotes: [...book.quotes, quote],
      );
    }
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
    for (final key in _store.keys) {
      final book = _store[key]!;
      _store[key] = book.copyWith(
        quotes: book.quotes.where((q) => q.id != quoteId).toList(),
      );
    }
  }

  @override
  Future<void> markBookCompleted({
    required String bookId,
    DateTime? customFinishDate,
  }) async {
    final finishDate = customFinishDate ?? DateTime(2026, 10, 19);
    final book = _store[bookId];
    if (book != null) {
      _store[bookId] = book.copyWith(
        status: ReadingStatus.completed,
        startDate: book.startDate ?? finishDate,
        finishDate: finishDate,
        endDate: finishDate,
        currentPage: book.totalPages,
      );
    }
  }

  @override
  Future<List<BookSearchResult>> searchOnline(
    String query, {
    bool forceRefresh = false,
  }) async {
    return [];
  }

  @override
  Future<String> getDatabasePath() async => '/mock/path/bookora.db';

  @override
  Future<void> closeDatabase() async {}

  @override
  Future<void> wipeAllData() async {
    _store.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookRepository & BookNotifier MVVM Decoupling Tests', () {
    test('BookNotifier delegates CRUD actions to BookRepository', () async {
      final mockRepo = MockBookRepository();
      final notifier = BookNotifier(mockRepo);

      // 1. Initial empty state
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.value, isEmpty);

      // 2. Add Book
      final testBook = Book(
        id: 'book-101',
        title: 'The Secret History',
        author: 'Donna Tartt',
        description: 'Dark academia classic',
        coverUrl: '',
        totalPages: 559,
        currentPage: 120,
        status: ReadingStatus.currentlyReading,
      );
      await notifier.addBook(testBook);

      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.title, 'The Secret History');

      // 3. Mark Completed
      await notifier.markBookCompleted(
        bookId: 'book-101',
        customFinishDate: DateTime(2026, 10, 19),
      );
      final completed = notifier.state.value!.first;
      expect(completed.status, ReadingStatus.completed);
      expect(completed.currentPage, 559);
      expect(completed.finishDate, DateTime(2026, 10, 19));

      // 4. Add Journal Entry
      final journal = JournalEntry.create(50, reflection: 'Exciting twist');
      await notifier.addJournalEntry('book-101', journal);
      expect(notifier.state.value!.first.journalEntries.length, 1);

      // 5. Delete Book
      await notifier.deleteBook('book-101');
      expect(notifier.state.value, isEmpty);
    });

    test('Riverpod container correctly binds repository to ViewModel', () async {
      final container = ProviderContainer(
        overrides: [
          bookRepositoryProvider.overrideWithValue(MockBookRepository()),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(bookRepositoryProvider);
      expect(repo, isA<MockBookRepository>());

      final bookNotifier = container.read(bookProvider.notifier);
      await bookNotifier.addBook(Book(
        id: 'book-202',
        title: 'Babel',
        author: 'R.F. Kuang',
        description: 'An Arcane History',
        coverUrl: '',
        totalPages: 544,
      ));

      final books = container.read(bookProvider).value!;
      expect(books.length, 1);
      expect(books.first.id, 'book-202');
    });
  });

  group('StoryCodexRepository MVVM Tests', () {
    test('StoryCodexRepository coordinates fallback generation and caching', () async {
      final mockRepo = MockBookRepository();
      final codexRepo = StoryCodexRepositoryImpl(bookRepository: mockRepo);

      final book = Book(
        id: 'codex-test-1',
        title: 'Ninth House',
        author: 'Leigh Bardugo',
        description: 'Galaxy Alex Stern is the most unlikely member of Yale freshman class. Galaxy can see ghosts.',
        coverUrl: '',
        totalPages: 480,
      );
      await mockRepo.insertBook(book);

      final codex = await codexRepo.getCodexForBook(book);
      expect(codex.bookId, 'codex-test-1');
      expect(codex.tropes, isNotEmpty);
      expect(codex.characters, isNotEmpty);

      // Synchronous peek
      final peeked = codexRepo.getCachedCodexSync('codex-test-1');
      expect(peeked != null, isTrue);
      expect(peeked!.bookId, 'codex-test-1');
    });

    test('storyCodexProvider resolves via storyCodexRepositoryProvider', () async {
      final container = ProviderContainer(
        overrides: [
          bookRepositoryProvider.overrideWithValue(MockBookRepository()),
        ],
      );
      addTearDown(container.dispose);

      final book = Book(
        id: 'codex-prov-1',
        title: 'Piranesi',
        author: 'Susanna Clarke',
        description: 'Piranesi lives in the House. Perhaps he has always lived there.',
        coverUrl: '',
        totalPages: 245,
      );

      final codex = await container.read(storyCodexProvider(book).future);
      expect(codex.bookId, 'codex-prov-1');
      expect(codex.setting, isNotEmpty);
    });
  });

  group('UserSettingsRepository MVVM Tests', () {
    test('UserSettingsRepository manages Reading Goals and CSV export/import', () async {
      final userSettingsRepo = UserSettingsRepositoryImpl();

      // Goal target
      await userSettingsRepo.setReadingGoal(35);
      final goal = await userSettingsRepo.getReadingGoal();
      expect(goal, 35);

      await userSettingsRepo.resetReadingGoal();
      final resetGoal = await userSettingsRepo.getReadingGoal();
      expect(resetGoal, 25);

      // CSV Export
      final books = [
        Book(
          id: 'csv-1',
          title: 'The Picture of Dorian Gray',
          author: 'Oscar Wilde',
          description: 'A philosophical gothic novel',
          coverUrl: '',
          totalPages: 254,
          status: ReadingStatus.finished,
          overallRating: 9.6,
        ),
      ];
      final csv = userSettingsRepo.exportBooksToCsv(books);
      expect(csv.contains('The Picture of Dorian Gray'), isTrue);
      expect(csv.contains('Oscar Wilde'), isTrue);

      // CSV Parse
      final parsed = userSettingsRepo.parseCsv(csv);
      expect(parsed.length, 1);
      expect(parsed.first.title, 'The Picture of Dorian Gray');
      expect(parsed.first.author, 'Oscar Wilde');
    });
  });
}
