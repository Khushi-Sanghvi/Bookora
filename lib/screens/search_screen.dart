import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../models/enums.dart';
import '../providers/book_provider.dart';
import '../services/book_cache_service.dart';
import '../services/book_search_service.dart';
import '../services/genre_parser.dart';
import '../services/bookora_notification_service.dart';
import '../theme/reading_app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _results = [];
  bool _isLoading = false;
  final Set<String> _addedTitles = {};
  Timer? _debounceTimer;

  static const List<String> _popularSuggestions = [
    'Dark Romance',
    'Fantasy',
    'Poetry',
    'Mafia',
    'Sci-Fi',
    'Classics',
    'Philosophy',
    'Self-Help',
  ];

  @override
  void initState() {
    super.initState();
    BookCacheService.clearAllSearchCaches();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      _performSearch('Poetry');
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
      BookoraNotificationService.showBookAddedToast(
        context,
        bookTitle: item.title,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 16.0,
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bookora Archive 📜',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'UNEARTH TALES FROM MILLIONS OF VOLUMES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search title, author, or genre...',
                        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.streakAmber),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _performSearch(_searchController.text),
                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Suggestion Chips
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
                        style: TextStyle(fontSize: 11, color: colors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: colors.cardBgSecondary,
                      side: BorderSide(color: colors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    ? Center(child: CircularProgressIndicator(color: colors.streakAmber))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text('No matching books found.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              final books = ref.watch(bookProvider).value ?? [];
                              final itemKey = '${item.title.toLowerCase().trim()}|${item.author.toLowerCase().trim()}';
                              final isAlreadyAdded = _addedTitles.contains(itemKey) ||
                                  books.any((b) =>
                                      b.title.trim().toLowerCase() == item.title.trim().toLowerCase() &&
                                      b.author.trim().toLowerCase() == item.author.trim().toLowerCase());
                              final isDark = Theme.of(context).brightness == Brightness.dark;

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
                                    // 1. Cover Image
                                    Container(
                                      width: 60,
                                      height: 88,
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
                                                  child: Icon(Icons.auto_stories_rounded, color: colors.streakAmber, size: 24),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Icon(Icons.auto_stories_rounded, color: colors.streakAmber, size: 24),
                                            ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. Book Info (Title, Author, Rating, Page Count, Genres)
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
                                            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                          ),
                                          const SizedBox(height: 6),

                                          // Metrics Row (Rating & Pages)
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            physics: const BouncingScrollPhysics(),
                                            child: Row(
                                              children: [
                                                if (item.rating > 0) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: colors.streakAmber.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.star_rounded, size: 12, color: colors.streakAmber),
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
                                                  const SizedBox(width: 6),
                                                ],
                                                // Page Count from API (hidden if 0)
                                                if (item.totalPages > 0) ...[
                                                  Icon(Icons.menu_book_rounded, size: 12, color: colors.textSecondary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${item.totalPages} pgs',
                                                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                                  ),
                                                  if (item.publishedYear != null) ...[
                                                    Text(' • ', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                                                    Text('${item.publishedYear}', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                                  ],
                                                ],
                                              ],
                                            ),
                                          ),

                                          // 3. Multi-Genre Editorial Badges
                                          if (item.genres.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Row(
                                                children: item.genres.take(3).map((s) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 5),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () {
                                                        _searchController.text = s;
                                                        _performSearch(s);
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                        decoration: BoxDecoration(
                                                          color: isDark ? const Color(0xFF261E17) : const Color(0xFFF3EDE2),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: isDark ? const Color(0xFF3D3227) : const Color(0xFFE2D6C5),
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          s,
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            color: isDark ? const Color(0xFFD6C8B4) : const Color(0xFF6B5846),
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 4. Direct 1-Tap Add Button
                                    _buildAddButton(context, item, isAlreadyAdded),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, BookSearchResult item, bool isAlreadyAdded) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final addedBg = isDark ? const Color(0xFF11261B) : const Color(0xFFE8F3EB);
    final addedBorder = isDark ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF86B392);
    final addedTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF20542F);

    const addBg = Color(0xFFB45309);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (isAlreadyAdded) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${item.title}" is already in your library shelf 📖'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _addBook(item);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isAlreadyAdded ? addedBg : addBg,
          borderRadius: BorderRadius.circular(10),
          border: isAlreadyAdded ? Border.all(color: addedBorder, width: 1.0) : null,
          boxShadow: isAlreadyAdded
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFB45309).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isAlreadyAdded
              ? Row(
                  key: const ValueKey('added_state'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 15, color: addedTextColor),
                    const SizedBox(width: 4),
                    Text(
                      'Added',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: addedTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('add_state'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
