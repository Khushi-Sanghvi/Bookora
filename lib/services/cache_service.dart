import 'dart:collection';
import '../models/book.dart';

class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Production-ready bounded LRU (Least Recently Used) cache with TTL expiration.
/// Uses LinkedHashMap to achieve O(1) access, MRU promotion, and LRU eviction.
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService({int maxCapacity = 100}) {
    if (maxCapacity > 0) {
      _instance._maxCapacity = maxCapacity;
    }
    return _instance;
  }
  CacheService._internal();

  int _maxCapacity = 100;
  int get maxCapacity => _maxCapacity;
  set maxCapacity(int capacity) {
    if (capacity < 1) return;
    _maxCapacity = capacity;
    _evictToCapacity();
  }

  final LinkedHashMap<String, CacheEntry<dynamic>> _cache =
      LinkedHashMap<String, CacheEntry<dynamic>>();

  final Duration defaultTTL = const Duration(hours: 2);

  /// Current number of entries stored in memory.
  int get length => _cache.length;

  /// Checks if key is cached and unexpired.
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Sets key-value pair in cache with optional TTL.
  /// Bounded LRU: evicts least recently used entry if maxCapacity is reached.
  void set<T>(String key, T value, {Duration? ttl}) {
    // If key already present, remove it first so re-insertion places it at the MRU end
    _cache.remove(key);

    // Evict least recently used entries if at capacity
    _evictToCapacity(targetLength: _maxCapacity - 1);

    _cache[key] = CacheEntry<dynamic>(
      data: value,
      expiry: DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// Retrieves cached value by key with O(1) MRU promotion.
  /// Returns null if missing or expired.
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final entry = _cache.remove(key);
    if (entry == null) return null;

    if (entry.isExpired) {
      return null;
    }

    // Promote to end (Most Recently Used)
    _cache[key] = entry;

    if (entry.data is T) {
      return entry.data as T;
    }
    try {
      return entry.data as T;
    } catch (_) {
      return null;
    }
  }

  /// Removes entry from cache by key.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Invalidate alias for remove.
  void invalidate(String key) => remove(key);

  void _evictToCapacity({int? targetLength}) {
    final target = targetLength ?? _maxCapacity;
    while (_cache.length > target && _cache.isNotEmpty) {
      _cache.remove(_cache.keys.first); // O(1) FIFO removal of least recently used
    }
  }

  // --- Dedicated Local Persistent Memory Cache Helpers ---
  void cacheBook(Book book, {Duration? ttl}) {
    set('book_${book.id}', book.toMap(), ttl: ttl ?? const Duration(days: 7));
  }

  Book? getCachedBook(String bookId) {
    final map = get<Map<String, dynamic>>('book_$bookId');
    if (map != null) {
      try {
        return Book.fromMap(map);
      } catch (_) {
        remove('book_$bookId');
        return null;
      }
    }
    return null;
  }

  void removeBook(String bookId) {
    remove('book_$bookId');
  }

  void clear() {
    _cache.clear();
  }
}

