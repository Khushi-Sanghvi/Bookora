class GenreParser {
  static final Set<String> _blacklist = {
    'accessible book',
    'protected daisy',
    'in library',
    'lending library',
    'borrowable',
    'open library',
    'internet archive wishlist',
  };

  /// Parses raw genre/category dynamic payload (strings, lists, nested hierarchical
  /// BISAC strings like "Fiction / Romance / Contemporary") into a clean,
  /// deduplicated, title-cased list of distinct genre tags.
  static List<String> parseRawGenres(dynamic rawData) {
    if (rawData == null) return const [];

    final List<String> uniqueGenres = [];
    final Set<String> seenLower = {};

    void processString(String str) {
      // Split on common category separators: /, ,, ;, and --
      final tokens = str.split(RegExp(r'[/,;]|--'));
      for (var token in tokens) {
        final cleaned = token
            .trim()
            .replaceAll(RegExp(r'^[\\/\s]+|[\\/\s]+$'), '')
            .trim();
        if (cleaned.isNotEmpty && !_blacklist.contains(cleaned.toLowerCase())) {
          // Capitalize each word nicely
          final formatted = cleaned
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
              .join(' ');

          final lower = formatted.toLowerCase();
          if (formatted.isNotEmpty && !seenLower.contains(lower)) {
            seenLower.add(lower);
            uniqueGenres.add(formatted);
          }
        }
      }
    }

    if (rawData is List) {
      for (var item in rawData) {
        if (item != null) {
          processString(item.toString());
        }
      }
    } else if (rawData is String) {
      processString(rawData);
    }

    return uniqueGenres;
  }

  /// Semantically infers 2-3 authentic genre tags from a book's title, author,
  /// and description when online APIs return 0 category metadata (e.g. for indie,
  /// self-published, and Kindle Unlimited titles).
  static List<String> inferGenresFromContext({
    required String title,
    required String author,
    required String description,
  }) {
    final text = '$title $author $description'.toLowerCase();
    final detected = <String>[];

    // 1. Dark Romance / Contemporary Romance / Romantasy
    final isRomance = text.contains('romance') ||
        text.contains('love story') ||
        text.contains('dating') ||
        text.contains('billionaire') ||
        text.contains('possessive') ||
        text.contains('arranged marriage') ||
        text.contains('enemies to lovers') ||
        text.contains('fake relationship') ||
        text.contains('twisted') ||
        text.contains('ana huang') ||
        text.contains('colleen hoover') ||
        text.contains('lucy score') ||
        text.contains('passion') ||
        text.contains('heartbreak') ||
        text.contains('kiss') ||
        text.contains('desire') ||
        text.contains('crush');

    if (text.contains('dark romance') ||
        text.contains('mafia') ||
        text.contains('billionaire') ||
        text.contains('possessive') ||
        text.contains('stalker') ||
        text.contains('ruthless') ||
        text.contains('god of') ||
        text.contains('king of') ||
        text.contains('wrath')) {
      detected.add('Dark Romance');
      detected.add('Contemporary Romance');
    } else if (isRomance) {
      if (text.contains('cowboy') || text.contains('ranch') || text.contains('small town')) {
        detected.add('Western Romance');
      }
      detected.add('Contemporary Romance');
    }

    // 2. Fantasy / Paranormal / Romantasy / Sci-Fi
    if (text.contains('dragon') ||
        text.contains('magic') ||
        text.contains('fae') ||
        text.contains('witch') ||
        text.contains('sorcer') ||
        text.contains('kingdom') ||
        text.contains('sword') ||
        text.contains('sanderson') ||
        text.contains('fourth wing')) {
      if (isRomance || text.contains('fae') || text.contains('court of')) {
        detected.add('Romantasy');
        detected.add('Fantasy');
      } else {
        detected.add('High Fantasy');
        detected.add('Epic Fantasy');
      }
    } else if (text.contains('sci-fi') ||
        text.contains('science fiction') ||
        text.contains('space') ||
        text.contains('alien') ||
        text.contains('galaxy') ||
        text.contains('cyber') ||
        text.contains('dystopian')) {
      detected.add('Science Fiction');
      if (text.contains('dystopian') || text.contains('apocalypse')) {
        detected.add('Dystopian');
      }
    }

    // 3. Thriller / Mystery / Psychological Suspense
    if (text.contains('murder') ||
        text.contains('killer') ||
        text.contains('detective') ||
        text.contains('investigat') ||
        text.contains('clue') ||
        text.contains('police') ||
        text.contains('crime')) {
      detected.add('Mystery');
      detected.add('Crime Thriller');
    } else if (text.contains('thriller') ||
        text.contains('suspense') ||
        text.contains('psychological') ||
        text.contains('chilling') ||
        text.contains('secrets') ||
        text.contains('verity')) {
      detected.add('Psychological Thriller');
      detected.add('Suspense');
    }

    // 4. Gothic / Horror / Dark Academia
    if (text.contains('dark academia') ||
        text.contains('secret society') ||
        text.contains('oxford') ||
        text.contains('secret history')) {
      detected.add('Dark Academia');
      detected.add('Literary Fiction');
    } else if (text.contains('haunted') ||
        text.contains('ghost') ||
        text.contains('gothic') ||
        text.contains('vampire') ||
        text.contains('horror') ||
        text.contains('curse')) {
      detected.add('Gothic Fiction');
      detected.add('Horror');
    }

    // 5. Historical Fiction
    if (text.contains('victorian') ||
        text.contains('regency') ||
        text.contains('historical') ||
        text.contains('wwii') ||
        text.contains('war') ||
        text.contains('duke') ||
        text.contains('century')) {
      detected.add('Historical Fiction');
    }

    // 6. Young Adult / New Adult
    if (text.contains('high school') ||
        text.contains('academy') ||
        text.contains('college') ||
        text.contains('teen') ||
        text.contains('coming of age')) {
      detected.add('Young Adult');
    }

    // 7. Non-Fiction Fallback
    if (detected.isEmpty) {
      if (text.contains('memoir') ||
          text.contains('biography') ||
          text.contains('essay') ||
          text.contains('self-help') ||
          text.contains('guide')) {
        detected.add('Nonfiction');
        detected.add('Memoir');
      } else {
        detected.addAll(['Contemporary Fiction', 'Literary Prose']);
      }
    }

    return detected.toSet().take(3).toList();
  }
}
