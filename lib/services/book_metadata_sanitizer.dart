import 'package:path/path.dart' as p;

/// Advanced Book Metadata Sanitizer.
/// Cleans distributor watermarks (OceanofPDF, Z-Library, Libgen, etc.),
/// extracts clean book titles & authors from filenames and headers,
/// strips copyright boilerplate, and sanitizes synopses and tags.
class BookMetadataSanitizer {
  BookMetadataSanitizer._();

  static final RegExp _uuidPrefixPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}_',
  );

  /// Strips distributor/pirate parentheticals/brackets e.g. "(z-library.sk, 1lib.sk, z-lib.sk)" or "[OceanofPDF.com]"
  static final RegExp _distributorParentheticalPattern = RegExp(
    r'\s*[\(\[\{][^\(\)\[\]\{\}]*(?:oceanofpdf|z-?library|libgen|library\s+genesis|pdfdrive|epubpub|bookzz|mobilism|vk\.com|telegram|1lib|\.(?:sk|com|org|net|io|me|li|rs|is|in|to|info|ru))\b[^\(\)\[\]\{\}]*[\)\]\}]\s*',
    caseSensitive: false,
  );

  /// Strips format and edition tokens in brackets e.g. "[EPUB]", "(PDF)", "(Retail)", "[Repack]", "(v1.0)"
  static final RegExp _formatAndEditionClutterPattern = RegExp(
    r'\s*[(\[{]\s*(?:epub|pdf|mobi|azw3?|retail|repack|v\d+(?:\.\d+)?|arc|a\.r\.c\.|arcs|advance\s+reader(?:[\x27\’]s)?\s+copy|advance\s+reading\s+copy|uncorrected\s+proof|proof\s+copy|galley(?:\s+copy)?|review\s+copy|special\s+edition|collector(?:[\x27\’]s)?\s+edition|deluxe\s+edition|anniversary\s+edition|illustrated(?:\s+edition)?|paperback|hardcover)\s*[)\}]\]\s*',
    caseSensitive: false,
  );

  /// Strips trailing ARC, proof, or edition words at the end of a title or after a separator
  /// e.g. "King of Greed ARC", "King of Greed Arc", "King of Greed - ARC", "King of Greed : Advance Reader Copy"
  static final RegExp _editionSuffixPattern = RegExp(
    r'(?:\s*[-–—:]\s*|\s+)\b(?:ARC|A\.R\.C\.|ARCs|Advance\s+Reader(?:[\x27\’]s)?\s+Copy|Advance\s+Reading\s+Copy|Uncorrected\s+Proof|Proof\s+Copy|Galley(?:\s+Copy)?|Review\s+Copy|Special\s+Edition|Collector(?:[\x27\’]s)?\s+Edition|Deluxe\s+Edition|Anniversary\s+Edition|Retail|Repack)\b\s*$',
    caseSensitive: false,
  );

  static final RegExp _watermarkPattern = RegExp(
    r'(?:\[|\(|\b)?(?:oceanofpdf(?:\.com)?|z-?library(?:\.[a-z]+)?|libgen(?:\.[a-z]+)?|1lib(?:\.[a-z]+)?|library\s+genesis|pdfdrive(?:\.com)?|epubpub|bookzz|mobilism|vk\.com|telegram)(?:\]|\)|\b)?',
    caseSensitive: false,
  );

  static final RegExp _copyrightSuffixPattern = RegExp(
    r'all\s+rights?\s+reserv.*|all\s+rights?.*|copyright\s*©?.*|published\s+by.*|first\s+edition.*|printed\s+in.*|\bcover\s+design.*',
    caseSensitive: false,
  );

  static final RegExp _multiSpacePattern = RegExp(r'\s{2,}');

  /// Cleans and extracts [title, author, seriesName, seriesOrder] from a raw file path or document name.
  static ({String title, String author, String? seriesName, int? seriesOrder}) extractTitleAndAuthor(
    String rawPath, {
    String? detectedAuthor,
  }) {
    String clean = p.basenameWithoutExtension(rawPath);

    // 1. Strip leading UUIDs
    clean = clean.replaceFirst(_uuidPrefixPattern, '');

    // 2. Strip whole distributor/pirate parentheticals & brackets first
    clean = clean.replaceAll(_distributorParentheticalPattern, ' ');

    // 3. Strip format and bracketed edition noise ([EPUB], (Retail), (ARC), etc.)
    clean = clean.replaceAll(_formatAndEditionClutterPattern, ' ');

    // 4. Strip known download watermarks
    clean = clean.replaceAll(_watermarkPattern, ' ');

    // 5. Check for trailing parenthesized author: e.g. "King of Greed (Ana Huang)"
    final trailingParenMatch = RegExp(
      r'\s*[\(\[]([^\(\)\[\]]+)[\)\]]\s*$',
    ).firstMatch(clean);
    if (trailingParenMatch != null) {
      final insideParen = trailingParenMatch.group(1)!.trim();
      if (!_isEditionNoise(insideParen) &&
          !_isSeriesNoise(insideParen) &&
          _looksLikeAuthorName(insideParen)) {
        clean = clean.substring(0, trailingParenMatch.start).trim();
        if (detectedAuthor == null ||
            detectedAuthor.isEmpty ||
            detectedAuthor == 'Unknown Author') {
          detectedAuthor = _cleanAuthorString(insideParen);
        }
      }
    }

    // 6. Strip trailing ARC / edition clutter e.g. "King of Greed ARC" or "King of Greed - ARC"
    clean = clean.replaceAll(_editionSuffixPattern, ' ');

    // 7. Normalize underscores and hyphens used as separators
    clean = clean.replaceAll('_', ' ');
    clean = clean.replaceAll(RegExp(r'\s*[-–—]\s*'), ' - ');
    clean = clean.replaceAll(RegExp(r'(?<=\w)\s*-\s*(?=\w)'), ' - ');

    String? foundSeries;
    int? foundOrder;

    // 8. Check for explicit "Title - Author" or "Author - Title" separator
    if (clean.contains(' - ')) {
      final parts = clean
          .split(' - ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        if (_isEditionNoise(parts[1])) {
          clean = parts[0];
        } else if (_isEditionNoise(parts[0])) {
          clean = parts[1];
        } else {
          final part1 = _toCleanTitleCase(parts[0]);
          final part2 = _cleanAuthorString(parts[1]);

          if (_looksLikeAuthorName(part1) && !_looksLikeAuthorName(part2)) {
            final sInfo = parseTitleAndSeries(part2);
            return (
              title: sInfo.cleanTitle,
              author: (detectedAuthor != null && detectedAuthor != 'Unknown Author')
                  ? _cleanAuthorString(detectedAuthor)
                  : part1,
              seriesName: sInfo.seriesName,
              seriesOrder: sInfo.seriesOrder,
            );
          }
          final sInfo = parseTitleAndSeries(part1);
          return (
            title: sInfo.cleanTitle,
            author: (detectedAuthor != null && detectedAuthor != 'Unknown Author')
                ? _cleanAuthorString(detectedAuthor)
                : part2,
            seriesName: sInfo.seriesName,
            seriesOrder: sInfo.seriesOrder,
          );
        }
      }
    }

    // 9. Check for "Title by Author" separator
    final byMatch = RegExp(
      r'^(.*?)\s+by\s+(.*?)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (byMatch != null) {
      final titlePart = _toCleanTitleCase(byMatch.group(1)!);
      final authorPart = _cleanAuthorString(byMatch.group(2)!);
      final sInfo = parseTitleAndSeries(titlePart);
      return (
        title: sInfo.cleanTitle,
        author: (detectedAuthor != null && detectedAuthor != 'Unknown Author')
            ? _cleanAuthorString(detectedAuthor)
            : authorPart,
        seriesName: sInfo.seriesName,
        seriesOrder: sInfo.seriesOrder,
      );
    }

    // 10. Clean and format the remaining string as the title
    clean = clean.replaceAll(_multiSpacePattern, ' ').trim();
    String finalTitle = _toCleanTitleCase(clean);

    final sInfo = parseTitleAndSeries(finalTitle);
    finalTitle = sInfo.cleanTitle;
    foundSeries = sInfo.seriesName;
    foundOrder = sInfo.seriesOrder;

    String finalAuthor = 'Unknown Author';
    if (detectedAuthor != null &&
        detectedAuthor.isNotEmpty &&
        detectedAuthor != 'Unknown Author') {
      finalAuthor = _cleanAuthorString(detectedAuthor);
    }

    return (
      title: finalTitle.isNotEmpty ? finalTitle : 'Untitled Book',
      author: finalAuthor,
      seriesName: foundSeries,
      seriesOrder: foundOrder,
    );
  }

  /// Extracts clean core title, and separates any series/subtitle enclosed in brackets or parentheses, or after colons.
  static ({
    String cleanTitle,
    String? seriesName,
    int? seriesOrder,
    String? subtitle,
  }) parseTitleAndSeries(String rawTitle) {
    var title = rawTitle.trim();
    String? series;
    int? order;
    String? subTitle;

    title = title.replaceAll(_distributorParentheticalPattern, ' ');
    title = title.replaceAll(_formatAndEditionClutterPattern, ' ');

    if (title.contains(':')) {
      final colonParts = title.split(':');
      if (colonParts.length >= 2) {
        final mainPart = colonParts[0].trim();
        final trailingPart = colonParts.sublist(1).join(':').trim();
        if (mainPart.isNotEmpty &&
            !mainPart.toLowerCase().startsWith('chapter') &&
            !mainPart.toLowerCase().startsWith('part')) {
          title = mainPart;
          subTitle = trailingPart;
        }
      }
    }

    final parenMatch = RegExp(
      r'\s*[\(\[]\s*([^()\[\]]+?)\s*[\)\]]',
    ).firstMatch(title);

    if (parenMatch != null) {
      final rawParen = parenMatch.group(1)!.trim();
      title = title.replaceRange(parenMatch.start, parenMatch.end, '').trim();

      if (!_isEditionNoise(rawParen)) {
        final orderMatch = RegExp(
          r'(?:book|vol(?:ume)?|#|duet|part)\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(rawParen);
        if (orderMatch != null) {
          order = int.tryParse(orderMatch.group(1)!);
        } else {
          final trailingNum = RegExp(r'\b(\d+)\b').firstMatch(rawParen);
          if (trailingNum != null) {
            order = int.tryParse(trailingNum.group(1)!);
          }
        }

        var cleanSeries = rawParen
            .replaceAll(
              RegExp(r'\b(?:book|vol(?:ume)?|#|part)\s*\d+\b', caseSensitive: false),
              '',
            )
            .replaceAll(_multiSpacePattern, ' ')
            .trim();
        cleanSeries = cleanSeries.replaceAll(RegExp(r'[,:\-–—\s]+$'), '').trim();
        if (cleanSeries.isNotEmpty &&
            cleanSeries.toLowerCase() != 'a novel' &&
            cleanSeries.toLowerCase() != 'novel') {
          series = _toCleanTitleCase(cleanSeries);
        }
      }
    }

    if (series == null && subTitle != null) {
      final subSeriesMatch = RegExp(
        r'(?:series|book|duet|trilogy|chronicles|saga)\s*(\d+)?',
        caseSensitive: false,
      ).firstMatch(subTitle);
      if (subSeriesMatch != null) {
        series = _toCleanTitleCase(subTitle);
        if (subSeriesMatch.group(1) != null) {
          order = int.tryParse(subSeriesMatch.group(1)!);
        }
      }
    }

    title = title.replaceAll(RegExp(r'\s*[\(\[][^()\[\]]*[\)\]]\s*$'), '').trim();
    title = title.replaceAll(_editionSuffixPattern, '').trim();
    title = title.replaceAll(
      RegExp(r'(?<!\b(?:of|the)\s+)\b(?:arc|a\.r\.c\.)\b', caseSensitive: false),
      '',
    ).trim();
    title = title.replaceAll(RegExp(r'[\s\-–—:,]+$'), '').trim();
    title = title.replaceAll(_multiSpacePattern, ' ').trim();

    return (
      cleanTitle: title.isNotEmpty ? _toCleanTitleCase(title) : rawTitle,
      seriesName: series,
      seriesOrder: order,
      subtitle: subTitle,
    );
  }

  /// Cleans query strings for online book searching by stripping parenthesized/bracketed series clutter, edition tags, ARC, and colon subtitles
  static String cleanSearchQuery(String query) {
    var clean = query;
    if (clean.toLowerCase().startsWith('isbn:')) {
      clean = clean.substring(5).trim();
    } else if (clean.contains(':')) {
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

  static bool _isEditionNoise(String text) {
    final lower = text.toLowerCase().trim();
    return lower == 'arc' ||
        lower == 'a.r.c.' ||
        lower == 'arcs' ||
        lower == 'epub' ||
        lower == 'pdf' ||
        lower == 'mobi' ||
        lower == 'azw3' ||
        lower == 'retail' ||
        lower == 'repack' ||
        lower == 'special edition' ||
        lower == 'collector edition' ||
        lower == "collector's edition" ||
        lower == 'deluxe edition' ||
        lower == 'anniversary edition' ||
        lower == 'illustrated' ||
        lower == 'illustrated edition' ||
        lower == 'paperback' ||
        lower == 'hardcover' ||
        lower.startsWith('v0.') ||
        lower.startsWith('v1.') ||
        lower.startsWith('v2.') ||
        lower.startsWith('v3.') ||
        lower.startsWith('v4.') ||
        lower.startsWith('v5.') ||
        lower.contains('advance reader') ||
        lower.contains('advance reading') ||
        lower.contains('uncorrected proof') ||
        lower.contains('proof copy') ||
        lower.contains('review copy') ||
        lower.contains('galley');
  }

  static bool _isSeriesNoise(String text) {
    final lower = text.toLowerCase().trim();
    return lower.contains('series') ||
        lower.contains('book') ||
        lower.contains('vol') ||
        lower.contains('part') ||
        lower.contains('duet') ||
        lower.contains('trilogy') ||
        lower.contains('chronicles') ||
        lower.contains('saga') ||
        lower.contains('novel') ||
        lower.contains('chapter') ||
        RegExp(r'#\s*\d+').hasMatch(lower) ||
        RegExp(r'\b\d+\b').hasMatch(lower);
  }

  /// Sanitizes raw title strings extracted from PDF title / cover pages.
  static String sanitizeTitle(String rawTitle) {
    if (rawTitle.isEmpty) return 'Untitled Book';
    final lower = rawTitle.toLowerCase();
    if (lower.contains('illustration') ||
        lower.contains('visual content') ||
        (rawTitle.startsWith('[') && rawTitle.endsWith(']')) ||
        lower.contains('cover image') ||
        lower.contains('full text and layout')) {
      return 'Untitled Book';
    }

    String clean = rawTitle.replaceAll(_watermarkPattern, ' ');
    clean = clean.replaceAll(_copyrightSuffixPattern, '');
    clean = clean.replaceAll(_uuidPrefixPattern, '');
    clean = clean.replaceAll('_', ' ');
    clean = clean.replaceAll(_multiSpacePattern, ' ').trim();
    if (clean.isEmpty || clean.length < 2) return 'Untitled Book';
    final titleCase = _toCleanTitleCase(clean);
    return parseTitleAndSeries(titleCase).cleanTitle;
  }

  /// Sanitizes raw author strings extracted from PDF copyright / title pages.
  static String sanitizeAuthor(String rawAuthor) {
    return _cleanAuthorString(rawAuthor);
  }

  static String _cleanAuthorString(String raw) {
    if (raw.isEmpty) return 'Unknown Author';

    String cleaned = raw.replaceAll(_watermarkPattern, ' ');
    cleaned = cleaned.replaceAll(_copyrightSuffixPattern, '');
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^(?:by|written\s+by|author[:\-]?|novel\s+by|story\s+by)\s*',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[()\[\]{}~"“”’‘]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[0-9_\-*]{2,}'), ' ');
    cleaned = cleaned.replaceAll(_multiSpacePattern, ' ').trim();

    final lower = cleaned.toLowerCase();
    if (cleaned.isEmpty ||
        cleaned.length < 2 ||
        lower == 'pdf document' ||
        lower == 'unknown' ||
        lower == 'unknown author' ||
        lower == 'document' ||
        lower == 'untitled' ||
        lower == 'untitled book' ||
        lower == 'epub' ||
        lower == 'pdf' ||
        lower == 'download' ||
        lower == 'oceanofpdf' ||
        lower == 'z-library' ||
        lower == 'libgen') {
      return 'Unknown Author';
    }

    return _toCleanTitleCase(cleaned);
  }

  static String _toCleanTitleCase(String text) {
    if (text.isEmpty) return text;
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return text;

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
      'from',
    };

    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final lower = word.toLowerCase();

      if (i > 0 && minorWords.contains(lower)) {
        buffer.write(lower);
      } else {
        if (word.length >= 2 &&
            word == word.toUpperCase() &&
            !word.contains('.')) {
          buffer.write(
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          );
        } else if (word.isNotEmpty) {
          buffer.write('${word[0].toUpperCase()}${word.substring(1)}');
        }
      }

      if (i < words.length - 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString().trim();
  }

  static bool _looksLikeAuthorName(String text) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    return words.length >= 2 &&
        words.length <= 3 &&
        !text.toLowerCase().contains(' of ') &&
        !text.toLowerCase().contains(' the ');
  }

  /// Sanitizes online fetched or local synopsis by removing markdown links, URLs, format clutter, distributor watermarks, and decoding entities
  static String sanitizeSynopsis(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Decode numeric HTML entities (decimal &#1234; and hex &#x1a2b;)
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

    // 2. Decode named HTML entities and typography
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&apos;', "'")
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

    // 3. Convert HTML structure tags to appropriate line breaks
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?(?:p|div|section|article)[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ');
    text = text.replaceAll(RegExp(r'</?(?:ul|ol|li)[^>]*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 4. Remove Markdown links e.g. [**Haunting Adeline pdf**](https://bookrenzo.com/book/haunting-adeline)
    text = text.replaceAll(RegExp(r'\[([^\]]*)\]\([^\)]+\)'), ' ');

    // 5. Remove all URLs and web addresses (https, http, www, domain.tld/path)
    text = text.replaceAll(
      RegExp(r'https?://[^\s\)\]]+', caseSensitive: false),
      ' ',
    );
    text = text.replaceAll(
      RegExp(r'www\.[^\s\)\]]+', caseSensitive: false),
      ' ',
    );

    // 6. Remove distributor / piracy / download site URLs and watermarks
    text = text.replaceAll(
      RegExp(
        r'(?:\[|\(|\b)?(?:oceanofpdf|z-?library|libgen|1lib|library\s+genesis|pdfdrive|epubpub|bookzz|bookrenzo|mobilism|vk\.com|telegram|goodreads)(?:\.[a-z0-9\-_]+)*(?:/[^\s\)\]]*)?(?:\]|\)|\b)?',
        caseSensitive: false,
      ),
      ' ',
    );

    // 7. Remove format/download tags
    text = text.replaceAll(
      RegExp(
        r'\b(?:free\s+)?(?:download\s+)?(?:epub|pdf|mobi|azw3?)(?:\s*(?:&|and)\s*(?:epub|pdf|mobi|azw3?))?\s*(?:download|edition|format|novel|book|free)?\b',
        caseSensitive: false,
      ),
      ' ',
    );

    // 8. Remove Wikipedia citations e.g. [1], [2], [citation needed]
    text = text.replaceAll(
      RegExp(r'\[\s*(?:\d+|citation\s+needed)\s*\]', caseSensitive: false),
      ' ',
    );

    // 9. Remove header markdown clutter
    text = text.replaceAll(
      RegExp(
        r'^\s*#{1,6}\s*(?:overview|synopsis|summary|blurb|description|about\s+the\s+book)?\s*$',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    // 10. Convert bold section headers into structured paragraphs
    text = text.replaceAllMapped(
      RegExp(r'(?:\*\*|__)(.*?)(?:\*\*|__)'),
      (match) {
        final header = match.group(1)!.trim();
        if (header.isEmpty) return '';
        if (header.length <= 40 && !header.contains('.')) {
          return '\n\n$header\n';
        }
        return header;
      },
    );

    // 11. Strip empty brackets or parentheticals
    text = text.replaceAll(RegExp(r'[\(\[]\s*[\)\]]'), ' ');

    // 12. Remove trailing boilerplate / promotional noise
    text = text.replaceAll(
      RegExp(
        r'(?:read\s+(?:more|online|full\s+novel)\s*|click\s+here\s+to\s+.*|download\s+(?:free\s+)?(?:at\s+.*)?|available\s+(?:for\s+free\s+)?(?:download\s+)?(?:at\s+.*)?|source:\s*wikipedia|from\s+wikipedia.*)$',
        caseSensitive: false,
        multiLine: true,
      ),
      ' ',
    );

    // 13. Strip leftover dangling prepositions at end of lines
    text = text.replaceAll(
      RegExp(
        r'\b(?:at|on|from|via)\s*$',
        caseSensitive: false,
        multiLine: true,
      ),
      ' ',
    );

    // 14. Strip leftover markdown clutter
    text = text.replaceAll(RegExp(r'(?<!\w)[*_~#]{1,3}(?!\w)'), ' ');
    text = text.replaceAll(RegExp(r'[*_~#]{2,}'), ' ');
    text = text.replaceAll(RegExp(r'[\[\]]'), ' ');

    // 15. Normalize whitespace & line breaks
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

    var result = buffer.toString().trim();

    // 16. Strip trailing cut-off fragment (e.g. "D...", "...", or broken word at very end)
    result = result.replaceAll(RegExp(r'(?:\n|\s+)[a-zA-Z]{1,3}\.{2,3}\s*$'), '').trim();

    return result;
  }

  /// Detects whether a synopsis is incomplete, truncated mid-sentence,
  /// cut off with an ellipsis, or a placeholder requiring full online enrichment.
  static bool isTruncatedSynopsis(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    final clean = text.trim();
    if (clean.length < 100) return true;

    // Check for trailing ellipsis or truncated letter with ellipsis (e.g. "D...", "...", "…")
    if (RegExp(r'(?:[a-zA-Z]\.{2,3}|\.{3,}|…)\s*$').hasMatch(clean)) {
      return true;
    }

    // Check if ends mid-sentence without terminal punctuation
    final lastChar = clean[clean.length - 1];
    if (!'.!?”"\'’'.contains(lastChar)) {
      return true;
    }

    // Check for common truncated tags or placeholders
    final lower = clean.toLowerCase();
    if (lower.contains('[truncated]') ||
        lower.contains('read more') ||
        lower.contains('continue reading') ||
        lower.contains('a captivating story by') ||
        lower.contains('imported from reading catalog') ||
        lower.contains('imported from csv') ||
        lower.contains('published by open library') ||
        lower.contains('no overview provided')) {
      return true;
    }

    return false;
  }

  static const Set<String> _discardTagPrefixes = {
    'collectionid:',
    'collection_id:',
    'collection:',
    'calibre:',
    'ia:',
    'ia_box_id:',
    'lending_library',
    'archive.org',
    'accessible_book',
    'protected_daisy',
    'inlibrary',
    'printdisabled',
    'nyt:',
    'nyt_',
    'bestseller',
    'new york times',
    'times bestseller',
    'isbn:',
    'isbn10:',
    'isbn13:',
    'issn:',
    'asin:',
    'goodreads:',
    'amazon:',
    'oclc:',
    'lccn:',
    'doi:',
    'uuid:',
    'guid:',
    'urn:',
    'id:',
    'schema:',
    'bisac:',
    'ddc:',
    'lcc:',
    'thema:',
    'bic:',
    'serie:',
    'series:',
    'series_id:',
    'status:',
    'format:',
    'cover:',
    'meta:',
    'source:',
  };

  static const Set<String> _discardExactTags = {
    'fiction',
    'general',
    'miscellaneous',
    'misc',
    'other',
    'uncategorized',
    'unknown',
    'n/a',
    'na',
    'none',
    'default',
    'books',
    'book',
    'ebook',
    'ebooks',
    'epub',
    'pdf',
    'mobi',
    'azw',
    'azw3',
    'paperback',
    'hardcover',
    'audiobook',
    'audio',
    'read',
    'to-read',
    'to read',
    'currently-reading',
    'favorites',
    'favourites',
    'owned',
    'books-i-own',
    'wishlist',
    'kindle',
    'borrowed',
    'reviewed',
    'library',
    'oceanofpdf',
    'z-library',
    'libgen',
    '1lib',
    'pdfdrive',
    'bookzz',
    'mobilism',
    'vk.com',
    'telegram',
    'epubpub',
  };

  /// Sanitizes and deduplicates tags, removing machine identifiers (collectionID, calibre),
  /// splitting composite BISAC categories, removing boilerplate noise tags (general, ebook),
  /// and applying clean title casing.
  static List<String> sanitizeTags(List<String> rawTags) {
    if (rawTags.isEmpty) return [];

    final uniqueTags = <String, String>{};

    for (final raw in rawTags) {
      if (raw.trim().isEmpty) continue;

      final splitParts = raw.contains('/') || raw.contains(';')
          ? raw.split(RegExp(r'[/;]'))
          : [raw];

      for (var token in splitParts) {
        var item = token.trim();
        if (item.isEmpty) continue;

        item = item.replaceAll(
          RegExp(r'^[\[\(\{\"\x27\-_:;•\\/\s]+|[\]\)\}"\x27\-_:;•\\/\s]+$'),
          '',
        );
        if (item.length < 2 || item.length > 50) continue;

        final lower = item.toLowerCase();

        if (lower.contains('=') ||
            _discardTagPrefixes.any(
              (prefix) => lower.startsWith(prefix) || lower == prefix,
            )) {
          continue;
        }

        if (RegExp(r'^\d+$').hasMatch(lower) ||
            RegExp(r'^[0-9a-f\-]{16,}$').hasMatch(lower)) {
          continue;
        }

        if (lower.startsWith('genre:') ||
            lower.startsWith('category:') ||
            lower.startsWith('subject:') ||
            lower.startsWith('tag:')) {
          final colonIdx = item.indexOf(':');
          if (colonIdx != -1 && colonIdx < item.length - 1) {
            item = item.substring(colonIdx + 1).trim();
          }
        }

        final cleanedLower =
            item.toLowerCase().replaceAll(RegExp(r'[-_]'), ' ').trim();
        if (_discardExactTags.contains(cleanedLower) ||
            _discardExactTags.contains(item.toLowerCase())) {
          continue;
        }

        if (item.length < 2) continue;

        final dedupeKey = cleanedLower;
        if (!uniqueTags.containsKey(dedupeKey)) {
          final cleanTag = _toCleanTitleCase(item);
          uniqueTags[dedupeKey] = cleanTag;
        }
      }
    }

    return uniqueTags.values.toList();
  }
}
