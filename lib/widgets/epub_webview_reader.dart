import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../services/epub_service.dart';

class EpubWebviewReader extends StatefulWidget {
  final EpubBookData epubData;
  final int initialChapterIndex;
  final double initialScrollAlignment;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;
  final bool isHorizontal;
  final ValueChanged<int> onChapterChanged;
  final void Function(int chapterIndex, double fraction) onScrollProgress;
  final VoidCallback onTap;
  final void Function(String error)? onError;

  const EpubWebviewReader({
    super.key,
    required this.epubData,
    required this.initialChapterIndex,
    required this.initialScrollAlignment,
    required this.fontSize,
    this.lineHeight = 1.65,
    required this.textColor,
    required this.backgroundColor,
    this.isHorizontal = false,
    required this.onChapterChanged,
    required this.onScrollProgress,
    required this.onTap,
    this.onError,
  });

  @override
  State<EpubWebviewReader> createState() => EpubWebviewReaderState();
}

class EpubWebviewReaderState extends State<EpubWebviewReader> {
  WebViewController? _controller;
  int _currentIndex = 0;
  bool _isLoaded = false;
  bool _hasWebviewError = false;
  double _currentScrollFraction = 0.0;
  double _currentChapterFraction = 0.0;

  double get currentScrollFraction => _currentScrollFraction;
  double get currentChapterFraction => _currentChapterFraction;
  int get currentChapterIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialChapterIndex.clamp(
      0,
      widget.epubData.pages.isNotEmpty
          ? widget.epubData.pages.length - 1
          : 0,
    );
    _initWebview();
  }

  @override
  void dispose() {
    try {
      _controller?.removeJavaScriptChannel('BookoraChannel');
    } catch (_) {}
    _controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EpubWebviewReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasWebviewError || _controller == null) return;
    try {
      if (oldWidget.backgroundColor != widget.backgroundColor) {
        _controller!.setBackgroundColor(widget.backgroundColor);
      }
      if (oldWidget.fontSize != widget.fontSize ||
          oldWidget.lineHeight != widget.lineHeight ||
          oldWidget.textColor != widget.textColor ||
          oldWidget.backgroundColor != widget.backgroundColor ||
          oldWidget.isHorizontal != widget.isHorizontal) {
        _injectStyles();
        if (oldWidget.isHorizontal != widget.isHorizontal) {
          _controller?.runJavaScript('if (window.bookoraUpdateOrientation) { window.bookoraUpdateOrientation(${widget.isHorizontal}); }');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            jumpToChapter(_currentIndex);
          });
        }
      }
    } catch (_) {}
  }

  void _initWebview() {
    try {
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(widget.backgroundColor);

      if (ctrl.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(false);
        (ctrl.platform as AndroidWebViewController).setAllowFileAccess(true);
        (ctrl.platform as AndroidWebViewController).setAllowContentAccess(true);
      }

      ctrl
        ..addJavaScriptChannel(
          'BookoraChannel',
          onMessageReceived: (JavaScriptMessage message) {
            final msg = message.message;
            if (msg.startsWith('chapter:')) {
              final idx = int.tryParse(msg.substring(8));
              if (idx != null && idx != _currentIndex) {
                _currentIndex = idx;
                widget.onChapterChanged(idx);
              }
            } else if (msg == 'tap') {
              widget.onTap();
            } else if (msg.startsWith('scroll:')) {
              final parts = msg.substring(7).split(',');
              if (parts.length >= 2) {
                final idx = int.tryParse(parts[0]) ?? _currentIndex;
                final chFraction = double.tryParse(parts[1]) ?? 0.0;
                final totalFraction = parts.length >= 3
                    ? (double.tryParse(parts[2]) ?? 0.0)
                    : chFraction;
                _currentScrollFraction = totalFraction;
                _currentChapterFraction = chFraction;
                if (idx != _currentIndex) {
                  _currentIndex = idx;
                  widget.onChapterChanged(idx);
                }
                widget.onScrollProgress(idx, chFraction);
              }
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoaded = true;
                });
              }
              _injectStyles();
              _injectListeners();

              if (widget.initialChapterIndex > 0 ||
                  widget.initialScrollAlignment > 0) {
                try {
                  _controller?.runJavaScript(
                    'if (window.bookoraExecuteRestore) { window.bookoraExecuteRestore(${widget.initialChapterIndex}, ${widget.initialScrollAlignment}); }',
                  );
                } catch (_) {}
              }
            },
          ),
        );

      _controller = ctrl;
      _loadEntireBook();
    } catch (e) {
      debugPrint('WebView initialization error: $e');
      _hasWebviewError = true;
      if (mounted) {
        widget.onError?.call(e.toString());
      }
    }
  }

  Future<void> _loadEntireBook() async {
    if (_hasWebviewError || _controller == null) return;
    final totalPages = widget.epubData.pages.length;
    final imagesDir = widget.epubData.imagesDir;

    if (imagesDir != null && Directory(imagesDir).existsSync()) {
      final htmlFile = File(p.join(imagesDir, '_bookora_reader_v10.html'));

      final sink = htmlFile.openWrite();
      try {
        sink.write('<!DOCTYPE html><html><head>');
        sink.write('<meta charset="utf-8">');
        sink.write(
          '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">',
        );
        sink.write('</head><body>');
        sink.write('<div id="bookora-book-container">');

        for (int i = 0; i < totalPages; i++) {
          sink.write(
            '<article id="chapter-$i" class="bookora-chapter" data-chapter="$i">',
          );
          sink.write('<div class="chapter-content">');
          sink.write(widget.epubData.pages[i]);
          sink.write('</div>');
          sink.write(
            '<div class="bookora-chapter-divider">— ${i + 1} / $totalPages —</div>',
          );
          sink.write('</article>');
        }

        sink.write('</div>');
        sink.write('<style id="bookora-dynamic-styles"></style>');
        sink.write('</body></html>');

        await sink.flush();
      } finally {
        await sink.close();
      }

      try {
        await _controller?.loadFile(htmlFile.path);
      } catch (e) {
        debugPrint('loadFile note, fallback to loadHtmlString: $e');
        final baseUrl = Uri.directory(imagesDir).toString();
        await _controller?.loadHtmlString(
          await htmlFile.readAsString(),
          baseUrl: baseUrl,
        );
      }
    } else {
      final buffer = StringBuffer();
      buffer.write('<!DOCTYPE html><html><head>');
      buffer.write('<meta charset="utf-8">');
      buffer.write(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">',
      );
      buffer.write('</head><body>');
      buffer.write('<div id="bookora-book-container">');

      for (int i = 0; i < totalPages; i++) {
        buffer.write(
          '<article id="chapter-$i" class="bookora-chapter" data-chapter="$i">',
        );
        buffer.write('<div class="chapter-content">');
        buffer.write(widget.epubData.pages[i]);
        buffer.write('</div>');
        buffer.write(
          '<div class="bookora-chapter-divider">— ${i + 1} / $totalPages —</div>',
        );
        buffer.write('</article>');
      }

      buffer.write('</div>');
      buffer.write('<style id="bookora-dynamic-styles"></style>');
      buffer.write('</body></html>');

      try {
        await _controller?.loadHtmlString(
          buffer.toString(),
        );
      } catch (_) {}
    }
  }

  String _buildCss(String bgHex, String textHex) {
    if (widget.isHorizontal) {
      return '''
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          overflow-x: scroll !important;
          overflow-y: hidden !important;
          -webkit-overflow-scrolling: touch !important;
          background-color: $bgHex !important;
          color: $textHex !important;
          font-size: ${widget.fontSize}px !important;
          line-height: ${widget.lineHeight} !important;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Georgia, serif !important;
          -webkit-text-size-adjust: 100% !important;
          scroll-snap-type: x mandatory !important;
          user-select: text;
          -webkit-user-select: text;
        }
        #bookora-book-container {
          height: calc(100vh - 60px) !important;
          column-width: calc(100vw - 48px) !important;
          column-gap: 48px !important;
          column-fill: auto !important;
          box-sizing: border-box !important;
          padding: 36px 24px 36px 24px !important;
        }
        .bookora-chapter {
          display: block !important;
          break-after: column !important;
          page-break-after: always !important;
          break-inside: avoid-column !important;
          margin-bottom: 0 !important;
          scroll-snap-align: start !important;
        }
        .chapter-content, .epub-body {
          display: block;
          background-color: transparent !important;
          text-rendering: optimizeLegibility;
          -webkit-font-smoothing: antialiased;
          -webkit-hyphens: auto;
          hyphens: auto;
          overflow-wrap: break-word;
          word-wrap: break-word;
        }
        a, a:link, a:visited, a:active {
          color: #E5A93C;
          text-decoration: none;
        }
        p {
          margin-top: 0;
          margin-bottom: 0.9em;
          text-align: justify;
          text-justify: inter-word;
          background-color: transparent !important;
          color: inherit !important;
        }
        h1, h2, h3, h4, h5, h6 {
          color: $textHex !important;
          text-align: center;
          font-weight: 700;
          margin-top: 1.2em;
          margin-bottom: 0.8em;
          line-height: 1.25;
          background-color: transparent !important;
          break-inside: avoid-column !important;
        }
        h1 { font-size: 1.45em; letter-spacing: 0.5px; }
        h2 { font-size: 1.25em; letter-spacing: 0.3px; }
        h3 { font-size: 1.1em; }
        img, svg, image {
          max-width: 100% !important;
          max-height: 60vh !important;
          height: auto !important;
          object-fit: contain !important;
          display: block !important;
          margin: 12px auto !important;
          border-radius: 4px;
          break-inside: avoid-column !important;
        }
        .bookora-chapter-divider {
          text-align: center;
          margin: 24px 0 24px 0;
          font-size: 0.75em;
          letter-spacing: 2px;
          opacity: 0.4;
          font-weight: 600;
          user-select: none;
          break-inside: avoid-column !important;
        }
        ::selection {
          background: rgba(212, 175, 55, 0.40) !important;
          color: inherit !important;
        }
      ''';
    }

    return '''
      html, body {
        margin: 0 !important;
        padding: 0 !important;
        width: 100% !important;
        height: auto !important;
        overflow-x: hidden !important;
        overflow-y: auto !important;
        -webkit-overflow-scrolling: touch !important;
        background-color: $bgHex !important;
        color: $textHex !important;
        font-size: ${widget.fontSize}px !important;
        line-height: ${widget.lineHeight} !important;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Georgia, serif !important;
        -webkit-text-size-adjust: 100% !important;
        scroll-snap-type: none !important;
        user-select: text;
        -webkit-user-select: text;
      }
      #bookora-book-container {
        padding: 48px 20px 80px 20px !important;
        max-width: 680px !important;
        margin: 0 auto !important;
        box-sizing: border-box !important;
        column-width: auto !important;
        column-gap: normal !important;
        column-fill: balance !important;
        height: auto !important;
      }
      .bookora-chapter {
        display: block !important;
        margin-bottom: 24px !important;
        background-color: transparent !important;
        break-after: auto !important;
        page-break-after: auto !important;
        break-inside: auto !important;
        scroll-snap-align: none !important;
      }
      .chapter-content, .epub-body {
        display: block;
        background-color: transparent !important;
        text-rendering: optimizeLegibility;
        -webkit-font-smoothing: antialiased;
        -webkit-hyphens: auto;
        hyphens: auto;
        overflow-wrap: break-word;
        word-wrap: break-word;
      }
      a, a:link, a:visited, a:active {
        color: #E5A93C;
        text-decoration: none;
      }
      p {
        margin-top: 0;
        margin-bottom: 1.15em;
        text-align: justify;
        text-justify: inter-word;
        background-color: transparent !important;
        color: inherit !important;
      }
      h1, h2, h3, h4, h5, h6 {
        color: $textHex !important;
        text-align: center;
        font-weight: 700;
        margin-top: 1.6em;
        margin-bottom: 0.9em;
        line-height: 1.3;
        background-color: transparent !important;
      }
      h1 { font-size: 1.55em; letter-spacing: 0.5px; }
      h2 { font-size: 1.35em; letter-spacing: 0.3px; }
      h3 { font-size: 1.15em; }
      img, svg, image {
        max-width: 100% !important;
        height: auto !important;
        display: block !important;
        margin: 20px auto !important;
        border-radius: 4px;
      }
      .bookora-chapter-divider {
        text-align: center;
        margin: 48px 0 32px 0;
        font-size: 0.75em;
        letter-spacing: 2px;
        opacity: 0.4;
        font-weight: 600;
        user-select: none;
      }
      ::selection {
        background: rgba(212, 175, 55, 0.40) !important;
        color: inherit !important;
      }
      ::-moz-selection {
        background: rgba(212, 175, 55, 0.40) !important;
        color: inherit !important;
      }
    ''';
  }

  void _injectStyles() {
    if (_hasWebviewError || _controller == null) return;
    final textHex =
        '#${widget.textColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final bgHex =
        '#${widget.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final css = _buildCss(bgHex, textHex);
    final jsonCss = jsonEncode(css);

    final js = '(function() { window._bookoraIsHoriz = ${widget.isHorizontal}; var styleTag = document.getElementById("bookora-dynamic-styles"); if (!styleTag) { styleTag = document.createElement("style"); styleTag.id = "bookora-dynamic-styles"; document.head.appendChild(styleTag); } styleTag.innerHTML = $jsonCss; })();';

    try {
      _controller?.runJavaScript(js);
    } catch (_) {}
  }

  void _injectListeners() {
    if (_hasWebviewError || _controller == null) return;
    final isHoriz = widget.isHorizontal;
    final js = '''
      (function() {
        window._bookoraIsHoriz = $isHoriz;
        window.bookoraUpdateOrientation = function(h) {
          window._bookoraIsHoriz = h;
        };

        if (window._bookoraListenersInjected) return;
        window._bookoraListenersInjected = true;

        var startX = 0, startY = 0, startTime = 0;
        var isRestoring = false;

        document.addEventListener('touchstart', function(e) {
          isRestoring = false;
          if (e.touches.length === 1) {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
            startTime = Date.now();
          }
        }, { passive: true });

        document.addEventListener('touchend', function(e) {
          if (e.changedTouches.length === 1) {
            var diffX = Math.abs(e.changedTouches[0].clientX - startX);
            var diffY = Math.abs(e.changedTouches[0].clientY - startY);
            var duration = Date.now() - startTime;
            if (diffX < 10 && diffY < 10 && duration < 300) {
              if (window.getSelection().toString().trim().length === 0) {
                if (window.BookoraChannel) {
                  window.BookoraChannel.postMessage('tap');
                }
              }
            }
          }
        }, { passive: true });

        var scrollTimeout = null;
        var chapters = document.querySelectorAll('.bookora-chapter');

        window.addEventListener('scroll', function() {
          if (isRestoring) return;
          if (scrollTimeout) cancelAnimationFrame(scrollTimeout);
          scrollTimeout = requestAnimationFrame(function() {
            var isHoriz = (typeof window._bookoraIsHoriz === 'boolean') ? window._bookoraIsHoriz : $isHoriz;
            var currentIdx = 0;
            var chFraction = 0.0;
            var totalProgress = 0.0;

            if (isHoriz) {
              var scrollX = window.scrollX || window.pageXOffset;
              var viewportWidth = window.innerWidth;
              var docWidth = document.documentElement.scrollWidth - viewportWidth;
              totalProgress = docWidth > 0 ? (scrollX / docWidth) : 0.0;

              for (var i = 0; i < chapters.length; i++) {
                var el = chapters[i];
                var rect = el.getBoundingClientRect();
                if (rect.left >= -viewportWidth / 2 && rect.left < viewportWidth / 2) {
                  currentIdx = parseInt(el.getAttribute('data-chapter')) || i;
                  break;
                }
              }
            } else {
              var scrollY = window.scrollY;
              var viewportHeight = window.innerHeight;
              var docHeight = document.documentElement.scrollHeight - viewportHeight;
              totalProgress = docHeight > 0 ? (scrollY / docHeight) : 0.0;

              var focalY = scrollY + (viewportHeight * 0.15);
              for (var i = 0; i < chapters.length; i++) {
                var el = chapters[i];
                var rect = el.getBoundingClientRect();
                var top = window.scrollY + rect.top;
                var height = el.offsetHeight;
                if (focalY >= top && focalY < (top + height)) {
                  currentIdx = parseInt(el.getAttribute('data-chapter')) || i;
                  chFraction = height > 0 ? ((focalY - top) / height) : 0.0;
                  break;
                }
              }
            }

            if (window.BookoraChannel) {
              window.BookoraChannel.postMessage('scroll:' + currentIdx + ',' + chFraction.toFixed(4) + ',' + totalProgress.toFixed(4));
            }
          });
        }, { passive: true });

        window.bookoraJumpToChapter = function(index, anchor) {
          isRestoring = false;
          var isHoriz = (typeof window._bookoraIsHoriz === 'boolean') ? window._bookoraIsHoriz : $isHoriz;
          if (anchor && anchor !== 'null' && anchor !== 'undefined') {
            var cleanAnchor = anchor.toString().split('#').pop();
            if (cleanAnchor) {
              var anchorEl = document.getElementById(cleanAnchor) || document.querySelector('[name="' + cleanAnchor + '"]');
              if (anchorEl) {
                if (isHoriz) {
                  anchorEl.scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'start' });
                } else {
                  anchorEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                return;
              }
            }
          }
          var el = document.getElementById('chapter-' + index);
          if (el) {
            if (isHoriz) {
              el.scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'start' });
            } else {
              el.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
          } else {
            var chapters = document.querySelectorAll('.bookora-chapter');
            if (chapters && chapters.length > index && chapters[index]) {
              if (isHoriz) {
                chapters[index].scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'start' });
              } else {
                chapters[index].scrollIntoView({ behavior: 'smooth', block: 'start' });
              }
            }
          }
        };

        window.bookoraRestorePosition = function(index, fraction) {
          var isHoriz = (typeof window._bookoraIsHoriz === 'boolean') ? window._bookoraIsHoriz : $isHoriz;
          var el = document.getElementById('chapter-' + index);
          if (el) {
            if (isHoriz) {
              el.scrollIntoView({ behavior: 'instant', block: 'start', inline: 'start' });
            } else {
              var rect = el.getBoundingClientRect();
              var absoluteTop = window.scrollY + rect.top;
              var height = el.offsetHeight;
              var targetY = absoluteTop + (height * (fraction || 0));
              window.scrollTo({ top: Math.max(0, targetY), behavior: 'instant' });
            }
          }
        };

        window.bookoraExecuteRestore = function(index, fraction) {
          isRestoring = true;
          window.bookoraRestorePosition(index, fraction);
          setTimeout(function() { window.bookoraRestorePosition(index, fraction); }, 100);
          setTimeout(function() { window.bookoraRestorePosition(index, fraction); }, 350);
          setTimeout(function() { 
            window.bookoraRestorePosition(index, fraction); 
            isRestoring = false;
          }, 800);
          if (document.fonts && document.fonts.ready) {
            document.fonts.ready.then(function() {
              window.bookoraRestorePosition(index, fraction);
            });
          }
        };
      })();
    ''';
    try {
      _controller?.runJavaScript(js);
    } catch (_) {}
  }

  void jumpToChapter(int index, {String? anchor}) {
    if (_hasWebviewError || _controller == null) return;
    try {
      final cleanAnchor = anchor != null ? jsonEncode(anchor) : 'null';
      _controller?.runJavaScript('if (window.bookoraJumpToChapter) { window.bookoraJumpToChapter($index, $cleanAnchor); }');
    } catch (_) {}
  }

  void restorePosition(int index, double fraction) {
    if (!_isLoaded || _hasWebviewError || _controller == null) return;
    try {
      _controller?.runJavaScript('if (window.bookoraExecuteRestore) { window.bookoraExecuteRestore($index, $fraction); }');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_hasWebviewError || _controller == null) {
      return const SizedBox();
    }
    try {
      return WebViewWidget(controller: _controller!);
    } catch (e) {
      debugPrint('Error inflating WebViewWidget: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onError?.call(e.toString());
      });
      return const SizedBox();
    }
  }
}
