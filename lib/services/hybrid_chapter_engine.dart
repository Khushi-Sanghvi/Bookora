class ParsedChapter {
  final String title;
  final String content;
  final int pageOffset;
  final String? anchor;

  ParsedChapter({
    required this.title,
    required this.content,
    required this.pageOffset,
    this.anchor,
  });
}

/// Result container for the Hybrid Chapter Discovery System.
class HybridChapterResult {
  final List<ParsedChapter> chapters;
  final bool hasCustomLayout;
  final int totalDiscoveredCount;

  const HybridChapterResult({
    required this.chapters,
    required this.hasCustomLayout,
    required this.totalDiscoveredCount,
  });

  @override
  String toString() =>
      'HybridChapterResult(count: ${chapters.length}, hasCustomLayout: $hasCustomLayout)';
}

/// The taxonomy style classification for chapter markers.
enum ChapterTaxonomyStyle {
  standardMatter, // "Playlist", "Prologue", "Epilogue", "Author's Note", etc.
  explicitChapter, // "Chapter 1", "Chapter 2", "Ch. 15", etc.
  writtenNumber, // "Chapter One", "Twenty-Three", "THREE - THE DISASTER", etc.
  romanNumeral, // "Chapter I", "Chapter II", "IV. IN THE SHADOWS", etc.
  partDivision, // "Part 1", "Part Two", "Volume I", etc.
  standaloneNumber, // "1", "2", "15: Killian", etc.
}

/// Internal candidate token discovered during document layout analysis.
class _ChapterCandidate {
  final int pageOffset;
  final String title;
  final ChapterTaxonomyStyle style;
  final int? numericValue;
  final String? subtitle;

  const _ChapterCandidate({
    required this.pageOffset,
    required this.title,
    required this.style,
    this.numericValue,
    this.subtitle,
  });

  @override
  String toString() =>
      '_ChapterCandidate(p$pageOffset: "$title", style: $style, num: $numericValue)';
}

/// The Definitive Hybrid Chapter Discovery & Sequential Harmonization Engine for Bookora.
/// Enforces dominant sequential taxonomy locking with zero style inconsistencies.
class HybridChapterEngine {
  HybridChapterEngine._();

  // 1. Bulletproof Regex Patterns

  // Pattern 1: Standard Matter
  static final RegExp standardMatterRegex = RegExp(
    r'''^(?:Playlist|Music\s+Playlist|Prologue|Epilogue|Introduction|Preface|Afterword|Foreword|Author(?:\x27s)?\s+Note|Note\s+from\s+(?:the\s+)?Author|Dear\s+Reader|Note\s+to\s+Reader|Content\s+Warnings?|Trigger\s+Warnings?|Reader\s+Warnings?|Warnings?|Dedication|Acknowledgments?|Acknowledgements?|Interlude|Intermission|Cast\s+of\s+Characters|Glossary)(?:\s*[\:\-\–\.\~]\s*([^\n\r]{2,60}))?$''',
    caseSensitive: false,
  );

  // Pattern 2: Explicit Chapter Digits
  static final RegExp explicitChapterDigitsRegex = RegExp(
    r'''^(?:(?:Chapter|Chap\.|Ch\.)\s+(\d+)|(\d+)[\.\:\-\–\~](?:\s+([^\n\r]{2,60}))?)(?:\s*[\:\-\–\.\~]\s*([^\n\r]{2,60}))?$''',
    caseSensitive: false,
  );

  // Pattern 3: Written Chapter Numbers
  static final RegExp writtenChapterNumbersRegex = RegExp(
    r'''^(?:Chapter\s+)?(Twenty-One|Twenty-Two|Twenty-Three|Twenty-Four|Twenty-Five|Twenty-Six|Twenty-Seven|Twenty-Eight|Twenty-Nine|Thirty-One|Thirty-Two|Thirty-Three|Thirty-Four|Thirty-Five|Forty-One|Forty-Two|Forty-Three|Forty-Four|Forty-Five|Fifty-One|Fifty-Two|Fifty-Three|Fifty-Four|Fifty-Five|Zero|One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|Eleven|Twelve|Thirteen|Fourteen|Fifteen|Sixteen|Seventeen|Eighteen|Nineteen|Twenty|Thirty|Forty|Fifty|Sixty|Seventy|Eighty|Ninety|One\s+Hundred)(?:\s*[\:\-\–\.\~]\s*([^\n\r]{2,60}))?$''',
    caseSensitive: false,
  );

