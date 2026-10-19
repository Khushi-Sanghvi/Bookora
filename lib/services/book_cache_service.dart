import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'book_search_service.dart';

class _CachedSearchResults {
  final List<BookSearchResult> results;
  final DateTime timestamp;

  const _CachedSearchResults(this.results, this.timestamp);

  bool get isExpired =>
      DateTime.now().difference(timestamp) > BookCacheService._memoryTtl;
}

class BookCacheService {
  static const String _searchCacheDirName = 'search_results_cache_v4';
  static const String _synopsisCacheDirName = 'synopsis_cache';
  static const int _maxMemoryLruItems = 20;
  static const Duration _memoryTtl = Duration(minutes: 15);
  static const Duration _diskTtl = Duration(hours: 2);

  // 20-item in-memory bounded LRU cache with 15-minute TTL
  static final LinkedHashMap<String, _CachedSearchResults> _memorySearchCache =
      LinkedHashMap<String, _CachedSearchResults>();

  static const int _maxSynopsisLruItems = 50;
  static final LinkedHashMap<String, String> _synopsisMemoryCache =
      LinkedHashMap<String, String>();

  static Future<Directory> _getSearchCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, _searchCacheDirName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static String _getSearchCacheFilePath(Directory cacheDir, String key) {
    final normalized = key.toLowerCase().trim();
    int hash = 0;
    for (int i = 0; i < normalized.length; i++) {
      hash = (hash * 31 + normalized.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final hashHex = hash.toRadixString(16).padLeft(8, '0');
    return p.join(cacheDir.path, 'cache_$hashHex.json');
  }

  /// Memory LRU lookup (< 0.01ms) with 15-min TTL validation
  static List<BookSearchResult>? getMemoryCachedSearchResults(String query) {
    final key = query.toLowerCase().trim();
    if (!_memorySearchCache.containsKey(key)) return null;
    final entry = _memorySearchCache.remove(key)!;
    if (entry.isExpired) return null;
    _memorySearchCache[key] = entry; // Refresh to MRU position
    return entry.results;
  }

  /// Saves search results into the in-memory 20-item bounded LRU cache
  static void saveMemorySearchResults(
    String query,
    List<BookSearchResult> results,
  ) {
    final key = query.toLowerCase().trim();
    _memorySearchCache.remove(key);
    if (_memorySearchCache.length >= _maxMemoryLruItems) {
      _memorySearchCache.remove(_memorySearchCache.keys.first); // Evict LRU
    }
    _memorySearchCache[key] = _CachedSearchResults(results, DateTime.now());
  }

  /// Attempts to load search results from local storage cache with 2-hour TTL
  /// and relevance validation check.
  static Future<List<BookSearchResult>?> getCachedSearchResults(
    String query, {
    bool Function(String query, BookSearchResult item)? relevanceValidator,
  }) async {
    // 1. Check in-memory bounded LRU cache first
    final memoryHit = getMemoryCachedSearchResults(query);
    if (memoryHit != null && memoryHit.isNotEmpty) {
      if (relevanceValidator != null) {
        final validMem =
            memoryHit.where((r) => relevanceValidator(query, r)).toList();
        if (validMem.isNotEmpty) return validMem;
      } else {
        return memoryHit;
      }
    }

    // 2. Check versioned disk storage cache
    try {
      final cacheDir = await _getSearchCacheDir();
      final file = File(_getSearchCacheFilePath(cacheDir, query));
      if (await file.exists()) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);

        // Enforce 2-hour disk TTL
        if (age > _diskTtl) {
          debugPrint('Expiring disk search cache for "$query" (age: ${age.inMinutes}m > 120m)');
          try {
            await file.delete();
          } catch (_) {}
          return null;
        }

        final jsonString = await file.readAsString();
        final list = jsonDecode(jsonString) as List?;
        if (list != null && list.isNotEmpty) {
          final results = list
              .map(
                (item) =>
                    BookSearchResult.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          // Enforce relevance validation
          if (relevanceValidator != null) {
            final validResults =
                results.where((r) => relevanceValidator(query, r)).toList();
            if (validResults.isEmpty) {
              debugPrint('Discarding cached search file for "$query" due to relevance validation failure.');
              try {
                await file.delete();
              } catch (_) {}
              return null;
            }
            saveMemorySearchResults(query, validResults);
            return validResults;
          }

          saveMemorySearchResults(query, results);
          return results;
        }
      }
    } catch (e) {
      debugPrint('Error reading search cache for $query: $e');
    }
    return null;
  }

  /// Saves search results to local storage cache & in-memory LRU cache
  static Future<void> saveSearchResultsToCache(
    String query,
    List<BookSearchResult> results,
  ) async {
    try {
      if (results.isEmpty) return;
      saveMemorySearchResults(query, results);
      final cacheDir = await _getSearchCacheDir();
      final file = File(_getSearchCacheFilePath(cacheDir, query));
      final jsonList = results.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving search cache for $query: $e');
    }
  }

  // --- Synopsis Cache Methods ---

  static Future<Directory> _getSynopsisCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, _synopsisCacheDirName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static String getSynopsisCacheKey(
    String title, [
    String? author,
    String? isbn,
  ]) {
    final cleanT = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .trim();
    final cleanA = (author != null &&
            author.isNotEmpty &&
            author != 'Unknown Author')
        ? author.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').trim()
        : '';
    final cleanI = (isbn != null && isbn.isNotEmpty)
        ? isbn.replaceAll(RegExp(r'[^0-9X]'), '')
        : '';
    if (cleanI.isNotEmpty) {
      return 'isbn_$cleanI';
    }
    if (cleanA.isNotEmpty) {
      return 't_${cleanT}_a_$cleanA';
    }
    return 't_$cleanT';
  }

  /// Instant memory lookup (< 0.01ms) for previously fetched synopses with MRU promotion
  static String? peekCachedSynopsis(String key) {
    if (!_synopsisMemoryCache.containsKey(key)) return null;
    final text = _synopsisMemoryCache.remove(key)!;
    _synopsisMemoryCache[key] = text; // Promotes to MRU position
    return text;
  }

  /// Loads cached synopsis from memory or persistent disk cache (< 1ms)
  static Future<String?> getCachedSynopsis(String key) async {
    if (_synopsisMemoryCache.containsKey(key)) {
      final text = _synopsisMemoryCache.remove(key)!;
      _synopsisMemoryCache[key] = text; // Promotes to MRU position
      return text;
    }
    try {
      final cacheDir = await _getSynopsisCacheDir();
      final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final file = File(p.join(cacheDir.path, '$sanitizedKey.txt'));
      if (await file.exists()) {
        final text = await file.readAsString();
        if (text.trim().isNotEmpty) {
          final cleanText = text.trim();
          _synopsisMemoryCache.remove(key);
          if (_synopsisMemoryCache.length >= _maxSynopsisLruItems) {
            _synopsisMemoryCache.remove(_synopsisMemoryCache.keys.first); // Evict LRU
          }
          _synopsisMemoryCache[key] = cleanText;
          return cleanText;
        }
      }
    } catch (e) {
      debugPrint('Error reading synopsis cache for $key: $e');
    }
    return null;
  }

  /// Saves a fetched synopsis to both memory and persistent disk cache
  static Future<void> saveCachedSynopsis(String key, String synopsis) async {
    final clean = synopsis.trim();
    if (clean.isEmpty) return;
    _synopsisMemoryCache.remove(key);
    if (_synopsisMemoryCache.length >= _maxSynopsisLruItems) {
      _synopsisMemoryCache.remove(_synopsisMemoryCache.keys.first); // Evict LRU
    }
    _synopsisMemoryCache[key] = clean;
    try {
      final cacheDir = await _getSynopsisCacheDir();
      final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final file = File(p.join(cacheDir.path, '$sanitizedKey.txt'));
      await file.writeAsString(clean);
    } catch (e) {
      debugPrint('Error saving synopsis cache for $key: $e');
    }
  }

  /// Clears in-memory search and synopsis caches
  static void clearMemoryCache() {
    _memorySearchCache.clear();
    _synopsisMemoryCache.clear();
  }

  /// Clears all search result caches (memory + current disk + legacy versions)
  static Future<void> clearSearchCache() async {
    _memorySearchCache.clear();
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final legacyDirNames = [
        _searchCacheDirName,
        'search_results_cache',
        'search_results_cache_v2',
        'search_results_cache_v3',
      ];
      for (final dirName in legacyDirNames) {
        final dir = Directory(p.join(appDir.path, dirName));
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error clearing search cache: $e');
    }
  }

  /// Legacy compatibility wrapper
  static Future<void> clearAllSearchCaches() async {
    await clearSearchCache();
  }

  /// Clears all synopsis caches
  static Future<void> clearAllSynopsisCaches() async {
    _synopsisMemoryCache.clear();
    try {
      final cacheDir = await _getSynopsisCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing synopsis caches: $e');
    }
  }
}
