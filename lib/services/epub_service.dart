import 'dart:async';
import 'dart:io';
import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hybrid_chapter_engine.dart';

class EpubChapter {
  final String title;
  final String content;
  final List<String> imagePaths;
  final int pageOffset;
  final String? anchor;

  EpubChapter({
    required this.title,
    required this.content,
    this.imagePaths = const [],
    this.pageOffset = 0,
    this.anchor,
  });
}

class EpubBookData {
  final String title;
  final String author;
  final List<EpubChapter> chapters;
  final List<String> pages;
  final int actualTotalPages;
  final String? imagesDir;
  final Uint8List? coverBytes;
  final String? description;

  EpubBookData({
    required this.title,
    required this.author,
    required this.chapters,
    required this.pages,
    this.actualTotalPages = 0,
    this.imagesDir,
    this.coverBytes,
    this.description,
  });
}

class EpubService {
  /// Extracts the cover image as raw JPEG bytes without parsing the entire EPUB.
  static Future<Uint8List?> extractCoverBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      if (epubBook.CoverImage != null) {
        final jpgBytes = img.encodeJpg(epubBook.CoverImage!, quality: 85);
        return Uint8List.fromList(jpgBytes);
      }
    } catch (e) {
      debugPrint('Error extracting EPUB cover: $e');
    }
    return null;
  }

  /// Extracts embedded description/synopsis metadata directly from EPUB package metadata or blurb chapters.
  static Future<String?> extractEpubDescription(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      // 1. Check OPF package metadata description
      final desc = epubBook.Schema?.Package?.Metadata?.Description;
      if (desc != null && desc.trim().isNotEmpty) {
        final clean = desc.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
        if (clean.length > 20) return clean;
      }

      // 2. Check early chapters / spine for Blurb / Synopsis section
      final chapters = epubBook.Chapters ?? [];
      for (final ch in chapters.take(6)) {
        final title = (ch.Title ?? '').toLowerCase();
        if (title.contains('blurb') ||
            title.contains('synopsis') ||
            title.contains('description') ||
            title.contains('about the book') ||
            title.contains('summary')) {
          final text = (ch.HtmlContent ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .trim();
          if (text.length > 30) return text;
        }
      }

      // 3. Check HTML content files for blurb
      final htmlMap = epubBook.Content?.Html ?? {};
      for (final entry in htmlMap.entries.take(8)) {
        final key = entry.key.toLowerCase();
        if (key.contains('blurb') ||
            key.contains('synopsis') ||
            key.contains('description')) {
          final text = (entry.value.Content ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .trim();
          if (text.length > 30) return text;
        }
      }
    } catch (e) {
      debugPrint('Error extracting EPUB description: $e');
    }
    return null;
  }

  /// Parses the EPUB file in a background isolate for responsive UI.
  Future<EpubBookData?> parseEpub(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      String basePath;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        basePath = appDir.path;
      } catch (_) {
        basePath = Directory.systemTemp.path;
      }

      final sanitizedTitle = p
          .basenameWithoutExtension(filePath)
          .replaceAll(RegExp(r'[^\w\s\.-]'), '_')
          .trim();
      final imagesDir = p.join(basePath, 'epub_images', sanitizedTitle);

      return await compute(_parseEpubIsolate, {
        'filePath': filePath,
        'imagesDir': imagesDir,
      });
    } catch (e) {
      debugPrint('Error parsing EPUB: $e');
      return null;
    }
  }

  static Future<EpubBookData?> _parseEpubIsolate(Map<String, dynamic> args) async {
    final String filePath = args['filePath'] as String;
    final String imagesDir = args['imagesDir'] as String;

    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = file.readAsBytesSync();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      final title = (epubBook.Title != null && epubBook.Title!.trim().isNotEmpty)
          ? epubBook.Title!.trim()
          : p.basenameWithoutExtension(filePath);
      final author = (epubBook.Author != null && epubBook.Author!.trim().isNotEmpty)
          ? epubBook.Author!.trim()
          : 'Unknown Author';

      final dir = Directory(imagesDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Extract cover image
      List<int>? cover;
      if (epubBook.CoverImage != null) {
        try {
          cover = img.encodeJpg(epubBook.CoverImage!, quality: 90);
        } catch (_) {}
      }

      // Extract and save all images to disk
      final Set<String> savedPaths = {};
      final imageFutures = <Future>[];

      void saveImageData(String keyPath, List<int>? imgBytes) {
        if (imgBytes == null || imgBytes.isEmpty) return;
        final rawFileName = Uri.decodeFull(keyPath);
        final cleanFileName = rawFileName
            .replaceAll(RegExp(r'^[/\\]+'), '')
            .replaceAll('\\', '/');

        final imgFile = File(p.join(imagesDir, cleanFileName));
        if (!savedPaths.contains(imgFile.path)) {
          savedPaths.add(imgFile.path);
          if (!imgFile.parent.existsSync()) {
            imgFile.parent.createSync(recursive: true);
          }
          imageFutures.add(imgFile.writeAsBytes(imgBytes));
        }

        final baseName = p.basename(cleanFileName);
        if (baseName.isNotEmpty) {
          final baseFile = File(p.join(imagesDir, baseName));
          if (!savedPaths.contains(baseFile.path)) {
            savedPaths.add(baseFile.path);
            imageFutures.add(baseFile.writeAsBytes(imgBytes));
          }

          final decodedBase = Uri.decodeFull(baseName);
          if (decodedBase != baseName) {
            final decFile = File(p.join(imagesDir, decodedBase));
            if (!savedPaths.contains(decFile.path)) {
              savedPaths.add(decFile.path);
              imageFutures.add(decFile.writeAsBytes(imgBytes));
            }
          }
        }
      }

      if (epubBook.Content?.Images != null) {
        for (final imageEntry in epubBook.Content!.Images!.entries) {
          saveImageData(imageEntry.key, imageEntry.value.Content);
        }
      }

      if (epubBook.Content?.AllFiles != null) {
        const imgExts = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.bmp'];
        for (final entry in epubBook.Content!.AllFiles!.entries) {
          final ext = p.extension(entry.key).toLowerCase();
          if (imgExts.contains(ext)) {
            final f = entry.value;
            if (f is epubx.EpubByteContentFile && f.Content != null) {
              saveImageData(entry.key, f.Content);
            }
          }
        }
      }

      await Future.wait(imageFutures);

      if (cover != null && cover.isNotEmpty) {
        try {
          final coverFile = File(p.join(imagesDir, 'cover.jpg'));
          await coverFile.writeAsBytes(cover);
        } catch (_) {}
      }

      // Extract all CSS into a single string
      String combinedCss = '';
      if (epubBook.Content?.Css != null) {
        for (final cssFile in epubBook.Content!.Css!.values) {
          if (cssFile.Content != null) {
            combinedCss += '${cssFile.Content}\n';
          }
        }
      }

      final chapters = <EpubChapter>[];
      final pages = <String>[];
      final fileToPageIndex = <String, int>{};

      // 1. Load spine items into sequential reading pages
      final spineItems = epubBook.Schema?.Package?.Spine?.Items;
      final manifestItems = epubBook.Schema?.Package?.Manifest?.Items;
      final htmlMap = epubBook.Content?.Html ?? {};

      bool populatedFromSpine = false;
      if (spineItems != null && manifestItems != null && htmlMap.isNotEmpty) {
        final idToManifest = <String, epubx.EpubManifestItem>{};
        for (final item in manifestItems) {
          if (item.Id != null) idToManifest[item.Id!] = item;
        }

        for (final spine in spineItems) {
          final manifest = idToManifest[spine.IdRef];
          if (manifest == null || manifest.Href == null) continue;

          final rawHref = manifest.Href!;
          final href = Uri.decodeFull(rawHref);

          epubx.EpubTextContentFile? htmlFile = htmlMap[rawHref] ?? htmlMap[href];

          if (htmlFile == null) {
            final base = p.basename(href).toLowerCase();
            for (final entry in htmlMap.entries) {
              if (p.basename(Uri.decodeFull(entry.key)).toLowerCase() == base) {
                htmlFile = entry.value;
                break;
              }
            }
          }

          if (htmlFile != null && htmlFile.Content != null) {
            final rawHtml = htmlFile.Content ?? '';
            final cleanHtml = _prepareRichHtml(rawHtml, combinedCss);
            if (cleanHtml.trim().isEmpty) continue;

            final pageIdx = pages.length;
            pages.add(cleanHtml);

            final baseName = p.basename(href).toLowerCase();
            fileToPageIndex[baseName] = pageIdx;
            fileToPageIndex[href.toLowerCase()] = pageIdx;
            fileToPageIndex[rawHref.toLowerCase()] = pageIdx;
            populatedFromSpine = true;
          }
        }
      }

      // 2. Extract Table of Contents (Official Author TOC first, then Hybrid Discovery)
      final tocList = epubBook.Chapters ?? [];
      if (populatedFromSpine && pages.isNotEmpty && tocList.isNotEmpty) {
        // EPUB HAS AN OFFICIAL TABLE OF CONTENTS:
        // Use the author's Table of Contents entries directly.
        void processTocChapter(epubx.EpubChapter ch) {
          final title = (ch.Title ?? '').trim();
          if (title.isNotEmpty) {
            final rawFileName = ch.ContentFileName ?? '';
            final cleanFileName = rawFileName.split('#').first;
            final baseName = p.basename(cleanFileName).toLowerCase();
            final fullLower = cleanFileName.toLowerCase();

            int? targetPageIndex = fileToPageIndex[baseName] ?? fileToPageIndex[fullLower];
            if (targetPageIndex == null) {
              final decodedBase = p.basename(Uri.decodeFull(cleanFileName)).toLowerCase();
              targetPageIndex = fileToPageIndex[decodedBase];
            }

            if (targetPageIndex != null && targetPageIndex < pages.length) {
              final anchor = ch.Anchor ?? (rawFileName.contains('#') ? rawFileName.split('#').last : null);
              final contentHtml = pages[targetPageIndex];
              chapters.add(
                EpubChapter(
                  title: title,
                  content: contentHtml,
                  pageOffset: targetPageIndex,
                  anchor: anchor,
                  imagePaths: _extractImagesFromHtml(contentHtml, imagesDir),
                ),
              );
            }
          }

          if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
            for (final sub in ch.SubChapters!) {
              processTocChapter(sub);
            }
          }
        }

        for (final ch in tocList) {
          processTocChapter(ch);
        }
      } else {
        // Fallback 1: Discover chapters using HybridChapterEngine
        final hybridResult = HybridChapterEngine.discoverChapters(
          pages: pages,
          bookTitle: title,
          bookAuthor: author,
        );

        if (!hybridResult.hasCustomLayout && hybridResult.chapters.isNotEmpty) {
          for (final ch in hybridResult.chapters) {
            final contentHtml = pages[ch.pageOffset];
            chapters.add(
              EpubChapter(
                title: ch.title,
                content: contentHtml,
                pageOffset: ch.pageOffset,
                anchor: ch.anchor,
                imagePaths: _extractImagesFromHtml(contentHtml, imagesDir),
              ),
            );
          }
        } else if (populatedFromSpine && pages.isNotEmpty) {
          // Fallback 2: Extract headings <h1-3> from spine pages
          for (int i = 0; i < pages.length; i++) {
            final raw = pages[i];
            final hMatch = RegExp(
              r'<h[1-3]\b([^>]*)>([\s\S]*?)<\/h[1-3]>',
              caseSensitive: false,
            ).firstMatch(raw);

            String? heading;
            if (hMatch != null) {
              final rawText = hMatch
                  .group(2)!
                  .replaceAll(RegExp(r'<[^>]*>'), '')
                  .trim();
              if (rawText.isNotEmpty) {
                heading = rawText;
              }
            }

            if (heading != null && heading.isNotEmpty) {
              chapters.add(
                EpubChapter(
                  title: heading,
                  content: raw,
                  pageOffset: i,
                  imagePaths: _extractImagesFromHtml(raw, imagesDir),
                ),
              );
            } else if (i == 0) {
              chapters.add(
                EpubChapter(
                  title: 'Cover / Start',
                  content: raw,
                  pageOffset: 0,
                  imagePaths: _extractImagesFromHtml(raw, imagesDir),
                ),
              );
            }
          }
        } else if (epubBook.Chapters != null && epubBook.Chapters!.isNotEmpty) {
          final addedHashes = <int>{};
          void processChapterContent(epubx.EpubChapter ch) {
            final chapterTitle = (ch.Title ?? '').trim();
            final rawHtml = (ch.HtmlContent ?? '').trim();
            final cleanHtml = _prepareRichHtml(rawHtml, combinedCss);

            final hash = cleanHtml.hashCode;
            if (cleanHtml.trim().isNotEmpty && !addedHashes.contains(hash)) {
              addedHashes.add(hash);
              final startOffset = pages.length;
              pages.add(cleanHtml);
              chapters.add(
                EpubChapter(
                  title: chapterTitle.isNotEmpty
                      ? chapterTitle
                      : 'Chapter ${chapters.length + 1}',
                  content: cleanHtml,
                  pageOffset: startOffset,
                  imagePaths: _extractImagesFromHtml(cleanHtml, imagesDir),
                ),
              );
            }

            if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
              for (final sub in ch.SubChapters!) {
                processChapterContent(sub);
              }
            }
          }

          for (final ch in epubBook.Chapters!) {
            processChapterContent(ch);
          }
        }
      }

      if (pages.isEmpty) {
        pages.add('No content available for this book.');
      }

      if (chapters.isEmpty) {
        chapters.add(
          EpubChapter(title: 'Chapter 1', content: pages[0], pageOffset: 0),
        );
      }

      int totalChars = 0;
      for (final p in pages) {
        final textOnly = p.replaceAll(RegExp(r'<[^>]*>'), '');
        totalChars += textOnly.length;
      }
      final int calculatedTotalPages = (totalChars / 1500).ceil().clamp(1, 999999);

      String? description;
      final opfDesc = epubBook.Schema?.Package?.Metadata?.Description;
      if (opfDesc != null && opfDesc.trim().isNotEmpty) {
        final clean = opfDesc.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
        if (clean.length > 20) description = clean;
      }

      return EpubBookData(
        title: title,
        author: author,
        chapters: chapters,
        pages: pages,
        actualTotalPages: calculatedTotalPages,
        imagesDir: imagesDir,
        coverBytes: cover != null ? Uint8List.fromList(cover) : null,
        description: description,
      );
    } catch (e) {
      debugPrint('Error in _parseEpubIsolate: $e');
      return null;
    }
  }

  static List<String> _extractImagesFromHtml(String html, String imagesDir) {
    final List<String> result = [];
    final dir = Directory(imagesDir);
    if (!dir.existsSync()) return result;

    final Map<String, String> fileMap = {};
    try {
      final List<FileSystemEntity> allFiles = dir.listSync(recursive: true);
      for (final f in allFiles) {
        if (f is File) {
          final bName = p.basename(f.path).toLowerCase();
          fileMap[bName] = f.path;
          final decName = Uri.decodeFull(bName).toLowerCase();
          fileMap[decName] = f.path;
        }
      }
    } catch (_) {}

    final imgMatches = RegExp(
      r'''<(?:img|image|use)\b[^>]*?\b(?:src|href|xlink:href)\s*=\s*(["'])(.*?)\1''',
      caseSensitive: false,
    ).allMatches(html);

    for (final m in imgMatches) {
      final src = m.group(2);
      if (src != null && src.isNotEmpty) {
        final lowerSrc = src.trim().toLowerCase();
        if (lowerSrc.startsWith('http://') ||
            lowerSrc.startsWith('https://') ||
            lowerSrc.startsWith('data:') ||
            lowerSrc.startsWith('#')) {
          continue;
        }

        final decoded = Uri.decodeFull(src.split('?').first.split('#').first);
        final baseName = p.basename(decoded.replaceAll('\\', '/')).toLowerCase();
        final foundPath = fileMap[baseName] ?? fileMap[Uri.decodeFull(baseName).toLowerCase()];

        if (foundPath != null && !result.contains(foundPath)) {
          result.add(foundPath);
        }
      }
    }

    final urlMatches = RegExp(
      r'''url\s*\(\s*(["']?)([^"'`\)]+)\1\s*\)''',
      caseSensitive: false,
    ).allMatches(html);

    for (final m in urlMatches) {
      final src = m.group(2);
      if (src != null && src.isNotEmpty) {
        final lowerSrc = src.trim().toLowerCase();
        if (lowerSrc.startsWith('http://') ||
            lowerSrc.startsWith('https://') ||
            lowerSrc.startsWith('data:') ||
            lowerSrc.startsWith('#') ||
            lowerSrc.endsWith('.css') ||
            lowerSrc.endsWith('.ttf') ||
            lowerSrc.endsWith('.otf') ||
            lowerSrc.endsWith('.woff') ||
            lowerSrc.endsWith('.woff2')) {
          continue;
        }

        final decoded = Uri.decodeFull(src.split('?').first.split('#').first);
        final baseName = p.basename(decoded.replaceAll('\\', '/')).toLowerCase();
        final foundPath = fileMap[baseName] ?? fileMap[Uri.decodeFull(baseName).toLowerCase()];

        if (foundPath != null && !result.contains(foundPath)) {
          result.add(foundPath);
        }
      }
    }

    return result;
  }

  static String _prepareRichHtml(String html, [String combinedCss = '']) {
    var text = html;

    final headStyles = StringBuffer();
    final styleMatches = RegExp(
      r'<style[^>]*>([\s\S]*?)<\/style>',
      caseSensitive: false,
    ).allMatches(text);
    for (final m in styleMatches) {
      final s = m.group(1)?.trim();
      if (s != null && s.isNotEmpty) {
        headStyles.writeln(s);
      }
    }

    String bodyClasses = '';
    String bodyId = '';
    String bodyStyle = '';

    final bodyTagMatch = RegExp(
      r'<body([^>]*)>',
      caseSensitive: false,
    ).firstMatch(text);
    if (bodyTagMatch != null) {
      final rawAttrs = bodyTagMatch.group(1) ?? '';
      final classMatch = RegExp(
        r'''class=(["'])(.*?)\1''',
        caseSensitive: false,
      ).firstMatch(rawAttrs);
      if (classMatch != null) {
        bodyClasses = classMatch.group(2)!.trim();
      }
      final idMatch = RegExp(
        r'''id=(["'])(.*?)\1''',
        caseSensitive: false,
      ).firstMatch(rawAttrs);
      if (idMatch != null) {
        bodyId = idMatch.group(2)!.trim();
      }
      final styleMatch = RegExp(
        r'''style=(["'])(.*?)\1''',
        caseSensitive: false,
      ).firstMatch(rawAttrs);
      if (styleMatch != null) {
        bodyStyle = styleMatch
            .group(2)!
            .trim()
            .replaceAll(
              RegExp(
                r'background(?:-color)?\s*:\s*(?:#[fF]{3,8}|white|rgb\s*\(\s*255\s*,\s*255\s*,\s*255\s*\))\s*;?',
                caseSensitive: false,
              ),
              '',
            )
            .replaceAll(
              RegExp(
                r'(?<![a-zA-Z0-9_-])color\s*:\s*(?:#[0]{3,8}|black|rgb\s*\(\s*0\s*,\s*0\s*,\s*0\s*\))\s*;?',
                caseSensitive: false,
              ),
              '',
            );
      }
    }

    final bodyStartIndex = text.indexOf(
      RegExp(r'<body[^>]*>', caseSensitive: false),
    );
    final bodyEndIndex = text.indexOf(RegExp(r'</body>', caseSensitive: false));

    if (bodyStartIndex != -1 &&
        bodyEndIndex != -1 &&
        bodyEndIndex > bodyStartIndex) {
      final endOfBodyTag = text.indexOf('>', bodyStartIndex) + 1;
      text = text.substring(endOfBodyTag, bodyEndIndex);
    } else {
      text = text
          .replaceAll(RegExp(r'<\?xml[^>]*\?>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<html[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</html>', caseSensitive: false), '')
          .replaceAll(
            RegExp(r'<head>[\s\S]*?</head>', caseSensitive: false),
            '',
          );
    }

    text = text.trim();
    if (text.isEmpty) return text;

    text = text.replaceAllMapped(
      RegExp(r'(<p\b[^>]*>\s*)([A-Z])\s+([a-z]{2,})', caseSensitive: false),
      (match) {
        final prefix = match.group(1)!;
        final letter = match.group(2)!;
        final remainder = match.group(3)!;
        if (letter.toUpperCase() == 'A' || letter.toUpperCase() == 'I') {
          return match.group(0)!;
        }
        return '$prefix$letter$remainder';
      },
    );

    // Rewrite <img src="...">, <image href/xlink:href="...">, <use xlink:href="..."> and CSS url(...)
    text = text.replaceAllMapped(
      RegExp(
        r'''(<(?:img|image|use)\b[^>]*?\b(?:src|href|xlink:href)\s*=\s*)(["'])(.*?)\2''',
        caseSensitive: false,
      ),
      (match) {
        final prefix = match.group(1)!;
        final quote = match.group(2)!;
        final originalPath = match.group(3)!;

        final lower = originalPath.trim().toLowerCase();
        if (lower.startsWith('http://') ||
            lower.startsWith('https://') ||
            lower.startsWith('data:')) {
          return match.group(0)!;
        }

        final decodedPath = Uri.decodeFull(originalPath.split('?').first.split('#').first);
        final baseName = p.basename(decodedPath.replaceAll('\\', '/'));
        if (baseName.isEmpty) return match.group(0)!;

        return '$prefix$quote$baseName$quote';
      },
    );

    text = text.replaceAllMapped(
      RegExp(r'''url\s*\(\s*(["']?)([^"'`\)]+)\1\s*\)''', caseSensitive: false),
      (match) {
        final quote = match.group(1) ?? '';
        final originalPath = match.group(2)!;

        final lower = originalPath.trim().toLowerCase();
        if (lower.startsWith('http://') ||
            lower.startsWith('https://') ||
            lower.startsWith('data:') ||
            lower.endsWith('.css') ||
            lower.endsWith('.ttf') ||
            lower.endsWith('.otf') ||
            lower.endsWith('.woff') ||
            lower.endsWith('.woff2')) {
          return match.group(0)!;
        }

        final decodedPath = Uri.decodeFull(originalPath.split('?').first.split('#').first);
        final baseName = p.basename(decodedPath.replaceAll('\\', '/'));
        if (baseName.isEmpty) return match.group(0)!;

        return 'url($quote$baseName$quote)';
      },
    );

    final StringBuffer container = StringBuffer('<div class="');
    container.write(bodyClasses.isNotEmpty ? 'epub-body $bodyClasses' : 'epub-body');
    container.write('"');
    if (bodyId.isNotEmpty) {
      container.write(' id="$bodyId"');
    }
    if (bodyStyle.isNotEmpty) {
      container.write(' style="$bodyStyle"');
    }
    container.write('>');
    container.write(text);
    container.write('</div>');
    final wrappedHtml = container.toString();

    final allStyles = StringBuffer();
    if (combinedCss.trim().isNotEmpty) {
      allStyles.writeln(combinedCss);
    }
    if (headStyles.isNotEmpty) {
      allStyles.writeln(headStyles.toString());
    }

    if (allStyles.isNotEmpty) {
      var sanitizedCss = allStyles
          .toString()
          .replaceAll(
            RegExp(
              r'background(?:-color)?\s*:\s*(?:#[fF]{3,8}|white|rgb\s*\(\s*255\s*,\s*255\s*,\s*255\s*\))\s*;?',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'(?<![a-zA-Z0-9_-])color\s*:\s*(?:#[0]{3,8}|black|rgb\s*\(\s*0\s*,\s*0\s*,\s*0\s*\))\s*;?',
              caseSensitive: false,
            ),
            '',
          );

      sanitizedCss = sanitizedCss.replaceAllMapped(
        RegExp(r'(^|[\s,;{}])body(?=[\s\.\#\[\:\,\{])', caseSensitive: false),
        (m) => '${m.group(1)}:is(body, .epub-body)',
      );

      return '<style>\n$sanitizedCss\n</style>\n$wrappedHtml';
    }

    return wrappedHtml;
  }
}