  // Pattern 4: Hierarchical & Compound Divisions
  static final RegExp hierarchicalDivisionRegex = RegExp(
    r'''^(?:Volume|Vol\.?|Book|Part|Act|Canto|Section)\s+([0-9IVXLCDM\w\s\’\‘\'\(\)\:\-\–\.]+)?''',
    caseSensitive: false,
  );

  // Pattern 5: Roman Numeral Chapters
  static final RegExp romanNumeralRegex = RegExp(
    r'''^(?:(?:Chapter|Ch\.|Part)\s+)?([IVXLCDM]{1,8})\.?(?:\s*[\:\-\–\.\~]\s*([A-Za-z0-9\s\’\‘\'\-\,\?]{2,60}))?$''',
    caseSensitive: false,
  );

  static final RegExp _standaloneDigitRegex = RegExp(r'^\d{1,4}$');

  /// Evaluates up to 6 opening lines from a page buffer using chronological structural pattern scanning.
  static String? evaluatePageHeading(List<String> pageLines) {
    final candidate = _extractCandidateFromLines(pageLines, 0);
    return candidate?.title;
  }

  /// Extracts a structured chapter candidate from page lines with noise filtering.
  static _ChapterCandidate? _extractCandidateFromLines(
    List<String> pageLines,
    int pageOffset,
  ) {
    if (pageLines.isEmpty) return null;

    final cleanLines = pageLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isNoiseOrPagination(l))
        .take(6)
        .toList();
    if (cleanLines.isEmpty) return null;

