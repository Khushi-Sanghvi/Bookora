import '../models/book.dart';

class BookAnalysisResult {
  final String dominantGenre;
  final List<String> subgenres;
  final String pacing;
  final String tone;
  final String narrativeComplexity;
  final Map<String, double> thematicScores; // 0.0 - 1.0 (Spice, Fluff, Tear, Humor, Suspense, Action, Mystery)
  final List<String> tropesAndThemes;
  final double estimatedTotalHours;
  final double estimatedRemainingHours;
  final String readingVelocityText;
  final String estimatedFinishDateText;

  const BookAnalysisResult({
    required this.dominantGenre,
    required this.subgenres,
    required this.pacing,
    required this.tone,
    required this.narrativeComplexity,
    required this.thematicScores,
    required this.tropesAndThemes,
    required this.estimatedTotalHours,
    required this.estimatedRemainingHours,
    required this.readingVelocityText,
    required this.estimatedFinishDateText,
  });
}

class BookAnalyzerService {
  static BookAnalysisResult analyze(
    Book book, {
    double userSpeedPagesPerHour = 320.0,
  }) {
    final speed = userSpeedPagesPerHour > 50 ? userSpeedPagesPerHour : 250.0;
    final remainingPages = (book.totalPages - book.currentPage).clamp(
      0,
      book.totalPages > 0 ? book.totalPages : 1,
    );
    final totalPages = book.totalPages > 0 ? book.totalPages : 300;
    final totalHours = totalPages / speed;
    final remainingHours = remainingPages / speed;

    final daysToFinish = (remainingPages / 40.0).ceil();
    final finishDate = DateTime.now().add(Duration(days: daysToFinish));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final finishDateText =
        '${months[finishDate.month - 1]} ${finishDate.day}, ${finishDate.year}';

    final textCorpus =
        '${book.title} ${book.author} ${book.description} ${book.genres.join(' ')}'
            .toLowerCase();

    // 1. Dominant Genre & Subgenres
    String dominantGenre = 'Contemporary Fiction';
    final List<String> subgenres = [];
    final List<String> tropes = [];

    final isDarkRomance =
        textCorpus.contains('twisted') ||
        textCorpus.contains('ana huang') ||
        textCorpus.contains('billionaire') ||
        textCorpus.contains('dark romance') ||
        textCorpus.contains('possessive') ||
        textCorpus.contains('king') ||
        textCorpus.contains('ruin') ||
        textCorpus.contains('wrath');

    final isLitRpg =
        textCorpus.contains('online') ||
        textCorpus.contains('level') ||
        textCorpus.contains('game') ||
        textCorpus.contains('dungeon') ||
        textCorpus.contains('system') ||
        textCorpus.contains('solo');

    final isVictorianRomance =
        textCorpus.contains('pride') ||
        textCorpus.contains('darcy') ||
        textCorpus.contains('bennet') ||
        textCorpus.contains('austen') ||
        textCorpus.contains('regency');

    final isMysteryDetective =
        textCorpus.contains('holmes') ||
        textCorpus.contains('watson') ||
        textCorpus.contains('detective') ||
        textCorpus.contains('murder') ||
        textCorpus.contains('investigation') ||
        textCorpus.contains('clue');

    final isFantasyQuest =
        textCorpus.contains('sanderson') ||
        textCorpus.contains('way of kings') ||
        textCorpus.contains('magic') ||
        textCorpus.contains('elf') ||
        textCorpus.contains('journey') ||
        textCorpus.contains('dragon') ||
        textCorpus.contains('realm');

    if (isDarkRomance) {
      dominantGenre = 'Contemporary Dark Romance';
      subgenres.addAll([
        'Romantic Suspense',
        'Billionaire Romance',
        'Enemies-to-Lovers',
        'New Adult Drama',
      ]);
      tropes.addAll([
        'Morally Grey Hero',
        'Touch Her and Die',
        'Secret Identity',
        'Grumpy x Sunshine',
        'Forbidden Lust',
      ]);
    } else if (isLitRpg) {
      dominantGenre = 'LitRPG & Progression Fantasy';
      subgenres.addAll([
        'Action / Adventure',
        'Virtual Reality',
        'Isekai / Portal Fantasy',
        'Urban Fantasy',
      ]);
      tropes.addAll([
        'Underdog Ascent',
        'Stat Progression',
        'Solo Fighter',
        'Virtual World Stakes',
        'Dungeon Crawling',
      ]);
    } else if (isVictorianRomance) {
      dominantGenre = 'Victorian Romance & Social Drama';
      subgenres.addAll([
        'Classic Literature',
        'Regency Romance',
        'Satirical Drama',
        'Enemies-to-Lovers',
      ]);
      tropes.addAll([
        'Social Class Conflict',
        'Misunderstandings',
        'Witty Banter',
        'Slow Burn',
        'Ballroom Drama',
      ]);
    } else if (isMysteryDetective) {
      dominantGenre = 'Detective & Classic Mystery';
      subgenres.addAll([
        'Crime Thriller',
        'Victorian London',
        'Deductive Investigation',
        'Whodunnit',
      ]);
      tropes.addAll([
        'Genius Detective',
        'Loyal Sidekick',
        'Baffling Clues',
        'Twist Reveal',
        'London Fog',
      ]);
    } else if (isFantasyQuest) {
      dominantGenre = 'High Fantasy & Epic Lore';
      subgenres.addAll([
        'Epic Fantasy',
        'Slice of Life',
        'Post-Heroic Journey',
        'Philosophical Fantasy',
      ]);
      tropes.addAll([
        'Immortality & Grief',
        'Found Family',
        'Passing of Time',
        'Ancient Magic Lore',
      ]);
    } else {
      for (final tag in book.genres) {
        subgenres.add(tag);
      }
      if (subgenres.isEmpty) {
        subgenres.addAll(['Literary Fiction', 'Narrative Prose']);
      }
      tropes.addAll([
        'Character Exploration',
        'Philosophical Insights',
        'Atmospheric Setting',
        'Emotional Depth',
      ]);
    }

    // 2. Real Thematic Heat Scores (0.0 - 1.0 mapped to 0% - 100%)
    double spiceScore = book.spiceRating > 0
        ? (book.spiceRating / 5.0).clamp(0.0, 1.0)
        : (isDarkRomance
              ? 0.88
              : _calculateThematicDensity(textCorpus, [
                  'kiss',
                  'romance',
                  'passion',
                  'mature',
                  'spice',
                  'desire',
                  'lover',
                  'touch',
                ], baseScore: 0.20));

    double fluffScore = book.fluffRating > 0
        ? (book.fluffRating / 5.0).clamp(0.0, 1.0)
        : (isVictorianRomance
              ? 0.72
              : (isFantasyQuest
                    ? 0.65
                    : _calculateThematicDensity(textCorpus, [
                        'wholesome',
                        'cozy',
                        'comfort',
                        'love',
                        'sweet',
                        'warmth',
                        'friendship',
                        'healing',
                      ], baseScore: 0.30)));

    double tearScore = book.tearRating > 0
        ? (book.tearRating / 5.0).clamp(0.0, 1.0)
        : (isDarkRomance
              ? 0.64
              : _calculateThematicDensity(textCorpus, [
                  'sadness',
                  'grief',
                  'death',
                  'tragedy',
                  'loss',
                  'tears',
                  'crying',
                  'heartbreak',
                  'trauma',
                ], baseScore: 0.25));

    double humorScore = book.humorRating > 0
        ? (book.humorRating / 5.0).clamp(0.0, 1.0)
        : (isVictorianRomance
              ? 0.82
              : _calculateThematicDensity(textCorpus, [
                  'comedy',
                  'witty',
                  'humor',
                  'satire',
                  'funny',
                  'laugh',
                  'banter',
                  'sarcasm',
                  'playful',
                ], baseScore: 0.32));

    double actionScore = isLitRpg
        ? 0.92
        : (isDarkRomance
              ? 0.58
              : _calculateThematicDensity(textCorpus, [
                  'battle',
                  'sword',
                  'fight',
                  'action',
                  'monster',
                  'war',
                  'hunter',
                  'clash',
                  'danger',
                  'chase',
                ], baseScore: 0.22));

    double mysteryScore = isMysteryDetective
        ? 0.96
        : (isDarkRomance
              ? 0.76
              : _calculateThematicDensity(textCorpus, [
                  'clue',
                  'detective',
                  'secret',
                  'mystery',
                  'puzzle',
                  'investigation',
                  'hidden',
                  'truth',
                  'secrets',
                  'conspiracy',
                ], baseScore: 0.28));

    double suspenseScore = isMysteryDetective || isDarkRomance
        ? 0.85
        : _calculateThematicDensity(textCorpus, [
            'suspense',
            'tension',
            'thrill',
            'danger',
            'panic',
            'threat',
            'cliffhanger',
            'stakes',
          ], baseScore: 0.28);

    // 3. Pacing & Complexity
    String pacing = 'Moderate Balanced Pacing';
    if (actionScore > 0.65 || isLitRpg || isDarkRomance || suspenseScore > 0.70) {
      pacing = 'Fast-Paced & Gripping';
    } else if (isVictorianRomance || dominantGenre.contains('Classic')) {
      pacing = 'Deliberate & Character-Focused';
    }

    String tone = 'Introspective & Atmospheric';
    if (spiceScore > 0.7) {
      tone = 'Passionate, Intense & High-Stakes';
    } else if (fluffScore > 0.65) {
      tone = 'Warm, Wholesome & Comforting';
    } else if (tearScore > 0.65) {
      tone = 'Melancholic & Emotionally Moving';
    } else if (suspenseScore > 0.75 || mysteryScore > 0.75) {
      tone = 'Tense, Suspenseful & Enigmatic';
    }

    String complexity = 'Accessible & Engaging';
    if (book.totalPages > 400 || isVictorianRomance) {
      complexity = 'Rich, Layered & Literarily Complex';
    }

    return BookAnalysisResult(
      dominantGenre: dominantGenre,
      subgenres: subgenres.toSet().toList(),
      pacing: pacing,
      tone: tone,
      narrativeComplexity: complexity,
      thematicScores: {
        '🌶️ Spice': spiceScore,
        '✨ Fluff': fluffScore,
        '💧 Tear': tearScore,
        '😄 Humor': humorScore,
        '⚡ Suspense': suspenseScore,
        '⚔️ Action': actionScore,
        '🔍 Mystery': mysteryScore,
      },
      tropesAndThemes: tropes.take(5).toList(),
      estimatedTotalHours: totalHours,
      estimatedRemainingHours: remainingHours,
      readingVelocityText: '${speed.toInt()} pages/hour measured pace',
      estimatedFinishDateText: finishDateText,
    );
  }

  static double _calculateThematicDensity(
    String corpus,
    List<String> keywords, {
    required double baseScore,
  }) {
    int matches = 0;
    for (final word in keywords) {
      if (corpus.contains(word)) matches++;
    }
    if (matches == 0) return baseScore.clamp(0.15, 0.90);
    final calculated = baseScore + (matches * 0.12);
    return calculated.clamp(0.20, 0.98);
  }
}
