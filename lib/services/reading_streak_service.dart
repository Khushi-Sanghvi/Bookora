import '../models/book.dart';
import 'reading_streak_calculator.dart';

class ReadingStreakService {
  /// Extracts qualified reading session dates from books and computes streak data
  static ReadingStreakData computeStreakFromBooks(List<Book> books) {
    final Set<DateTime> qualifiedDates = {};

    for (var book in books) {
      // 1. Journal entries where pagesRead > 0
      for (var entry in book.journalEntries) {
        if (entry.pagesRead > 0) {
          qualifiedDates.add(entry.date);
        }
      }

      // 2. Book start dates
      if (book.startDate != null) {
        qualifiedDates.add(book.startDate!);
      }

      // 3. Book finish dates
      if (book.finishDate != null) {
        qualifiedDates.add(book.finishDate!);
      }

      // 4. If current page > 0 and progress is active, ensure today or recent date is qualified if logged
      if (book.currentPage > 0 && book.startDate != null) {
        qualifiedDates.add(book.startDate!);
      }
    }

    return ReadingStreakCalculator.calculate(qualifiedDates: qualifiedDates);
  }
}
