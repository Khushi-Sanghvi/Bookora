import 'book_metadata_parser.dart';

class MetadataSanitizer {
  /// Strips HTML tags and unescapes common HTML entities from raw API responses
  static String stripHtml(String html) {
    if (html.isEmpty) return '';

    // Strip HTML tags
    String clean = html.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ');

    // Unescape common HTML entities
    clean = clean
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–');

    // Collapse multiple whitespace spaces into single space
    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Cleans messy raw API category/subject strings into human-readable genre pill tags
  static List<String> cleanCategories(List<dynamic> rawCategories) {
    return BookMetadataParser.cleanGenres(rawCategories);
  }

  /// Parses first punchy sentence, promotional subtitle, or lead quote for tagline
  static String? extractTagline({
    required String title,
    required String author,
    required String description,
    String? subtitle,
  }) {
    if (subtitle != null &&
        subtitle.trim().length >= 8 &&
        subtitle.trim().length <= 180) {
      return stripHtml(subtitle.trim());
    }

    final cleanDesc = stripHtml(description);
    if (cleanDesc.isNotEmpty) {
      final sentences = cleanDesc.split(RegExp(r'(?<=[.!?])\s+'));
      for (final s in sentences) {
        final trimmed = s.trim();
        if (trimmed.length >= 15 &&
            trimmed.length <= 220 &&
            !trimmed.toLowerCase().contains('published by') &&
            !trimmed.toLowerCase().contains('all rights reserved') &&
            !trimmed.toLowerCase().startsWith('no. 1 ') &&
            !trimmed.toLowerCase().startsWith('the no. 1 ')) {
          return trimmed;
        }
      }
    }
    return null;
  }

  /// Truncates clean text into a short 2-3 sentence preview synopsis
  static String? extractBlurb({
    required String title,
    required String author,
    required String description,
  }) {
    final cleanDesc = stripHtml(description);
    if (cleanDesc.isEmpty) return null;

    final sentences = cleanDesc
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where(
          (s) =>
              s.length > 15 &&
              !s.toLowerCase().contains('published by') &&
              !s.toLowerCase().startsWith('no. 1 ') &&
              !s.toLowerCase().startsWith('the no. 1 '),
        )
        .toList();

    if (sentences.length >= 3) {
      return '${sentences[0]} ${sentences[1]} ${sentences[2]}';
    } else if (sentences.length >= 2) {
      return '${sentences[0]} ${sentences[1]}';
    } else if (sentences.isNotEmpty) {
      return sentences.first;
    }
    return null;
  }

  /// Upgrades standard Google Books or Open Library thumbnail URLs to high-resolution variants
  static String upgradeCoverUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';

    String clean = rawUrl.trim();
    if (clean.startsWith('http:')) {
      clean = clean.replaceFirst('http:', 'https:');
    }

    // Google Books high-res zoom
    clean = clean.replaceAll('&edge=curl', '');
    if (clean.contains('books.google.com')) {
      clean = clean
          .replaceAll('zoom=5', 'zoom=1')
          .replaceAll('zoom=2', 'zoom=1');
    }

    // Open Library high-res zoom (-S.jpg / -M.jpg -> -L.jpg)
    if (clean.contains('covers.openlibrary.org')) {
      clean = clean
          .replaceAll('-S.jpg', '-L.jpg')
          .replaceAll('-M.jpg', '-L.jpg');
    }

    return clean;
  }
}