    for (int i = 0; i < cleanLines.length && i < 4; i++) {
      final line = cleanLines[i];
      if (_isExcludedLine(line) || _isAggressiveDialogue(line)) continue;

      // 1. Standard Matter
      final matterMatch = standardMatterRegex.firstMatch(line);
      if (matterMatch != null) {
        final base = _toCleanTitleCase(
          line.split(RegExp(r'[\:\-\–\.]')).first.trim(),
        );
        var sub = matterMatch.groupCount >= 1
            ? matterMatch.group(1)?.trim()
            : null;

        if ((sub == null || sub.isEmpty) && i + 1 < cleanLines.length) {
          final nextLine = cleanLines[i + 1];
          if (_isProperNameOrSubtitle(nextLine)) {
            sub = nextLine;
          }
        }

        final title = (sub != null && sub.isNotEmpty)
            ? '$base: ${_toCleanTitleCase(sub)}'
            : base;
        return _ChapterCandidate(
          pageOffset: pageOffset,
          title: title,
          style: ChapterTaxonomyStyle.standardMatter,
          subtitle: sub,
        );
      }

      // 2. Explicit Chapter Digits
      final digitMatch = explicitChapterDigitsRegex.firstMatch(line);
      if (digitMatch != null) {
        final numStr =
            digitMatch.group(1)?.trim() ?? digitMatch.group(2)?.trim();
        final numVal = int.tryParse(numStr ?? '');
        var sub = digitMatch.group(3)?.trim() ?? digitMatch.group(4)?.trim();

        if ((sub == null || sub.isEmpty) && i + 1 < cleanLines.length) {
          final nextLine = cleanLines[i + 1];
          if (_isProperNameOrSubtitle(nextLine)) {
            sub = nextLine;
          }
        }

        final base = 'Chapter $numStr';
        final title = (sub != null && sub.isNotEmpty)
            ? '$base: ${_toCleanTitleCase(sub)}'
            : base;
        return _ChapterCandidate(
          pageOffset: pageOffset,
          title: title,
          style: ChapterTaxonomyStyle.explicitChapter,
          numericValue: numVal,
          subtitle: sub,
        );
      }

      // 3. Standalone Digit line
      if (_standaloneDigitRegex.hasMatch(line)) {
        final numVal = int.tryParse(line);
        final base = 'Chapter $line';
        String? sub;
        if (i + 1 < cleanLines.length) {
          final nextLine = cleanLines[i + 1];
          if (_isProperNameOrSubtitle(nextLine)) {
            sub = nextLine;
          }
        }
        final title = (sub != null && sub.isNotEmpty)
            ? '$base: ${_toCleanTitleCase(sub)}'
            : base;
        return _ChapterCandidate(
          pageOffset: pageOffset,
          title: title,
          style: ChapterTaxonomyStyle.standaloneNumber,
          numericValue: numVal,
          subtitle: sub,
        );
      }

      // 4. Written Chapter Numbers
      final wordMatch = writtenChapterNumbersRegex.firstMatch(line);
      if (wordMatch != null) {
        final numWord = wordMatch.group(1)!.trim();
        final numVal = _parseWrittenNumber(numWord);
        var sub = wordMatch.groupCount >= 2 ? wordMatch.group(2)?.trim() : null;
        final formattedNum = numWord
            .split('-')
            .map((p) => _toCleanTitleCase(p))
            .join('-');
        final base = 'Chapter $formattedNum';

        if ((sub == null || sub.isEmpty) && i + 1 < cleanLines.length) {
          final nextLine = cleanLines[i + 1];
          if (_isProperNameOrSubtitle(nextLine)) {
            sub = nextLine;
          }
        }

        final title = (sub != null && sub.isNotEmpty)
            ? '$base: ${_toCleanTitleCase(sub)}'
            : base;
        return _ChapterCandidate(
          pageOffset: pageOffset,
          title: title,
          style: ChapterTaxonomyStyle.writtenNumber,
          numericValue: numVal,
          subtitle: sub,
        );
      }

      // 5. Hierarchical Divisions
      final hierMatch = hierarchicalDivisionRegex.firstMatch(line);
      if (hierMatch != null) {
        final base = _toCleanTitleCase(line.split('\n').first.trim());
        String? sub;
        if (i + 1 < cleanLines.length) {
          final nextLine = cleanLines[i + 1];
          if (_isProperNameOrSubtitle(nextLine)) {
            sub = nextLine;
          }
        }
        final title = (sub != null && sub.isNotEmpty)
            ? '$base: ${_toCleanTitleCase(sub)}'
            : base;
        return _ChapterCandidate(
          pageOffset: pageOffset,
          title: title,
          style: ChapterTaxonomyStyle.partDivision,
          subtitle: sub,
        );
      }

      // 6. Roman Numeral Chapters
      final romanMatch = romanNumeralRegex.firstMatch(line);
      if (romanMatch != null) {
        final numeral = romanMatch.group(1)!.trim().toUpperCase();
        final numVal = _parseRomanNumeral(numeral);
        var sub = romanMatch.group(2)?.trim();

        final isSubChapter =
            sub != null &&
            RegExp(
              r'^(?:chapter|ch\.)\s*\d+',
              caseSensitive: false,
            ).hasMatch(sub);
        final isSingleLetterInitial =
            numeral.length == 1 &&
            !line.toLowerCase().startsWith('chapter') &&
            !line.toLowerCase().startsWith('part');

        if (!isSubChapter && !isSingleLetterInitial) {
          if ((sub == null || sub.isEmpty) && i + 1 < cleanLines.length) {
            final nextLine = cleanLines[i + 1];
            if (_isProperNameOrSubtitle(nextLine)) {
              sub = nextLine;
            }
          }

          final cleanHeader =
              line.toLowerCase().startsWith('chapter') ||
                  line.toLowerCase().startsWith('ch.')
              ? 'Chapter $numeral'
              : (line.toLowerCase().startsWith('part')
                    ? 'Part $numeral'
                    : 'Chapter $numeral');

          final title = (sub != null && sub.isNotEmpty)
              ? '$cleanHeader: ${_toCleanTitleCase(sub)}'
              : cleanHeader;
          return _ChapterCandidate(
            pageOffset: pageOffset,
            title: title,
            style: ChapterTaxonomyStyle.romanNumeral,
            numericValue: numVal,
            subtitle: sub,
          );
        }
      }
    }

