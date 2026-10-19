import 'book_metadata_sanitizer.dart';

class BookMetadataParser {
  BookMetadataParser._();

  static final RegExp _distributorParentheticalPattern = RegExp(
    r'\s*[\(\[\{][^\(\)\[\]\{\}]*(?:oceanofpdf|z-?library|libgen|library\s+genesis|pdfdrive|epubpub|bookzz|mobilism|vk\.com|telegram|1lib|\.(?:sk|com|org|net|io|me|li|rs|is|in|to|info|ru))\b[^\(\)\[\]\{\}]*[\)\]\}]\s*',
    caseSensitive: false,
  );

  static final RegExp _formatAndEditionClutterPattern = RegExp(
    r'\s*[\(\[\{]\s*(?:epub|pdf|mobi|azw3?|retail|repack|v\d+(?:\.\d+)?|arc|a\.r\.c\.|arcs|advance\s+reader(?:[\x27\’]s)?\s+copy|advance\s+reading\s+copy|uncorrected\s+proof|proof\s+copy|galley(?:\s+copy)?|review\s+copy|special\s+edition|collector(?:[\x27\’]s)?\s+edition|deluxe\s+edition|anniversary\s+edition|illustrated(?:\s+edition)?|paperback|hardcover)\s*[\)\]\}]\s*',
    caseSensitive: false,
  );

  static final RegExp _editionSuffixPattern = RegExp(
    r'(?:\s*[-–—:]\s*|\s+)\b(?:ARC|A\.R\.C\.|ARCs|Advance\s+Reader(?:[\x27\’]s)?\s+Copy|Advance\s+Reading\s+Copy|Uncorrected\s+Proof|Proof\s+Copy|Galley(?:\s+Copy)?|Review\s+Copy|Special\s+Edition|Collector(?:[\x27\’]s)?\s+Edition|Deluxe\s+Edition|Anniversary\s+Edition|Retail|Repack)\b\s*$',
    caseSensitive: false,
  );

  static final RegExp _multiSpacePattern = RegExp(r'\s{2,}');

  /// Pre-sanitizes raw search query strings in Bookora
  static String cleanSearchQuery(String query) {
    var clean = query.trim();
    if (clean.toLowerCase().startsWith('isbn:')) {
      return clean.substring(5).trim();
    }
    if (clean.contains(':')) {
      final firstPart = clean.split(':')[0].trim();
      if (firstPart.isNotEmpty &&
          !firstPart.toLowerCase().startsWith('chapter') &&
          !firstPart.toLowerCase().startsWith('part')) {
        clean = firstPart;
      }
    }
    clean = clean.replaceAll(_formatAndEditionClutterPattern, ' ');
    clean = clean.replaceAll(_distributorParentheticalPattern, ' ');
    clean = clean.replaceAll(RegExp(r'\s*[\(\[][^()\[\]]*[\)\]]'), ' ');
    clean = clean.replaceAll(_editionSuffixPattern, ' ');
    clean = clean.replaceAll(
      RegExp(r'(?<!\b(?:of|the)\s+)\b(?:arc|a\.r\.c\.)\b', caseSensitive: false),
      ' ',
    );
    return clean.replaceAll(_multiSpacePattern, ' ').trim();
  }

