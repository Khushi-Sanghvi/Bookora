import 'dart:io';
import 'package:epubx/epubx.dart' as epubx;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../models/enums.dart';
import 'book_metadata_sanitizer.dart';
import 'book_search_service.dart';
import 'database_service.dart';
import 'genre_parser.dart';

class FileImportResult {
  final bool success;
  final String? bookId;
  final String? bookTitle;
  final String? errorMessage;
  final String message;
  final Book? book;
  final Book? importedBook;
  final int totalImported;

  FileImportResult({
    required this.success,
    this.bookId,
    this.bookTitle,
    this.errorMessage,
    String? message,
    Book? book,
    Book? importedBook,
    this.totalImported = 1,
  })  : message = message ?? errorMessage ?? (success ? 'Successfully imported' : 'Import failed'),
        book = book ?? importedBook,
        importedBook = importedBook ?? book;
}

class FileImportService {
  /// Picks and imports a single or batch .epub or .pdf documents with progress streaming
  static Future<FileImportResult> pickAndImportDocument({
    void Function(String stage, double progress)? onProgress,
    bool allowMultiple = false,
  }) async {
    try {
      // 1. Pick file(s) from device storage restricted to EPUB and PDF
      onProgress?.call('Selecting document...', 0.05);
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf'],
        allowMultiple: allowMultiple,
      );

      if (pickResult == null || pickResult.files.isEmpty) {
        return FileImportResult(
          success: false,
          errorMessage: 'Import cancelled by user',
          message: 'Import cancelled.',
        );
      }

      final validFiles = pickResult.files
          .where((f) => f.path != null && File(f.path!).existsSync())
          .map((f) => File(f.path!))
          .toList();

      if (validFiles.isEmpty) {
        return FileImportResult(
          success: false,
          errorMessage: 'Selected file could not be accessed.',
          message: 'Selected file could not be accessed.',
        );
      }

      if (validFiles.length == 1) {
        return await processDocumentFile(
          sourceFile: validFiles.first,
          onProgress: onProgress,
        );
      } else {
        // Batch import handling
        int importedCount = 0;
        Book? lastBook;
        for (int i = 0; i < validFiles.length; i++) {
          final file = validFiles[i];
          final stepProgress = (i / validFiles.length);
          onProgress?.call(
            'Importing ${i + 1} of ${validFiles.length}: ${p.basename(file.path)}',
            stepProgress,
          );
          final res = await processDocumentFile(
            sourceFile: file,
            onProgress: (subStage, subP) {
              final overall = stepProgress + (subP / validFiles.length);
              onProgress?.call(subStage, overall.clamp(0.0, 1.0));
            },
          );
          if (res.success && res.book != null) {
            importedCount++;
            lastBook = res.book;
          }
        }

        onProgress?.call('Imported $importedCount books successfully!', 1.0);
        return FileImportResult(
          success: importedCount > 0,
          bookId: lastBook?.id,
          bookTitle: importedCount == 1 ? lastBook?.title : '$importedCount documents',
          book: lastBook,
          totalImported: importedCount,
          message: 'Imported $importedCount books successfully!',
        );
      }
    } catch (e) {
      debugPrint('FileImportService error: $e');
      return FileImportResult(
        success: false,
        errorMessage: 'Failed to import document: $e',
        message: 'Failed to import document: $e',
      );
    }
  }

  /// Ingests and processes a local EPUB or PDF file into the app sandbox and SQLite database
  static Future<FileImportResult> processDocumentFile({
    required File sourceFile,
    void Function(String stage, double progress)? onProgress,
  }) async {
    try {
      final bookId = const Uuid().v4();
      final ext = p.extension(sourceFile.path).toLowerCase();
      final isEpub = ext == '.epub';
      final fileName = p.basenameWithoutExtension(sourceFile.path);

      onProgress?.call('Reading "${p.basename(sourceFile.path)}"...', 0.20);

      // 2. Prepare Sandbox Persistent Directories
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDir.path, 'documents'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final coversDir = Directory(p.join(appDir.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      // Copy document file to app sandbox
      final rawFileName = p.basename(sourceFile.path);
      final sanitizedFileName = '${bookId}_${rawFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_')}';
      final destinationPath = p.join(targetDir.path, sanitizedFileName);
      await sourceFile.copy(destinationPath);

      onProgress?.call('Parsing typography & metadata...', 0.40);

      String title = fileName.replaceAll('_', ' ').replaceAll('-', ' ').trim();
      String author = 'Unknown Author';
      String description = 'Document imported from local storage.';
      List<String> genres = ['General'];
      int totalPages = 150;
      String localCoverPath = '';

      if (isEpub) {
        // --- EPUB PIPELINE ---
        final bytes = await sourceFile.readAsBytes();
        try {
          final epubBook = await epubx.EpubReader.readBook(bytes);

          // Metadata extraction
          if (epubBook.Title != null && epubBook.Title!.trim().isNotEmpty) {
            title = epubBook.Title!.trim();
          }
          if (epubBook.Author != null && epubBook.Author!.trim().isNotEmpty) {
            author = epubBook.Author!.trim();
          }

          final opfDesc = epubBook.Schema?.Package?.Metadata?.Description;
          if (opfDesc != null && opfDesc.trim().isNotEmpty) {
            description = opfDesc.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
          }

          // Subjects & Genres
          final subjects = epubBook.Schema?.Package?.Metadata?.Subjects;
          final parsedGenres = GenreParser.parseRawGenres(subjects);
          if (parsedGenres.isNotEmpty) {
            genres = parsedGenres;
          } else {
            genres = GenreParser.inferGenresFromContext(
              title: title,
              author: author,
              description: description,
            );
          }

          // Cover extraction
          if (epubBook.CoverImage != null) {
            try {
              final jpgBytes = img.encodeJpg(epubBook.CoverImage!, quality: 85);
              final coverFile = File(p.join(coversDir.path, '${bookId}_cover.jpg'));
              await coverFile.writeAsBytes(jpgBytes);
              localCoverPath = coverFile.path;
            } catch (e) {
              debugPrint('Cover encode error: $e');
            }
          }

          // Total pages calculation
          int totalChars = 0;
          if (epubBook.Chapters != null) {
            for (final ch in epubBook.Chapters!) {
              final text = (ch.HtmlContent ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
              totalChars += text.length;
            }
          }
          if (totalChars > 0) {
            totalPages = (totalChars / 1500).ceil().clamp(1, 99999);
          }
        } catch (e) {
          debugPrint('EPUB parsing error: $e');
        }
      } else {
        // --- PDF PIPELINE ---
        final bytes = await sourceFile.readAsBytes();

        // 1. Page count extraction from PDF Catalog
        try {
          final content = String.fromCharCodes(bytes.take(bytes.length < 500000 ? bytes.length : 500000));
          final countMatches = RegExp(r'/Count\s+(\d+)').allMatches(content);
          for (final m in countMatches) {
            final cnt = int.tryParse(m.group(1) ?? '');
            if (cnt != null && cnt > 0 && cnt < 50000) {
              totalPages = cnt;
              break;
            }
          }
          if (totalPages <= 1) {
            final pageCountMatches = RegExp(r'/Type\s*/Page\b').allMatches(content);
            if (pageCountMatches.length > 1) {
              totalPages = pageCountMatches.length;
            }
          }
        } catch (_) {}

        // 2. Title & Author from /Info dictionary or XMP packet
        try {
          final headerSnippet = String.fromCharCodes(bytes.take(bytes.length < 40000 ? bytes.length : 40000));
          final tMatch = RegExp(r'/Title\s*\(([^)]+)\)').firstMatch(headerSnippet);
          if (tMatch != null && tMatch.group(1)!.trim().isNotEmpty) {
            title = tMatch.group(1)!.trim();
          }
          final aMatch = RegExp(r'/Author\s*\(([^)]+)\)').firstMatch(headerSnippet);
          if (aMatch != null && aMatch.group(1)!.trim().isNotEmpty) {
            author = aMatch.group(1)!.trim();
          }
        } catch (_) {}

        // 3. Genres via semantic inference
        genres = GenreParser.inferGenresFromContext(
          title: title,
          author: author,
          description: 'PDF document: $title',
        );

        // 4. Cover extraction or artisanal Dark Academia bookplate generation
        try {
          final coverFile = File(p.join(coversDir.path, '${bookId}_cover.jpg'));
          final embeddedJpeg = _findEmbeddedJpeg(bytes);
          if (embeddedJpeg != null && embeddedJpeg.isNotEmpty) {
            await coverFile.writeAsBytes(embeddedJpeg);
            localCoverPath = coverFile.path;
          } else {
            // Generate elegant Dark Academia leather bookplate
            final coverImg = img.Image(400, 600);
            img.fill(coverImg, img.getColor(27, 23, 21)); // Midnight leather
            img.drawRect(coverImg, 16, 16, 384, 584, img.getColor(212, 175, 55)); // Gold border
            img.drawRect(coverImg, 20, 20, 380, 580, img.getColor(212, 175, 55));
            final jpgBytes = img.encodeJpg(coverImg, quality: 85);
            await coverFile.writeAsBytes(jpgBytes);
            localCoverPath = coverFile.path;
          }
        } catch (e) {
          debugPrint('PDF cover generation error: $e');
        }
      }

      onProgress?.call('Adding book to your library...', 0.85);

      // Auto-heal truncated synopsis from online repositories
      if (BookMetadataSanitizer.isTruncatedSynopsis(description)) {
        try {
          final fullSynopsis = await BookSearchService.fetchSynopsisForBook(
            title: title,
            author: author,
          ).timeout(const Duration(seconds: 4), onTimeout: () => null);
          if (fullSynopsis != null &&
              fullSynopsis.trim().isNotEmpty &&
              !BookMetadataSanitizer.isTruncatedSynopsis(fullSynopsis)) {
            description = BookMetadataSanitizer.sanitizeSynopsis(fullSynopsis);
          } else {
            description = BookMetadataSanitizer.sanitizeSynopsis(description);
          }
        } catch (_) {
          description = BookMetadataSanitizer.sanitizeSynopsis(description);
        }
      }

      // 3. Construct Book Model & Persist to SQLite
      final importedBook = Book(
        id: bookId,
        title: title,
        author: author,
        description: description,
        format: isEpub ? BookFormat.epub : BookFormat.pdf,
        localFilePath: destinationPath,
        coverUrl: localCoverPath,
        genres: genres.isNotEmpty ? genres : ['General'],
        totalPages: totalPages > 0 ? totalPages : 100,
        currentPage: 0,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        progress: 0.0,
      );

      await DatabaseService.instance.insertBook(importedBook);

      onProgress?.call('Successfully Added to Shelf!', 1.0);

      return FileImportResult(
        success: true,
        bookId: bookId,
        bookTitle: title,
        book: importedBook,
        importedBook: importedBook,
        message: 'Successfully imported "$title"',
      );
    } catch (e) {
      debugPrint('processDocumentFile error: $e');
      return FileImportResult(
        success: false,
        errorMessage: 'Error processing document: $e',
        message: 'Error processing document: $e',
      );
    }
  }

  /// Scans raw bytes for embedded DCTDecode JPEG streams (SOI marker 0xFFD8 to EOI marker 0xFFD9)
  static Uint8List? _findEmbeddedJpeg(Uint8List bytes) {
    final searchLimit = bytes.length < 409600 ? bytes.length : 409600;
    for (int i = 0; i < searchLimit - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
        for (int j = i + 2; j < searchLimit - 1; j++) {
          if (bytes[j] == 0xFF && bytes[j + 1] == 0xD9) {
            final length = (j + 2) - i;
            if (length >= 6000) {
              return bytes.sublist(i, j + 2);
            }
            break;
          }
        }
      }
    }
    return null;
  }
}
