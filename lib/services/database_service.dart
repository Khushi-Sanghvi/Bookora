import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';
import '../models/journal_entry.dart';
import '../models/quote_annotation.dart';
import '../models/user_profile.dart';
import 'cache_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'bookora.db');
    return await openDatabase(
      path,
      version: 8, // Bumped version for endDate lifecycle tracking
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE books ADD COLUMN tagline TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE books ADD COLUMN blurb TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE search_cache (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            description TEXT,
            tagline TEXT,
            blurb TEXT,
            coverUrl TEXT,
            totalPages INTEGER,
            genres TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE books ADD COLUMN is_favorite INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          "DELETE FROM search_cache WHERE description LIKE '%compelling literary work%'",
        );
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            name TEXT NOT NULL,
            username TEXT NOT NULL,
            bio TEXT NOT NULL,
            avatarPath TEXT,
            hasCompletedOnboarding INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          "ALTER TABLE books ADD COLUMN genres TEXT DEFAULT '[]'",
        );
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE books ADD COLUMN endDate TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'UPDATE books SET endDate = finishDate WHERE endDate IS NULL',
        );
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        tagline TEXT,
        blurb TEXT,
        coverUrl TEXT,
        totalPages INTEGER,
        currentPage INTEGER,
        status INTEGER,
        format INTEGER,
        genres TEXT DEFAULT '[]',
        startDate TEXT,
        finishDate TEXT,
        endDate TEXT,
        overallRating REAL,
        spiceRating REAL,
        fluffRating REAL,
        tearRating REAL,
        humorRating REAL,
        localFilePath TEXT,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        date TEXT NOT NULL,
        pagesRead INTEGER,
        reflection TEXT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quotes (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        quoteText TEXT NOT NULL,
        pageNumber INTEGER,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE search_cache (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        tagline TEXT,
        blurb TEXT,
        coverUrl TEXT,
        totalPages INTEGER,
        genres TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        username TEXT NOT NULL,
        bio TEXT NOT NULL,
        avatarPath TEXT,
        hasCompletedOnboarding INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Profile CRUD
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    var map = profile.toMap();
    map['id'] = 1;
    await db.insert(
      'user_profile',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = 1',
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  // Book CRUD
  Future<void> insertBook(dynamic book) async {
    final db = await database;
    if (book is Book) {
      await db.insert(
        'books',
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      CacheService().cacheBook(book);
    } else if (book is Map<String, dynamic>) {
      await db.insert(
        'books',
        book,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (book['id'] != null) {
        try {
          CacheService().cacheBook(Book.fromMap(book));
        } catch (_) {}
      }
    }
  }

  Future<void> insertBooks(List<Book> books) async {
    if (books.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final book in books) {
        batch.insert(
          'books',
          book.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    for (final book in books) {
      CacheService().cacheBook(book);
    }
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books');

    List<Book> books = [];
    for (var map in maps) {
      try {
        final journalEntries = await getJournalEntriesForBook(map['id']);
        final quotes = await getQuotesForBook(map['id']);
        books.add(
          Book.fromMap(map, journalEntries: journalEntries, quotes: quotes),
        );
      } catch (e) {
        debugPrint('Error deserializing book row ${map['id']}: $e');
      }
    }
    return books;
  }

  Future<Book?> getBookById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      try {
        final journalEntries = await getJournalEntriesForBook(id);
        final quotes = await getQuotesForBook(id);
        return Book.fromMap(
          maps.first,
          journalEntries: journalEntries,
          quotes: quotes,
        );
      } catch (e) {
        debugPrint('Error deserializing book $id: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
    CacheService().cacheBook(book);
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('quotes', where: 'bookId = ?', whereArgs: [id]);
      await txn.delete('journal_entries', where: 'bookId = ?', whereArgs: [id]);
      await txn.delete('books', where: 'id = ?', whereArgs: [id]);
    });
    CacheService().removeBook(id);
  }

  // Journal CRUD
  Future<void> insertJournalEntry(String bookId, JournalEntry entry) async {
    final db = await database;
    var map = entry.toMap();
    map['bookId'] = bookId;
    await db.insert('journal_entries', map);
  }

  Future<List<JournalEntry>> getJournalEntriesForBook(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journal_entries',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }

  // Quotes CRUD
  Future<void> insertQuote(String bookId, QuoteAnnotation quote) async {
    final db = await database;
    var map = quote.toMap();
    map['bookId'] = bookId;
    await db.insert('quotes', map);
  }

  Future<List<QuoteAnnotation>> getQuotesForBook(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotes',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => QuoteAnnotation.fromMap(maps[i]));
  }

  Future<void> deleteQuote(String quoteId) async {
    final db = await database;
    await db.delete('quotes', where: 'id = ?', whereArgs: [quoteId]);
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'bookora.db');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> wipeAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('books');
      await txn.delete('quotes');
      await txn.delete('journal_entries');
      try {
        await txn.delete('search_cache');
      } catch (_) {}
    });
    CacheService().clear();
  }
}

class DatabaseHelper {
  static DatabaseService get instance => DatabaseService.instance;
}
