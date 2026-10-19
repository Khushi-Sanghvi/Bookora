import 'dart:convert';

class CodexCharacter {
  final String? _name;
  final String?
  _role; // Protagonist, Antagonist, Supporting, Love Interest, Confidant
  final String?
  _archetype; // e.g., "The Consuls", "The Scholar", "The Morally Gray Anti-hero"
  final String? description;
  final String? quote;

  String get name => _name ?? 'Unknown Character';
  String get role => _role ?? 'Protagonist';
  String get archetype => _archetype ?? 'Archetype';

  const CodexCharacter({
    String name = 'Unknown Character',
    String role = 'Protagonist',
    String archetype = 'Archetype',
    this.description = '',
    this.quote,
  }) : _name = name,
       _role = role,
       _archetype = archetype;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'archetype': archetype,
      'description': description ?? '',
      if (quote != null) 'quote': quote,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory CodexCharacter.fromMap(Map<String, dynamic> map) {
    return CodexCharacter(
      name: map['name']?.toString() ?? 'Unknown Character',
      role: map['role']?.toString() ?? 'Protagonist',
      archetype: map['archetype']?.toString() ?? 'Archetype',
      description: map['description']?.toString() ?? '',
      quote: map['quote']?.toString(),
    );
  }

  factory CodexCharacter.fromJson(dynamic json) {
    if (json is String) {
      try {
        return CodexCharacter.fromMap(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        return const CodexCharacter(
          name: 'Unknown Character',
          role: 'Protagonist',
          archetype: 'Archetype',
        );
      }
    }
    if (json is Map<String, dynamic>) {
      return CodexCharacter.fromMap(json);
    }
    if (json is Map) {
      return CodexCharacter.fromMap(Map<String, dynamic>.from(json));
    }
    return const CodexCharacter(
      name: 'Unknown Character',
      role: 'Protagonist',
      archetype: 'Archetype',
    );
  }
}

class StoryCodex {
  final String? _bookId;
  final String? _hook; // Single punchy tagline
  final String? _premise; // 1-2 sentence core conflict
  final String? _synopsis; // Full, deduplicated story overview

  // 1. Worldbuilding & Settings
  final String?
  timePeriod; // e.g., "Far Future / 28th Century", "Victorian Era"
  final String?
  primaryLocation; // e.g., "Web World of Hegemony / Hyperion Valley"
  final List<String>?
  _worldbuildingTags; // e.g., ["Time Tombs", "Space Opera", "Cybernetic Web"]
  final String? atmosphericTone; // e.g., "Gothic", "Eerie", "Philosophical"

  // 2. Dramatis Personae (Character Roster)
  final List<CodexCharacter>? _characters;

  // 3. Narrative DNA & Tropes
  final List<String>?
  _tropes; // e.g., ["Enemies to Lovers", "Pilgrimage", "Bodyguard", "Unreliable Narrator"]
  final String?
  povType; // e.g., "Multiple POV", "First Person Dual", "Third Person Omniscient"
  final String? pacing; // e.g., "Fast-paced", "Slow-burn", "Episodic"

  // 4. 5D Narrative Flavor Profile (Scores 0.0 to 5.0)
  final double? _spiceLevel;
  final double? _fluffLevel;
  final double? _tearLevel;
  final double? _humorLevel;
  final double? _tensionLevel;

  // 5. Content Advisory & Thematic Motifs
  final List<String>?
  _themes; // e.g., ["Identity", "Mortality", "Forbidden Love", "Faith vs Technology"]
  final List<String>?
  _contentWarnings; // e.g., ["Violence", "Grief", "Substance Abuse"]
  final List<String>? _relationshipDynamics;

  // Bulletproof Non-Null Getters (guaranteed never to return null or throw subtype error)
  String get bookId => _bookId ?? '';
  String get hook {
    final h = _hook;
    return (h != null && h.isNotEmpty) ? h : premise;
  }

  String get premise => _premise ?? '';
  String get synopsis => _synopsis ?? '';

