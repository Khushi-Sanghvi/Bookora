import 'dart:convert';
import 'enums.dart';
import 'journal_entry.dart';
import 'quote_annotation.dart';
import '../services/genre_parser.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String?
  tagline; // 1-line hook (e.g. "He can't have her, but he's taking her anyway.")
  final String?
  blurb; // Short 1-2 sentence teaser pitch summarizing conflict and tone
  final String coverUrl;
  final int totalPages;
  final int currentPage;
  final ReadingStatus status;
  final BookFormat format;
  final List<String>? _genres;
  List<String> get genres => (_genres != null && _genres.isNotEmpty) ? _genres : const ['General'];
  final DateTime? startDate;
  final DateTime? finishDate;

  // 5D Ratings
  final double overallRating;
  final double spiceRating;
  final double fluffRating;
  final double tearRating;
  final double humorRating;

  final List<JournalEntry> journalEntries;
  final List<QuoteAnnotation> quotes;
  final String? localFilePath;
  final bool isFavorite;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = '',
    this.tagline,
    this.blurb,
    required this.coverUrl,
    required this.totalPages,
    this.currentPage = 0,
    this.status = ReadingStatus.toRead,
    this.format = BookFormat.paperback,
    List<String>? genres = const ['General'],
    DateTime? startDate,
    DateTime? finishDate,
    DateTime? endDate,
    DateTime? createdAt,
    this.overallRating = 0.0,
    this.spiceRating = 0.0,
    this.fluffRating = 0.0,
    this.tearRating = 0.0,
    this.humorRating = 0.0,
    this.journalEntries = const [],
    this.quotes = const [],
    this.localFilePath,
    this.isFavorite = false,
    double? progress,
  }) : _genres = (genres != null && genres.isNotEmpty) ? genres : const ['General'],
       finishDate = finishDate ?? endDate,
       startDate = startDate ?? createdAt;

  DateTime? get endDate => finishDate;

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;

  // --- Dynamic Metadata Extraction & Individual Book Story Engine ---
  String get effectiveTagline {
    // 1. Explicitly saved tagline (ignoring old cached template strings or truncated fragments)
    if (tagline != null &&
        tagline!.trim().isNotEmpty &&
        !RegExp(r'(?:[a-zA-Z]{1,3}\.{2,3}|\.{2,}|…)\s*$').hasMatch(tagline!.trim()) &&
        !tagline!.toLowerCase().contains('unforgettable story of') &&
        !tagline!.toLowerCase().contains('enthralling story of') &&
        !tagline!.toLowerCase().contains('weaves an unforgettable story') &&
        !tagline!.toLowerCase().contains('published by open library') &&
        !tagline!.toLowerCase().contains('an addictive, high-stakes romance')) {
      return tagline!.trim();
    }

    final titleLower = title.toLowerCase();
    final authorLower = author.toLowerCase();

    // 2. Specific Popular Books
    if (titleLower.contains('reminders of him')) {
      return "A troubled young mother seeks redemption after serving five years in prison.";
    } else if (titleLower.contains('it ends with us')) {
      return "Sometimes the one who loves you is the one who hurts you the most.";
    } else if (titleLower.contains('it starts with us')) {
      return "Every ending has a new beginning worth fighting for.";
    } else if (titleLower.contains('verity')) {
      return "Whose truth is the lie? A chilling psychological thriller of obsession.";
    } else if (titleLower.contains('ugly love')) {
      return "When love is ugly, it hurts even when it feels good.";
    } else if (titleLower.contains('november 9')) {
      return "One date a year. Zero contact between. A love story written in the stars.";
    } else if (titleLower.contains('king of pride')) {
      return "She's a bright, wild barmaid. He's a proper billionaire with strict rules.";
    } else if (titleLower.contains('king of wrath')) {
      return "A ruthless billionaire forced into an engagement he never wanted.";
    } else if (titleLower.contains('king of greed')) {
      return "He had everything he ever wanted, except the woman he lost.";
    } else if (titleLower.contains('king of sloth')) {
      return "He's a charming playboy with zero ambition. She's the publicist sent to save his empire.";
    } else if (titleLower.contains('king of gluttony')) {
      return "He craves control over everything—until she becomes his most dangerous vice.";
    } else if (titleLower.contains('king of envy')) {
      return "He wants what he can't have, and he will burn down empires to claim her.";
    } else if (titleLower.contains('twisted games')) {
      return "He can't have her, but he's taking her anyway.";
    } else if (titleLower.contains('twisted love')) {
      return "He has a heart of ice. But for her, he'd burn the world.";
    } else if (titleLower.contains('twisted hate')) {
      return "He hates her. She despises him. But passion refuses to obey.";
    } else if (titleLower.contains('twisted lies')) {
      return "A fake relationship built on secrets, desire, and dangerous lies.";
    } else if (titleLower.contains('haunting adeline')) {
      return "I'm a stalker. A monster. And she is my obsession.";
    } else if (titleLower.contains('god of war')) {
      return "She belongs to my enemy. But I will wage war to make her mine.";
    } else if (titleLower.contains('god of malice')) {
      return "A dark, dangerous obsession where rules are made to be broken.";
    } else if (titleLower.contains('beach read')) {
      return "Two rival authors. One summer. A wager that changes everything.";
    } else if (titleLower.contains('book lovers')) {
      return "A cutthroat literary agent meets her rival in a tiny North Carolina town.";
    } else if (titleLower.contains('happy place')) {
      return "They broke up months ago. But for one week, they're pretending to be in love.";
    } else if (titleLower.contains('fourth wing')) {
      return "Fly or die. At Basgiath War College, dragon riders don't survive by playing nice.";
    } else if (titleLower.contains('deal') ||
        authorLower.contains('elle kennedy')) {
      return "She needs a tutor to pass ethics. He needs a fake date to make an ex jealous.";
    } else if (titleLower.contains('fine print') ||
        authorLower.contains('lauren asher')) {
      return "Rowan is a cynical billionaire heir. Zahra is the fiery dreamer who changes everything.";
    } else if (titleLower.contains('never got over') ||
        authorLower.contains('lucy score')) {
      return "Knockemout's baddest grump meets the runaway bride who turned his town upside down.";
    } else if (titleLower.contains('love hypothesis') ||
        authorLower.contains('ali hazelwood')) {
      return "A fake relationship between two scientists leads to an explosive chemical reaction.";
    }

    // 3. Keyword-based Dynamic Hook Synthesis
    if (titleLower.contains('remind') ||
        titleLower.contains('memory') ||
        titleLower.contains('forget')) {
      return "A heart-wrenching tale of second chances, forgiveness, and healing.";
    } else if (titleLower.contains('king') ||
        titleLower.contains('queen') ||
        titleLower.contains('throne')) {
      return "Power, forbidden desire, and a high-stakes clash for total control.";
    } else if (titleLower.contains('god') ||
        titleLower.contains('dark') ||
        titleLower.contains('shadow')) {
      return "A dark, dangerous obsession where rules are made to be broken.";
    } else if (titleLower.contains('love') ||
        titleLower.contains('heart') ||
        titleLower.contains('kiss')) {
      return "A razor-thin line between rivalry and an all-consuming passion.";
    } else if (titleLower.contains('secret') ||
        titleLower.contains('lie') ||
        titleLower.contains('fake')) {
      return "A high-stakes web of secrets where the fake rules become dangerously real.";
    }

    // 4. Dynamic Sentence Extraction from Description
    final cleanDesc = description.trim();
    if (cleanDesc.isNotEmpty &&
        !cleanDesc.toLowerCase().contains('published by open library') &&
        !cleanDesc.toLowerCase().contains('unforgettable story of') &&
        !cleanDesc.toLowerCase().contains('imported from reading catalog') &&
        !cleanDesc.toLowerCase().contains(
          'an addictive, high-stakes romance',
        )) {
      final sentences = cleanDesc.split(RegExp(r'(?<=[.!?])\s+'));
      for (var s in sentences) {
        final cleanSentence = s.trim();
        if (cleanSentence.length >= 15 &&
            !cleanSentence.toLowerCase().contains('published by') &&
            !cleanSentence.toLowerCase().contains('unforgettable story') &&
            !cleanSentence.toLowerCase().startsWith('no. 1 ') &&
            !cleanSentence.toLowerCase().startsWith('the no. 1 ') &&
            !RegExp(r'(?:[a-zA-Z]\.{2,3}|\.{3,}|…)\s*$').hasMatch(cleanSentence)) {
          return cleanSentence;
        }
      }
    }

    return "An intense, high-stakes story of $title where passion and destiny collide.";
  }

  String get effectiveBlurb {
    // 1. Explicitly saved blurb (ignoring old cached template strings or truncated fragments)
    if (blurb != null &&
        blurb!.trim().isNotEmpty &&
        !RegExp(r'(?:[a-zA-Z]{1,3}\.{2,3}|\.{2,}|…)\s*$').hasMatch(blurb!.trim()) &&
        !blurb!.toLowerCase().contains('unforgettable story of') &&
        !blurb!.toLowerCase().contains('enthralling story of') &&
        !blurb!.toLowerCase().contains('weaves an unforgettable story') &&
        !blurb!.toLowerCase().contains('published by open library') &&
        !blurb!.toLowerCase().contains('an addictive, high-stakes romance')) {
      return blurb!.trim();
    }

    final titleLower = title.toLowerCase();
    final authorLower = author.toLowerCase();

    // 2. Specific Popular Books
    if (titleLower.contains('reminders of him')) {
      return "Kenna Rowan returns to the town where it all went wrong, hoping to reunite with her four-year-old daughter. But the bridges she burned prove impossible to rebuild—except through Ledger Ward, the local bar owner with a secret connection to her past.";
    } else if (titleLower.contains('it ends with us')) {
      return "Lily hasn't always had it easy, but that's never stopped her from working hard for the life she wants. When she falls for neurosurgeon Ryle Kincaid, everything seems too good to be true—until Atlas Corrigan reappears.";
    } else if (titleLower.contains('it starts with us')) {
      return "Switching between the perspectives of Lily and Atlas, this installment picks up right where the epilogue for 'It Ends with Us' left off, uncovering Atlas's past and following Lily's second chance at true love.";
    } else if (titleLower.contains('verity')) {
      return "Lowen Ashleigh is hired to complete the remaining books of injured bestselling author Verity Crawford, only to discover an unfinished autobiography filled with horrifying admissions about Verity's family.";
    } else if (titleLower.contains('ugly love')) {
      return "When Tate Collins meets airline pilot Miles Archer, they know it isn't love at first sight. They realize they have an mutual attraction, but Miles doesn't want love, and Tate doesn't have time for love.";

      // 3. Ana Huang & Series
    } else if (titleLower.contains('king of pride')) {
      return "Reserved, controlled, and proper, Kai Young has no time or inclination for distraction. Until he meets Isabella, the wild, bright barmaid who breaks every rule he ever had.";
    } else if (titleLower.contains('king of wrath')) {
      return "Dante Russo thrives on control. But when blackmailed into marrying Vivian Lau, the daughter of his enemy, a fake engagement turns into an all-consuming war of desire.";
    } else if (titleLower.contains('king of greed')) {
      return "Dominic Davenport took Alessandra for granted until she walked away. Now he will tear down his empire to win back her heart.";
    } else if (titleLower.contains('king of sloth')) {
      return "Xavier Castillo has no desire to take over his family's media empire. Sloane Walton is the ambitious PR manager tasked with polishing his image, but sparks turn into wildfire.";
    } else if (titleLower.contains('king of gluttony')) {
      return "Accustomed to having every craving satisfied, he never expected the one woman who refuses to submit to his charm. When their paths cross, indulgence turns into an explosive clash of wills.";
    } else if (titleLower.contains('twisted games')) {
      return "Stoic, haunted bodyguard Rhys Larsen has two rules: protect his clients at all costs and do not get emotionally involved. Until Princess Bridget von Ascheberg breaks down every wall he ever built.";
    } else if (titleLower.contains('twisted love')) {
      return "Alex Volkov is a devil blessed with the face of an angel. When he's forced to look after his best friend's sister, Ava Chen, the sparks fly into an all-consuming fire.";

      // 4. Emily Henry & Bestsellers
    } else if (titleLower.contains('beach read')) {
      return "Augustus Everett is an acclaimed author of literary fiction. January Andrews writes bestselling romance. When they spend the summer in neighboring beach houses, they strike a wager to swap genres.";
    } else if (titleLower.contains('book lovers')) {
      return "Nora Fischer is a cutthroat literary agent who keeps meeting Charlie Lastra, a brooding editor from the city. Stranded together in Sunshine Falls, North Carolina, their rival world becomes a romance.";
    } else if (titleLower.contains('fourth wing')) {
      return "Twenty-year-old Violet Sorrengail was supposed to enter the Scribe Quadrant. Instead, her commanding mother orders her to join the candidates striving to become the elite of Navarre: dragon riders.";
    } else if (titleLower.contains('deal') ||
        authorLower.contains('elle kennedy')) {
      return "Hannah Wells has finally found someone who turns her on, but to get his attention, she agrees to tutor college hockey captain Garrett Graham in exchange for a fake date that changes everything.";
    } else if (titleLower.contains('fine print') ||
        authorLower.contains('lauren asher')) {
      return "Rowan Kane is tasked with renovating Dreamland theme park, but his cynical corporate worldview is challenged when he hires Zahra Gulian, a fiery idealist who refuses to back down.";
    } else if (titleLower.contains('never got over') ||
        authorLower.contains('lucy score')) {
      return "Naomi fled her own wedding to save her estranged twin, only to end up stranded in Knockemout, Virginia with no money, no car, and custody of an 11-year-old niece she didn't know existed.";
    }

    // 5. Keyword-based Dynamic Teaser Generator
    if (titleLower.contains('king') ||
        titleLower.contains('queen') ||
        titleLower.contains('throne')) {
      return "In '$title', $author builds a gilded world of power, duty, and ruthless ambition where love is the most dangerous weapon of all.";
    } else if (titleLower.contains('god of malice')) {
      return "Killian Carson is charming, brilliant—and a predator beneath the polish. Glyndon King sees the darkness in him and knows she should run, but their desire is all-consuming. As obsession deepens, both are pulled into a dangerous game where love might be the weapon that finally breaks them.";
    } else if (titleLower.contains('god of') ||
        titleLower.contains('dark') ||
        titleLower.contains('shadow')) {
      return "A dark, addictive tale where secrets lurk in every shadow and two lovers are pulled into an all-consuming storm of desire.";
    }

    // 6. Dynamic Extraction from Book Description
    final cleanDesc = description.trim();
    if (cleanDesc.isNotEmpty &&
        !cleanDesc.toLowerCase().contains('published by open library') &&
        !cleanDesc.toLowerCase().contains('unforgettable story of') &&
        !cleanDesc.toLowerCase().contains('imported from reading catalog')) {
      final sentences = cleanDesc.split(RegExp(r'(?<=[.!?])\s+'));
      final validSentences = sentences
          .map((s) => s.trim())
          .where(
            (s) =>
                s.length > 15 &&
                !s.toLowerCase().contains('published by') &&
                !s.toLowerCase().contains('unforgettable story') &&
                !s.toLowerCase().startsWith('no. 1 ') &&
                !s.toLowerCase().startsWith('the no. 1 ') &&
                !RegExp(r'(?:[a-zA-Z]\.{2,3}|\.{3,}|…)\s*$').hasMatch(s),
          )
          .toList();

      if (validSentences.length >= 3) {
        return '${validSentences[0]} ${validSentences[1]} ${validSentences[2]}';
      } else if (validSentences.length >= 2) {
        return '${validSentences[0]} ${validSentences[1]}';
      } else if (validSentences.isNotEmpty) {
        return validSentences.first;
      }
    }

    return "In '$title', $author crafts a gripping narrative where opposing forces collide, testing loyalty, passion, and the power of love.";
  }

  String? get audioFilePath => localFilePath;
  String? get epubFilePath =>
      (format == BookFormat.epub ||
          (localFilePath != null &&
              localFilePath!.toLowerCase().endsWith('.epub')))
      ? localFilePath
      : null;
  String? get pdfFilePath =>
      (format == BookFormat.pdf ||
          (localFilePath != null &&
              localFilePath!.toLowerCase().endsWith('.pdf')))
      ? localFilePath
      : null;

  static const Object _sentinel = Object();

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? tagline,
    String? blurb,
    String? coverUrl,
    int? totalPages,
    int? currentPage,
    ReadingStatus? status,
    BookFormat? format,
    List<String>? genres,
    DateTime? startDate,
    DateTime? finishDate,
    DateTime? endDate,
    Object? finishDateValue = _sentinel,
    Object? endDateValue = _sentinel,
    double? overallRating,
    double? spiceRating,
    double? fluffRating,
    double? tearRating,
    double? humorRating,
    List<JournalEntry>? journalEntries,
    List<QuoteAnnotation>? quotes,
    Object? localFilePath = _sentinel,
    Object? audioFilePath = _sentinel,
    Object? epubFilePath = _sentinel,
    Object? pdfFilePath = _sentinel,
    bool clearLocalFilePath = false,
    bool? isFavorite,
  }) {
    String? resolvedLocalFilePath;
    if (clearLocalFilePath) {
      resolvedLocalFilePath = null;
    } else if (!identical(localFilePath, _sentinel)) {
      resolvedLocalFilePath = localFilePath as String?;
    } else if (!identical(audioFilePath, _sentinel)) {
      resolvedLocalFilePath = audioFilePath as String?;
    } else if (!identical(epubFilePath, _sentinel)) {
      resolvedLocalFilePath = epubFilePath as String?;
    } else if (!identical(pdfFilePath, _sentinel)) {
      resolvedLocalFilePath = pdfFilePath as String?;
    } else {
      resolvedLocalFilePath = this.localFilePath;
    }

    final DateTime? resolvedFinishDate;
    if (!identical(finishDateValue, _sentinel)) {
      resolvedFinishDate = finishDateValue as DateTime?;
    } else if (!identical(endDateValue, _sentinel)) {
      resolvedFinishDate = endDateValue as DateTime?;
    } else if (endDate != null) {
      resolvedFinishDate = endDate;
    } else if (finishDate != null) {
      resolvedFinishDate = finishDate;
    } else {
      resolvedFinishDate = this.finishDate;
    }

    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      tagline: tagline ?? this.tagline,
      blurb: blurb ?? this.blurb,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      format: format ?? this.format,
      genres: genres ?? this.genres,
      startDate: startDate ?? this.startDate,
      finishDate: resolvedFinishDate,
      overallRating: overallRating ?? this.overallRating,
      spiceRating: spiceRating ?? this.spiceRating,
      fluffRating: fluffRating ?? this.fluffRating,
      tearRating: tearRating ?? this.tearRating,
      humorRating: humorRating ?? this.humorRating,
      journalEntries: journalEntries ?? this.journalEntries,
      quotes: quotes ?? this.quotes,
      localFilePath: resolvedLocalFilePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] is Map<String, dynamic>
        ? json['volumeInfo'] as Map<String, dynamic>
        : null;

    final id = (json['id'] ?? volumeInfo?['id'] ?? '').toString();
    final title = (json['title'] ?? volumeInfo?['title'] ?? 'Unknown Title')
        .toString();

    String author = 'Unknown Author';
    final rawAuthor =
        json['author'] ?? json['authors'] ?? volumeInfo?['authors'];
    if (rawAuthor is List && rawAuthor.isNotEmpty) {
      author = rawAuthor.first.toString();
    } else if (rawAuthor != null) {
      author = rawAuthor.toString();
    }

    final description =
        (json['description'] ?? volumeInfo?['description'] ?? '').toString();
    final tagline = (json['tagline'] ?? volumeInfo?['subtitle'])?.toString();
    final blurb = json['blurb']?.toString();

    String coverUrl = '';
    if (json['coverUrl'] != null) {
      coverUrl = json['coverUrl'].toString();
    } else if (volumeInfo?['imageLinks'] is Map) {
      final img = volumeInfo!['imageLinks'] as Map;
      coverUrl =
          (img['extraLarge'] ??
                  img['large'] ??
                  img['medium'] ??
                  img['thumbnail'] ??
                  '')
              .toString();
    }

    final totalPages =
        (json['totalPages'] ??
                json['pageCount'] ??
                volumeInfo?['pageCount'] as num?)
            ?.toInt() ??
        0;
    final currentPage = (json['currentPage'] as num?)?.toInt() ?? 0;

    ReadingStatus status = ReadingStatus.toRead;
    if (json['status'] != null) {
      if (json['status'] is int &&
          (json['status'] as int) < ReadingStatus.values.length) {
        status = ReadingStatus.values[json['status'] as int];
      }
    }

    BookFormat format = BookFormat.paperback;
    if (json['format'] != null) {
      if (json['format'] is int &&
          (json['format'] as int) < BookFormat.values.length) {
        format = BookFormat.values[json['format'] as int];
      }
    }

    // Check Google Books categories and OpenLibrary subjects
    final rawData =
        json['categories'] ??
        json['subjects'] ??
        json['genres'] ??
        volumeInfo?['categories'] ??
        volumeInfo?['subjects'];
    final parsedGenres = GenreParser.parseRawGenres(rawData);

    return Book(
      id: id,
      title: title,
      author: author,
      description: description,
      tagline: tagline,
      blurb: blurb,
      coverUrl: coverUrl,
      totalPages: totalPages,
      currentPage: currentPage,
      status: status,
      format: format,
      genres: parsedGenres.isNotEmpty ? parsedGenres : const ['General'],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      finishDate:
          (json['endDate'] ?? json['finishDate'] ?? json['completedDate']) !=
              null
          ? DateTime.tryParse(
              (json['endDate'] ?? json['finishDate'] ?? json['completedDate'])
                  .toString(),
            )
          : null,
      overallRating:
          (json['overallRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      spiceRating: (json['spiceRating'] as num?)?.toDouble() ?? 0.0,
      fluffRating: (json['fluffRating'] as num?)?.toDouble() ?? 0.0,
      tearRating: (json['tearRating'] as num?)?.toDouble() ?? 0.0,
      humorRating: (json['humorRating'] as num?)?.toDouble() ?? 0.0,
      localFilePath: json['localFilePath']?.toString(),
      isFavorite: json['is_favorite'] == 1 || json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'tagline': tagline,
      'blurb': blurb,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status.index,
      'format': format.index,
      'genres': jsonEncode(genres), // Store cleanly as JSON string array
      'startDate': startDate?.toIso8601String(),
      'finishDate': finishDate?.toIso8601String(),
      'endDate': (endDate ?? finishDate)?.toIso8601String(),
      'overallRating': overallRating,
      'spiceRating': spiceRating,
      'fluffRating': fluffRating,
      'tearRating': tearRating,
      'humorRating': humorRating,
      'localFilePath': localFilePath,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Book.fromMap(
    Map<String, dynamic> map, {
    List<JournalEntry> journalEntries = const [],
    List<QuoteAnnotation> quotes = const [],
  }) {
    List<String> loadedGenres = [];
    final raw = map['genres'] ?? map['genre'];

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) {
          loadedGenres = List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {
        // Fallback for legacy plain text / comma-separated strings
        loadedGenres = raw
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    final rawStatus = map['status'];
    final ReadingStatus resolvedStatus = () {
      if (rawStatus is int && rawStatus >= 0 && rawStatus < ReadingStatus.values.length) {
        return ReadingStatus.values[rawStatus];
      }
      if (rawStatus is String) {
        return ReadingStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == rawStatus.toLowerCase(),
          orElse: () => ReadingStatus.toRead,
        );
      }
      return ReadingStatus.toRead;
    }();

    final rawFormat = map['format'];
    final BookFormat resolvedFormat = () {
      if (rawFormat is int && rawFormat >= 0 && rawFormat < BookFormat.values.length) {
        return BookFormat.values[rawFormat];
      }
      if (rawFormat is String) {
        return BookFormat.values.firstWhere(
          (e) => e.name.toLowerCase() == rawFormat.toLowerCase(),
          orElse: () => BookFormat.paperback,
        );
      }
      return BookFormat.paperback;
    }();

    final int totalPages = (map['totalPages'] is num)
        ? (map['totalPages'] as num).toInt()
        : int.tryParse(map['totalPages']?.toString() ?? '') ?? 0;

    final int currentPage = (map['currentPage'] is num)
        ? (map['currentPage'] as num).toInt()
        : int.tryParse(map['currentPage']?.toString() ?? '') ?? 0;

    final double overallRating = (map['overallRating'] is num)
        ? (map['overallRating'] as num).toDouble()
        : (map['rating'] is num)
            ? (map['rating'] as num).toDouble()
            : double.tryParse(map['overallRating']?.toString() ?? '') ?? 0.0;

    final double spiceRating = (map['spiceRating'] is num)
        ? (map['spiceRating'] as num).toDouble()
        : double.tryParse(map['spiceRating']?.toString() ?? '') ?? 0.0;

    final double fluffRating = (map['fluffRating'] is num)
        ? (map['fluffRating'] as num).toDouble()
        : double.tryParse(map['fluffRating']?.toString() ?? '') ?? 0.0;

    final double tearRating = (map['tearRating'] is num)
        ? (map['tearRating'] as num).toDouble()
        : double.tryParse(map['tearRating']?.toString() ?? '') ?? 0.0;

    final double humorRating = (map['humorRating'] is num)
        ? (map['humorRating'] as num).toDouble()
        : double.tryParse(map['humorRating']?.toString() ?? '') ?? 0.0;

    final bool isFavorite = map['is_favorite'] == 1 ||
        map['is_favorite'] == true ||
        map['isFavorite'] == true;

    return Book(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Title',
      author: map['author']?.toString() ?? 'Unknown Author',
      description: map['description']?.toString() ?? '',
      tagline: map['tagline']?.toString(),
      blurb: map['blurb']?.toString(),
      coverUrl: map['coverUrl']?.toString() ?? '',
      totalPages: totalPages,
      currentPage: currentPage,
      status: resolvedStatus,
      format: resolvedFormat,
      genres: loadedGenres.isNotEmpty ? loadedGenres : const ['General'],
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString())
          : null,
      finishDate:
          (map['endDate'] ?? map['finishDate'] ?? map['completedDate']) != null
          ? DateTime.tryParse(
              (map['endDate'] ?? map['finishDate'] ?? map['completedDate'])
                  .toString(),
            )
          : null,
      overallRating: overallRating,
      spiceRating: spiceRating,
      fluffRating: fluffRating,
      tearRating: tearRating,
      humorRating: humorRating,
      journalEntries: journalEntries,
      quotes: quotes,
      localFilePath: map['localFilePath']?.toString(),
      isFavorite: isFavorite,
    );
  }
}
