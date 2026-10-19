import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../models/book.dart';

class BackupService {
  final DatabaseService _db = DatabaseService();

  Future<String> createBackupJson({Map<String, dynamic>? profileData}) async {
    final books = await _db.getAllBooks();

    final List<Map<String, dynamic>> booksJson = [];
    for (var b in books) {
      final bookMap = b.toMap();
      bookMap['journalEntries'] = b.journalEntries.map((e) => e.toMap()).toList();
      bookMap['quotes'] = b.quotes.map((q) => q.toMap()).toList();
      booksJson.add(bookMap);
    }

    final backupPayload = {
      'app': 'Bookora',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profileData ?? {},
      'books': booksJson,
    };

    return const JsonEncoder.withIndent('  ').convert(backupPayload);
  }

  Future<int> restoreBackupJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup payload format. Expected JSON root object.');
    }

    final appName = decoded['app'];
    if (appName != 'Bookora') {
      throw const FormatException('Invalid backup file. Not a valid Bookora backup.');
    }

    final version = decoded['version'];
    if (version == null) {
      throw const FormatException('Invalid backup file. Missing version specification.');
    }

    final dynamic booksRaw = decoded['books'];
    if (booksRaw is! List) {
      throw const FormatException('Invalid backup file. Books collection missing or malformed.');
    }

    final db = await _db.database;
    int restoredCount = 0;

    await db.transaction((txn) async {
      for (final bookElement in booksRaw) {
        if (bookElement is! Map) continue;
        final bookMapCast = Map<String, dynamic>.from(bookElement);

        final List<dynamic> journalEntriesJson =
            bookMapCast['journalEntries'] is List ? bookMapCast['journalEntries'] as List : [];
        final List<dynamic> quotesJson =
            bookMapCast['quotes'] is List ? bookMapCast['quotes'] as List : [];

        final Book book = Book.fromMap(bookMapCast);
        await txn.insert(
          'books',
          book.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert Journal Entries
        for (final entryElement in journalEntriesJson) {
          if (entryElement is! Map) continue;
          final entryMapCast = Map<String, dynamic>.from(entryElement);
          final date = DateTime.tryParse(entryMapCast['date']?.toString() ?? '') ?? DateTime.now();
          final id = entryMapCast['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          await txn.insert(
            'journal_entries',
            {
              'id': id,
              'bookId': book.id,
              'date': date.toIso8601String(),
              'pagesRead': (entryMapCast['pagesRead'] as num?)?.toInt() ?? 0,
              'reflection': entryMapCast['reflection']?.toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insert Quotes
        for (final quoteElement in quotesJson) {
          if (quoteElement is! Map) continue;
          final quoteMapCast = Map<String, dynamic>.from(quoteElement);
          final createdAt = DateTime.tryParse(quoteMapCast['createdAt']?.toString() ?? '') ?? DateTime.now();
          final id = quoteMapCast['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          await txn.insert(
            'quotes',
            {
              'id': id,
              'bookId': book.id,
              'quoteText': quoteMapCast['quoteText']?.toString() ?? '',
              'pageNumber': (quoteMapCast['pageNumber'] as num?)?.toInt(),
              'note': quoteMapCast['note']?.toString(),
              'createdAt': createdAt.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        restoredCount++;
      }
    });

    return restoredCount;
  }
}
