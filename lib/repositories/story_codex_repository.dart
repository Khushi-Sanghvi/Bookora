import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/story_codex.dart';
import '../services/story_codex_service.dart';
import 'book_repository.dart';

/// Single source of truth repository for Story Codex narrative metadata and enrichment.
abstract class StoryCodexRepository {
  Future<StoryCodex> getCodexForBook(Book book);
  Future<StoryCodex?> getCodexByBookId(String bookId);
  StoryCodex? getCachedCodexSync(String bookId);
  Future<StoryCodex?> getCachedCodex(String bookId);
  Future<void> saveCodexToCache(StoryCodex codex);
  Future<StoryCodex> enrichCodex(Book book);
}

/// Concrete implementation coordinating StoryCodexService, cache layers, and BookRepository.
class StoryCodexRepositoryImpl implements StoryCodexRepository {
  final BookRepository _bookRepository;

  StoryCodexRepositoryImpl({
    BookRepository? bookRepository,
  }) : _bookRepository = bookRepository ?? BookRepositoryImpl();

  @override
  Future<StoryCodex> getCodexForBook(Book book) async {
    return await StoryCodexService.getCodexForBook(book);
  }

  @override
  Future<StoryCodex?> getCodexByBookId(String bookId) async {
    // 1. Check synchronous and asynchronous cache first
    final cached = await StoryCodexService.getCachedCodex(bookId);
    if (cached != null) return cached;

    // 2. Fetch book from repository and enrich
    final book = await _bookRepository.getBookById(bookId);
    if (book != null) {
      return await StoryCodexService.getCodexForBook(book);
    }
    return null;
  }

  @override
  StoryCodex? getCachedCodexSync(String bookId) {
    return StoryCodexService.getCachedCodexSync(bookId);
  }

  @override
  Future<StoryCodex?> getCachedCodex(String bookId) async {
    return await StoryCodexService.getCachedCodex(bookId);
  }

  @override
  Future<void> saveCodexToCache(StoryCodex codex) async {
    await StoryCodexService.saveCodexToCache(codex);
  }

  @override
  Future<StoryCodex> enrichCodex(Book book) async {
    return await StoryCodexService.enrichCodex(book);
  }
}

/// Riverpod provider for StoryCodexRepository
final storyCodexRepositoryProvider = Provider<StoryCodexRepository>((ref) {
  final bookRepo = ref.watch(bookRepositoryProvider);
  return StoryCodexRepositoryImpl(bookRepository: bookRepo);
});
