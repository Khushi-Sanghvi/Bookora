import 'dart:convert';
import 'calendar_book_entry.dart';

/// Represents a calendar date record containing multiple book string entries,
/// supporting both rich structured JSON objects and legacy single-string fallbacks.
class ReadingCalendarEntry {
  final DateTime date;
  final List<CalendarBookEntry> entries;

  ReadingCalendarEntry({
    required this.date,
    required this.entries,
  });

  /// Normalized date key: YYYY-MM-DD
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'date': dateKey,
      'entries': entries.map((e) => e.toMap()).toList(),
    };
  }

  String toJson() => jsonEncode(toMap());

  /// Encodes entries into a JSON string suitable for storage
  String encodeEntries() => CalendarBookEntry.encodeList(entries);

  factory ReadingCalendarEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawEntries = map['entries'] ?? map['books'] ?? map['entryNotes'] ?? map['bookTitle'];
    return ReadingCalendarEntry(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      entries: CalendarBookEntry.parseEntries(rawEntries),
    );
  }

  factory ReadingCalendarEntry.fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return ReadingCalendarEntry.fromMap(decoded);
      } else if (decoded is Map) {
        return ReadingCalendarEntry.fromMap(Map<String, dynamic>.from(decoded));
      } else if (decoded is List) {
        return ReadingCalendarEntry(
          date: DateTime.now(),
          entries: CalendarBookEntry.parseEntries(decoded),
        );
      }
    } catch (_) {}
    return ReadingCalendarEntry(
      date: DateTime.now(),
      entries: CalendarBookEntry.parseEntries(source),
    );
  }

  ReadingCalendarEntry copyWith({
    DateTime? date,
    List<CalendarBookEntry>? entries,
  }) {
    return ReadingCalendarEntry(
      date: date ?? this.date,
      entries: entries ?? this.entries,
    );
  }
}
