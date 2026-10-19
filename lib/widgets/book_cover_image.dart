import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/book_cover_resolver.dart';

class BookCoverImage extends StatefulWidget {
  final String coverUrl;
  final String title;
  final String author;
  final String? coverId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    required this.title,
    required this.author,
    this.coverId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  late Future<String?> _resolvedUrlFuture;

  @override
  void initState() {
    super.initState();
    if (widget.coverUrl.trim().isNotEmpty) {
      _resolvedUrlFuture = Future.value(widget.coverUrl);
    } else {
      _resolvedUrlFuture = BookCoverResolver.resolveCoverUrl(
        title: widget.title,
        author: widget.author,
        primaryUrl: widget.coverUrl,
      );
    }
  }

  @override
  void didUpdateWidget(covariant BookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.title != widget.title ||
        oldWidget.author != widget.author) {
      if (widget.coverUrl.trim().isNotEmpty) {
        _resolvedUrlFuture = Future.value(widget.coverUrl);
      } else {
        _resolvedUrlFuture = BookCoverResolver.resolveCoverUrl(
          title: widget.title,
          author: widget.author,
          primaryUrl: widget.coverUrl,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(8);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: FutureBuilder<String?>(
          future: _resolvedUrlFuture,
          builder: (context, snapshot) {
            final resolvedUrl = snapshot.data ?? widget.coverUrl;

            // 1. Check if the cover is a local file (e.g. from EPUB / PDF import)
            if (resolvedUrl.trim().isNotEmpty &&
                !resolvedUrl.startsWith('http://') &&
                !resolvedUrl.startsWith('https://')) {
              try {
                final localFile = File(resolvedUrl.trim());
                if (localFile.existsSync()) {
                  return Image.file(
                    localFile,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    errorBuilder: (context, error, stackTrace) {
                      return BookCoverResolver.buildDarkAcademiaFallback(
                        title: widget.title,
                        author: widget.author,
                        width: widget.width,
                        height: widget.height,
                      );
                    },
                  );
                }
              } catch (_) {}
            }

            final candidateUrls = BookCoverResolver.getCandidateCoverUrls(
              primaryUrl: resolvedUrl,
              coverId: widget.coverId,
              title: widget.title,
              author: widget.author,
            );

            if (candidateUrls.isEmpty) {
              return BookCoverResolver.buildDarkAcademiaFallback(
                title: widget.title,
                author: widget.author,
                width: widget.width,
                height: widget.height,
              );
            }

            return _BookCoverStack(
              candidateUrls: candidateUrls,
              title: widget.title,
              author: widget.author,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
            );
          },
        ),
      ),
    );
  }
}

class _BookCoverStack extends StatefulWidget {
  final List<String> candidateUrls;
  final String title;
  final String author;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _BookCoverStack({
    required this.candidateUrls,
    required this.title,
    required this.author,
    this.width,
    this.height,
    required this.fit,
  });

  @override
  State<_BookCoverStack> createState() => _BookCoverStackState();
}

class _BookCoverStackState extends State<_BookCoverStack> {
  int _currentIndex = 0;
  bool _hasFailedAll = false;

  @override
  Widget build(BuildContext context) {
    if (_hasFailedAll || widget.candidateUrls.isEmpty) {
      return BookCoverResolver.buildDarkAcademiaFallback(
        title: widget.title,
        author: widget.author,
        width: widget.width,
        height: widget.height,
      );
    }

    final currentUrl = widget.candidateUrls[_currentIndex];

    return CachedNetworkImage(
      imageUrl: currentUrl,
      httpHeaders: const {
        'User-Agent': 'BookoraApp/1.0 (Android)',
        'Accept':
            'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      },
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 100),
      memCacheWidth: (widget.width != null && widget.width!.isFinite)
          ? (widget.width! * 2).toInt()
          : 400,
      memCacheHeight: (widget.height != null && widget.height!.isFinite)
          ? (widget.height! * 2).toInt()
          : 600,
      placeholder: (context, url) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF1E2026),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFFFFA726),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (_currentIndex < widget.candidateUrls.length - 1) {
                _currentIndex++;
              } else {
                _hasFailedAll = true;
              }
            });
          }
        });
        return Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFF1E2026),
        );
      },
    );
  }
}
