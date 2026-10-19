import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/services/csv_service.dart';

void main() {
  group('CsvService Tests', () {
    test('exportBooksToCsv and parseCsv preserve book records cleanly', () {
      final sampleBooks = [
        Book(
          id: 'b-1',
          title: 'The Secret History',
          author: 'Donna Tartt',
          description: 'A dark academia masterpiece',
          coverUrl: '',
          totalPages: 559,
          currentPage: 559,
          status: ReadingStatus.finished,
          format: BookFormat.paperback,
          genres: ['Dark Academia', 'Mystery'],
          overallRating: 9.6,
        ),
        Book(
          id: 'b-2',
          title: 'Babel',
          author: 'R.F. Kuang',
          description: 'An arcane history',
          coverUrl: '',
          totalPages: 544,
          currentPage: 120,
          status: ReadingStatus.currentlyReading,
          format: BookFormat.epub,
          genres: ['Fantasy', 'Historical Fiction'],
          overallRating: 8.8,
        ),
      ];

      final csvString = CsvService.exportBooksToCsv(sampleBooks);
      expect(csvString.contains('The Secret History'), isTrue);
      expect(csvString.contains('Donna Tartt'), isTrue);
      expect(csvString.contains('Babel'), isTrue);

      final parsedBooks = CsvService.parseCsv(csvString);
      expect(parsedBooks.length, equals(2));
      expect(parsedBooks[0].title, equals('The Secret History'));
      expect(parsedBooks[0].author, equals('Donna Tartt'));
      expect(parsedBooks[0].totalPages, equals(559));
      expect(parsedBooks[0].status, equals(ReadingStatus.finished));

      expect(parsedBooks[1].title, equals('Babel'));
      expect(parsedBooks[1].author, equals('R.F. Kuang'));
      expect(parsedBooks[1].totalPages, equals(544));
      expect(parsedBooks[1].status, equals(ReadingStatus.currentlyReading));
    });

    test('parseCsv correctly parses Goodreads export format', () {
      const goodreadsCsv =
          '''Book Id,Title,Author,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies
123,"A Little Life","Hanya Yanagihara",,"12345","1234567890123",5,4.3,"Doubleday","Paperback",720,2015,2015,2023/10/15,2023/08/01,"favorites, contemporary","favorites (#1), contemporary (#2)",read,"Devastating masterpiece.",,,,1,,,0
456,"Tomorrow, and Tomorrow, and Tomorrow","Gabrielle Zevin",,"67890","9876543210987",4,4.2,"Knopf","Kindle Edition",416,2022,2022,,2023/11/01,"fiction","fiction (#1)",currently-reading,"",,,,1,,,0
''';

      final books = CsvService.parseCsv(goodreadsCsv);
      expect(books.length, equals(2));

      final b1 = books[0];
      expect(b1.title, equals('A Little Life'));
      expect(b1.author, equals('Hanya Yanagihara'));
      expect(b1.totalPages, equals(720));
      expect(b1.currentPage, equals(720));
      expect(b1.status, equals(ReadingStatus.finished));
      expect(b1.overallRating, equals(10.0)); // 5 stars * 2.0 = 10.0
      expect(b1.format, equals(BookFormat.paperback));
      expect(b1.finishDate, isNotNull);

      final b2 = books[1];
      expect(b2.title, equals('Tomorrow, and Tomorrow, and Tomorrow'));
      expect(b2.author, equals('Gabrielle Zevin'));
      expect(b2.totalPages, equals(416));
      expect(b2.status, equals(ReadingStatus.currentlyReading));
      expect(b2.format, equals(BookFormat.epub)); // Kindle Edition maps to epub
    });

    test('parseCsv correctly parses StoryGraph export format', () {
      const storygraphCsv =
          '''Title,Authors,Contributors,ISBN/UID,Format,Read Status,Date Added,Last Date Read,Dates Read,Star Rating,Review,Tags,Owned Copies
"Fourth Wing","Rebecca Yarros",,"B09WXX","digital","read","2023-06-01","2023-06-05","2023-06-01 to 2023-06-05",4.5,"Loved the dragons","fantasy, romance",0
"Iron Flame","Rebecca Yarros",,"B0C77Y","audio","to-read","2023-11-08",,,"","","fantasy",0
''';

      final books = CsvService.parseCsv(storygraphCsv);
      expect(books.length, equals(2));

      final b1 = books[0];
      expect(b1.title, equals('Fourth Wing'));
      expect(b1.author, equals('Rebecca Yarros'));
      expect(b1.status, equals(ReadingStatus.finished));
      expect(b1.overallRating, equals(9.0)); // 4.5 stars * 2.0 = 9.0
      expect(b1.format, equals(BookFormat.epub)); // digital maps to epub
      expect(b1.genres.contains('fantasy'), isTrue);

      final b2 = books[1];
      expect(b2.title, equals('Iron Flame'));
      expect(b2.status, equals(ReadingStatus.toRead));
      expect(
        b2.format,
        equals(BookFormat.audiobook),
      ); // audio maps to audiobook
    });

    test('parseCsv handles custom column overrides and Bookwyrm export cleanly', () {
      const customCsv = '''Book Name;Writer;Category;Page Length;Bookwyrm Status
"The Song of Achilles";"Madeline Miller";"Mythology, Romance";416;stopped-reading
"Circe";"Madeline Miller";"Fantasy";393;read
''';

      final books = CsvService.parseCsv(
        customCsv.replaceAll(';', ','),
        titleCol: 'Book Name',
        authorCol: 'Writer',
        genreCol: 'Category',
        pagesCol: 'Page Length',
      );

      expect(books.length, equals(2));
      expect(books[0].title, equals('The Song of Achilles'));
      expect(books[0].author, equals('Madeline Miller'));
      expect(books[0].totalPages, equals(416));
      expect(books[0].genres.contains('Mythology'), isTrue);
      expect(books[0].status, equals(ReadingStatus.abandoned)); // stopped-reading maps to abandoned

      expect(books[1].title, equals('Circe'));
      expect(books[1].totalPages, equals(393));
      expect(books[1].status, equals(ReadingStatus.finished));
    });

    test('parseCsv handles empty or invalid strings gracefully', () {
      expect(CsvService.parseCsv(''), isEmpty);
      expect(CsvService.parseCsv('Title,Author\n'), isEmpty);
    });
  });
}
