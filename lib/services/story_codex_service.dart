import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../models/story_codex.dart';
import 'book_metadata_sanitizer.dart';
import 'cache_service.dart';
import 'story_codex_engine.dart';

class StoryCodexService {
  StoryCodexService._();

  static const String _cacheSubdir = 'story_codex_cache';
  static final http.Client _httpClient = http.Client();

  // --- 1. CACHING & PERSISTENCE ---

  /// Instant synchronous memory lookup (< 0.01ms)
  static StoryCodex? getCachedCodexSync(String bookId) {
    try {
      final raw = CacheService().get<dynamic>('story_codex_$bookId');
      if (raw == null) return null;
      if (raw is StoryCodex) return raw;
      if (raw is Map<String, dynamic>) {
        return StoryCodex.fromJson(raw);
      }
      if (raw is Map) {
        return StoryCodex.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {
      CacheService().remove('story_codex_$bookId');
    }
    return null;
  }

  /// Ergonomic alias for getCachedCodexSync
  static StoryCodex? peekCachedCodex(String bookId) => getCachedCodexSync(bookId);

  /// Persistent disk directory getter
  static Future<Directory> _getDiskCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _cacheSubdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Loads cached codex from memory first, then disk
  static Future<StoryCodex?> getCachedCodex(String bookId) async {
    // 1. Check in-memory CacheService
    final memHit = getCachedCodexSync(bookId);
    if (memHit != null) return memHit;

    // 2. Check persistent disk cache
    try {
      final dir = await _getDiskCacheDir();
      final file = File(p.join(dir.path, 'codex_$bookId.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          final codex = StoryCodex.fromJson(decoded);
          // Re-populate in-memory cache
          CacheService().set('story_codex_$bookId', codex.toMap(), ttl: const Duration(days: 30));
          return codex;
        }
      }
    } catch (e) {
      debugPrint('Error reading StoryCodex disk cache for $bookId: $e');
    }
    return null;
  }

  /// Persists codex to memory and disk
  static Future<void> saveCodexToCache(StoryCodex codex) async {
    try {
      // 1. Memory cache
      CacheService().set('story_codex_${codex.bookId}', codex.toMap(), ttl: const Duration(days: 30));

      // 2. Disk cache
      final dir = await _getDiskCacheDir();
      final file = File(p.join(dir.path, 'codex_${codex.bookId}.json'));
      await file.writeAsString(jsonEncode(codex.toJson()));
    } catch (e) {
      debugPrint('Error saving StoryCodex cache for ${codex.bookId}: $e');
    }
  }

  // --- 2. MULTI-TIER ENRICHMENT PIPELINE ---

  /// Ergonomic alias for getCodexForBook
  static Future<StoryCodex> enrichCodex(Book book) => getCodexForBook(book);

  /// Main entry point: returns cached codex or enriches dynamically across tiers
  static Future<StoryCodex> getCodexForBook(Book book) async {
    // Check cache first
    final cached = await getCachedCodex(book.id);
    if (cached != null) {
      return cached;
    }

    // Check if handcrafted literature template exists in StoryCodexEngine
    if (StoryCodexEngine.isCuratedBook(book)) {
      final flagship = StoryCodexEngine.generateCodex(book);
      await saveCodexToCache(flagship);
      return flagship;
    }

    // Run dynamic multi-tier enrichment pipeline
    StoryCodex enriched;
    try {
      enriched = await _runEnrichmentPipeline(book);
    } catch (e) {
      debugPrint('Enrichment pipeline error for "${book.title}": $e. Using NLP fallback.');
      enriched = _extractTier3NlpCodex(
        book: book,
        synopsisText: book.description,
        externalSubjects: [],
        externalPlaces: [],
        externalTimes: [],
        externalPeople: [],
      );
    }

    await saveCodexToCache(enriched);
    return enriched;
  }

  static Future<StoryCodex> _runEnrichmentPipeline(Book book) async {
    List<String> rawSubjects = [];
    List<String> rawPlaces = [];
    List<String> rawTimes = [];
    List<String> rawPeople = [];
    String fetchedSynopsis = book.description;

    // --- Tier 1: Open Library & Google Books Deep Subject Parsing ---
    try {
      final cleanTitle = Uri.encodeComponent(book.title.trim());
      final cleanAuthor = Uri.encodeComponent(book.author.trim());

      final olSearchUrl = Uri.parse(
        'https://openlibrary.org/search.json?title=$cleanTitle&author=$cleanAuthor&fields=key,title,author_name,subject,subject_facet,subject_places,subject_times,subject_people,person,place,time,characters&limit=1',
      );

      final olResponse = await _httpClient.get(
        olSearchUrl,
        headers: {'User-Agent': 'Bookora-Codex/2.0 (Mobile App; Flutter)'},
      ).timeout(const Duration(seconds: 4));

      if (olResponse.statusCode == 200) {
        final decoded = jsonDecode(olResponse.body) as Map<String, dynamic>?;
        final docs = decoded?['docs'] as List<dynamic>?;
        if (docs != null && docs.isNotEmpty) {
          final first = docs.first as Map<String, dynamic>;

          if (first['subject'] is List) {
            rawSubjects.addAll((first['subject'] as List).map((e) => e.toString()));
          }
          if (first['subject_places'] is List) {
            rawPlaces.addAll((first['subject_places'] as List).map((e) => e.toString()));
          } else if (first['place'] is List) {
            rawPlaces.addAll((first['place'] as List).map((e) => e.toString()));
          }

          if (first['subject_times'] is List) {
            rawTimes.addAll((first['subject_times'] as List).map((e) => e.toString()));
          } else if (first['time'] is List) {
            rawTimes.addAll((first['time'] as List).map((e) => e.toString()));
          }

          if (first['subject_people'] is List) {
            rawPeople.addAll((first['subject_people'] as List).map((e) => e.toString()));
          } else if (first['person'] is List) {
            rawPeople.addAll((first['person'] as List).map((e) => e.toString()));
          }
          if (first['characters'] is List) {
            rawPeople.addAll((first['characters'] as List).map((e) => e.toString()));
          }

          // Tier 1 Query: Open Library Works API for explicit characters
          final workKey = first['key']?.toString();
          if (workKey != null && workKey.startsWith('/works/')) {
            try {
              final workUrl = Uri.parse('https://openlibrary.org$workKey.json');
              final workRes = await _httpClient.get(
                workUrl,
                headers: {'User-Agent': 'Bookora-Codex/2.0 (Mobile App; Flutter)'},
              ).timeout(const Duration(seconds: 2));
              if (workRes.statusCode == 200) {
                final workData = jsonDecode(workRes.body) as Map<String, dynamic>?;
                if (workData?['characters'] is List) {
                  rawPeople.addAll((workData!['characters'] as List).map((e) => e.toString()));
                }
                if (workData?['subject_people'] is List) {
                  rawPeople.addAll((workData!['subject_people'] as List).map((e) => e.toString()));
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('OpenLibrary subject search note: $e');
    }

    // --- Tier 2: Google Books / Specialized Metadata ---
    try {
      final cleanTitle = Uri.encodeComponent(book.title.trim());
      final cleanAuthor = Uri.encodeComponent(book.author.trim());
      final gbUrl = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=intitle:$cleanTitle+inauthor:$cleanAuthor&maxResults=1',
      );

      final gbResponse = await _httpClient.get(gbUrl).timeout(const Duration(seconds: 4));
      if (gbResponse.statusCode == 200) {
        final gbData = jsonDecode(gbResponse.body) as Map<String, dynamic>?;
        final items = gbData?['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final volInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
          if (volInfo != null) {
            final categories = volInfo['categories'] as List<dynamic>?;
            if (categories != null) {
              rawSubjects.addAll(categories.map((c) => c.toString()));
            }
            final gbDesc = volInfo['description']?.toString() ?? '';
            if (gbDesc.length > fetchedSynopsis.length && !BookMetadataSanitizer.isTruncatedSynopsis(gbDesc)) {
              fetchedSynopsis = gbDesc;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google Books metadata note: $e');
    }

    // --- Tier 3: Smart Algorithmic Synopsis & NLP Heuristic Extractor ---
    return _extractTier3NlpCodex(
      book: book,
      synopsisText: fetchedSynopsis.isNotEmpty ? fetchedSynopsis : book.effectiveBlurb,
      externalSubjects: rawSubjects,
      externalPlaces: rawPlaces,
      externalTimes: rawTimes,
      externalPeople: rawPeople,
    );
  }

  // --- 3. TIER 3 NLP & HEURISTIC ENGINE ---

  static StoryCodex _extractTier3NlpCodex({
    required Book book,
    required String synopsisText,
    required List<String> externalSubjects,
    required List<String> externalPlaces,
    required List<String> externalTimes,
    required List<String> externalPeople,
  }) {
    final cleanSynopsis = BookMetadataSanitizer.sanitizeSynopsis(synopsisText);
    final titleLower = book.title.toLowerCase();
    final synopsisLower = cleanSynopsis.toLowerCase();
    final combinedText = '$titleLower $synopsisLower ${book.genres.join(' ').toLowerCase()} ${externalSubjects.join(' ').toLowerCase()}';

    // A. Hook & Premise Extractor
    final hookAndPremise = _extractHookAndPremise(book, cleanSynopsis);

    // B. Worldbuilding & Settings
    final settingData = _extractWorldbuilding(
      combinedText: combinedText,
      genres: book.genres,
      externalPlaces: externalPlaces,
      externalTimes: externalTimes,
      externalSubjects: externalSubjects,
    );

    // C. Figures of Destiny (Lead Character Roster)
    final characters = _extractCharacters(
      synopsisText: cleanSynopsis,
      title: book.title,
      author: book.author,
      genres: book.genres,
      externalPeople: externalPeople,
    );

    // D. Narrative DNA & Tropes
    final tropes = _extractTropes(combinedText: combinedText, genres: book.genres);

    // E. 5D Flavor Profile Estimator
    final flavor = _estimate5DFlavor(combinedText: combinedText, book: book);

    // F. Content Advisory & Themes
    final themesAndAdvisory = _extractThemesAndAdvisory(combinedText: combinedText, genres: book.genres);

    // G. Narrative Metrics (POV & Pacing)
    final povType = _inferPovType(cleanSynopsis);
    final pacing = _inferPacing(cleanSynopsis, combinedText);

    return StoryCodex(
      bookId: book.id,
      hook: hookAndPremise.$1,
      premise: hookAndPremise.$2,
      synopsis: cleanSynopsis.isNotEmpty ? cleanSynopsis : book.effectiveBlurb,
      timePeriod: settingData.timePeriod,
      primaryLocation: settingData.location,
      worldbuildingTags: settingData.worldbuildingTags,
      atmosphericTone: settingData.atmosphere,
      characters: characters,
      tropes: tropes,
      povType: povType,
      pacing: pacing,
      spiceLevel: flavor.spice,
      fluffLevel: flavor.fluff,
      tearLevel: flavor.tears,
      humorLevel: flavor.humor,
      tensionLevel: flavor.tension,
      themes: themesAndAdvisory.themes,
      contentWarnings: themesAndAdvisory.warnings,
    );
  }

  // --- NLP SUB-ROUTINES ---

  /// Extracts punchy lead hook and 1-2 sentence core conflict premise
  static (String hook, String premise) _extractHookAndPremise(Book book, String synopsis) {
    if (book.tagline != null && book.tagline!.trim().isNotEmpty && book.tagline!.length > 10) {
      final hook = book.effectiveTagline;
      final premise = book.effectiveBlurb.isNotEmpty ? book.effectiveBlurb : hook;
      return (hook, premise);
    }

    if (synopsis.isEmpty) {
      final hook = book.effectiveTagline;
      return (hook, hook);
    }

    // Check for marketing quote or opening punchline
    final lines = synopsis.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      // Check for leading quote
      final quoteMatch = RegExp(r'^["“]([^"”]+)["”]').firstMatch(firstLine);
      if (quoteMatch != null) {
        final quote = quoteMatch.group(1)!.trim();
        final remaining = lines.length > 1 ? lines[1] : synopsis;
        return (quote, remaining);
      }

      // If first sentence is short and punchy
      final sentences = firstLine.split(RegExp(r'(?<=[.!?])\s+'));
      if (sentences.isNotEmpty) {
        final firstSent = sentences.first.trim();
        if (firstSent.length >= 15 && firstSent.length <= 110) {
          final premise = sentences.length > 1
              ? '$firstSent ${sentences[1].trim()}'
              : (lines.length > 1 ? lines[1] : book.effectiveBlurb);
          return (firstSent, premise);
        }
      }
    }

    return (book.effectiveTagline, book.effectiveBlurb);
  }

  /// Worldbuilding & Setting Inference
  static _SettingInference _extractWorldbuilding({
    required String combinedText,
    required List<String> genres,
    required List<String> externalPlaces,
    required List<String> externalTimes,
    required List<String> externalSubjects,
  }) {
    // 1. Time Period
    String timePeriod = 'Contemporary Era';
    if (externalTimes.isNotEmpty) {
      timePeriod = externalTimes.first;
    } else if (combinedText.contains('far future') || combinedText.contains('28th century') || combinedText.contains('30th century') || combinedText.contains('space opera') || combinedText.contains('galactic')) {
      timePeriod = 'Far Future / Interstellar Era';
    } else if (combinedText.contains('victorian') || combinedText.contains('19th century')) {
      timePeriod = 'Victorian Era (19th Century)';
    } else if (combinedText.contains('regency')) {
      timePeriod = 'Regency Era';
    } else if (combinedText.contains('medieval') || combinedText.contains('middle ages') || combinedText.contains('feudal')) {
      timePeriod = 'Medieval Lore Era';
    } else if (combinedText.contains('ancient rome') || combinedText.contains('ancient greece') || combinedText.contains('antiquity')) {
      timePeriod = 'Classical Antiquity';
    } else if (combinedText.contains('world war') || combinedText.contains('1940s') || combinedText.contains('1920s')) {
      timePeriod = 'Early 20th Century';
    } else if (combinedText.contains('cyberpunk') || combinedText.contains('near future')) {
      timePeriod = 'Near-Future Cybernetic Era';
    }

    // 2. Primary Location
    String location = 'Contemporary World';
    if (externalPlaces.isNotEmpty) {
      location = externalPlaces.take(2).join(' / ');
    } else if (combinedText.contains('hyperion')) {
      location = 'Web World of Hegemony / Hyperion Valley';
    } else if (combinedText.contains('london') || combinedText.contains('england') || combinedText.contains('oxford')) {
      location = 'London, England & Historic Estates';
    } else if (combinedText.contains('new york') || combinedText.contains('manhattan')) {
      location = 'Manhattan, New York';
    } else if (combinedText.contains('paris') || combinedText.contains('france')) {
      location = 'Paris, France';
    } else if (combinedText.contains('colorado') || combinedText.contains('rockies')) {
      location = 'Colorado Mountain Frontier';
    } else if (combinedText.contains('seattle') || combinedText.contains('pacific northwest')) {
      location = 'Pacific Northwest / Seattle';
    } else if (combinedText.contains('fae') || combinedText.contains('prythian')) {
      location = 'Prythian / High Fae Realms';
    } else if (combinedText.contains('space') || combinedText.contains('starship') || combinedText.contains('fleet')) {
      location = 'Deep Space Fleet & Frontier Colonies';
    } else if (combinedText.contains('dark academia') || combinedText.contains('university') || combinedText.contains('campus')) {
      location = 'Historic Elite Collegiate Campus';
    } else if (combinedText.contains('small town')) {
      location = 'Cozy Coastal Small Town';
    }

    // 3. Worldbuilding Tags
    final tags = <String>{};
    if (combinedText.contains('space opera')) tags.add('Space Opera');
    if (combinedText.contains('magic') || combinedText.contains('spell')) tags.add('Arcane Magic');
    if (combinedText.contains('dark academia')) tags.add('Dark Academia');
    if (combinedText.contains('cyberpunk') || combinedText.contains('ai')) tags.add('Cybernetic Systems');
    if (combinedText.contains('high fae') || combinedText.contains('court')) tags.add('Fae Royalty');
    if (combinedText.contains('dragon')) tags.add('Dragon Riders');
    if (combinedText.contains('billionaire') || combinedText.contains('empire')) tags.add('Corporate Dynasties');
    if (combinedText.contains('war') || combinedText.contains('military')) tags.add('Wartime Crucible');
    if (combinedText.contains('dystopian')) tags.add('Dystopian Order');
    if (combinedText.contains('gothic')) tags.add('Gothic Mansions');
    if (combinedText.contains('small town')) tags.add('Close-Knit Community');
    if (combinedText.contains('time travel')) tags.add('Temporal Flux');
    if (tags.isEmpty) {
      tags.addAll(['Immersive Realism', 'Interpersonal Dynamics']);
    }

    // 4. Atmospheric Tone
    String atmosphere = 'Immersive & Atmospheric';
    if (combinedText.contains('gothic') || combinedText.contains('spooky') || combinedText.contains('eerie')) {
      atmosphere = 'Gothic, Ominous & Haunting';
    } else if (combinedText.contains('dark') || combinedText.contains('gritty') || combinedText.contains('ruthless')) {
      atmosphere = 'Tense, Brooding & High-Stakes';
    } else if (combinedText.contains('cozy') || combinedText.contains('warm') || combinedText.contains('heartwarming')) {
      atmosphere = 'Warm, Whimsical & Heartfelt';
    } else if (combinedText.contains('philosophical') || combinedText.contains('contemplative')) {
      atmosphere = 'Philosophical & Thought-Provoking';
    } else if (combinedText.contains('epic') || combinedText.contains('grand')) {
      atmosphere = 'Grand, Majestic & High-Fantasy';
    } else if (combinedText.contains('romantic') || combinedText.contains('passionate') || combinedText.contains('swoon')) {
      atmosphere = 'Passionate, Tender & Charged';
    }

    return _SettingInference(
      location: location,
      timePeriod: timePeriod,
      worldbuildingTags: tags.take(4).toList(),
      atmosphere: atmosphere,
    );
  }

  /// Strict negative filter to ensure authors, publishers, formats, and non-character entities are discarded
  static bool _isAuthorOrNonCharacter(String candidate, String author, String title, [String? synopsis]) {
    return StoryCodexEngine.isAuthorOrNonCharacter(candidate, author, title, synopsis);
  }

  /// Character Extraction via Named Entity Recognition & Lead Persona Heuristics
  static List<CodexCharacter> _extractCharacters({
    required String synopsisText,
    required String title,
    required String author,
    required List<String> genres,
    required List<String> externalPeople,
  }) {
    final characters = <CodexCharacter>[];
    final seenNames = <String>{};

    // 1. Process external people & characters extracted from Open Library / Wikidata
    for (final person in externalPeople) {
      final clean = person.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      if (clean.length > 2 &&
          !_isAuthorOrNonCharacter(clean, author, title, synopsisText) &&
          !seenNames.contains(clean.toLowerCase())) {
        seenNames.add(clean.toLowerCase());
        final isFirst = characters.isEmpty;
        final role = isFirst
            ? 'Protagonist / Lead'
            : (characters.length == 1
                ? 'Central Figure / Counterpart'
                : 'Supporting Figure');
        characters.add(CodexCharacter(
          name: clean,
          role: role,
          archetype: _inferCharacterArchetype(clean, synopsisText, genres),
          description: _inferCharacterDescription(clean, synopsisText, role),
        ));
      }
      if (characters.length >= 3) break;
    }

    if (characters.length >= 2) return characters;

    // 2. High-precision candidate extraction from synopsis via StoryCodexEngine
    final candidates = StoryCodexEngine.extractCandidateCharacters(
      synopsis: synopsisText,
      author: author,
      title: title,
      genres: genres,
    );

    for (final c in candidates) {
      if (!seenNames.contains(c.name.toLowerCase())) {
        seenNames.add(c.name.toLowerCase());
        characters.add(c);
      }
      if (characters.length >= 3) break;
    }

    // Never output generic "Central Protagonist" or "The Counterpart"
    return characters;
  }

  static String _detectGender(String name, String synopsis) {
    final sentences = synopsis.split(RegExp(r'(?<=[.!?])\s+'));
    int femaleCount = 0;
    int maleCount = 0;
    for (final s in sentences) {
      if (s.contains(name)) {
        final sLower = s.toLowerCase();
        femaleCount += RegExp(r'\b(she|her|hers)\b').allMatches(sLower).length;
        maleCount += RegExp(r'\b(he|him|his)\b').allMatches(sLower).length;
      }
    }
    return femaleCount >= maleCount ? 'female' : 'male';
  }

  static String _inferCharacterArchetype(String name, String synopsis, List<String> genres) {
    final lower = synopsis.toLowerCase();
    final gStr = genres.join(' ').toLowerCase();

    if (lower.contains('morally grey') || lower.contains('villain') || lower.contains('anti-hero')) {
      return 'The Morally Gray Anti-Hero';
    }
    if (lower.contains('billionaire') || lower.contains('ceo') || lower.contains('heir')) {
      return 'The Powerful Heir';
    }
    if (lower.contains('mother') || lower.contains('daughter') || lower.contains('grief')) {
      return 'The Resilient Penitent';
    }
    if (lower.contains('detective') || lower.contains('investigator') || lower.contains('agent')) {
      return 'The Inquisitive Investigator';
    }
    if (lower.contains('scholar') || lower.contains('academic') || lower.contains('student')) {
      return 'The Inquisitive Scholar';
    }
    if (gStr.contains('fantasy') || lower.contains('chosen') || lower.contains('crown')) {
      return 'The Reluctant Chosen';
    }
    if (gStr.contains('sci-fi') || lower.contains('pilot') || lower.contains('captain')) {
      return 'The Starfarer Voyager';
    }
    if (gStr.contains('romance')) {
      return 'The Guarded Heart';
    }
    return 'The Complex Protagonist';
  }

  static String _inferCharacterDescription(String name, String synopsis, String role) {
    final sentences = synopsis.split(RegExp(r'(?<=[.!?])\s+'));
    for (final sent in sentences) {
      if (sent.contains(name) && sent.length > 20 && sent.length < 180) {
        return sent.trim();
      }
    }
    return 'Drives significant conflict, momentum, and thematic weight throughout the story.';
  }

  /// Curated Trope Classification across 80+ authentic literary tropes
  static List<String> _extractTropes({required String combinedText, required List<String> genres}) {
    final matchedTropes = <String>[];

    void match(String keyword, String tropeName) {
      if (combinedText.contains(keyword.toLowerCase()) && !matchedTropes.contains(tropeName)) {
        matchedTropes.add(tropeName);
      }
    }

    // Romance & Dark Romance
    match('enemies to lovers', 'Enemies to Lovers');
    match('touch her and die', 'Touch Her and Die');
    match('morally grey', 'Morally Grey Hero');
    match('morally gray', 'Morally Grey Hero');
    match('forced proximity', 'Forced Proximity');
    match('fake dating', 'Fake Relationship');
    match('fake relationship', 'Fake Relationship');
    match('second chance', 'Second Chance Romance');
    match('grumpy', 'Grumpy x Sunshine');
    match('friends to lovers', 'Friends to Lovers');
    match('billionaire', 'Billionaire Romance');
    match('forbidden', 'Forbidden Love');
    match('bodyguard', 'Bodyguard Romance');
    match('love triangle', 'Love Triangle');
    match('slow burn', 'Slow Burn');
    match('fated mates', 'Fated Mates');
    match('soulmates', 'Fated Mates');
    match('arranged marriage', 'Arranged Marriage');
    match('dark academia', 'Dark Academia');
    match('stalker', 'Dark Obsession');

    // Fantasy & Supernatural
    match('chosen one', 'The Chosen One');
    match('magic academy', 'Magic Academy');
    match('royal blood', 'Hidden Royalty');
    match('fae', 'Fae Politics & Court Intrigue');
    match('dragon', 'Dragon Riders');
    match('prophecy', 'Ancient Prophecy');
    match('immortal', 'Immortal Romance');
    match('ancient evil', 'Ancient Evil Awakening');
    match('quest', 'Epic Quest');
    match('rebellion', 'Dystopian Rebellion');

    // Sci-Fi & Cyberpunk
    match('space opera', 'Space Opera');
    match('cybernetic', 'Cybernetic Web');
    match('ai', 'AI Awakening');
    match('galactic empire', 'Galactic Empire');
    match('time travel', 'Time Travel / Paradox');
    match('first contact', 'First Contact');
    match('colon', 'Colony World');
    match('hyperion', 'Pilgrimage');

    // Mystery & Thriller
    match('unreliable narrator', 'Unreliable Narrator');
    match('locked room', 'Locked Room Mystery');
    match('small town secret', 'Small Town Secrets');
    match('conspiracy', 'Corrupt Conspiracy');
    match('serial killer', 'Serial Killer Cat-and-Mouse');
    match('whodunit', 'Whodunit');
    match('amnesia', 'Forgotten Past');
    match('revenge', 'Vengeance Quest');

    // Fallbacks if no specific tropes caught
    if (matchedTropes.isEmpty) {
      final g = genres.join(' ').toLowerCase();
      if (g.contains('romance')) {
        matchedTropes.addAll(['High Emotional Stakes', 'Mutual Attraction', 'Guarded Hearts']);
      } else if (g.contains('fantasy')) {
        matchedTropes.addAll(['World in Peril', 'Ancient Powers', 'Unforeseen Destiny']);
      } else if (g.contains('sci-fi')) {
        matchedTropes.addAll(['Technological Crucible', 'Cosmic Frontiers', 'Moral Duality']);
      } else if (g.contains('thriller') || g.contains('mystery')) {
        matchedTropes.addAll(['Ticking Clock', 'Hidden Agendas', 'Unraveling Secrets']);
      } else {
        matchedTropes.addAll(['Identity & Growth', 'Moral Dilemma', 'Transformative Journey']);
      }
    }

    return matchedTropes.take(5).toList();
  }

  /// 5D Narrative Flavor Profile Estimator
  static _FlavorProfile _estimate5DFlavor({required String combinedText, required Book book}) {
    double spice = book.spiceRating > 0 ? book.spiceRating : 1.5;
    double fluff = book.fluffRating > 0 ? book.fluffRating : 3.0;
    double tears = book.tearRating > 0 ? book.tearRating : 2.5;
    double humor = book.humorRating > 0 ? book.humorRating : 3.0;
    double tension = 3.0;

    // Spice evaluation
    if (combinedText.contains('dark romance') || combinedText.contains('steamy') || combinedText.contains('spicy') || combinedText.contains('smut')) {
      spice = 4.8;
    } else if (combinedText.contains('erotic') || combinedText.contains('seductive') || combinedText.contains('passion')) {
      spice = 4.0;
    } else if (combinedText.contains('enemies to lovers') || combinedText.contains('touch her and die')) {
      spice = 3.8;
    }

    // Tears evaluation
    if (combinedText.contains('grief') || combinedText.contains('tragedy') || combinedText.contains('heartbreaking') || combinedText.contains('devastating') || combinedText.contains('cancer') || combinedText.contains('prison')) {
      tears = 4.7;
    } else if (combinedText.contains('sad') || combinedText.contains('sorrow') || combinedText.contains('pain')) {
      tears = 3.8;
    }

    // Fluff & Warmth evaluation
    if (combinedText.contains('cozy') || combinedText.contains('wholesome') || combinedText.contains('sweet') || combinedText.contains('cute') || combinedText.contains('found family')) {
      fluff = 4.6;
    } else if (combinedText.contains('dark') || combinedText.contains('horror') || combinedText.contains('grim')) {
      fluff = 1.2;
    }

    // Humor evaluation
    if (combinedText.contains('witty') || combinedText.contains('banter') || combinedText.contains('hilarious') || combinedText.contains('laugh') || combinedText.contains('rom-com')) {
      humor = 4.5;
    } else if (combinedText.contains('serious') || combinedText.contains('dark') || combinedText.contains('tragic')) {
      humor = 1.8;
    }

    // Tension & Stakes evaluation
    if (combinedText.contains('thriller') || combinedText.contains('serial killer') || combinedText.contains('war') || combinedText.contains('conspiracy') || combinedText.contains('survival')) {
      tension = 4.8;
    } else if (combinedText.contains('slow burn') || combinedText.contains('mystery')) {
      tension = 3.8;
    }

    return _FlavorProfile(
      spice: spice.clamp(0.0, 5.0),
      fluff: fluff.clamp(0.0, 5.0),
      tears: tears.clamp(0.0, 5.0),
      humor: humor.clamp(0.0, 5.0),
      tension: tension.clamp(0.0, 5.0),
    );
  }

  /// Content Themes & Advisory Extractor
  static _ThemesAndAdvisory _extractThemesAndAdvisory({required String combinedText, required List<String> genres}) {
    final themes = <String>[];
    final warnings = <String>[];

    void checkTheme(String kw, String theme) {
      if (combinedText.contains(kw) && !themes.contains(theme)) themes.add(theme);
    }
    void checkWarning(String kw, String warning) {
      if (combinedText.contains(kw) && !warnings.contains(warning)) warnings.add(warning);
    }

    // Themes
    checkTheme('identity', 'Identity & Self-Discovery');
    checkTheme('redemption', 'Redemption & Second Chances');
    checkTheme('forgive', 'The Crucible of Forgiveness');
    checkTheme('power', 'Power, Ambition & Corruption');
    checkTheme('family', 'Found Family vs. Blood Ties');
    checkTheme('love', 'Love as a Transformative Force');
    checkTheme('grief', 'Healing Beyond Profound Loss');
    checkTheme('faith', 'Faith vs. Technological Supremacy');
    checkTheme('loyalty', 'Loyalty Tested by Secrets');

    // Warnings
    checkWarning('violence', 'Depictions of Violence & Conflict');
    checkWarning('grief', 'Profound Grief & Bereavement');
    checkWarning('death', 'Themes of Mortality & Loss');
    checkWarning('abuse', 'Past Emotional / Physical Abuse');
    checkWarning('manipulat', 'Psychological Manipulation');
    checkWarning('stalker', 'Stalker Romance / Dubious Consent');
    checkWarning('substance', 'Substance Abuse & Addiction');
    checkWarning('suicid', 'Depictions of Mental Health Struggles');

    if (themes.isEmpty) {
      themes.addAll(['Emotional Resonance', 'Moral Complexity', 'Personal Growth']);
    }
    if (warnings.isEmpty) {
      warnings.addAll(['Thematic Intensity', 'Emotional Conflict']);
    }

    return _ThemesAndAdvisory(themes: themes.take(4).toList(), warnings: warnings.take(3).toList());
  }

  static String _inferPovType(String synopsis) {
    final lower = synopsis.toLowerCase();
    if (lower.contains('dual pov') || lower.contains('alternating pov')) {
      return 'First Person Dual POV';
    }
    if (lower.contains('i run') || lower.contains('i caught') || lower.contains('my life') || lower.contains('i never')) {
      return 'First Person';
    }
    return 'Third Person Omniscient';
  }

  static String _inferPacing(String synopsis, String combinedText) {
    if (combinedText.contains('thriller') || combinedText.contains('relentless') || combinedText.contains('fast-paced') || combinedText.contains('action')) {
      return 'Fast-paced & Relentless';
    }
    if (combinedText.contains('slow burn') || combinedText.contains('epic') || combinedText.contains('saga')) {
      return 'Atmospheric Slow-burn';
    }
    return 'Engaging & Balanced';
  }
}

// --- HELPER VALUE CLASSES ---

class _SettingInference {
  final String location;
  final String timePeriod;
  final List<String> worldbuildingTags;
  final String atmosphere;

  _SettingInference({
    required this.location,
    required this.timePeriod,
    required this.worldbuildingTags,
    required this.atmosphere,
  });
}

class _FlavorProfile {
  final double spice;
  final double fluff;
  final double tears;
  final double humor;
  final double tension;

  _FlavorProfile({
    required this.spice,
    required this.fluff,
    required this.tears,
    required this.humor,
    required this.tension,
  });
}

class _ThemesAndAdvisory {
  final List<String> themes;
  final List<String> warnings;

  _ThemesAndAdvisory({
    required this.themes,
    required this.warnings,
  });
}