  List<String> get worldbuildingTags => _worldbuildingTags ?? const [];
  List<CodexCharacter> get characters => _characters ?? const [];
  List<String> get tropes => _tropes ?? const [];
  List<String> get themes => _themes ?? const [];
  List<String> get contentWarnings => _contentWarnings ?? const [];
  List<String> get relationshipDynamics {
    final rd = _relationshipDynamics;
    return (rd != null && rd.isNotEmpty)
        ? rd
        : (tropes.isNotEmpty ? tropes : const []);
  }

  double get spiceLevel => _spiceLevel ?? 2.5;
  double get fluffLevel => _fluffLevel ?? 3.5;
  double get tearLevel => _tearLevel ?? 3.0;
  double get humorLevel => _humorLevel ?? 3.0;
  double get tensionLevel => _tensionLevel ?? 3.0;

  // Backward-compatibility getters for existing views
  String get setting => primaryLocation ?? 'Contemporary World';
  String get atmosphere => atmosphericTone ?? 'Immersive & Atmospheric';
  String get tone => atmosphericTone ?? 'Intriguing & Emotional';
  String get timePeriodDisplay => timePeriod ?? 'Present Day';
  String get pacingDisplay => pacing ?? 'Medium';
  String get povTypeDisplay => povType ?? 'Third Person';
  double get emotionalResonance => fluffLevel > 0 ? fluffLevel : 3.5;
  double get suspenseLevel => tensionLevel > 0 ? tensionLevel : 3.0;

  const StoryCodex({
    String bookId = '',
    String? hook,
    String premise = '',
    String synopsis = '',
    this.timePeriod = 'Present Day',
    String? setting,
    String? primaryLocation,
    List<String>? worldbuildingTags = const [],
    String? atmosphere,
    String? atmosphericTone,
    List<CodexCharacter>? characters = const [],
    List<String>? tropes = const [],
    this.povType = 'Third Person',
    this.pacing = 'Medium',
    String? tone,
    double spiceLevel = 2.5,
    double? emotionalResonance,
    double? fluffLevel,
    double? tearLevel,
    double humorLevel = 3.0,
    double? suspenseLevel,
    double? tensionLevel,
    List<String>? themes = const [],
    List<String>? contentWarnings = const [],
    List<String>? relationshipDynamics,
  }) : _bookId = bookId,
       _hook = hook,
       _premise = premise,
       _synopsis = synopsis,
       primaryLocation = primaryLocation ?? setting ?? 'Contemporary World',
       _worldbuildingTags = worldbuildingTags ?? const [],
       atmosphericTone =
           atmosphericTone ?? atmosphere ?? tone ?? 'Immersive & Atmospheric',
       _characters = characters ?? const [],
       _tropes = tropes ?? const [],
       _spiceLevel = spiceLevel,
       _fluffLevel = fluffLevel ?? emotionalResonance ?? 3.5,
       _tearLevel = tearLevel ?? 3.0,
       _humorLevel = humorLevel,
       _tensionLevel = tensionLevel ?? suspenseLevel ?? 3.0,
       _themes = themes ?? const [],
       _contentWarnings = contentWarnings ?? const [],
       _relationshipDynamics = relationshipDynamics;

