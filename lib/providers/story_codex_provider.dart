import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/story_codex.dart';
import '../repositories/story_codex_repository.dart';

export '../repositories/story_codex_repository.dart'
    show storyCodexRepositoryProvider, StoryCodexRepository, StoryCodexRepositoryImpl;

/// Reactive provider fetching or enriching StoryCodex for a given Book model via StoryCodexRepository
final storyCodexProvider = FutureProvider.family<StoryCodex, Book>((ref, book) async {
  final repository = ref.watch(storyCodexRepositoryProvider);
  return await repository.getCodexForBook(book);
});

/// Reactive provider fetching or enriching StoryCodex by bookId via StoryCodexRepository
final storyCodexByIdProvider = FutureProvider.family<StoryCodex?, String>((ref, bookId) async {
  final repository = ref.watch(storyCodexRepositoryProvider);
  return await repository.getCodexByBookId(bookId);
});
