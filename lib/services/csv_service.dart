import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/enums.dart';

class CsvService {
  static String exportBooksToCsv(List<Book> books) {
    final buffer = StringBuffer();
    // Goodreads-standard CSV header
    buffer.writeln(
      'Book Id,Title,Author,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies',
    );

    for (final book in books) {
      final shelf = _statusToShelf(book.status);
      final title = _escapeCsv(book.title);
      final author = _escapeCsv(book.author);
      final pages = book.totalPages;
      final rating = book.overallRating > 0
          ? (book.overallRating / 2.0).toStringAsFixed(1)
          : '';
      final dateAdded = book.startDate != null
          ? book.startDate!.toIso8601String().substring(0, 10)
          : '';
      final dateRead = book.finishDate != null
          ? book.finishDate!.toIso8601String().substring(0, 10)
          : '';

      buffer.writeln(
        '${book.id},$title,$author,,,,, $rating,,Paperback,$pages,,,,$dateRead,$dateAdded,$shelf,$shelf,$shelf,,,,1,,,0',
      );
    }

    return buffer.toString();
  }

  static List<Book> parseCsv(
    String csvContent, {
    String? titleCol,
    String? authorCol,
    String? genreCol,
    String? pagesCol,
  }) {
    final books = <Book>[];
    final lines = csvContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return books;

    // Header index discovery
    final headerRow = _parseCsvRow(
      lines.first,
    ).map((h) => h.toLowerCase().trim()).toList();

    int titleIndex = -1;
    if (titleCol != null && titleCol.trim().isNotEmpty && titleCol != 'Default / Auto') {
      titleIndex = headerRow.indexOf(titleCol.toLowerCase().trim());
    }
    if (titleIndex == -1) {
      titleIndex = headerRow.indexWhere(
        (h) => h == 'title' || h.startsWith('title'),
      );
    }

    int authorIndex = -1;
    if (authorCol != null && authorCol.trim().isNotEmpty && authorCol != 'Default / Auto') {
      authorIndex = headerRow.indexOf(authorCol.toLowerCase().trim());
    }
    if (authorIndex == -1) {
      authorIndex = headerRow.indexWhere(
        (h) => h == 'author' || h == 'authors' || h.startsWith('author'),
      );
    }

    int pagesIndex = -1;
    if (pagesCol != null && pagesCol.trim().isNotEmpty && pagesCol != 'Default / Auto') {
      pagesIndex = headerRow.indexOf(pagesCol.toLowerCase().trim());
    }
    if (pagesIndex == -1) {
      pagesIndex = headerRow.indexWhere((h) => h.contains('page'));
    }

    // Priority shelf detection for Goodreads (Exclusive Shelf), StoryGraph (Read Status), and Bookwyrm
    int shelfIndex = headerRow.indexWhere(
      (h) => h.contains('exclusive shelf') || h.contains('read status'),
    );
    if (shelfIndex == -1) {
      shelfIndex = headerRow.indexWhere(
        (h) => h.contains('shelf') || h.contains('status'),
      );
    }

    final ratingIndex = headerRow.indexWhere(
      (h) =>
          h.contains('my rating') ||
          h.contains('star rating') ||
          (h.contains('rating') &&
              !h.contains('avg') &&
              !h.contains('average')),
    );
    final formatIndex = headerRow.indexWhere(
      (h) => h.contains('format') || h.contains('binding'),
    );
    final dateReadIndex = headerRow.indexWhere(
      (h) =>
          h.contains('date read') ||
          h.contains('last date read') ||
          h.contains('dates read'),
    );
    final dateAddedIndex = headerRow.indexWhere(
      (h) => h.contains('date added') || h.contains('added'),
    );

    int genresIndex = -1;
    if (genreCol != null && genreCol.trim().isNotEmpty && genreCol != 'Default / Auto') {
      genresIndex = headerRow.indexOf(genreCol.toLowerCase().trim());
    }
    if (genresIndex == -1) {
      genresIndex = headerRow.indexWhere(
        (h) =>
            h.contains('bookshelves') ||
            h.contains('tags') ||
            h.contains('genres'),
      );
    }

    final reviewIndex = headerRow.indexWhere(
      (h) =>
          h.contains('my review') ||
          h.contains('review') ||
          h.contains('private notes'),
    );
    final isbnIndex = headerRow.indexWhere(
      (h) => h == 'isbn' || h == 'isbn/uid' || h == 'isbn10',
    );
    final isbn13Index = headerRow.indexWhere(
      (h) => h == 'isbn13' || h.contains('isbn13') || h.contains('isbn 13'),
    );
    final coverIndex = headerRow.indexWhere(
      (h) => h.contains('cover') || h.contains('image'),
    );

    if (titleIndex == -1) return books;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final row = _parseCsvRow(line);
      if (row.length <= titleIndex) continue;

      final title = row[titleIndex].trim();
      if (title.isEmpty) continue;

      final author = authorIndex != -1 && row.length > authorIndex
          ? row[authorIndex].trim()
          : 'Unknown Author';
      final pages = pagesIndex != -1 && row.length > pagesIndex
          ? int.tryParse(row[pagesIndex].replaceAll(RegExp(r'[^0-9]'), '')) ??
                250
          : 250;
      final shelfStr = shelfIndex != -1 && row.length > shelfIndex
          ? row[shelfIndex].toLowerCase().trim()
          : '';

      ReadingStatus status = ReadingStatus.toRead;
      if (shelfStr.contains('abandon') ||
          shelfStr.contains('did-not-finish') ||
          shelfStr.contains('stopped-reading') ||
          shelfStr.contains('dnf')) {
        status = ReadingStatus.abandoned;
      } else if (shelfStr.contains('currently') || shelfStr.contains('reading')) {
        status = ReadingStatus.currentlyReading;
      } else if (shelfStr.contains('to-read') ||
          shelfStr.contains('want-to-read') ||
          shelfStr.contains('to read')) {
        status = ReadingStatus.toRead;
      } else if (shelfStr.contains('read') || shelfStr.contains('finished')) {
        status = ReadingStatus.finished;
      }

      // Rating (Convert 5-star to Bookora 10-star system)
      double rating = 0.0;
      if (ratingIndex != -1 && row.length > ratingIndex) {
        final rVal = double.tryParse(
          row[ratingIndex].replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        if (rVal != null && rVal > 0) {
          rating = rVal <= 5.0
              ? (rVal * 2.0).clamp(0.0, 10.0)
              : rVal.clamp(0.0, 10.0);
        }
      }

      // Format
      BookFormat format = BookFormat.paperback;
      if (formatIndex != -1 && row.length > formatIndex) {
        final fStr = row[formatIndex].toLowerCase();
        if (fStr.contains('audio')) {
          format = BookFormat.audiobook;
        } else if (fStr.contains('epub') ||
            fStr.contains('ebook') ||
            fStr.contains('kindle') ||
            fStr.contains('digital')) {
          format = BookFormat.epub;
        } else if (fStr.contains('pdf')) {
          format = BookFormat.pdf;
        }
      }

      // Dates
      DateTime? finishDate;
      if (dateReadIndex != -1 && row.length > dateReadIndex) {
        finishDate = _parseDate(row[dateReadIndex]);
      }
      DateTime? startDate;
      if (dateAddedIndex != -1 && row.length > dateAddedIndex) {
        startDate = _parseDate(row[dateAddedIndex]);
      }
      startDate ??= (status == ReadingStatus.finished && finishDate != null
          ? finishDate
          : DateTime.now());
      if (status == ReadingStatus.finished && finishDate == null) {
        finishDate = startDate;
      }

      // Genres / Bookshelves
      List<String> genres = ['General'];
      if (genresIndex != -1 && row.length > genresIndex) {
        final rawTags = row[genresIndex]
            .split(RegExp(r'[,;]'))
            .map((s) => s.trim())
            .where(
              (s) =>
                  s.isNotEmpty &&
                  !s.toLowerCase().contains('read') &&
                  !s.toLowerCase().contains('shelf') &&
                  !s.toLowerCase().contains('owned'),
            )
            .toList();
        if (rawTags.isNotEmpty) {
          genres = rawTags;
        }
      }

      // Description / Review
      String description = 'Imported from reading catalog CSV.';
      if (reviewIndex != -1 &&
          row.length > reviewIndex &&
          row[reviewIndex].trim().isNotEmpty) {
        description = row[reviewIndex].trim();
      }

      // Cover & ISBN resolution
      String coverUrl = '';
      if (coverIndex != -1 && row.length > coverIndex) {
        final cVal = row[coverIndex].trim();
        if (cVal.startsWith('http://') || cVal.startsWith('https://')) {
          coverUrl = cVal;
        }
      }

      if (coverUrl.isEmpty) {
        String rawIsbn = '';
        if (isbn13Index != -1 && row.length > isbn13Index) {
          rawIsbn = row[isbn13Index].trim();
        }
        if ((rawIsbn.isEmpty || rawIsbn.length < 9) &&
            isbnIndex != -1 &&
            row.length > isbnIndex) {
          rawIsbn = row[isbnIndex].trim();
        }

        final cleanIsbn =
            rawIsbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
        if (cleanIsbn.length == 10 || cleanIsbn.length == 13) {
          coverUrl = 'https://covers.openlibrary.org/b/isbn/$cleanIsbn-L.jpg?default=false';
        }
      }

      books.add(
        Book(
          id: const Uuid().v4(),
          title: title,
          author: author.isNotEmpty ? author : 'Unknown Author',
          description: description,
          coverUrl: coverUrl,
          totalPages: pages > 0 ? pages : 250,
          currentPage: status == ReadingStatus.finished
              ? pages
              : (status == ReadingStatus.currentlyReading
                    ? (pages * 0.25).toInt()
                    : 0),
          status: status,
          format: format,
          genres: genres,
          startDate: startDate,
          finishDate: finishDate,
          overallRating: rating,
        ),
      );
    }

    return books;
  }

  static DateTime? _parseDate(String dateStr) {
    final clean = dateStr.trim().replaceAll('/', '-');
    if (clean.isEmpty) return null;
    final direct = DateTime.tryParse(clean);
    if (direct != null) return direct;

    final parts = clean.split(RegExp(r'[\-\/]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p0 > 1000) {
          return DateTime(p0, p1, p2);
        } else if (p2 > 1000) {
          return DateTime(p2, p0, p1);
        }
      }
    }
    return null;
  }

  static String _statusToShelf(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return 'currently-reading';
      case ReadingStatus.finished:
        return 'read';
      case ReadingStatus.toRead:
        return 'to-read';
      case ReadingStatus.abandoned:
        return 'did-not-finish';
      case ReadingStatus.wishlist:
        return 'wishlist';
    }
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  static List<String> _parseCsvRow(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