  /// Full HTML entity decoding, structural tag replacement, and link removal
  static String sanitizeSynopsis(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Decode numeric & hex HTML entities
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return (code != null && code > 0 && code < 65536)
          ? String.fromCharCode(code)
          : match.group(0)!;
    });
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return (code != null && code > 0 && code < 65536)
          ? String.fromCharCode(code)
          : match.group(0)!;
    });

    // 2. Decode standard HTML entities & quotes
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&middot;', '·')
        .replaceAll('&bull;', '•')
        .replaceAll('…', '...');

    // 3. Convert structural HTML blocks to paragraphs
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?(?:p|div|section|article)[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ');
    text = text.replaceAll(RegExp(r'</?(?:ul|ol|li)[^>]*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 4. Remove Markdown links, URLs, and distributor domains
    text = text.replaceAll(RegExp(r'\[([^\]]*)\]\([^\)]+\)'), ' ');
    text = text.replaceAll(RegExp(r'https?://[^\s\)\]]+', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'www\.[^\s\)\]]+', caseSensitive: false), ' ');
    text = text.replaceAll(
      RegExp(
        r'(?:\[|\(|\b)?(?:oceanofpdf|z-?library|libgen|1lib|library\s+genesis|pdfdrive|epubpub|bookzz|bookrenzo|mobilism|vk\.com|telegram|goodreads)(?:\.[a-z0-9\-_]+)*(?:/[^\s\)\]]*)?(?:\]|\)|\b)?',
        caseSensitive: false,
      ),
      ' ',
    );

    // 5. Remove Wikipedia citations
    text = text.replaceAll(RegExp(r'\[\s*(?:\d+|citation\s+needed)\s*\]', caseSensitive: false), ' ');

    // 6. Clean paragraph linebreaks
    final lines = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .toList();
    final buffer = StringBuffer();
    bool prevEmpty = false;
    for (final l in lines) {
      if (l.isEmpty) {
        if (!prevEmpty && buffer.isNotEmpty) {
          buffer.writeln();
          prevEmpty = true;
        }
      } else {
        buffer.writeln(l);
        prevEmpty = false;
      }
    }

    return buffer.toString().trim();
  }

  static String extractFullPlotSummary({
    required String title,
    required String author,
    required String description,
  }) {
    final clean = sanitizeSynopsis(description);
    if (clean.isNotEmpty) return clean;
    return 'No overview provided for "$title" by $author.';
  }

  static String extractBlurbTagline({
    required String title,
    required String author,
    required String description,
    String? subtitle,
  }) {
    if (subtitle != null && subtitle.trim().length >= 6 && subtitle.trim().length <= 180) {
      return sanitizeSynopsis(subtitle.trim());
    }

    final clean = sanitizeSynopsis(description);
    if (clean.isNotEmpty) {
      final quoteMatch = RegExp(r'^["“]([^"”]{10,200})["”]').firstMatch(clean);
      if (quoteMatch != null && quoteMatch.group(1) != null) {
        return quoteMatch.group(1)!.trim();
      }

      final sentences = _splitSentences(clean);
      for (final s in sentences) {
        final trimmed = s.trim();
        if (trimmed.length >= 15 &&
            trimmed.length <= 220 &&
            !trimmed.toLowerCase().contains('copyright') &&
            !trimmed.toLowerCase().contains('published by') &&
            !trimmed.toLowerCase().startsWith('no. 1 ') &&
            !trimmed.toLowerCase().startsWith('the no. 1 ')) {
          return trimmed;
        }
      }

      if (sentences.isNotEmpty) {
        final first = sentences.first.trim();
        if (first.length > 220) {
          final lastSpace = first.lastIndexOf(' ', 200);
          if (lastSpace > 50) {
            return '${first.substring(0, lastSpace)}...';
          }
        }
        return first;
      }
      return clean;
    }
    return 'Uncover the story of "$title" by $author.';
  }

  static String extractStoryline({
    required String title,
    required String author,
    required String description,
  }) {
    final clean = sanitizeSynopsis(description);
    if (clean.isNotEmpty) {
      final sentences = _splitSentences(clean)
          .map((s) => s.trim())
          .where((s) =>
              s.length > 15 &&
              !s.toLowerCase().contains('published by') &&
              !s.toLowerCase().startsWith('no. 1 ') &&
              !s.toLowerCase().startsWith('the no. 1 '))
          .toList();

      if (sentences.length >= 3) {
        return '${sentences[0]} ${sentences[1]} ${sentences[2]}';
      } else if (sentences.length >= 2) {
        return '${sentences[0]} ${sentences[1]}';
      } else if (sentences.isNotEmpty) {
        return sentences.first;
      }
      return clean;
    }
    return 'Explore the narrative and themes of "$title" by $author.';
  }

  /// Bookora composite BISAC genre cleaner & de-duplicator
  static List<String> cleanGenres(List<dynamic> rawTags) {
    if (rawTags.isEmpty) return const ['General'];

    final strTags = rawTags
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString())
        .toList();

    final cleaned = BookMetadataSanitizer.sanitizeTags(strTags);
    if (cleaned.isNotEmpty) {
      return cleaned.take(4).toList();
    }

    return const ['General'];
  }

  static List<String> _splitSentences(String text) {
    if (text.isEmpty) return [];
    final matches = RegExp(r'[^.!?]+[.!?]+(\s|$)').allMatches(text);
    if (matches.isEmpty) return [text];
    return matches.map((m) => m.group(0)!.trim()).toList();
  }
}
