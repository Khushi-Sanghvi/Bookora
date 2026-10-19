import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Represents an individual book entry associated with a calendar date,
/// containing rich metadata modeled after the Figures of Destiny codex pattern.
class CalendarBookEntry {
  final String id;
  final String bookTitle;
  final String readingStatusTag; // e.g. "Active Read", "Companion Tome", "Shelved / DNF", "Finished"
  final String archetypeOrRoleTag; // e.g. "Primary Focus", "Audiobook Companion", "Chapter Milestone", "Physical Copy"
  final String entryNotes; // e.g. reflections, chapter milestones, reasons for setting aside
  final DateTime createdAt;

  CalendarBookEntry({
    String? id,
    required this.bookTitle,
    this.readingStatusTag = 'Active Read',
    this.archetypeOrRoleTag = 'Primary Focus',
    this.entryNotes = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookTitle': bookTitle,
      'readingStatusTag': readingStatusTag,
      'archetypeOrRoleTag': archetypeOrRoleTag,
      'entryNotes': entryNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CalendarBookEntry.fromMap(Map<String, dynamic> map) {
    return CalendarBookEntry(
      id: map['id']?.toString() ?? const Uuid().v4(),
      bookTitle: map['bookTitle']?.toString() ?? map['title']?.toString() ?? 'Untitled Tome',
      readingStatusTag: map['readingStatusTag']?.toString() ?? map['status']?.toString() ?? 'Active Read',
      archetypeOrRoleTag: map['archetypeOrRoleTag']?.toString() ?? map['role']?.toString() ?? 'Primary Focus',
      entryNotes: map['entryNotes']?.toString() ?? map['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CalendarBookEntry.fromJson(String source) =>
      CalendarBookEntry.fromMap(jsonDecode(source));

  static String encodeList(List<CalendarBookEntry> entries) {
    return jsonEncode(entries.map((e) => e.toMap()).toList());
  }

  CalendarBookEntry copyWith({
    String? id,
    String? bookTitle,
    String? readingStatusTag,
    String? archetypeOrRoleTag,
    String? entryNotes,
    DateTime? createdAt,
  }) {
    return CalendarBookEntry(
      id: id ?? this.id,
      bookTitle: bookTitle ?? this.bookTitle,
      readingStatusTag: readingStatusTag ?? this.readingStatusTag,
      archetypeOrRoleTag: archetypeOrRoleTag ?? this.archetypeOrRoleTag,
      entryNotes: entryNotes ?? this.entryNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Robust backward-compatible parser:
  /// - JSON string array of objects -> decoded via jsonDecode into `List<CalendarBookEntry>`
  /// - JSON string array of plain strings -> wraps into CalendarBookEntry objects
  /// - Plain legacy single string (or comma-separated) -> automatically wraps
  /// - Null or empty -> safely returns []
  static List<CalendarBookEntry> parseEntries(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      final result = <CalendarBookEntry>[];
      for (final item in raw) {
        if (item is CalendarBookEntry) {
          result.add(item);
        } else if (item is Map<String, dynamic>) {
          result.add(CalendarBookEntry.fromMap(item));
        } else if (item is Map) {
          result.add(CalendarBookEntry.fromMap(Map<String, dynamic>.from(item)));
        } else if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty) {
            result.add(CalendarBookEntry(
              bookTitle: str,
              readingStatusTag: 'Active Read',
              archetypeOrRoleTag: 'Companion Tome',
              entryNotes: '',
            ));
          }
        }
      }
      return _deduplicate(result);
    }

    final rawStr = raw.toString().trim();
    if (rawStr.isEmpty) return [];

    if (rawStr.startsWith('[') && rawStr.endsWith(']')) {
      try {
        final decoded = jsonDecode(rawStr);
        if (decoded is List) {
          return parseEntries(decoded);
        }
      } catch (_) {}
    }

    if (rawStr.startsWith('{') && rawStr.endsWith('}')) {
      try {
        final decoded = jsonDecode(rawStr);
        if (decoded is Map<String, dynamic>) {
          return [CalendarBookEntry.fromMap(decoded)];
        }
      } catch (_) {}
    }

    // Plain legacy comma-separated string or raw title
    if (rawStr.contains(',')) {
      final titles = rawStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
      return titles.map((t) => CalendarBookEntry(
        bookTitle: t,
        readingStatusTag: 'Active Read',
        archetypeOrRoleTag: 'Companion Tome',
        entryNotes: '',
      )).toList();
    }

    return [
      CalendarBookEntry(
        bookTitle: rawStr,
        readingStatusTag: 'Active Read',
        archetypeOrRoleTag: 'Companion Tome',
        entryNotes: '',
      ),
    ];
  }

  static List<CalendarBookEntry> _deduplicate(List<CalendarBookEntry> entries) {
    final seen = <String>{};
    final result = <CalendarBookEntry>[];
    for (final e in entries) {
      final key = '${e.bookTitle.trim().toLowerCase()}_${e.readingStatusTag.trim().toLowerCase()}';
      if (e.bookTitle.trim().isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        result.add(e);
      }
    }
    return result;
  }
}
