import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookCoverResolver {
  static final Map<String, String> _memoryUrlCache = {};

  /// Sanitizes, upgrades, and forces HTTPS on raw API image URLs
  static String sanitizeAndUpgradeUrl(String url) {
    if (url.trim().isEmpty) return '';

    String clean = url.trim();

    // 1. Force HTTPS cleartext traffic compliance for Android/iOS
    if (clean.startsWith('http:')) {
      clean = clean.replaceFirst('http:', 'https:');
    }

    // 2. Strip breaking Google Books image edge parameters
    clean = clean
        .replaceAll('&edge=curl', '')
        .replaceAll('&edge=curl&', '')
        .replaceAll('&edge=curl', '');

    // 3. Upgrade Google Books low-res zoom parameters to high-definition (zoom=2 or zoom=3)
    if (clean.contains('books.google.com')) {
      clean = clean
          .replaceAll('zoom=1', 'zoom=2')
          .replaceAll('zoom=5', 'zoom=2')
          .replaceAll('zoom=0', 'zoom=2');
    }

    // 4. Upgrade Open Library thumbnail sizes (-S.jpg / -M.jpg -> -L.jpg) and force default=false
    if (clean.contains('covers.openlibrary.org')) {
      clean = clean
          .replaceAll('-S.jpg', '-L.jpg')
          .replaceAll('-M.jpg', '-L.jpg');
      if (!clean.contains('default=false')) {
        clean = clean.contains('?') ? '$clean&default=false' : '$clean?default=false';
      }
    }

    return clean;
  }

  /// Generates a bulletproof fallback chain with Google Books content thumbnails prioritized first
  static List<String> getCandidateCoverUrls({
    String? primaryUrl,
    String? coverId,
    String? title,
    String? author,
  }) {
    final List<String> candidates = [];

    // 1. Primary Sanitized URL (if valid)
    if (primaryUrl != null &&
        primaryUrl.trim().isNotEmpty &&
        primaryUrl.startsWith('http')) {
      final cleanPrimary = sanitizeAndUpgradeUrl(primaryUrl);
      if (cleanPrimary.isNotEmpty) {
        candidates.add(cleanPrimary);
      }
    }

    // 2. Open Library Covers by Cover ID
    if (coverId != null && coverId.trim().isNotEmpty) {
      candidates.add(
        'https://covers.openlibrary.org/b/id/$coverId-L.jpg?default=false',
      );
    }

    // 3. Google Books Title & Author Search Thumbnail Fallback
    if (title != null && title.trim().isNotEmpty) {
      final cleanTitle = title.trim();
      final cleanAuthor = (author != null &&
              author.trim().isNotEmpty &&
              author != 'Unknown Author')
          ? author.trim()
          : '';

      if (cleanAuthor.isNotEmpty) {
        final queryCombined = Uri.encodeComponent('$cleanTitle $cleanAuthor');
        candidates.add(
          'https://books.google.com/books/content?q=$queryCombined&printsec=frontcover&img=1&zoom=2',
        );
      }

      final encodedTitle = Uri.encodeComponent(cleanTitle);
      candidates.add(
        'https://books.google.com/books/content?q=$encodedTitle&printsec=frontcover&img=1&zoom=2',
      );
    }

    return candidates.toSet().toList(); // Deduplicate candidate list
  }

  /// Dynamically queries Google Books by title and author if primary URL is missing
  static Future<String?> resolveCoverUrl({
    required String title,
    String? author,
    String? primaryUrl,
  }) async {
    final cacheKey =
        '${title.trim().toLowerCase()}_${author?.trim().toLowerCase() ?? ''}';
    if (_memoryUrlCache.containsKey(cacheKey)) {
      return _memoryUrlCache[cacheKey];
    }

    if (primaryUrl != null &&
        primaryUrl.trim().isNotEmpty &&
        primaryUrl.startsWith('http')) {
      final sanitized = sanitizeAndUpgradeUrl(primaryUrl);
      _memoryUrlCache[cacheKey] = sanitized;
      return sanitized;
    }

    try {
      final query =
          'intitle:${Uri.encodeComponent(title)}${author != null && author.isNotEmpty && author != 'Unknown Author' ? '+inauthor:${Uri.encodeComponent(author)}' : ''}';
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=1',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'BetweenWorldBookApp/1.0'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> &&
            data['items'] is List &&
            (data['items'] as List).isNotEmpty) {
          final item = data['items'][0];
          if (item is Map<String, dynamic> &&
              item['volumeInfo'] is Map<String, dynamic>) {
            final info = item['volumeInfo'];
            final imageLinks = info['imageLinks'];
            if (imageLinks is Map<String, dynamic>) {
              final raw =
                  (imageLinks['extraLarge'] ??
                          imageLinks['large'] ??
                          imageLinks['medium'] ??
                          imageLinks['thumbnail'] ??
                          '')
                      .toString();
              if (raw.isNotEmpty) {
                final resolved = sanitizeAndUpgradeUrl(raw);
                _memoryUrlCache[cacheKey] = resolved;
                return resolved;
              }
            }
          }
        }
      }
    } catch (_) {}

    // Fallback Google Books search content thumbnail URL
    final fallbackUrl =
        'https://books.google.com/books/content?q=${Uri.encodeComponent(title)}&printsec=frontcover&img=1&zoom=2';
    _memoryUrlCache[cacheKey] = fallbackUrl;
    return fallbackUrl;
  }

  /// Renders an artisanal dark-academia fallback bookplate with deterministic gradient derived from title hash
  static Widget buildDarkAcademiaFallback({
    required String title,
    required String author,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    // Deterministic gradient color pair derived from title hash code
    final hash = title.hashCode.abs();
    final baseColors = [
      const Color(0xFF2C1E1A), // Rich leather brown
      const Color(0xFF1B1210), // Dark antique leather
      const Color(0xFF2A2030), // Deep plum leather
      const Color(0xFF16222A), // Midnight blue leather
      const Color(0xFF1F2E23), // Forest leather
    ];
    final color1 = baseColors[hash % baseColors.length];
    final color2 = const Color(0xFF0F0A09);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        border: Border.all(
          color: const Color(
            0xFFD4AF37,
          ).withValues(alpha: 0.4), // Antique gold border
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 20,
                    color: Color(0xFFD4AF37), // Gold book/quill icon
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.isNotEmpty ? title : 'Untitled',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4EEDC), // Parchment text color
                      height: 1.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: 1,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author.isNotEmpty ? author : 'Unknown Author',
                    style: const TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFE0D8C3),
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
