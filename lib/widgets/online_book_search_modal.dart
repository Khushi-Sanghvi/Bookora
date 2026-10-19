import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../models/enums.dart';
import '../providers/book_provider.dart';
import '../services/book_search_service.dart';
import '../services/genre_parser.dart';
import '../theme/reading_app_colors.dart';

class OnlineBookSearchModal extends ConsumerStatefulWidget {
  final String? initialQuery;

  const OnlineBookSearchModal({super.key, this.initialQuery});

  static Future<void> show(BuildContext context, {String? initialQuery}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OnlineBookSearchModal(initialQuery: initialQuery),
    );
  }

  @override
  ConsumerState<OnlineBookSearchModal> createState() =>
      _OnlineBookSearchModalState();
}

class _OnlineBookSearchModalState extends ConsumerState<OnlineBookSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _results = [];
  bool _isLoading = false;
  final Set<String> _addedTitles = {};
  Timer? _debounceTimer;

  static const List<String> _popularSuggestions = [
    'Dark Romance',
    'Fantasy',
    'Mafia',
    'Enemies to Lovers',
    'High Fantasy',
    'Sci-Fi',
    'Classics',
    'Dune',
    'Twisted Games',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      _performSearch('Fantasy Light Novels Classics');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && query.trim().isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isLoading = true);

    final cleanIsbn = trimmed.replaceAll(RegExp(r'[^0-9X]'), '');
    final List<BookSearchResult> list = [];

    if (cleanIsbn.length == 10 || cleanIsbn.length == 13) {
      final isbnRes = await BookSearchService.searchByIsbn(cleanIsbn);
      if (isbnRes != null) {
        list.add(isbnRes);
      }
    }

    final generalResults = await BookSearchService.searchBooks(trimmed);
    for (final item in generalResults) {
      final key = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
      final existingIndex = list.indexWhere(
        (r) => '${r.title.toLowerCase().trim()}|${r.author.toLowerCase().trim()}' == key,
      );

      if (existingIndex == -1) {
        list.add(item);
      } else {
        // Merge genre lists so no category tags are lost between providers
        final existing = list[existingIndex];
        final combinedGenres = {...existing.genres, ...item.genres}.toList();
        list[existingIndex] = existing.copyWith(
          genres: combinedGenres,
          coverUrl: existing.coverUrl ?? item.coverUrl,
          synopsis: (existing.synopsis?.length ?? 0) > (item.synopsis?.length ?? 0)
              ? existing.synopsis
              : item.synopsis,
        );
      }
    }

    if (mounted) {
      setState(() {
        _results = list;
        _isLoading = false;
      });
    }
  }

  /// 1-Tap Direct Ingestion: Instant UI feedback + background non-blocking enrichment
  Future<void> _addBook(BookSearchResult item) async {
    final colors = context.appColors;

    final bookKey = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
    if (_addedTitles.contains(bookKey)) return;
    setState(() => _addedTitles.add(bookKey));

    final initialDesc = item.synopsis ?? 'A captivating story by ${item.author}.';
    final initialPages = item.totalPages > 0 ? item.totalPages : 300;

    final initialGenres = item.subjects.isNotEmpty &&
            !(item.subjects.length == 1 &&
                item.subjects.first.toLowerCase() == 'general')
        ? item.subjects
        : GenreParser.inferGenresFromContext(
            title: item.title,
            author: item.author,
            description: initialDesc,
          );

    final initialBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: item.title,
      author: item.author,
      description: initialDesc,
      totalPages: initialPages,
      currentPage: 0,
      coverUrl: item.coverUrl ?? '',
      genres: initialGenres,
      status: ReadingStatus.toRead,
      overallRating: item.rating > 0 ? (item.rating / 2.0).clamp(1.0, 5.0) : 4.5,
      format: BookFormat.paperback,
    );

    // Save immediately and refresh shelf via ViewModel
    await ref.read(bookProvider.notifier).addBook(initialBook);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: colors.streakAmber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added "${item.title}" to Shelf!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: colors.cardBg,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Capture the notifier instance synchronously before launching unawaited task
    // to strictly prevent "Bad state: Cannot use 'ref' after the widget was disposed"
    final bookNotifier = ref.read(bookProvider.notifier);

    // Background asynchronous enrichment (unawaited)
    unawaited(
      BookSearchService.fetchEnrichedDetailsForBook(
        title: item.title,
        author: item.author,
        isbn: item.isbn,
        existingPages: item.totalPages,
        existingSynopsis: item.synopsis,
      ).then((enriched) async {
        if (enriched != null) {
          final resolvedGenres = enriched.genres.isNotEmpty &&
                  !(enriched.genres.length == 1 &&
                      enriched.genres.first.toLowerCase() == 'general')
              ? enriched.genres
              : initialBook.genres;

          final updatedBook = initialBook.copyWith(
            description: enriched.synopsis.length > 20
                ? enriched.synopsis
                : initialBook.description,
            tagline: enriched.tagline,
            blurb: enriched.blurb,
            totalPages: enriched.totalPages > 0 ? enriched.totalPages : initialBook.totalPages,
            genres: resolvedGenres,
          );
          await bookNotifier.updateBook(updatedBook);
        }
      }).catchError((e) {
        debugPrint('Background enrichment note: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bookora Search & Ingest',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Universal Open Library & Google Books Engine',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, or genre...',
                    hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.streakAmber,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.cardBgSecondary,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.streakAmber),
                    ),
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: _performSearch,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.streakAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _performSearch(_searchController.text),
                child: const Text(
                  'Search',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Suggestion Chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popularSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _popularSuggestions[index];
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: colors.cardBgSecondary,
                  side: BorderSide(color: colors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () {
                    _searchController.text = suggestion;
                    _performSearch(suggestion);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Results List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colors.streakAmber,
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No matching books found.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final itemKey = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
                      final isAdded = _addedTitles.contains(itemKey);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Thumbnail
                            Container(
                              width: 56,
                              height: 82,
                              decoration: BoxDecoration(
                                color: colors.cardBgSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(
                                            Icons.auto_stories_rounded,
                                            color: colors.streakAmber,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        color: colors.streakAmber,
                                        size: 24,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Book Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'by ${item.author}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        if (item.rating > 0) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.streakAmber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.star_rounded,
                                                  size: 12,
                                                  color: colors.streakAmber,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  item.rating.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.streakAmber,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                        Text(
                                          item.totalPages > 0
                                              ? '${item.totalPages} pgs'
                                              : 'Unknown pgs',
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (item.publishedYear != null) ...[
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '${item.publishedYear}',
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (item.synopsis != null && item.synopsis!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.synopsis!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: colors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                  if (item.subjects.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: item.subjects.take(3).map((s) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.cardBgSecondary,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: colors.borderSubtle),
                                          ),
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: colors.quoteGold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Add Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAdded
                                    ? colors.accentSage
                                    : colors.streakAmber,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: isAdded ? null : () => _addBook(item),
                              child: isAdded
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded, size: 14),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
