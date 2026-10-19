import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_book_entry.dart';

/// Single source of truth repository for date-level multi-book tracking.
abstract class ReadingCalendarRepository {
  Future<List<CalendarBookEntry>> getBookEntriesForDate(DateTime date);
  List<CalendarBookEntry> getBookEntriesForDateSync(DateTime date);
  Future<void> addBookEntryToDate(DateTime date, CalendarBookEntry entry);
  Future<void> updateBookEntry(
    DateTime date,
    String entryId,
    CalendarBookEntry updatedEntry,
  );
  Future<void> removeBookEntry(DateTime date, String entryId);
  Future<Map<String, List<CalendarBookEntry>>> getAllCalendarEntries();

  /// Normalized YYYY-MM-DD date key
  static String normalizeDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Concrete implementation with memory caching and SharedPreferences persistence.
class ReadingCalendarRepositoryImpl implements ReadingCalendarRepository {
  static const String _prefsKeyPrefix = 'reading_calendar_entries_v1_';
  static final Map<String, List<CalendarBookEntry>> _memoryCache = {};

  final SharedPreferences? _prefs;

  ReadingCalendarRepositoryImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _prefs;
    if (prefs != null) return prefs;
    return await SharedPreferences.getInstance();
  }

  @override
  List<CalendarBookEntry> getBookEntriesForDateSync(DateTime date) {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    return List<CalendarBookEntry>.unmodifiable(_memoryCache[key] ?? []);
  }

  @override
  Future<List<CalendarBookEntry>> getBookEntriesForDate(DateTime date) async {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    if (_memoryCache.containsKey(key)) {
      return List<CalendarBookEntry>.unmodifiable(_memoryCache[key]!);
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString('$_prefsKeyPrefix$key');
    if (raw == null || raw.isEmpty) {
      _memoryCache[key] = [];
      return [];
    }

    final entries = CalendarBookEntry.parseEntries(raw);
    _memoryCache[key] = entries;
    return List<CalendarBookEntry>.unmodifiable(entries);
  }

  @override
  Future<void> addBookEntryToDate(DateTime date, CalendarBookEntry entry) async {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final currentEntries = List<CalendarBookEntry>.from(
      await getBookEntriesForDate(date),
    );

    // Automatic deduplication: check for same id or identical book title
    final existingIndex = currentEntries.indexWhere(
      (e) =>
          e.id == entry.id ||
          (e.bookTitle.trim().toLowerCase() ==
                  entry.bookTitle.trim().toLowerCase() &&
              e.readingStatusTag.trim().toLowerCase() ==
                  entry.readingStatusTag.trim().toLowerCase()),
    );

    if (existingIndex >= 0) {
      currentEntries[existingIndex] = entry;
    } else {
      currentEntries.add(entry);
    }

    _memoryCache[key] = currentEntries;
    final prefs = await _getPrefs();
    await prefs.setString(
      '$_prefsKeyPrefix$key',
      CalendarBookEntry.encodeList(currentEntries),
    );
  }

  @override
  Future<void> updateBookEntry(
    DateTime date,
    String entryId,
    CalendarBookEntry updatedEntry,
  ) async {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final currentEntries = List<CalendarBookEntry>.from(
      await getBookEntriesForDate(date),
    );

    final index = currentEntries.indexWhere((e) => e.id == entryId);
    if (index >= 0) {
      currentEntries[index] = updatedEntry;
      _memoryCache[key] = currentEntries;
      final prefs = await _getPrefs();
      await prefs.setString(
        '$_prefsKeyPrefix$key',
        CalendarBookEntry.encodeList(currentEntries),
      );
    }
  }

  @override
  Future<void> removeBookEntry(DateTime date, String entryId) async {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final currentEntries = List<CalendarBookEntry>.from(
      await getBookEntriesForDate(date),
    );

    currentEntries.removeWhere((e) => e.id == entryId);
    _memoryCache[key] = currentEntries;

    final prefs = await _getPrefs();
    await prefs.setString(
      '$_prefsKeyPrefix$key',
      CalendarBookEntry.encodeList(currentEntries),
    );
  }

  @override
  Future<Map<String, List<CalendarBookEntry>>> getAllCalendarEntries() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));

    for (final fullKey in keys) {
      final dateKey = fullKey.substring(_prefsKeyPrefix.length);
      if (!_memoryCache.containsKey(dateKey)) {
        final raw = prefs.getString(fullKey);
        if (raw != null && raw.isNotEmpty) {
          _memoryCache[dateKey] = CalendarBookEntry.parseEntries(raw);
        }
      }
    }

    return Map<String, List<CalendarBookEntry>>.unmodifiable(_memoryCache);
  }
}

/// Global repository provider
final readingCalendarRepositoryProvider =
    Provider<ReadingCalendarRepository>((ref) {
  return ReadingCalendarRepositoryImpl();
});

/// StateNotifier managing calendar entries reactively
class ReadingCalendarNotifier
    extends StateNotifier<Map<String, List<CalendarBookEntry>>> {
  final ReadingCalendarRepository _repository;

  ReadingCalendarNotifier(this._repository) : super({}) {
    loadAll();
  }

  Future<void> loadAll() async {
    final all = await _repository.getAllCalendarEntries();
    state = Map<String, List<CalendarBookEntry>>.from(all);
  }

  List<CalendarBookEntry> getBookEntriesForDate(DateTime date) {
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    return state[key] ?? _repository.getBookEntriesForDateSync(date);
  }

  Future<void> addBookEntryToDate(DateTime date, CalendarBookEntry entry) async {
    await _repository.addBookEntryToDate(date, entry);
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final updated = await _repository.getBookEntriesForDate(date);
    state = {
      ...state,
      key: updated,
    };
  }

  Future<void> updateBookEntry(
    DateTime date,
    String entryId,
    CalendarBookEntry updatedEntry,
  ) async {
    await _repository.updateBookEntry(date, entryId, updatedEntry);
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final updated = await _repository.getBookEntriesForDate(date);
    state = {
      ...state,
      key: updated,
    };
  }

  Future<void> removeBookEntry(DateTime date, String entryId) async {
    await _repository.removeBookEntry(date, entryId);
    final key = ReadingCalendarRepository.normalizeDateKey(date);
    final updated = await _repository.getBookEntriesForDate(date);
    state = {
      ...state,
      key: updated,
    };
  }
}

/// Reactive StateNotifierProvider for ReadingCalendar
final readingCalendarNotifierProvider = StateNotifierProvider<
    ReadingCalendarNotifier, Map<String, List<CalendarBookEntry>>>((ref) {
  final repo = ref.watch(readingCalendarRepositoryProvider);
  return ReadingCalendarNotifier(repo);
});

/// Convenience family provider watching entries for a specific date
final calendarBookEntriesForDateProvider =
    Provider.family<List<CalendarBookEntry>, DateTime>((ref, date) {
  final allEntries = ref.watch(readingCalendarNotifierProvider);
  final key = ReadingCalendarRepository.normalizeDateKey(date);
  return allEntries[key] ?? [];
});
