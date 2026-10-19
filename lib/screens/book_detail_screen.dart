import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../models/quote_annotation.dart';
import '../providers/book_provider.dart';
import '../services/book_metadata_sanitizer.dart';
import '../services/book_search_service.dart';
import '../services/file_service.dart';
import '../services/bookora_notification_service.dart';
import '../services/genre_parser.dart';
import '../theme/reading_app_colors.dart';
import '../widgets/add_quote_dialog.dart';
import '../widgets/log_progress_dialog.dart';

import '../widgets/format_and_documents_sheet.dart';
import '../widgets/book_cover_image.dart';
import '../widgets/book_metadata_summary_bar.dart';
import '../widgets/expandable_book_hook_text.dart';
import '../widgets/story_codex_view.dart';
import 'pdf_reader_screen.dart';
import 'epub_reader_screen.dart';
import '../providers/audiobook_provider.dart';
import '../widgets/full_screen_audio_player_sheet.dart';
import 'dart:io';

final fileServiceProvider = Provider((ref) => FileService());

class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ScrollController _scrollController;
  late Book _currentBook;
  bool _isSynopsisExpanded = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    final cached = ref.read(bookDetailProvider(widget.book.id));
    _currentBook = cached ?? widget.book;
    _isFavorite = _currentBook.isFavorite;

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _enrichBookDetailsIfNeeded();
  }

  void _enrichBookDetailsIfNeeded() async {
    final descLower = _currentBook.description.toLowerCase();
    final isPlaceholderOrTruncated =
        BookMetadataSanitizer.isTruncatedSynopsis(_currentBook.description) ||
        _currentBook.description.length < 80 ||
        descLower.contains('a captivating story by') ||
        descLower.contains('imported from reading catalog') ||
        descLower.contains('imported from csv') ||
        descLower.contains('published by open library') ||
        descLower.contains('no overview provided');

    final needsGenres =
        _currentBook.genres.isEmpty ||
        (_currentBook.genres.length == 1 &&
            _currentBook.genres.first.toLowerCase() == 'general');

    if (_currentBook.totalPages <= 1 ||
        _currentBook.tagline == null ||
        _currentBook.blurb == null ||
        isPlaceholderOrTruncated ||
        needsGenres) {
      final enriched = await BookSearchService.fetchEnrichedDetailsForBook(
        title: _currentBook.title,
        author: _currentBook.author,
        existingPages: _currentBook.totalPages > 1
            ? _currentBook.totalPages
            : 0,
        existingSynopsis: isPlaceholderOrTruncated ? null : _currentBook.description,
        existingGenres: _currentBook.genres,
      );

      if (enriched != null && mounted) {
        final newGenres =
            (enriched.genres.isNotEmpty &&
                !(enriched.genres.length == 1 &&
                    enriched.genres.first.toLowerCase() == 'general'))
            ? enriched.genres
            : (_currentBook.genres.isNotEmpty &&
                      !(_currentBook.genres.length == 1 &&
                          _currentBook.genres.first.toLowerCase() == 'general')
                  ? _currentBook.genres
                  : GenreParser.inferGenresFromContext(
                      title: _currentBook.title,
                      author: _currentBook.author,
                      description: enriched.synopsis,
                    ));

        final newDescription = (enriched.synopsis.isNotEmpty &&
                !BookMetadataSanitizer.isTruncatedSynopsis(enriched.synopsis))
            ? enriched.synopsis
            : (_currentBook.description.isNotEmpty &&
                    !BookMetadataSanitizer.isTruncatedSynopsis(
                      _currentBook.description,
                    )
                ? _currentBook.description
                : (enriched.synopsis.isNotEmpty
                    ? BookMetadataSanitizer.sanitizeSynopsis(enriched.synopsis)
                    : BookMetadataSanitizer.sanitizeSynopsis(
                        _currentBook.description,
                      )));

        final updatedBook = _currentBook.copyWith(
          description: newDescription,
          tagline: enriched.tagline,
          blurb: enriched.blurb,
          totalPages: enriched.totalPages > 0
              ? enriched.totalPages
              : (_currentBook.totalPages > 0 ? _currentBook.totalPages : 300),
          genres: newGenres,
        );

        await ref.read(bookRepositoryProvider).updateBook(updatedBook);
        if (mounted) {
          setState(() {
            _currentBook = updatedBook;
          });
          _updateBook();
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openStoryCodexModal(BuildContext context, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF18191E) : const Color(0xFFFFFFFF);
    final headerBg = isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F5);
    final borderColor = isDark ? const Color(0xFF282C3B) : const Color(0xFFE5DFC9);
    final textPrimary = isDark ? const Color(0xFFE0D8C3) : const Color(0xFF231F1C);
    final textSecondary = isDark ? const Color(0xFFA09B8E) : const Color(0xFF6B655B);
    final accentGold = isDark ? const Color(0xFFFFA726) : const Color(0xFFD97706);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.4),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.2),
                  left: BorderSide(color: borderColor, width: 0.8),
                  right: BorderSide(color: borderColor, width: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Header Container
                  Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 12,
                      top: 10,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: headerBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 1.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: textSecondary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentGold.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: accentGold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Story Codex',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'NARRATIVE ANATOMY & OVERVIEW',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                        color: accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: textSecondary,
                                size: 22,
                              ),
                              splashRadius: 20,
                              onPressed: () => Navigator.pop(modalContext),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Expanded(
                    child: StoryCodexContentView(
                      book: book,
                      scrollController: scrollController,
                      isModal: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateBook() {
    ref.read(bookProvider.notifier).updateBook(_currentBook);
  }

  Future<void> _selectFinishDate(BuildContext context) async {
    final colors = context.appColors;
    final initialDate =
        _currentBook.endDate ?? _currentBook.finishDate ?? DateTime.now();
    final firstDate = _currentBook.startDate ?? DateTime(2000);
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.streakAmber,
              onPrimary: Colors.black,
              surface: colors.cardBg,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.cardBg),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await ref
          .read(booksProvider.notifier)
          .markBookCompleted(bookId: _currentBook.id, customFinishDate: picked);
      final updated = await ref.read(bookRepositoryProvider).getBookById(_currentBook.id);
      if (updated != null && mounted) {
        setState(() => _currentBook = updated);
      }
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final colors = context.appColors;
    final finishDateValue = _currentBook.endDate ?? _currentBook.finishDate;
    final initialDate = _currentBook.startDate ?? DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate =
        finishDateValue ?? DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.streakAmber,
              onPrimary: Colors.black,
              surface: colors.cardBg,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.cardBg),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final updated = _currentBook.copyWith(
        startDate: picked,
        status: _currentBook.status == ReadingStatus.toRead
            ? ReadingStatus.currentlyReading
            : _currentBook.status,
      );
      setState(() => _currentBook = updated);
      _updateBook();
    }
  }

  String _getStatusDisplay(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return '⏳ READING';
      case ReadingStatus.toRead:
        return '📖 TO READ';
      case ReadingStatus.finished:
        return '✅ FINISHED';
      case ReadingStatus.abandoned:
        return '⏸️ PAUSED';
      case ReadingStatus.wishlist:
        return '💫 WISHLIST';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Reactive Riverpod binding: instantly reflects SQLite and state updates
    final bookFromProvider = ref.watch(bookDetailProvider(widget.book.id));
    final currentBook = bookFromProvider ?? _currentBook;
    _currentBook = currentBook;

    // Listen to Riverpod booksProvider updates to keep local disk cache in sync
    ref.listen<AsyncValue<List<Book>>>(booksProvider, (previous, next) {
      next.whenData((books) {
        final updated = books.firstWhere(
          (b) => b.id == widget.book.id,
          orElse: () => _currentBook,
        );
        if (mounted) {
          ref.read(bookRepositoryProvider).updateBook(updated);
        }
      });
    });

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Pinned Top Header Bar with Circle Action Pills
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              backgroundColor: colors.scaffoldBg,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              toolbarHeight: 56,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.cardBgSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: colors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _openStoryCodexModal(context, _currentBook),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.cardBgSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.streakAmber.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: colors.streakAmber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFavorite = !_isFavorite;
                              _currentBook = _currentBook.copyWith(
                                isFavorite: _isFavorite,
                              );
                            });
                            _updateBook();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.cardBgSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? Colors.redAccent
                                  : colors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDeleteBook(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.cardBgSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              color: colors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Scrollable Book Body
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Book Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookCoverImage(
                          coverUrl: _currentBook.coverUrl,
                          title: _currentBook.title,
                          author: _currentBook.author,
                          width: 120,
                          height: 165,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentBook.title,
                                style: GoogleFonts.crimsonPro(
                                  fontSize: _currentBook.title.length > 50
                                      ? 21
                                      : (_currentBook.title.length > 30
                                            ? 23
                                            : 26),
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${_currentBook.author}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),

                              _buildMultiGenreTags(
                                _currentBook.genres,
                                context,
                              ),
                              if (_currentBook.genres.isNotEmpty)
                                const SizedBox(height: 10),

                              ExpandableBookHookText(
                                hookText: _currentBook.effectiveTagline,
                                colors: colors,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Metadata Summary Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: BookMetadataSummaryBar(
                      book: _currentBook,
                      onTapStartDate: () => _selectStartDate(context),
                      onTapEndDate: () => _selectFinishDate(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Tab Bar (Details | Quotes)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    indicatorColor: colors.streakAmber,
                    labelColor: colors.streakAmber,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    onTap: (index) {
                      setState(() {});
                    },
                    tabs: [
                      const Tab(text: 'Details'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Quotes'),
                            if (_currentBook.quotes.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.streakAmber.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentBook.quotes.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colors.streakAmber,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 4. Tab Body Content with gesture swipe support
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -200) {
                          // Swipe left -> next tab
                          if (_tabController.index < 1) {
                            _tabController.animateTo(_tabController.index + 1);
                          }
                        } else if (details.primaryVelocity! > 200) {
                          // Swipe right -> previous tab
                          if (_tabController.index > 0) {
                            _tabController.animateTo(_tabController.index - 1);
                          }
                        }
                      }
                    },
                    child: _tabController.index == 0
                        ? _buildDetailsTab(colors)
                        : _buildQuotesTab(colors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddQuoteDialog,
              backgroundColor: colors.streakAmber,
              foregroundColor: Colors.black,
              label: const Text(
                'Add Quote',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.format_quote),
            )
          : null,
    );
  }

  Widget _buildDetailsTab(ReadingAppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingProgressCard(colors),
          const SizedBox(height: 16),
          _buildFormatSection(colors),
          const SizedBox(height: 16),
          _buildTaglineAndBlurbSection(colors),
          const SizedBox(height: 16),
          _buildVibeAndTropeMeter(colors),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReadingProgressCard(ReadingAppColors colors) {
    final progressPercent = _currentBook.progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardBgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReadingStatus>(
                      value: _currentBook.status,
                      isExpanded: true,
                      isDense: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.textPrimary,
                        size: 16,
                      ),
                      dropdownColor: colors.cardBg,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      selectedItemBuilder: (context) {
                        return ReadingStatus.values.map((s) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _getStatusDisplay(s),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (status) async {
                        if (status != null) {
                          if (status == ReadingStatus.finished) {
                            await ref
                                .read(booksProvider.notifier)
                                .markBookCompleted(bookId: _currentBook.id);
                            ref
                                .read(bookProvider.notifier)
                                .addJournalEntry(
                                  _currentBook.id,
                                  JournalEntry.create(
                                    1,
                                    reflection:
                                        'Completed reading "${_currentBook.title}"!',
                                  ),
                                );
                            final updated = await ref.read(bookRepositoryProvider).getBookById(
                              _currentBook.id,
                            );
                            if (updated != null && mounted) {
                              setState(() => _currentBook = updated);
                            }
                          } else {
                            Book updated = _currentBook.copyWith(
                              status: status,
                            );
                            setState(() => _currentBook = updated);
                            _updateBook();
                          }
                        }
                      },
                      items: ReadingStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            _getStatusDisplay(s),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Flexible(
                flex: 4,
                child: InkWell(
                  onTap: () =>
                      LogProgressDialog.show(context, book: _currentBook),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${_currentBook.currentPage}/${_currentBook.totalPages} pgs',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: colors.streakAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(
                            color: colors.streakAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: colors.streakAmber,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (_currentBook.currentPage > 0) {
                    setState(() {
                      _currentBook = _currentBook.copyWith(
                        currentPage: _currentBook.currentPage - 1,
                      );
                    });
                    _updateBook();
                  }
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.streakAmber,
                    inactiveTrackColor: colors.borderSubtle,
                    thumbColor: colors.streakAmber,
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    value: _currentBook.currentPage.toDouble().clamp(
                      0.0,
                      max(1.0, _currentBook.totalPages.toDouble()),
                    ),
                    min: 0.0,
                    max: max(1.0, _currentBook.totalPages.toDouble()),
                    onChanged: (val) {
                      setState(() {
                        _currentBook = _currentBook.copyWith(
                          currentPage: val.round(),
                        );
                      });
                    },
                    onChangeEnd: (val) async {
                      final newPage = val.round();
                      final delta = max(0, newPage - widget.book.currentPage);
                      if (newPage >= _currentBook.totalPages &&
                          _currentBook.totalPages > 0) {
                        await ref
                            .read(booksProvider.notifier)
                            .markBookCompleted(bookId: _currentBook.id);
                        final updated = await ref.read(bookRepositoryProvider).getBookById(
                          _currentBook.id,
                        );
                        if (updated != null && mounted) {
                          setState(() => _currentBook = updated);
                        }
                      } else {
                        _updateBook();
                      }
                      if (delta > 0) {
                        ref
                            .read(bookProvider.notifier)
                            .addJournalEntry(
                              _currentBook.id,
                              JournalEntry.create(delta),
                            );
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: colors.streakAmber,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  if (_currentBook.currentPage < _currentBook.totalPages) {
                    final newPage = _currentBook.currentPage + 1;
                    if (newPage >= _currentBook.totalPages &&
                        _currentBook.totalPages > 0) {
                      await ref
                          .read(booksProvider.notifier)
                          .markBookCompleted(bookId: _currentBook.id);
                      final updated = await ref.read(bookRepositoryProvider).getBookById(
                        _currentBook.id,
                      );
                      if (updated != null && mounted) {
                        setState(() => _currentBook = updated);
                      }
                    } else {
                      setState(() {
                        _currentBook = _currentBook.copyWith(
                          currentPage: newPage,
                        );
                      });
                      _updateBook();
                    }
                    ref
                        .read(bookProvider.notifier)
                        .addJournalEntry(
                          _currentBook.id,
                          JournalEntry.create(1),
                        );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection(ReadingAppColors colors) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool hasAudioFileAttached =
        _currentBook.format == BookFormat.audiobook &&
        (_currentBook.localFilePath != null &&
            _currentBook.localFilePath!.isNotEmpty) &&
        File(_currentBook.localFilePath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentBook.format == BookFormat.audiobook)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildAudiobookLaunchCard(
              colors,
              isLightMode,
              hasAudioFileAttached: hasAudioFileAttached,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Format & Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.quoteGold,
              ),
            ),
            InkWell(
              onTap: () =>
                  FormatAndDocumentsSheet.show(context, book: _currentBook),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.streakAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward,
                    color: colors.streakAmber,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          children: BookFormat.values
              .where((f) => f != BookFormat.hardcover && f != BookFormat.ebook)
              .map((f) {
                final isSelected = _currentBook.format == f;
                return ChoiceChip(
                  avatar: Icon(
                    _getFormatIcon(f),
                    size: 14,
                    color: isSelected ? Colors.black : colors.streakAmber,
                  ),
                  label: Text(
                    isSelected
                        ? '${f.name.toUpperCase()} (Active)'
                        : f.name.toUpperCase(),
                  ),
                  selected: isSelected,
                  selectedColor: colors.streakAmber,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 11,
                  ),
                  backgroundColor: colors.cardBgSecondary,
                  side: BorderSide(
                    color: isSelected
                        ? colors.streakAmber
                        : colors.borderSubtle,
                  ),
                  onSelected: (_) {
                    final updated = _currentBook.copyWith(format: f);
                    setState(() => _currentBook = updated);
                    _updateBook();
                    FormatAndDocumentsSheet.show(
                      context,
                      book: updated,
                      initialFormat: f,
                    );
                  },
                );
              })
              .toList(),
        ),

        if (_currentBook.format == BookFormat.pdf ||
            _currentBook.format == BookFormat.epub) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final bool hasEpubAttached =
                  _currentBook.format == BookFormat.epub &&
                  (_currentBook.localFilePath != null &&
                      _currentBook.localFilePath!.isNotEmpty) &&
                  File(_currentBook.localFilePath!).existsSync();

              final bool hasPdfAttached =
                  _currentBook.format == BookFormat.pdf &&
                  (_currentBook.localFilePath != null &&
                      _currentBook.localFilePath!.isNotEmpty) &&
                  File(_currentBook.localFilePath!).existsSync();

              final bool hasDocAttached = hasEpubAttached || hasPdfAttached;

              if (hasDocAttached) {
                final isPdf = _currentBook.format == BookFormat.pdf;
                final filePath = _currentBook.localFilePath!;
                final fileName = filePath.contains('/')
                    ? filePath.split('/').last
                    : filePath.split(Platform.pathSeparator).last;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPdf
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : colors.accentAmethyst.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.collections_bookmark_rounded,
                          color: isPdf
                              ? Colors.redAccent
                              : colors.accentAmethyst,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isPdf
                                  ? 'PDF Document • Attached'
                                  : 'EPUB eBook • Attached',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isPdf) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PdfReaderScreen(book: _currentBook),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EpubReaderScreen(book: _currentBook),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.north_east_rounded, size: 12),
                        label: const Text(
                          'Continue Reading',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.streakAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // When deleted or unattached: hide reading action button completely and display outlined Upload Document button
                final isPdf = _currentBook.format == BookFormat.pdf;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.cardBgSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.streakAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.phonelink_rounded,
                          color: colors.streakAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPdf ? 'No PDF Attached' : 'No EPUB Attached',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Attach document to read inside Bookora',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          FormatAndDocumentsSheet.show(
                            context,
                            book: _currentBook,
                            initialFormat: _currentBook.format,
                          );
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 14),
                        label: const Text(
                          'Upload Document',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.streakAmber,
                          side: BorderSide(
                            color: colors.streakAmber.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  IconData _getFormatIcon(BookFormat f) {
    switch (f) {
      case BookFormat.paperback:
        return Icons.menu_book;
      case BookFormat.audiobook:
        return Icons.headphones;
      case BookFormat.pdf:
        return Icons.picture_as_pdf;
      case BookFormat.epub:
        return Icons.book;
      default:
        return Icons.menu_book;
    }
  }

  Widget _buildTaglineAndBlurbSection(ReadingAppColors colors) {
    final taglineText = _currentBook.effectiveTagline;
    final blurbText = _currentBook.effectiveBlurb;
    final fullSynopsis = _currentBook.description;
    final synopsisContent = fullSynopsis.trim().isNotEmpty
        ? fullSynopsis.trim()
        : blurbText.trim();
    final bool canExpand = synopsisContent.length > 180 ||
        synopsisContent.contains('\n') ||
        (fullSynopsis.length > blurbText.length && fullSynopsis != blurbText);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: colors.streakAmber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“$taglineText”',
                    style: GoogleFonts.crimsonPro(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    synopsisContent,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                    maxLines: _isSynopsisExpanded ? null : 4,
                    overflow: _isSynopsisExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (canExpand) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(
                          () => _isSynopsisExpanded = !_isSynopsisExpanded,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isSynopsisExpanded ? 'Read less ∧' : 'Read more ∨',
                              style: TextStyle(
                                color: colors.streakAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeAndTropeMeter(ReadingAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.equalizer, color: colors.streakAmber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Vibe & Trope Meter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.quoteGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSegmentedRatingRow(
            label: 'Overall Rating',
            value: _currentBook.overallRating,
            icon: Icons.star_rounded,
            color: const Color(0xFFFFD700),
            colors: colors,
            onChanged: (v) {
              setState(
                () => _currentBook = _currentBook.copyWith(overallRating: v),
              );
              _updateBook();
            },
          ),
          const SizedBox(height: 12),
          _buildSegmentedRatingRow(
            label: 'Spice Level',
            value: _currentBook.spiceRating,
            icon: Icons.whatshot_rounded,
            color: Colors.redAccent,
            colors: colors,
            onChanged: (v) {
              setState(
                () => _currentBook = _currentBook.copyWith(spiceRating: v),
              );
              _updateBook();
            },
          ),
          const SizedBox(height: 12),
          _buildSegmentedRatingRow(
            label: 'Fluff & Warmth',
            value: _currentBook.fluffRating,
            icon: Icons.favorite_rounded,
            color: Colors.pinkAccent,
            colors: colors,
            onChanged: (v) {
              setState(
                () => _currentBook = _currentBook.copyWith(fluffRating: v),
              );
              _updateBook();
            },
          ),
          const SizedBox(height: 12),
          _buildSegmentedRatingRow(
            label: 'Tears & Drama',
            value: _currentBook.tearRating,
            icon: Icons.water_drop_rounded,
            color: Colors.blueAccent,
            colors: colors,
            onChanged: (v) {
              setState(
                () => _currentBook = _currentBook.copyWith(tearRating: v),
              );
              _updateBook();
            },
          ),
          const SizedBox(height: 12),
          _buildSegmentedRatingRow(
            label: 'Humor & Wit',
            value: _currentBook.humorRating,
            icon: Icons.auto_awesome,
            color: Colors.amberAccent,
            colors: colors,
            onChanged: (v) {
              setState(
                () => _currentBook = _currentBook.copyWith(humorRating: v),
              );
              _updateBook();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudiobookLaunchCard(
    ReadingAppColors colors,
    bool isLightMode, {
    required bool hasAudioFileAttached,
  }) {
    return InkWell(
      onTap: () async {
        if (hasAudioFileAttached) {
          if (_currentBook.status != ReadingStatus.currentlyReading) {
            final updated = _currentBook.copyWith(
              status: ReadingStatus.currentlyReading,
              startDate: _currentBook.startDate ?? DateTime.now(),
            );
            await ref.read(booksProvider.notifier).updateBook(updated);
          }
          ref
              .read(audiobookPlayerProvider.notifier)
              .loadAndPlay(_currentBook, audioPath: _currentBook.localFilePath);
          if (mounted) {
            FullScreenAudioPlayerSheet.show(context);
          }
        } else {
          FormatAndDocumentsSheet.show(
            context,
            book: _currentBook,
            initialFormat: BookFormat.audiobook,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasAudioFileAttached
              ? (isLightMode
                    ? const Color(0xFFB45309)
                    : const Color(0xFFF59E0B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLightMode
                ? const Color(0xFFB45309)
                : const Color(0xFFF59E0B),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasAudioFileAttached
                  ? Icons.play_arrow_rounded
                  : Icons.upload_file_rounded,
              color: hasAudioFileAttached
                  ? (isLightMode ? Colors.white : const Color(0xFF1E1712))
                  : (isLightMode
                        ? const Color(0xFFB45309)
                        : const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 8),
            Text(
              hasAudioFileAttached ? 'Play Audiobook' : 'Upload Audiobook File',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hasAudioFileAttached
                    ? (isLightMode ? Colors.white : const Color(0xFF1E1712))
                    : (isLightMode
                          ? const Color(0xFFB45309)
                          : const Color(0xFFF59E0B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedRatingRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ReadingAppColors colors,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: List.generate(5, (index) {
                  final fill = (value - index).clamp(0.0, 1.0);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged((index + 1).toDouble()),
                      child: Container(
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: fill > 0
                              ? color.withValues(alpha: 0.2 + (fill * 0.8))
                              : colors.borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${value.toStringAsFixed(1)}/5',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuotesTab(ReadingAppColors colors) {
    final uniqueQuotesMap = <String, QuoteAnnotation>{};
    for (var q in _currentBook.quotes) {
      uniqueQuotesMap[q.id] = q;
    }
    final quotesList = uniqueQuotesMap.values.toList();

    if (quotesList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.format_quote, size: 48, color: colors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'No quotes or annotations saved yet.',
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddQuoteDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add First Quote & Annotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.streakAmber,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...quotesList.map((quote) => _buildQuoteCard(quote, colors)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showAddQuoteDialog,
                icon: const Icon(Icons.format_quote),
                label: const Text('Add Quote & Annotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.cardBg,
                  foregroundColor: colors.streakAmber,
                  side: BorderSide(color: colors.streakAmber),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(QuoteAnnotation quote, ReadingAppColors colors) {
    return Card(
      color: colors.cardBg,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, color: colors.streakAmber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '“${quote.quoteText}”',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: colors.quoteGold,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _confirmDeleteQuote(quote.id),
                ),
              ],
            ),
            if (quote.note != null && quote.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                quote.note!,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
            ],
            if (quote.pageNumber > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.cardBgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pg. ${quote.pageNumber}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBook() async {
    final confirm = await BookoraNotificationService.showConfirmationDialog(
      context,
      type: ConfirmationType.removeBook,
      title: 'Remove Book?',
      message: 'Remove "${_currentBook.title}" from your library?',
      onConfirm: () {}, // Handled below in if(confirm == true)
    );

    if (confirm == true) {
      await ref.read(bookProvider.notifier).deleteBook(_currentBook.id);
      if (mounted) {
        Navigator.pop(context);
        BookoraNotificationService.showSuccessModal(
          context,
          title: 'Book Removed',
          message:
              '"${_currentBook.title}" has been removed from your library.',
          coverUrl: _currentBook.coverUrl,
        );
      }
    }
  }

  Future<void> _confirmDeleteQuote(String quoteId) async {
    final confirm = await BookoraNotificationService.showConfirmationDialog(
      context,
      type: ConfirmationType.removeQuote,
      title: 'Remove Quote?',
      message: 'Remove this quote from the book?',
      onConfirm: () {}, // Handled below
    );

    if (confirm == true) {
      await ref
          .read(bookProvider.notifier)
          .deleteQuote(_currentBook.id, quoteId);
      final updatedQuotes = _currentBook.quotes
          .where((q) => q.id != quoteId)
          .toList();
      final updatedBook = _currentBook.copyWith(quotes: updatedQuotes);
      setState(() {
        _currentBook = updatedBook;
      });
      ref.read(bookRepositoryProvider).updateBook(updatedBook);
      if (mounted) {
        BookoraNotificationService.showToast(
          context,
          type: NotificationType.info,
          title: 'Quote removed',
        );
      }
    }
  }

  void _showAddQuoteDialog() {
    AddQuoteDialog.show(
      context,
      initialPage: _currentBook.currentPage,
      onSave: (quote) async {
        await ref.read(bookProvider.notifier).addQuote(_currentBook.id, quote);
        if (mounted) {
          BookoraNotificationService.showToast(
            context,
            type: NotificationType.added,
            title: 'Quote added to book!',
          );
        }
      },
    );
  }

  Widget _buildMultiGenreTags(List<String> genres, BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A221B) : const Color(0xFFF0EBE1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3E3228) : const Color(0xFFE2D9CC),
            ),
          ),
          child: Text(
            genre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: isDark ? const Color(0xFFD4C7B8) : const Color(0xFF5A4634),
            ),
          ),
        );
      }).toList(),
    );
  }
}
