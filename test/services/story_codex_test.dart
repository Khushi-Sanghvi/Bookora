import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/story_codex.dart';
import 'package:between_world/services/story_codex_engine.dart';
import 'package:between_world/services/story_codex_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  group('StoryCodex & CodexCharacter Model Serialization Tests', () {
    test('CodexCharacter toJson and fromJson roundtrip correctly', () {
      const character = CodexCharacter(
        name: 'Killian Carson',
        role: 'Protagonist / Anti-hero',
        archetype: 'The Morally Gray Anti-hero',
        description: 'Enigmatic, dangerous student who commands fear and obsession.',
        quote: 'You do not run from the storm, Little Bird.',
      );

      final jsonMap = character.toJson();
      expect(jsonMap['name'], equals('Killian Carson'));
      expect(jsonMap['role'], equals('Protagonist / Anti-hero'));
      expect(jsonMap['archetype'], equals('The Morally Gray Anti-hero'));
      expect(jsonMap['description'], contains('Enigmatic'));
      expect(jsonMap['quote'], contains('storm'));

      final restored = CodexCharacter.fromJson(jsonMap);
      expect(restored.name, equals(character.name));
      expect(restored.role, equals(character.role));
      expect(restored.archetype, equals(character.archetype));
      expect(restored.description, equals(character.description));
      expect(restored.quote, equals(character.quote));
    });

    test('StoryCodex toJson and fromJson roundtrip with full 5D narrative schema', () {
      const codex = StoryCodex(
        bookId: 'test_hyperion_1',
        hook: 'On the eve of armageddon, seven pilgrims set out for the Time Tombs.',
        premise: 'Seven travelers share their haunting tales on an interplanetary pilgrimage to the lethal Shrike.',
        synopsis: 'Hyperion is a legendary science fiction masterpiece spanning deep time and space.',
        timePeriod: 'Far Future / 28th Century',
        primaryLocation: 'Web World of Hegemony / Hyperion Valley',
        worldbuildingTags: ['Time Tombs', 'Space Opera', 'Cybernetic Web', 'The Shrike'],
        atmosphericTone: 'Philosophical, Gothic & Haunting',
        characters: [
          CodexCharacter(
            name: 'The Consul',
            role: 'Protagonist',
            archetype: 'The Diplomat',
            description: 'Carries a dark secret from Siri’s world.',
          ),
          CodexCharacter(
            name: 'The Shrike',
            role: 'Antagonist',
            archetype: 'The Monster of Time',
            description: 'Four-armed creature of razor wire and thorns.',
          ),
        ],
        tropes: ['Pilgrimage', 'Framed Narrative', 'Cosmic Horror', 'AI Hegemony'],
        povType: 'Multiple POV',
        pacing: 'Slow-burn',
        spiceLevel: 1.5,
        fluffLevel: 2.0,
        tearLevel: 4.5,
        humorLevel: 2.0,
        tensionLevel: 4.8,
        themes: ['Mortality', 'Faith vs Technology', 'Grief', 'Identity'],
        contentWarnings: ['Violence', 'Body Horror', 'Existential Dread'],
      );

      final jsonMap = codex.toJson();
      expect(jsonMap['bookId'], equals('test_hyperion_1'));
      expect(jsonMap['hook'], contains('seven pilgrims'));
      expect(jsonMap['spiceLevel'], equals(1.5));
      expect(jsonMap['tensionLevel'], equals(4.8));
      expect(jsonMap['worldbuildingTags'], contains('Time Tombs'));
      expect(jsonMap['characters'].length, equals(2));

      final restored = StoryCodex.fromJson(jsonMap);
      expect(restored.bookId, equals('test_hyperion_1'));
      expect(restored.hook, equals(codex.hook));
      expect(restored.primaryLocation, equals('Web World of Hegemony / Hyperion Valley'));
      expect(restored.pacing, equals('Slow-burn'));
      expect(restored.povType, equals('Multiple POV'));
      expect(restored.characters.length, equals(2));
      expect(restored.characters.first.name, equals('The Consul'));
      expect(restored.themes, contains('Faith vs Technology'));
      expect(restored.contentWarnings, contains('Body Horror'));
    });

    test('StoryCodex maintains backward-compatibility getters', () {
      const codex = StoryCodex(
        bookId: 'legacy_compat',
        premise: 'A dangerous love at Kingston University.',
        synopsis: 'Full synopsis text here.',
        primaryLocation: 'Kingston University',
        atmosphericTone: 'Dark & Gripping',
        tropes: ['Enemies to Lovers', 'Dark Romance'],
        fluffLevel: 4.0,
        tensionLevel: 4.5,
      );

      expect(codex.setting, equals('Kingston University'));
      expect(codex.atmosphere, equals('Dark & Gripping'));
      expect(codex.tone, equals('Dark & Gripping'));
      expect(codex.emotionalResonance, equals(4.0));
      expect(codex.suspenseLevel, equals(4.5));
      expect(codex.relationshipDynamics, contains('Enemies to Lovers'));
      expect(codex.timePeriodDisplay, equals('Present Day'));
      expect(codex.pacingDisplay, equals('Medium'));
    });
  });

  group('StoryCodexService Heuristic NLP & Enrichment Engine Tests', () {
    test('Fallback NLP extracts hook, characters, tropes, and 5D flavor from synopsis', () async {
      final book = Book(
        id: 'mock_dark_romance_book',
        title: 'Dark Obsession',
        author: 'Rina Kent',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 400,
        description: '"I made a deal with the devil, and now he owns my soul." '
            'Killian Carson is a ruthless psychopath at Kingston University. '
            'Glyndon King is an art student haunted by guilt. When their paths cross on the cliffs, '
            'a dark, toxic obsession begins with enemies to lovers rivalry, stalking, and forbidden romance.',
        genres: ['Dark Romance', 'College Romance', 'Romantic Suspense'],
      );

      final codex = await StoryCodexService.enrichCodex(book);

      expect(codex.bookId, equals(book.id));
      expect(codex.hook.isNotEmpty, isTrue);
      expect(codex.hook, contains('devil')); // Extracted quote/first sentence
      expect(codex.characters.any((c) => c.name.contains('Killian') || c.name.contains('Glyndon')), isTrue);
      expect(codex.tropes.any((t) => t.toLowerCase().contains('enemies') || t.toLowerCase().contains('dark romance')), isTrue);
      // Dark romance flavor calibration: Spice >= 3.0, Tension >= 3.0
      expect(codex.spiceLevel, greaterThanOrEqualTo(3.0));
      expect(codex.tensionLevel, greaterThanOrEqualTo(3.0));
      expect(codex.themes.isNotEmpty, isTrue);
    });

    test('Synchronous and in-memory cache returns instantly after enrichment', () async {
      final book = Book(
        id: 'fast_cache_book_42',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        coverUrl: 'https://example.com/cover.jpg',
        totalPages: 496,
        description: 'Ryland Grace is the sole survivor on a desperate, last-chance mission to save Earth from an extinction-level solar crisis.',
        genres: ['Sci-Fi', 'Space Opera'],
      );

      // Before enrichment, peek returns fallback or null
      final before = StoryCodexService.peekCachedCodex(book.id);
      expect(before, isNull);

      // Run enrichment
      final enriched = await StoryCodexService.enrichCodex(book);
      expect(enriched.bookId, equals(book.id));

      // After enrichment, instant peek must return the enriched codex immediately
      final cached = StoryCodexService.peekCachedCodex(book.id);
      expect(cached, isNotNull);
      expect(cached!.bookId, equals(book.id));
      expect(cached.hook, equals(enriched.hook));
    });
  });

  group('StoryCodex Distinct Characters & Author Exclusion Tests', () {
    test('different books resolve their own unique main characters', () {
      final acotar = StoryCodexEngine.generateCodex(Book(
        id: 'b_acotar',
        title: 'A Court of Thorns and Roses',
        author: 'Sarah J. Maas',
        coverUrl: '',
        totalPages: 419,
      ));
      expect(acotar.characters.any((c) => c.name.contains('Feyre')), isTrue);
      expect(acotar.characters.any((c) => c.name.contains('Rhysand') || c.name.contains('Tamlin')), isTrue);

      final fourthWing = StoryCodexEngine.generateCodex(Book(
        id: 'b_fw',
        title: 'Fourth Wing',
        author: 'Rebecca Yarros',
        coverUrl: '',
        totalPages: 528,
      ));
      expect(fourthWing.characters.any((c) => c.name.contains('Violet')), isTrue);
      expect(fourthWing.characters.any((c) => c.name.contains('Xaden')), isTrue);

      final cruelPrince = StoryCodexEngine.generateCodex(Book(
        id: 'b_cp',
        title: 'The Cruel Prince',
        author: 'Holly Black',
        coverUrl: '',
        totalPages: 370,
      ));
      expect(cruelPrince.characters.any((c) => c.name.contains('Jude')), isTrue);
      expect(cruelPrince.characters.any((c) => c.name.contains('Cardan')), isTrue);

      final hungerGames = StoryCodexEngine.generateCodex(Book(
        id: 'b_hg',
        title: 'The Hunger Games',
        author: 'Suzanne Collins',
        coverUrl: '',
        totalPages: 374,
      ));
      expect(hungerGames.characters.any((c) => c.name.contains('Katniss')), isTrue);
      expect(hungerGames.characters.any((c) => c.name.contains('Peeta')), isTrue);

      final pride = StoryCodexEngine.generateCodex(Book(
        id: 'b_pp',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        coverUrl: '',
        totalPages: 432,
      ));
      expect(pride.characters.any((c) => c.name.contains('Elizabeth')), isTrue);
      expect(pride.characters.any((c) => c.name.contains('Darcy')), isTrue);

      // Verify that characters from one book are not cross-contaminated into another
      expect(acotar.characters.any((c) => c.name.contains('Katniss')), isFalse);
      expect(fourthWing.characters.any((c) => c.name.contains('Feyre')), isFalse);
      expect(hungerGames.characters.any((c) => c.name.contains('Violet')), isFalse);
    });

    test('author names are strictly excluded from characters list', () {
      final book = Book(
        id: 'b_author_test',
        title: 'Mystic Whispers',
        author: 'Sarah J. Maas',
        coverUrl: '',
        totalPages: 350,
        description: 'From #1 New York Times bestselling author Sarah J. Maas comes an epic story. '
            'Praise from Colleen Hoover: Unforgettable! '
            'Written by Sarah J. Maas for fans of Rebecca Yarros. '
            'Elysia Thorne is a fierce sorceress defending her realm. '
            'Kaelen Vance is a shadow warrior bound by honor.',
      );

      final codex = StoryCodexEngine.generateCodex(book);

      // Verify author names were NOT added as characters
      for (final char in codex.characters) {
        final nameLower = char.name.toLowerCase();
        expect(nameLower.contains('sarah'), isFalse, reason: 'Author name Sarah J. Maas must not be a character');
        expect(nameLower.contains('maas'), isFalse, reason: 'Author name Sarah J. Maas must not be a character');
        expect(nameLower.contains('hoover'), isFalse, reason: 'Blurb author Colleen Hoover must not be a character');
        expect(nameLower.contains('yarros'), isFalse, reason: 'Promo author Rebecca Yarros must not be a character');
      }

      // Verify actual fictional characters were extracted
      expect(codex.characters.any((c) => c.name.contains('Elysia') || c.name.contains('Kaelen')), isTrue);
      for (final char in codex.characters) {
        expect(char.description, isNotNull);
        expect(char.description!.trim().isNotEmpty, isTrue);
      }
    });

    test('curated literature resolves exact authentic leads and descriptions', () {
      final twistedLies = StoryCodexEngine.generateCodex(Book(
        id: 'b_tl',
        title: 'Twisted Lies',
        author: 'Ana Huang',
        coverUrl: '',
        totalPages: 480,
      ));
      expect(twistedLies.characters.any((c) => c.name == 'Christian Harper'), isTrue);
      expect(twistedLies.characters.any((c) => c.name == 'Stella Alonso'), isTrue);
      expect(twistedLies.characters.firstWhere((c) => c.name == 'Christian Harper').description, contains('cybersecurity'));

      final midnightLib = StoryCodexEngine.generateCodex(Book(
        id: 'b_ml',
        title: 'The Midnight Library',
        author: 'Matt Haig',
        coverUrl: '',
        totalPages: 304,
      ));
      expect(midnightLib.characters.any((c) => c.name == 'Nora Seed'), isTrue);
      expect(midnightLib.characters.any((c) => c.name == 'Mrs. Elm'), isTrue);
      expect(midnightLib.characters.any((c) => c.name.contains('Matt') || c.name.contains('Haig')), isFalse);
      expect(midnightLib.characters.any((c) => c.name == 'The Midnight' || c.name == 'Library'), isFalse);

      final daisyJones = StoryCodexEngine.generateCodex(Book(
        id: 'b_dj',
        title: 'Daisy Jones & The Six',
        author: 'Taylor Jenkins Reid',
        coverUrl: '',
        totalPages: 368,
      ));
      expect(daisyJones.characters.any((c) => c.name == 'Daisy Jones'), isTrue);
      expect(daisyJones.characters.any((c) => c.name == 'Billy Dunne'), isTrue);
      expect(daisyJones.characters.any((c) => c.name.contains('Taylor') || c.name.contains('Reid')), isFalse);

      final loveBrain = StoryCodexEngine.generateCodex(Book(
        id: 'b_lob',
        title: 'Love on the Brain',
        author: 'Ali Hazelwood',
        coverUrl: '',
        totalPages: 360,
      ));
      expect(loveBrain.characters.any((c) => c.name == 'Bee Königswasser'), isTrue);
      expect(loveBrain.characters.any((c) => c.name == 'Levi Ward'), isTrue);

      final harryPotter = StoryCodexEngine.generateCodex(Book(
        id: 'b_hp',
        title: 'Harry Potter and the Sorcerer\'s Stone',
        author: 'J.K. Rowling',
        coverUrl: '',
        totalPages: 309,
      ));
      expect(harryPotter.characters.any((c) => c.name == 'Harry Potter'), isTrue);
      expect(harryPotter.characters.any((c) => c.name == 'Hermione Granger'), isTrue);
      expect(harryPotter.characters.any((c) => c.name == 'Ron Weasley'), isTrue);
    });

    test('contemporary books do not receive spurious AI or Cybernetic tropes', () {
      final contemporaryCodex = StoryCodexService.getCodexForBook(Book(
        id: 'b_contemp',
        title: 'Beach Read',
        author: 'Emily Henry',
        coverUrl: '',
        totalPages: 360,
        description: 'Two writers spend the summer challenging each other, sharing daily conversations and healing old family pain.',
        genres: ['Romance', 'Contemporary'],
      ));

      contemporaryCodex.then((codex) {
        expect(codex.tropes.contains('AI Awakening'), isFalse);
        expect(codex.worldbuildingTags.contains('Cybernetic Systems'), isFalse);
      });
    });

    test('autoFetchCharactersOnline resolves exact authentic leads for God of Ruin', () async {
      final godOfRuin = Book(
        id: 'b_gor',
        title: 'God of Ruin',
        author: 'Rina Kent',
        coverUrl: '',
        totalPages: 450,
      );

      final characters = await StoryCodexService.autoFetchCharactersOnline(godOfRuin);
      expect(characters.isNotEmpty, isTrue);
      expect(characters.any((c) => c.name == 'Landon King'), isTrue);
      expect(characters.any((c) => c.name == 'Mia Sokolov'), isTrue);
      expect(characters.any((c) => c.name.toLowerCase() == 'genius artist'), isFalse);
      expect(characters.any((c) => c.name.toLowerCase().contains('rina') || c.name.toLowerCase().contains('kent')), isFalse);
    });

    test('lead regex strictly rejects lowercase occupation phrases like genius artist', () {
      final candidates = StoryCodexEngine.extractCandidateCharacters(
        synopsis: 'Landon King is a genius artist, a posh rich boy, and my worst nightmare. '
            'Mia Sokolov is a silent prodigy who knows his darkest secrets.',
        author: 'Rina Kent',
        title: 'God of Ruin',
        genres: ['Dark Romance', 'College'],
      );

      final names = candidates.map((c) => c.name).toList();
      expect(names, contains('Landon King'));
      expect(names, contains('Mia Sokolov'));
      expect(names.contains('genius artist'), isFalse);
      expect(names.any((n) => n.toLowerCase() == 'genius artist'), isFalse);
      expect(names.any((n) => n.toLowerCase() == 'posh rich'), isFalse);
    });
  });
}

