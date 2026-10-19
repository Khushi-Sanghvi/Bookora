import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/models/journal_entry.dart';
import 'package:between_world/models/quote_annotation.dart';
import 'package:between_world/services/cache_service.dart';
import 'package:between_world/services/backup_service.dart';
import 'package:between_world/services/notification_service.dart';

void main() {
  group('CacheService Tests', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService();
      cache.clear();
    });

    test('set and get cached data before expiry', () {
      cache.set('test_key', 'test_value', ttl: const Duration(minutes: 5));
      final result = cache.get<String>('test_key');
      expect(result, 'test_value');
    });

    test('get returns null if key expired or missing', () {
      cache.set('expired_key', 'data', ttl: const Duration(milliseconds: -100));
      final result = cache.get<String>('expired_key');
      expect(result, isNull);

      final missing = cache.get<String>('non_existent');
      expect(missing, isNull);
    });

    test('cacheBook and getCachedBook helper methods', () {
      final book = Book(
        id: 'c_100',
        title: 'Cached Volume',
        author: 'Jane Doe',
        description: 'Cache test',
        coverUrl: '',
        totalPages: 250,
        status: ReadingStatus.currentlyReading,
      );

      cache.cacheBook(book);
      final retrieved = cache.getCachedBook('c_100');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'c_100');
      expect(retrieved.title, 'Cached Volume');
      expect(retrieved.status, ReadingStatus.currentlyReading);
    });

    test('clear wipes all cached entries', () {
      cache.set('key_1', 'val_1');
      cache.set('key_2', 'val_2');

      cache.clear();

      expect(cache.get<String>('key_1'), isNull);
      expect(cache.get<String>('key_2'), isNull);
    });

    test('bounded LRU eviction evicts least recently used item when capacity reached', () {
      cache.maxCapacity = 3;
      cache.clear();

      cache.set('a', 'alpha');
      cache.set('b', 'beta');
      cache.set('c', 'gamma');

      expect(cache.length, 3);
      expect(cache.get<String>('a'), 'alpha'); // 'a' promoted to MRU; order is now b, c, a

      cache.set('d', 'delta'); // exceeds capacity 3, evicts 'b' (LRU)

      expect(cache.length, 3);
      expect(cache.get<String>('b'), isNull); // 'b' was evicted
      expect(cache.get<String>('a'), 'alpha'); // 'a' was retained due to MRU promotion
      expect(cache.get<String>('c'), 'gamma');
      expect(cache.get<String>('d'), 'delta');

      // Reset capacity for subsequent tests
      cache.maxCapacity = 100;
    });
  });

  group('BackupService Payload Validation Tests', () {
    test('JSON structure format validation', () {
      final payload = {
        'app': 'Bookora',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': {'name': 'Aria'},
        'books': [],
      };

      final jsonStr = jsonEncode(payload);
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);

      expect(decoded['app'], 'Bookora');
      expect(decoded['version'], 1);
      expect(decoded['profile']['name'], 'Aria');
    });

    test('restoreBackupJson throws FormatException on invalid app name or missing version', () async {
      // 1. Invalid root structure
      expect(() => BackupService().restoreBackupJson('"invalid"'), throwsA(isA<FormatException>()));

      // 2. Unknown app
      final unknownAppPayload = jsonEncode({
        'app': 'OtherApp',
        'version': 1,
        'books': [],
      });
      expect(() => BackupService().restoreBackupJson(unknownAppPayload), throwsA(isA<FormatException>()));

      // 3. Missing version
      final missingVersionPayload = jsonEncode({
        'app': 'Bookora',
        'books': [],
      });
      expect(() => BackupService().restoreBackupJson(missingVersionPayload), throwsA(isA<FormatException>()));
    });
  });

  group('Cache Invalidation & Deserialization Resilience Tests', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService();
      cache.clear();
    });

    test('remove and removeBook properly evict cache entries', () {
      final book = Book(
        id: 'book_999',
        title: 'Transient Tome',
        author: 'Ghost Author',
        description: 'Testing eviction',
        coverUrl: '',
        totalPages: 100,
      );

      cache.cacheBook(book);
      expect(cache.getCachedBook('book_999'), isNotNull);

      cache.removeBook('book_999');
      expect(cache.getCachedBook('book_999'), isNull);
    });

    test('getCachedBook safely cleans up corrupted cache entries without crashing', () {
      // Intentionally insert corrupt data under book key
      cache.set('book_corrupt', {'id': null, 'title': null});
      final result = cache.getCachedBook('corrupt');
      // Should cleanly return a book with fallback defaults or recover
      expect(result, isNotNull);
      expect(result!.title, 'Unknown Title');
    });

    test('Book.fromMap handles out-of-bounds enums and string enum values safely', () {
      final malformedMap = {
        'id': 'err_1',
        'title': 'Fault Tolerant Book',
        'author': 'Resilient Author',
        'status': 999, // out of range
        'format': 'epub', // string instead of int
        'totalPages': '350', // string number
        'currentPage': '50',
        'overallRating': '4.5',
        'is_favorite': 1,
      };

      final book = Book.fromMap(malformedMap);
      expect(book.status, ReadingStatus.toRead); // fallback
      expect(book.format, BookFormat.epub); // parsed string enum
      expect(book.totalPages, 350);
      expect(book.currentPage, 50);
      expect(book.overallRating, 4.5);
      expect(book.isFavorite, isTrue);
    });

    test('JournalEntry.fromMap and QuoteAnnotation.fromMap gracefully fall back on null/malformed data', () {
      final badJournal = JournalEntry.fromMap({'id': null, 'date': 'invalid-date', 'pagesRead': '25'});
      expect(badJournal.id, isNotEmpty);
      expect(badJournal.pagesRead, 25);

      final badQuote = QuoteAnnotation.fromMap({'id': null, 'quoteText': null, 'pageNumber': '42', 'createdAt': 'not-a-date'});
      expect(badQuote.id, isNotEmpty);
      expect(badQuote.quoteText, '');
      expect(badQuote.pageNumber, 42);
    });
  });

  group('NotificationService Spicy Fantasy Dialogues Tests', () {
    test('contains over 100 spicy fantasy notifications', () {
      expect(NotificationService.romanticDialogues.length, greaterThanOrEqualTo(108));
    });

    test('each notification has valid non-empty title and body', () {
      for (final dialogue in NotificationService.romanticDialogues) {
        expect(dialogue['title'], isNotNull);
        expect(dialogue['title']!.trim(), isNotEmpty);
        expect(dialogue['body'], isNotNull);
        expect(dialogue['body']!.trim(), isNotEmpty);
      }
    });

    test('getRandomRomanticDialogue returns a random dialogue reliably', () {
      final sample = NotificationService.getRandomRomanticDialogue();
      expect(sample['title'], isNotNull);
      expect(sample['body'], isNotNull);
      expect(NotificationService.romanticDialogues.contains(sample), isTrue);
    });
  });
}
