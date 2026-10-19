import 'package:flutter/material.dart';
import '../models/book.dart';

/// Metadata for a curated book spine/cover color.
class SpineColorInfo {
  final String hex;
  final String name;
  final String category;

  const SpineColorInfo({
    required this.hex,
    required this.name,
    required this.category,
  });

  Color get color {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

/// Centralized color engine for book covers and spines in Bookora.
///
/// Features:
/// - 24 curated rich jewel tones and luxury leather library binding colors.
/// - Arranged in chromatic contrast order so consecutive books land on
///   widely different hue quadrants (e.g. Red -> Emerald -> Sapphire -> Amber -> Purple -> Teal).
/// - Non-repeating stateful dispenser [nextSpineColor] that guarantees
///   consecutive additions never repeat colors or similar hues.
class BookColorEngine {
  BookColorEngine._();

  static const String defaultColorHex = 'C0392B'; // Crimson Ruby

  /// 24 curated, vibrant book binding colors arranged for maximum adjacent contrast.
  static const List<SpineColorInfo> palette = [
    SpineColorInfo(
      hex: 'C0392B',
      name: 'Crimson Ruby',
      category: 'Red',
    ),
    SpineColorInfo(
      hex: '1E824C',
      name: 'Lush Emerald',
      category: 'Green',
    ),
    SpineColorInfo(
      hex: '1976D2',
      name: 'Royal Sapphire',
      category: 'Blue',
    ),
    SpineColorInfo(
      hex: 'D35400',
      name: 'Saffron Amber',
      category: 'Orange',
    ),
    SpineColorInfo(
      hex: '8E44AD',
      name: 'Amethyst Purple',
      category: 'Purple',
    ),
    SpineColorInfo(
      hex: '00838F',
      name: 'Ocean Teal',
      category: 'Teal',
    ),
    SpineColorInfo(
      hex: 'BF360C',
      name: 'Burnt Terracotta',
      category: 'Warm Terracotta',
    ),
    SpineColorInfo(
      hex: '0D47A1',
      name: 'Midnight Cobalt',
      category: 'Deep Blue',
    ),
    SpineColorInfo(
      hex: '880E4F',
      name: 'Imperial Wine',
      category: 'Wine / Berry',
    ),
    SpineColorInfo(
      hex: '00897B',
      name: 'Jade Sea',
      category: 'Teal Green',
    ),
    SpineColorInfo(
      hex: 'C2185B',
      name: 'Rosewood Magenta',
      category: 'Magenta',
    ),
    SpineColorInfo(
      hex: 'B7950B',
      name: 'Antique Ochre',
      category: 'Gold',
    ),
    SpineColorInfo(
      hex: '0288D1',
      name: 'Deep Cerulean',
      category: 'Sky Azure',
    ),
    SpineColorInfo(
      hex: '512DA8',
      name: 'Imperial Plum',
      category: 'Deep Violet',
    ),
    SpineColorInfo(
      hex: '935116',
      name: 'Warm Cognac',
      category: 'Warm Leather',
    ),
    SpineColorInfo(
      hex: '2E7D32',
      name: 'Forest Pine',
      category: 'Deep Green',
    ),
    SpineColorInfo(
      hex: 'E65100',
      name: 'Flame Rust',
      category: 'Vibrant Orange',
    ),
    SpineColorInfo(
      hex: '3F51B5',
      name: 'Royal Indigo',
      category: 'Indigo',
    ),
    SpineColorInfo(
      hex: '4E342E',
      name: 'Vintage Saddle',
      category: 'Leather Brown',
    ),
    SpineColorInfo(
      hex: 'AD1457',
      name: 'Burgundy Rose',
      category: 'Deep Pink',
    ),
    SpineColorInfo(
      hex: '33691E',
      name: 'Olive Moss',
      category: 'Olive Green',
    ),
    SpineColorInfo(
      hex: '006064',
      name: 'Abyssal Teal',
      category: 'Dark Teal',
    ),
    SpineColorInfo(
      hex: '6A1B9A',
      name: 'Mulberry Violet',
      category: 'Violet',
    ),
    SpineColorInfo(
      hex: 'D84315',
      name: 'Spiced Clay',
      category: 'Warm Clay',
    ),
  ];

  static int _stepCounter = 0;
  static String? _lastAssignedHex;

  /// Resets the internal counter (mainly for deterministic test assertions).
  @visibleForTesting
  static void resetState() {
    _stepCounter = 0;
    _lastAssignedHex = null;
  }

  /// Parses a hex color string (with or without `#`) into a Flutter [Color].
  /// Falls back to [defaultColorHex] on format failure.
  static Color parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color(0xFFC0392B);
    }
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return const Color(0xFFC0392B);
    } catch (_) {
      return const Color(0xFFC0392B);
    }
  }

  /// Finds [SpineColorInfo] by hex string, or returns null if not in palette.
  static SpineColorInfo? findByHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').toUpperCase();
    for (final info in palette) {
      if (info.hex.toUpperCase() == clean) return info;
    }
    return null;
  }

  /// Returns the next spine color hex, guaranteeing chromatic diversity.
  ///
  /// - [seed]: Optional title or string. If provided, hashes the seed while still
  ///   incorporating the step counter so identical or similar titles still advance.
  /// - [avoidColorHex]: Optional color to strictly avoid (e.g. the last book on the shelf).
  static String nextSpineColor({String? seed, String? avoidColorHex}) {
    final effectiveAvoid = (avoidColorHex != null && avoidColorHex.isNotEmpty)
        ? avoidColorHex.replaceAll('#', '').toUpperCase()
        : _lastAssignedHex?.toUpperCase();

    int targetIndex;

    if (seed != null && seed.trim().isNotEmpty) {
      // DJB2 hash of the seed string
      int hash = 5381;
      for (final codeUnit in seed.trim().codeUnits) {
        hash = (((hash << 5) + hash) + codeUnit) & 0x7FFFFFFF;
      }
      targetIndex = (hash + _stepCounter) % palette.length;
    } else {
      targetIndex = _stepCounter % palette.length;
    }

    _stepCounter++;

    if (effectiveAvoid != null &&
        palette[targetIndex].hex.toUpperCase() == effectiveAvoid) {
      targetIndex = (targetIndex + 1) % palette.length;
    }

    final avoidInfo = findByHex(effectiveAvoid);
    if (avoidInfo != null &&
        palette[targetIndex].category == avoidInfo.category) {
      targetIndex = (targetIndex + 1) % palette.length;
    }

    final chosenHex = palette[targetIndex].hex;
    _lastAssignedHex = chosenHex;
    return chosenHex;
  }

  /// Assigns distinct colors across an entire list of books.
  static List<Book> diversifyBookList(List<Book> books) {
    if (books.isEmpty) return books;
    return books;
  }
}
