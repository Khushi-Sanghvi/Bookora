import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BookGenreFetcher {
  static const Set<String> _ignoredTags = {
    'fiction',
    'general',
    'protected daisy',
    'accessible book',
    'lending library',
    'in library',
    'borrowable',
    'large print',
    'open_library',
    'juvenile fiction',
    'juvenile nonfiction',
    'internet archive wishlist',
    'books',
    'book',
    'literature',
    'reading level',
    'unread',
    'ebook',
    'ebooks',
    'epub',
    'pdf',
    'paperback',
    'hardcover',
    'audiobook',
    'read',
    'to-read',
    'currently-reading',
    'favorites',
    'kindle',
    'library',
  };

  /// Sanitizes, extracts leaves from hierarchical trees, and deduplicates tags.
  static List<String> sanitizeAndFilterTags(List<dynamic> rawTags) {
    if (rawTags.isEmpty) return const ['General'];

    final Map<String, String> distinctGenres = {};

    for (final raw in rawTags) {
      if (raw == null || raw.toString().trim().isEmpty) continue;
      final str = raw.toString().trim();

      // Split hierarchical paths delimited by / and ; and ,
      final parts = str.contains('/') || str.contains(';') || str.contains(',')
          ? str.split(RegExp(r'[/;,]'))
          : [str];

      for (var i = parts.length - 1; i >= 0; i--) {
        var token = parts[i].trim();
        token = token.replaceAll(
            RegExp(r'^[\[\(\{\"\x27\-\_\:\;\•\\\/\s]+|[\]\)\}\"\x27\-\_\:\;\•\\\/\s]+$'),
            '');
        if (token.length < 2 || token.length > 30) continue;

        final lower = token.toLowerCase();
        if (_ignoredTags.contains(lower)) continue;

        final titleCased = _toCleanTitleCase(token);
        final lowerKey = titleCased.toLowerCase();

        if (!distinctGenres.containsKey(lowerKey)) {
          distinctGenres[lowerKey] = titleCased;
        }
      }
    }

    // Filter out generic roots ("Fiction", "General", "Nonfiction") IF deeper, more descriptive tokens exist
    if (distinctGenres.length > 1) {
      distinctGenres.removeWhere((key, _) =>
          key == 'fiction' ||
          key == 'general' ||
          key == 'nonfiction' ||
          key == 'non-fiction');
    }

    if (distinctGenres.isEmpty) {
      return const ['General'];
    }

    return distinctGenres.values.take(4).toList();
  }

  /// Fetches rich genres for a book using volume/work IDs or title + author fallback.
  static Future<List<String>> fetchGenresForBook({
    required String title,
    required String author,
    String? googleVolumeId,
    String? openLibraryWorkKey,
    List<String>? initialRawTags,
  }) async {
    final List<dynamic> collectedRaw = [];
    if (initialRawTags != null) {
      collectedRaw.addAll(initialRawTags);
    }

    // 1. Google Books Volume Detailed Lookup if volume ID provided
    if (googleVolumeId != null && googleVolumeId.trim().isNotEmpty) {
      try {
        final url = Uri.parse(
            'https://www.googleapis.com/books/v1/volumes/${googleVolumeId.trim()}');
        final res = await http.get(url, headers: {
          'User-Agent': 'BookoraApp/1.0'
        }).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>?;
          final cats = data?['volumeInfo']?['categories'] as List?;
          if (cats != null && cats.isNotEmpty) {
            collectedRaw.addAll(cats);
          }
        }
      } catch (e) {
        debugPrint('Google Books Volume Genre Note: $e');
      }
    }

    // 2. Open Library Work Detailed Lookup if work key provided
    if (openLibraryWorkKey != null && openLibraryWorkKey.trim().isNotEmpty) {
      try {
        final cleanKey = openLibraryWorkKey.trim().startsWith('/')
            ? openLibraryWorkKey.trim()
            : '/works/${openLibraryWorkKey.trim()}';
        final url = Uri.parse('https://openlibrary.org$cleanKey.json');
        final res = await http.get(url, headers: {
          'User-Agent': 'BookoraApp/1.0'
        }).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>?;
          final subjects = data?['subjects'] as List?;
          if (subjects != null && subjects.isNotEmpty) {
            collectedRaw.addAll(subjects);
          }
        }
      } catch (e) {
        debugPrint('Open Library Work Genre Note: $e');
      }
    }

    final sanitized = sanitizeAndFilterTags(collectedRaw);
    if (sanitized.isNotEmpty && !listEquals(sanitized, const ['General'])) {
      return sanitized;
    }

    // 3. Fallback Title/Author Search on Google Books for Rich Taxonomy
    try {
      final query = Uri.encodeComponent('$title $author');
      final url = Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=1');
      final res = await http.get(url, headers: {
        'User-Agent': 'BookoraApp/1.0'
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        final items = data?['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final vol = items.first['volumeInfo'] as Map<String, dynamic>?;
          final cats = vol?['categories'] as List?;
          if (cats != null && cats.isNotEmpty) {
            collectedRaw.addAll(cats);
            final freshSanitized = sanitizeAndFilterTags(collectedRaw);
            if (freshSanitized.isNotEmpty) {
              return freshSanitized;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Fallback Genre Search Note: $e');
    }

    return sanitizeAndFilterTags(collectedRaw);
  }

  static String _toCleanTitleCase(String text) {
    if (text.isEmpty) return text;
    const minorWords = {
      'of',
      'and',
      'a',
      'an',
      'in',
      'the',
      'for',
      'with',
      'on',
      'at',
      'to',
      'by',
      'from'
    };
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final lower = w.toLowerCase();
      if (i > 0 && minorWords.contains(lower)) {
        buffer.write(lower);
      } else {
        buffer.write('${w[0].toUpperCase()}${w.substring(1).toLowerCase()}');
      }
      if (i < words.length - 1) buffer.write(' ');
    }
    return buffer.toString();
  }
}