  StoryCodex copyWith({
    String? bookId,
    String? hook,
    String? premise,
    String? synopsis,
    String? timePeriod,
    String? primaryLocation,
    String? setting,
    List<String>? worldbuildingTags,
    String? atmosphericTone,
    String? atmosphere,
    List<CodexCharacter>? characters,
    List<String>? tropes,
    String? povType,
    String? pacing,
    String? tone,
    double? spiceLevel,
    double? fluffLevel,
    double? emotionalResonance,
    double? tearLevel,
    double? humorLevel,
    double? tensionLevel,
    double? suspenseLevel,
    List<String>? themes,
    List<String>? contentWarnings,
    List<String>? relationshipDynamics,
  }) {
    return StoryCodex(
      bookId: bookId ?? this.bookId,
      hook: hook ?? this.hook,
      premise: premise ?? this.premise,
      synopsis: synopsis ?? this.synopsis,
      timePeriod: timePeriod ?? this.timePeriod,
      primaryLocation: primaryLocation ?? setting ?? this.primaryLocation,
      worldbuildingTags: worldbuildingTags ?? this.worldbuildingTags,
      atmosphericTone:
          atmosphericTone ?? atmosphere ?? tone ?? this.atmosphericTone,
      characters: characters ?? this.characters,
      tropes: tropes ?? this.tropes,
      povType: povType ?? this.povType,
      pacing: pacing ?? this.pacing,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      fluffLevel: fluffLevel ?? emotionalResonance ?? this.fluffLevel,
      tearLevel: tearLevel ?? this.tearLevel,
      humorLevel: humorLevel ?? this.humorLevel,
      tensionLevel: tensionLevel ?? suspenseLevel ?? this.tensionLevel,
      themes: themes ?? this.themes,
      contentWarnings: contentWarnings ?? this.contentWarnings,
      relationshipDynamics: relationshipDynamics ?? this.relationshipDynamics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'hook': hook,
      'premise': premise,
      'synopsis': synopsis,
      'timePeriod': timePeriod,
      'primaryLocation': primaryLocation,
      'setting': setting,
      'worldbuildingTags': worldbuildingTags,
      'atmosphericTone': atmosphericTone,
      'atmosphere': atmosphere,
      'tone': tone,
      'characters': characters.map((c) => c.toMap()).toList(),
      'tropes': tropes,
      'povType': povType,
      'pacing': pacing,
      'spiceLevel': spiceLevel,
      'fluffLevel': fluffLevel,
      'emotionalResonance': emotionalResonance,
      'tearLevel': tearLevel,
      'humorLevel': humorLevel,
      'tensionLevel': tensionLevel,
      'suspenseLevel': suspenseLevel,
      'themes': themes,
      'contentWarnings': contentWarnings,
      'relationshipDynamics': relationshipDynamics,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory StoryCodex.fromMap(Map<String, dynamic> map) {
    return StoryCodex(
      bookId: map['bookId']?.toString() ?? '',
      hook: map['hook']?.toString() ?? map['premise']?.toString() ?? '',
      premise: map['premise']?.toString() ?? map['hook']?.toString() ?? '',
      synopsis: map['synopsis']?.toString() ?? '',
      timePeriod: map['timePeriod']?.toString() ?? 'Present Day',
      primaryLocation:
          map['primaryLocation']?.toString() ??
          map['setting']?.toString() ??
          'Contemporary World',
      worldbuildingTags:
          (map['worldbuildingTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      atmosphericTone:
          map['atmosphericTone']?.toString() ??
          map['atmosphere']?.toString() ??
          map['tone']?.toString() ??
          'Immersive & Atmospheric',
      characters:
          (map['characters'] as List<dynamic>?)
              ?.map((e) => CodexCharacter.fromJson(e))
              .toList() ??
          const [],
      tropes:
          (map['tropes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      povType: map['povType']?.toString() ?? 'Third Person',
      pacing: map['pacing']?.toString() ?? 'Medium',
      spiceLevel: (map['spiceLevel'] as num?)?.toDouble() ?? 2.5,
      fluffLevel:
          (map['fluffLevel'] as num?)?.toDouble() ??
          (map['emotionalResonance'] as num?)?.toDouble() ??
          3.5,
      tearLevel: (map['tearLevel'] as num?)?.toDouble() ?? 3.0,
      humorLevel: (map['humorLevel'] as num?)?.toDouble() ?? 3.0,
      tensionLevel:
          (map['tensionLevel'] as num?)?.toDouble() ??
          (map['suspenseLevel'] as num?)?.toDouble() ??
          3.0,
      themes:
          (map['themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      contentWarnings:
          (map['contentWarnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      relationshipDynamics:
          (map['relationshipDynamics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  factory StoryCodex.fromJson(dynamic json) {
    if (json is String) {
      try {
        return StoryCodex.fromMap(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        return const StoryCodex(
          bookId: '',
          hook: '',
          premise: '',
          synopsis: '',
        );
      }
    }
    if (json is Map<String, dynamic>) {
      return StoryCodex.fromMap(json);
    }
    if (json is Map) {
      return StoryCodex.fromMap(Map<String, dynamic>.from(json));
    }
    return const StoryCodex(bookId: '', hook: '', premise: '', synopsis: '');
  }
}
