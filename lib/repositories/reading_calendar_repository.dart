import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_calendar_entry.dart';

abstract class ReadingCalendarRepository {
  Future<void> addBookStringToDate(DateTime date, String bookEntry);
  Future<void> removeBookStringFromDate(DateTime date, String bookEntry);
  Future<List<String>> getBookStringsForDate(DateTime date);
  Future<Map<DateTime, List<String>>> getAllDateBookStrings();
  Future<void> clearDate(DateTime date);
}

class ReadingCalendarRepositoryImpl implements ReadingCalendarRepository {
  static const String _prefix = 'calendar_books_';
  final SharedPreferences? _prefs;

  ReadingCalendarRepositoryImpl([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  static String _keyForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final monthStr = d.month.toString().padLeft(2, '0');
    final dayStr = d.day.toString().padLeft(2, '0');
    return '$_prefix${d.year}_${monthStr}_$dayStr';
  }

  static DateTime _dateFromKey(String key) {
    final stripped = key.replaceFirst(_prefix, '');
    final parts = stripped.split('_');
    if (parts.length >= 3) {
      final y = int.tryParse(parts[0]) ?? 2026;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.now();
  }

  @override
  Future<List<String>> getBookStringsForDate(DateTime date) async {
    final prefs = await _getPrefs();
    final key = _keyForDate(date);
    final raw = prefs.getString(key);
    return ReadingCalendarEntry.parseBookStrings(raw);
  }

  @override
  Future<void> addBookStringToDate(DateTime date, String bookEntry) async {
    final cleanEntry = bookEntry.trim();
    if (cleanEntry.isEmpty) return;

    final existing = await getBookStringsForDate(date);
    // Deduplication check
    if (existing.any((e) => e.toLowerCase() == cleanEntry.toLowerCase())) {
      return;
    }

    final updated = [...existing, cleanEntry];
    final prefs = await _getPrefs();
    await prefs.setString(_keyForDate(date), jsonEncode(updated));
  }

  @override
  Future<void> removeBookStringFromDate(DateTime date, String bookEntry) async {
    final cleanEntry = bookEntry.trim().toLowerCase();
    final existing = await getBookStringsForDate(date);
    final updated = existing.where((e) => e.trim().toLowerCase() != cleanEntry).toList();

    final prefs = await _getPrefs();
    final key = _keyForDate(date);
    if (updated.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(updated));
    }
  }

  @override
  Future<Map<DateTime, List<String>>> getAllDateBookStrings() async {
    final prefs = await _getPrefs();
    final map = <DateTime, List<String>>{};
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      final raw = prefs.getString(key);
      final list = ReadingCalendarEntry.parseBookStrings(raw);
      if (list.isNotEmpty) {
        map[_dateFromKey(key)] = list;
      }
    }
    return map;
  }

  @override
  Future<void> clearDate(DateTime date) async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyForDate(date));
  }
}

final readingCalendarRepositoryProvider = Provider<ReadingCalendarRepository>((ref) {
  return ReadingCalendarRepositoryImpl();
});
