import 'dart:convert';

/// Represents a calendar date entry associated with multiple book strings,
/// titles, sessions, formats, notes, or identifiers.
class ReadingCalendarEntry {
  final DateTime date;
  final List<String> bookStrings;

  ReadingCalendarEntry({
    required this.date,
    required List<String> bookStrings,
  }) : bookStrings = _deduplicate(bookStrings);

  static List<String> _deduplicate(List<String> list) {
    final seen = <String>{};
    final result = <String>[];
    for (final s in list) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty && !seen.contains(trimmed)) {
        seen.add(trimmed);
        result.add(trimmed);
      }
    }
    return result;
  }

  /// Robust parser implementing backward-compatibility:
  /// - JSON string array (e.g. `["Book Title A", "Book Title B"]`) -> decoded via jsonDecode
  /// - Legacy single raw string (or comma-separated string) -> automatically wrapped: `[legacyString]`
  /// - Null or empty -> safely returns `[]`
  static List<String> parseBookStrings(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return _deduplicate(raw.map((e) => e?.toString() ?? '').toList());
    }
    final str = raw.toString().trim();
    if (str.isEmpty) return [];

    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return _deduplicate(decoded.map((e) => e?.toString() ?? '').toList());
        }
      } catch (_) {}
    }

    if (str.contains(',')) {
      return _deduplicate(str.split(','));
    }

    return [str];
  }

  /// Serializes the book strings to a JSON string array
  String serializeBookStrings() {
    return jsonEncode(bookStrings);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'bookStrings': serializeBookStrings(),
    };
  }

  factory ReadingCalendarEntry.fromMap(Map<String, dynamic> map) {
    final dateRaw = map['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    final rawStrings = map['bookStrings'] ?? map['books'] ?? map['title'];
    return ReadingCalendarEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      bookStrings: parseBookStrings(rawStrings),
    );
  }

  ReadingCalendarEntry copyWith({
    DateTime? date,
    List<String>? bookStrings,
  }) {
    return ReadingCalendarEntry(
      date: date ?? this.date,
      bookStrings: bookStrings ?? this.bookStrings,
    );
  }
}
