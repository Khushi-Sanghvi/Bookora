import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import 'book_provider.dart';
import '../services/reading_streak_service.dart';
import '../services/reading_streak_calculator.dart';

// Backward compatibility alias
typedef StreakInfo = ReadingStreakData;

final streakProvider = Provider<ReadingStreakData>((ref) {
  final bookState = ref.watch(bookProvider);
  final books = bookState.maybeWhen(
    data: (list) => list,
    orElse: () => <Book>[],
  );

  return ReadingStreakService.computeStreakFromBooks(books);
});

StreakInfo calculateStreak(List<Book> books) {
  return ReadingStreakService.computeStreakFromBooks(books);
}
