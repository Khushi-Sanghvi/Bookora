import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_cover_resolver.dart';

/// Intelligent color extractor that samples the dominant accent/signature
/// color from book cover images, with caching and theme-adaptive contrast.
class BookCoverColorExtractor {
  static final Map<String, Color> _colorCache = {};
  static final Set<String> _pendingUrls = {};

  // Rich Dark-Academia / Bookish Fallback Palette
  static const List<Color> _fallbackPalette = [
    Color(0xFFE07A38), // Terracotta Amber
    Color(0xFFAB47BC), // Amethyst Violet
    Color(0xFF26A69A), // Jade Teal
    Color(0xFFEC407A), // Rose Coral
    Color(0xFF3B82F6), // Cerulean Blue
    Color(0xFFF59E0B), // Warm Sun Amber
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Crimson
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFD97706), // Antique Bronze
  ];

  /// Returns the cached color for a book cover if available,
  /// or returns a deterministic color and triggers background extraction.
  static Color getColorForBook({
    required String coverUrl,
    required String title,
    String author = '',
    Color? preferredColor,
    bool isDark = true,
    VoidCallback? onExtracted,
  }) {
    final cacheKey = _getCacheKey(coverUrl, title, author);

    if (_colorCache.containsKey(cacheKey)) {
      final baseColor = _colorCache[cacheKey]!;
      return adaptColorForTheme(baseColor, isDark);
    }

    // Trigger asynchronous extraction if not already pending
    if (coverUrl.trim().isNotEmpty && !_pendingUrls.contains(cacheKey)) {
      _extractColorAsync(
        coverUrl: coverUrl.trim(),
        title: title,
        author: author,
        cacheKey: cacheKey,
        onExtracted: onExtracted,
      );
    }

    // Fallback while loading
    if (preferredColor != null &&
        preferredColor != Colors.transparent &&
        preferredColor.toARGB32() != 0) {
      return adaptColorForTheme(preferredColor, isDark);
    }

    final deterministic = getDeterministicColor(title, author);
    return adaptColorForTheme(deterministic, isDark);
  }

  /// Synchronously returns whether the color for this cover is already cached.
  static bool hasCachedColor(String coverUrl, String title, String author) {
    return _colorCache.containsKey(_getCacheKey(coverUrl, title, author));
  }

  /// Manually cache an extracted color (useful for testing or direct bindings).
  static void cacheColor(String coverUrl, String title, String author, Color color) {
    _colorCache[_getCacheKey(coverUrl, title, author)] = color;
  }

  /// Generates a stable deterministic color from book title and author.
  static Color getDeterministicColor(String title, [String author = '']) {
    final combined = '$title $author'.trim();
    final hash = combined.isEmpty ? 0 : combined.hashCode.abs();
    return _fallbackPalette[hash % _fallbackPalette.length];
  }

  /// Adjusts lightness and saturation of [color] for optimal visibility and
  /// harmony against dark or light calendar backgrounds.
  static Color adaptColorForTheme(Color color, bool isDark) {
    final hsl = HSLColor.fromColor(color);

    // Ensure adequate saturation so the string looks vibrant and lively
    final double targetSaturation = hsl.saturation < 0.35 ? 0.55 : hsl.saturation;

    double targetLightness = hsl.lightness;
    if (isDark) {
      // In dark mode: ensure it's not too dark (minimum 0.50 for high readability)
      if (targetLightness < 0.50) {
        targetLightness = 0.56;
      } else if (targetLightness > 0.85) {
        targetLightness = 0.78;
      }
    } else {
      // In light mode: ensure it's not too bright (maximum 0.48 for crisp contrast)
      if (targetLightness > 0.52) {
        targetLightness = 0.42;
      } else if (targetLightness < 0.18) {
        targetLightness = 0.28;
      }
    }

    return hsl
        .withSaturation(targetSaturation.clamp(0.0, 1.0))
        .withLightness(targetLightness.clamp(0.0, 1.0))
        .toColor();
  }

  static String _getCacheKey(String coverUrl, String title, String author) {
    if (coverUrl.trim().isNotEmpty) return coverUrl.trim();
    return '${title.trim()}_${author.trim()}';
  }

  static void _extractColorAsync({
    required String coverUrl,
    required String title,
    required String author,
    required String cacheKey,
    VoidCallback? onExtracted,
  }) {
    _pendingUrls.add(cacheKey);

    try {
      ImageProvider? provider;

      if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
        final cleanUrl = BookCoverResolver.sanitizeAndUpgradeUrl(coverUrl);
        provider = CachedNetworkImageProvider(cleanUrl);
      } else {
        final file = File(coverUrl);
        if (file.existsSync()) {
          provider = FileImage(file);
        }
      }

      if (provider == null) {
        _pendingUrls.remove(cacheKey);
        return;
      }

      // Resize down to 24x36 for instant, lightweight color sampling
      final resizeProvider = ResizeImage(
        provider,
        width: 24,
        height: 36,
        policy: ResizeImagePolicy.exact,
      );

      final ImageStream stream = resizeProvider.resolve(const ImageConfiguration());
      late final ImageStreamListener listener;

      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) async {
          stream.removeListener(listener);
          _pendingUrls.remove(cacheKey);

          try {
            final ui.Image image = info.image;
            final ByteData? byteData = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );

            if (byteData != null) {
              final extracted = _sampleDominantAccent(byteData, image.width, image.height);
              if (extracted != null) {
                _colorCache[cacheKey] = extracted;
                onExtracted?.call();
              }
            }
          } catch (_) {
            // Safe fallback
          }
        },
        onError: (exception, stackTrace) {
          stream.removeListener(listener);
          _pendingUrls.remove(cacheKey);
        },
      );

      stream.addListener(listener);
    } catch (_) {
      _pendingUrls.remove(cacheKey);
    }
  }

  /// Samples the most representative, vibrant accent color from the pixel data.
  static Color? _sampleDominantAccent(ByteData byteData, int width, int height) {
    final totalPixels = width * height;
    if (totalPixels == 0) return null;

    // 12 Hue bins (each covering 30 degrees of color spectrum)
    final List<double> binWeights = List.filled(12, 0.0);
    final List<double> binRedSum = List.filled(12, 0.0);
    final List<double> binGreenSum = List.filled(12, 0.0);
    final List<double> binBlueSum = List.filled(12, 0.0);

    double fallbackR = 0, fallbackG = 0, fallbackB = 0;
    int fallbackCount = 0;

    for (int i = 0; i < totalPixels; i++) {
      final offset = i * 4;
      if (offset + 3 >= byteData.lengthInBytes) break;

      final r = byteData.getUint8(offset);
      final g = byteData.getUint8(offset + 1);
      final b = byteData.getUint8(offset + 2);
      final a = byteData.getUint8(offset + 3);

      if (a < 120) continue; // Skip transparent pixels

      final color = Color.fromARGB(a, r, g, b);
      final hsl = HSLColor.fromColor(color);

      // Keep track of average non-background color as fallback
      if (hsl.lightness > 0.08 && hsl.lightness < 0.92) {
        fallbackR += r;
        fallbackG += g;
        fallbackB += b;
        fallbackCount++;
      }

      // Prioritize colorful, saturated accents (e.g. title text, artwork focal points)
      if (hsl.saturation >= 0.18 && hsl.lightness >= 0.12 && hsl.lightness <= 0.88) {
        final bin = (hsl.hue / 30.0).floor() % 12;
        // Weight by saturation and balance around medium lightness
        final weight = hsl.saturation * (1.0 - (hsl.lightness - 0.5).abs() * 0.8);

        binWeights[bin] += weight;
        binRedSum[bin] += r * weight;
        binGreenSum[bin] += g * weight;
        binBlueSum[bin] += b * weight;
      }
    }

    // Find the hue bin with the highest accumulated accent weight
    int bestBin = -1;
    double maxWeight = 0;

    for (int b = 0; b < 12; b++) {
      if (binWeights[b] > maxWeight) {
        maxWeight = binWeights[b];
        bestBin = b;
      }
    }

    if (bestBin != -1 && maxWeight > 0.5) {
      final avgR = (binRedSum[bestBin] / binWeights[bestBin]).round().clamp(0, 255);
      final avgG = (binGreenSum[bestBin] / binWeights[bestBin]).round().clamp(0, 255);
      final avgB = (binBlueSum[bestBin] / binWeights[bestBin]).round().clamp(0, 255);
      return Color.fromARGB(255, avgR, avgG, avgB);
    }

    // If monochrome/low saturation, use average non-extreme color
    if (fallbackCount > 0) {
      final avgR = (fallbackR / fallbackCount).round().clamp(0, 255);
      final avgG = (fallbackG / fallbackCount).round().clamp(0, 255);
      final avgB = (fallbackB / fallbackCount).round().clamp(0, 255);
      return Color.fromARGB(255, avgR, avgG, avgB);
    }

    return null;
  }
}