    return null;
  }

  /// Scans the entire text of a book page-by-page using the Strict Universal Sequential Engine.
  /// Locks onto the book's dominant taxonomy style and eliminates format inconsistencies.
  static HybridChapterResult discoverChapters({
    required List<String> pages,
    String? bookTitle,
    String? bookAuthor,
  }) {
    if (pages.isEmpty) {
      return const HybridChapterResult(
        chapters: [],
        hasCustomLayout: true,
        totalDiscoveredCount: 0,
      );
    }

    // Step 1: Collect candidates across all pages
    final List<_ChapterCandidate> rawCandidates = [];

    for (int i = 0; i < pages.length; i++) {
      final pageText = pages[i].trim();
      if (pageText.isEmpty) continue;

      final pageLines = pageText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(6)
          .toList();

      final cand = _extractCandidateFromLines(pageLines, i);
      if (cand != null) {
        if (rawCandidates.isEmpty || rawCandidates.last.pageOffset != i) {
          rawCandidates.add(cand);
        }
      }
    }

    // Step 2: Determine Dominant Style among numbered body chapters
    int explicitCount = 0;
    int writtenCount = 0;
    int romanCount = 0;
    int partCount = 0;
    int standaloneCount = 0;

    for (final c in rawCandidates) {
      switch (c.style) {
        case ChapterTaxonomyStyle.explicitChapter:
          explicitCount++;
          break;
        case ChapterTaxonomyStyle.writtenNumber:
          writtenCount++;
          break;
        case ChapterTaxonomyStyle.romanNumeral:
          romanCount++;
          break;
        case ChapterTaxonomyStyle.partDivision:
          partCount++;
          break;
        case ChapterTaxonomyStyle.standaloneNumber:
          standaloneCount++;
          break;
        case ChapterTaxonomyStyle.standardMatter:
          break;
      }
    }

    ChapterTaxonomyStyle dominantStyle = ChapterTaxonomyStyle.explicitChapter;
    int maxCount = explicitCount;

    if (writtenCount > maxCount) {
      dominantStyle = ChapterTaxonomyStyle.writtenNumber;
      maxCount = writtenCount;
    }
    if (romanCount > maxCount) {
      dominantStyle = ChapterTaxonomyStyle.romanNumeral;
      maxCount = romanCount;
    }
    if (partCount > maxCount) {
      dominantStyle = ChapterTaxonomyStyle.partDivision;
      maxCount = partCount;
    }
    if (standaloneCount > maxCount) {
      dominantStyle = ChapterTaxonomyStyle.standaloneNumber;
      maxCount = standaloneCount;
    }

    // Step 3: Sequential Harmonization & Consistency Filter
    final List<ParsedChapter> harmonized = [];
    final Set<String> seenNormalizedKeys = {};
    int lastObservedNumber = 0;

    for (final cand in rawCandidates) {
      if (cand.style == ChapterTaxonomyStyle.standardMatter) {
        final key = cand.title.toLowerCase();
        if (!seenNormalizedKeys.contains(key)) {
          seenNormalizedKeys.add(key);
          harmonized.add(
            ParsedChapter(
              title: cand.title,
              content: '',
              pageOffset: cand.pageOffset,
            ),
          );
        }
        continue;
      }

      String finalTitle = cand.title;
      final int? numVal = cand.numericValue;

      if (dominantStyle == ChapterTaxonomyStyle.explicitChapter ||
          dominantStyle == ChapterTaxonomyStyle.standaloneNumber ||
          dominantStyle == ChapterTaxonomyStyle.writtenNumber) {
        if ((cand.style == ChapterTaxonomyStyle.partDivision ||
                cand.style == ChapterTaxonomyStyle.romanNumeral) &&
            numVal == null) {
          if (explicitCount >= 3) {
            continue;
          }
        }

        if (numVal != null) {
          if (numVal <= lastObservedNumber &&
              numVal > 0 &&
              harmonized.any((h) => h.title.startsWith('Chapter $numVal'))) {
            continue;
          }
          lastObservedNumber = numVal;

          if (dominantStyle == ChapterTaxonomyStyle.explicitChapter ||
              dominantStyle == ChapterTaxonomyStyle.standaloneNumber) {
            if (cand.style == ChapterTaxonomyStyle.explicitChapter ||
                cand.style == ChapterTaxonomyStyle.standaloneNumber) {
              final base = 'Chapter $numVal';
              finalTitle = (cand.subtitle != null && cand.subtitle!.isNotEmpty)
                  ? '$base: ${_toCleanTitleCase(cand.subtitle!)}'
                  : base;
            }
          }
        }
      }

      final key = finalTitle.toLowerCase();
      if (!seenNormalizedKeys.contains(key)) {
        seenNormalizedKeys.add(key);
        harmonized.add(
          ParsedChapter(
            title: finalTitle,
            content: '',
            pageOffset: cand.pageOffset,
          ),
        );
      }
    }

    final bool hasCustomLayout = harmonized.length < 3;

    if (hasCustomLayout) {
      return const HybridChapterResult(
        chapters: [],
        hasCustomLayout: true,
        totalDiscoveredCount: 0,
      );
    }

    return HybridChapterResult(
      chapters: harmonized,
      hasCustomLayout: false,
      totalDiscoveredCount: harmonized.length,
    );
  }

  static int? _parseWrittenNumber(String word) {
    const map = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
      'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
      'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
      'twenty': 20, 'twenty-one': 21, 'twenty-two': 22, 'twenty-three': 23,
      'twenty-four': 24, 'twenty-five': 25, 'twenty-six': 26,
      'twenty-seven': 27, 'twenty-eight': 28, 'twenty-nine': 29,
      'thirty': 30, 'thirty-one': 31, 'thirty-two': 32, 'thirty-three': 33,
      'thirty-four': 34, 'thirty-five': 35, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90, 'one hundred': 100,
    };
    return map[word.toLowerCase().trim()];
  }

  static int? _parseRomanNumeral(String roman) {
    const romanValues = {
      'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000,
    };
    int total = 0;
    int prevValue = 0;
    final clean = roman.toUpperCase().trim();

    for (int i = clean.length - 1; i >= 0; i--) {
      final val = romanValues[clean[i]];
      if (val == null) return null;
      if (val < prevValue) {
        total -= val;
      } else {
        total += val;
        prevValue = val;
      }
    }
    return total > 0 ? total : null;
  }

  static bool _isNoiseOrPagination(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('oceanofpdf') ||
        lower.contains('z-library') ||
        lower.contains('libgen')) {
      return true;
    }
    if (RegExp(
      r'^[\-\—\–]?\s*\d+\s*(?:\/|\sof\s)\s*\d+\s*[\-\—\–]?$',
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(
      r'^page\s+\d+(?:\s*(?:\/|\sof\s)\s*\d+)?$',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static bool _isProperNameOrSubtitle(String line) {
    final clean = line.trim();
    if (clean.length < 2 || clean.length > 50) return false;
    if (_isExcludedLine(clean) || _isSentence(clean)) return false;
    if (_isAggressiveDialogue(clean)) return false;

    if (RegExp(
      r'^(?:chapter|chap\.|ch\.|part|vol|volume|\d+)',
      caseSensitive: false,
    ).hasMatch(clean)) {
      return false;
    }

    final words = clean.split(RegExp(r'\s+'));
    return words.isNotEmpty && words.length <= 6;
  }

  static bool _isAggressiveDialogue(String line) {
    final clean = line.trim();
    if (clean.length > 40 &&
        (clean.startsWith('“') ||
            clean.startsWith('"') ||
            clean.startsWith('\''))) {
      return true;
    }
    if (clean.endsWith('.”') ||
        clean.endsWith('?”') ||
        clean.endsWith('!”') ||
        clean.endsWith('."') ||
        clean.endsWith('?"')) {
      return true;
    }
    return false;
  }

  static bool _isExcludedLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('oceanofpdf') ||
        lower.contains('z-library') ||
        lower.contains('copyright') ||
        lower.contains('www.') ||
        lower.contains('http') ||
        lower.contains('page ') ||
        lower.contains('all rights') ||
        lower.contains('published');
  }

  static bool _isSentence(String line) {
    return line.endsWith('.') ||
        line.endsWith('?') ||
        line.endsWith('!') ||
        line.endsWith(';') ||
        line.endsWith(',');
  }

  static String _toCleanTitleCase(String text) {
    if (text.isEmpty) return text;
    var clean = text.trim();
    final charsToStrip = [
      '(', ')', '[', ']', '{', '}', '"', '“', '”', "'", '‘', '’', '-', '–', '—', ':',
    ];
    while (clean.isNotEmpty &&
        (charsToStrip.contains(clean[0]) || clean[0] == ' ')) {
      clean = clean.substring(1).trim();
    }
    while (clean.isNotEmpty &&
        (charsToStrip.contains(clean[clean.length - 1]) ||
            clean[clean.length - 1] == ' ')) {
      clean = clean.substring(0, clean.length - 1).trim();
    }
    if (clean.isEmpty) return '';

    final lowerWords = {
      'a', 'an', 'the', 'and', 'but', 'or', 'for', 'nor', 'on', 'at', 'to', 'from', 'by', 'of', 'in',
    };
    final words = clean.split(RegExp(r'\s+'));
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;
      final lower = w.toLowerCase();
      if (i == 0 || !lowerWords.contains(lower)) {
        result.add('${lower[0].toUpperCase()}${lower.substring(1)}');
      } else {
        result.add(lower);
      }
    }
    return result.join(' ');
  }
}
