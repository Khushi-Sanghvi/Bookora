import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/story_codex.dart';
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
}
