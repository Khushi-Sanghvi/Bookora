import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../providers/book_provider.dart';
import '../services/epub_service.dart';
import '../theme/reading_app_colors.dart';
import '../widgets/add_quote_dialog.dart';
import '../widgets/epub_webview_reader.dart';
import '../widgets/format_and_documents_sheet.dart';
import '../services/bookora_dialog_service.dart';
import '../services/reading_status_resolver.dart';
import '../services/toc_sync_service.dart';

enum EpubPaperTheme { parchment, sepia, emerald, celestial, romance, pureDark, cleanWhite }

class EpubReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  const EpubReaderScreen({super.key, required this.book});

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  final GlobalKey<EpubWebviewReaderState> _webviewKey = GlobalKey<EpubWebviewReaderState>();
  bool _showControls = true;
  bool _useWebview = true;
  bool _swipeHorizontal = false;
  late int _totalPages;
  late int _currentPage;
  final Set<int> _bookmarkedPages = {};
  DateTime? _startDate;
  DateTime? _finishDate;
  Timer? _debounceTimer;

  EpubBookData? _epubData;
  int _currentChapterIndex = 0;
  bool _isLoadingEpub = false;
  PageController? _epubPageController;

  double _readerFontSize = 16.5;
  double _readerLineHeight = 1.65;
  EpubPaperTheme _paperTheme = EpubPaperTheme.parchment;
  String _activeSoundscape = 'Quiet Library 📖';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 300;
    _startDate = widget.book.startDate ?? DateTime.now();
    _finishDate = widget.book.finishDate;

    _loadEpubContent();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _epubPageController?.dispose();
    _epubPageController = null;
    super.dispose();
  }

  Book get _currentBook {
    try {
      final books = ref.read(booksProvider).value;
      if (books != null) {
        return books.firstWhere(
          (b) => b.id == widget.book.id,
          orElse: () => widget.book,
        );
      }
    } catch (_) {}
    return widget.book;
  }

  bool get _hasValidEpubFile {
    final book = _currentBook;
    final path = book.epubFilePath ?? book.localFilePath;
    if (path == null || path.trim().isEmpty) return false;
    return path.toLowerCase().endsWith('.epub') && File(path).existsSync();
  }

  Future<void> _loadEpubContent() async {
    final book = _currentBook;
    final path = book.epubFilePath ?? book.localFilePath;
    if (path == null || path.trim().isEmpty || !File(path).existsSync()) return;
    setState(() => _isLoadingEpub = true);
    final data = await EpubService().parseEpub(path);
    if (mounted) {
      final initialIdx = (data != null && data.chapters.isNotEmpty)
          ? (_currentPage / 15).floor().clamp(0, data.chapters.length - 1)
          : 0;

      setState(() {
        _epubData = data;
        _isLoadingEpub = false;
        _currentChapterIndex = initialIdx;
        _epubPageController = PageController(initialPage: initialIdx);
        if (data != null && data.chapters.isNotEmpty) {
          _totalPages = data.chapters.length * 15;
        }
      });
    }
  }

  void _debounceProgressUpdate(int page) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final pagesReadDelta = max(0, page - widget.book.currentPage);
      final effectiveTotal = _totalPages > 0 ? _totalPages : widget.book.totalPages;

      final transition = ReadingStatusResolver.evaluateStatusTransition(
        currentStatus: widget.book.status,
        currentPage: page,
        totalPages: effectiveTotal,
        existingStartDate: _startDate,
        existingFinishDate: _finishDate,
      );

      setState(() {
        _startDate = transition.startDate;
        _finishDate = transition.finishDate;
      });

      List<JournalEntry> updatedJournal = List.from(widget.book.journalEntries);
      if (pagesReadDelta > 0) {
        final today = DateTime.now();
        final todayIdx = updatedJournal.indexWhere((e) =>
          e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
        );
        if (todayIdx != -1) {
          final existing = updatedJournal[todayIdx];
          updatedJournal[todayIdx] = JournalEntry(
            id: existing.id,
            date: existing.date,
            pagesRead: existing.pagesRead + pagesReadDelta,
            reflection: existing.reflection,
          );
        } else {
          updatedJournal.add(JournalEntry.create(pagesReadDelta));
        }
      }

      final updatedBook = widget.book.copyWith(
        currentPage: page,
        totalPages: effectiveTotal,
        status: transition.status,
        startDate: transition.startDate,
        finishDate: transition.finishDate,
        journalEntries: updatedJournal,
      );
      ref.read(bookProvider.notifier).updateBook(updatedBook);

      if (transition.status == ReadingStatus.finished && widget.book.status != ReadingStatus.finished) {
        if (mounted) {
          BookoraDialogService.showSuccessToast(context, message: '🎉 Finished "${widget.book.title}"!');
        }
      }
    });
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final colors = context.appColors;
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_finishDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.streakAmber,
              onPrimary: Colors.black,
              surface: colors.cardBg,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.scaffoldBg),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _finishDate = picked;
        }
      });

      final updatedBook = widget.book.copyWith(
        currentPage: _currentPage,
        totalPages: _totalPages > 0 ? _totalPages : widget.book.totalPages,
        startDate: _startDate,
        finishDate: _finishDate,
      );
      ref.read(bookProvider.notifier).updateBook(updatedBook);

      if (mounted) {
        BookoraDialogService.showDateUpdatedSnackBar(
          context,
          dateText: DateFormat('MMM d, yyyy').format(picked),
          isStart: isStartDate,
        );
      }
    }
  }

  List<TocItem> get _tocItemList {
    if (_epubData == null) return [];
    return _epubData!.chapters
        .map((ch) => TocItem(title: ch.title, pageIndex: ch.pageOffset, anchor: ch.anchor))
        .toList();
  }

  void _showChapterTocSheet() {
    if (_epubData == null || _epubData!.chapters.isEmpty) return;
    final colors = context.appColors;
    final activeTocItem = TocSyncService.resolveActiveChapter(
      currentPage: _currentChapterIndex,
      tocItems: _tocItemList,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Table of Contents',
                    style: GoogleFonts.playfairDisplay(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _epubData!.chapters.length,
                  separatorBuilder: (context, index) => Divider(color: colors.borderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final chapter = _epubData!.chapters[index];
                    final isSelected = chapter.title == activeTocItem.title && chapter.pageOffset == activeTocItem.pageIndex;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        isSelected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSelected ? colors.streakAmber : colors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        chapter.title,
                        style: TextStyle(
                          color: isSelected ? colors.streakAmber : colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Chapter ${index + 1}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.streakAmber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color: colors.streakAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _currentChapterIndex = chapter.pageOffset;
                          _currentPage = chapter.pageOffset * 15;
                        });
                        if (_useWebview) {
                          _webviewKey.currentState?.jumpToChapter(
                            chapter.pageOffset,
                            anchor: chapter.anchor,
                          );
                        } else {
                          _epubPageController?.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        _debounceProgressUpdate(_currentPage);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontAndAppearanceSheet() {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.text_fields_rounded, color: colors.streakAmber),
                      const SizedBox(width: 8),
                      Text(
                        'Typography & Paper Aesthetics',
                        style: GoogleFonts.playfairDisplay(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Reading Layout:',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.cardBgSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() => _swipeHorizontal = true);
                              setSheetState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                (_webviewKey.currentState as dynamic)?.jumpToChapter(_currentChapterIndex);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _swipeHorizontal ? colors.streakAmber : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_horiz_rounded, size: 18, color: _swipeHorizontal ? Colors.black : colors.textPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Horizontal Flip',
                                    style: TextStyle(
                                      fontWeight: _swipeHorizontal ? FontWeight.bold : FontWeight.normal,
                                      color: _swipeHorizontal ? Colors.black : colors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() => _swipeHorizontal = false);
                              setSheetState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                (_webviewKey.currentState as dynamic)?.jumpToChapter(_currentChapterIndex);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_swipeHorizontal ? colors.streakAmber : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_vert_rounded, size: 18, color: !_swipeHorizontal ? Colors.black : colors.textPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Vertical Scroll',
                                    style: TextStyle(
                                      fontWeight: !_swipeHorizontal ? FontWeight.bold : FontWeight.normal,
                                      color: !_swipeHorizontal ? Colors.black : colors.textPrimary,
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Font Size:',
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded, color: colors.streakAmber),
                        onPressed: () {
                          if (_readerFontSize > 13.0) {
                            setState(() => _readerFontSize -= 1.0);
                            setSheetState(() {});
                          }
                        },
                      ),
                      Text(
                        '${_readerFontSize.toInt()} pt',
                        style: TextStyle(color: colors.quoteGold, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: colors.streakAmber),
                        onPressed: () {
                          if (_readerFontSize < 26.0) {
                            setState(() => _readerFontSize += 1.0);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        'Line Spacing:',
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildLineHeightChip(colors, setSheetState, '1.5x', 1.50),
                          _buildLineHeightChip(colors, setSheetState, '1.65x', 1.65),
                          _buildLineHeightChip(colors, setSheetState, '1.8x', 1.80),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Paper Color & Ink Tint:',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaperThemeChoiceChip(colors, setSheetState, '📜 Parchment', EpubPaperTheme.parchment, const Color(0xFFF7F3E9), const Color(0xFF2C241E)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '☕ Sepia', EpubPaperTheme.sepia, const Color(0xFFEFE3D3), const Color(0xFF3A2A1A)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '🌿 Emerald', EpubPaperTheme.emerald, const Color(0xFF10281F), const Color(0xFFE0F2E9)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '🌌 Celestial', EpubPaperTheme.celestial, const Color(0xFF181930), const Color(0xFFE8EAF6)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '🌸 Rose Quartz', EpubPaperTheme.romance, const Color(0xFFFDF0ED), const Color(0xFF381A1A)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '📄 Pure Dark', EpubPaperTheme.pureDark, const Color(0xFF121212), const Color(0xFFE5E5E5)),
                      _buildPaperThemeChoiceChip(colors, setSheetState, '☀️ Clean White', EpubPaperTheme.cleanWhite, const Color(0xFFFFFFFF), const Color(0xFF1A1A1A)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
      },
    );
  }

  Widget _buildPaperThemeChoiceChip(ReadingAppColors colors, StateSetter setSheetState, String label, EpubPaperTheme theme, Color bg, Color text) {
    final isSelected = _paperTheme == theme;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: bg, radius: 6),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (_) {
        setState(() => _paperTheme = theme);
        setSheetState(() {});
      },
    );
  }

  Widget _buildLineHeightChip(ReadingAppColors colors, StateSetter setSheetState, String label, double height) {
    final isSelected = (_readerLineHeight - height).abs() < 0.05;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.black : colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (_) {
        setState(() => _readerLineHeight = height);
        setSheetState(() {});
      },
    );
  }

  void _showSoundscapesSheet() {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.scaffoldBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: colors.streakAmber),
                      const SizedBox(width: 8),
                      Text(
                        'Cozy Reading Soundscapes',
                        style: GoogleFonts.playfairDisplay(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSoundscapeOption(colors, setSheetState, 'Quiet Library 📖', 'Subtle, peaceful reading room atmosphere'),
                  _buildSoundscapeOption(colors, setSheetState, 'Cozy Rain on Window 🌧️', 'Gentle raindrops pattering on glass'),
                  _buildSoundscapeOption(colors, setSheetState, 'Flickering Fireplace 🕯️', 'Warm crackling wood fire ambiance'),
                  _buildSoundscapeOption(colors, setSheetState, 'Coffeehouse Jazz ☕', 'Soft background acoustic coffeehouse'),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSoundscapeOption(ReadingAppColors colors, StateSetter setSheetState, String name, String subtitle) {
    final isSelected = _activeSoundscape == name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? colors.streakAmber : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colors.streakAmber)
          : Icon(Icons.circle_outlined, color: colors.textSecondary),
      onTap: () {
        setState(() => _activeSoundscape = name);
        setSheetState(() {});
        Navigator.pop(context);
        BookoraDialogService.showAmbianceSwitchedSnackBar(context, ambianceName: name);
      },
    );
  }

  void _showPageProgressDialog() {
    final colors = context.appColors;
    final pageController = TextEditingController(text: '${_currentPage + 1}');
    final totalPagesController = TextEditingController(text: '$_totalPages');
    bool logAsJournalSession = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.borderSubtle),
            ),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: colors.streakAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Page & Progress Settings',
                    style: GoogleFonts.playfairDisplay(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Jump to Page / Position',
                      labelStyle: TextStyle(color: colors.streakAmber),
                      prefixIcon: Icon(Icons.menu_book_rounded, color: colors.streakAmber),
                      filled: true,
                      fillColor: colors.cardBgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.streakAmber)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalPagesController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Total Pages / Units',
                      labelStyle: TextStyle(color: colors.streakAmber),
                      prefixIcon: Icon(Icons.auto_stories_rounded, color: colors.streakAmber),
                      filled: true,
                      fillColor: colors.cardBgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.streakAmber)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text('Log pages read in daily session', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    value: logAsJournalSession,
                    activeColor: colors.streakAmber,
                    checkColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setDialogState(() {
                        logAsJournalSession = val ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.streakAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final targetPageDisplay = int.tryParse(pageController.text) ?? (_currentPage + 1);
                  final targetTotalPages = int.tryParse(totalPagesController.text) ?? _totalPages;

                  final newCurrentPage = (targetPageDisplay - 1).clamp(0, max(0, targetTotalPages - 1)).toInt();
                  final pagesReadDelta = max(0, newCurrentPage - _currentPage);

                  setState(() {
                    _currentPage = newCurrentPage;
                    _totalPages = targetTotalPages;
                  });

                  if (_epubData != null && _epubData!.pages.isNotEmpty) {
                    final targetCh = (newCurrentPage / 15).floor().clamp(0, _epubData!.pages.length - 1);
                    if (_useWebview) {
                      (_webviewKey.currentState as dynamic)?.jumpToChapter(targetCh);
                    } else {
                      _epubPageController?.animateToPage(
                        targetCh,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }

                  final transition = ReadingStatusResolver.evaluateStatusTransition(
                    currentStatus: widget.book.status,
                    currentPage: newCurrentPage,
                    totalPages: targetTotalPages,
                    existingStartDate: _startDate,
                    existingFinishDate: _finishDate,
                  );

                  setState(() {
                    _startDate = transition.startDate;
                    _finishDate = transition.finishDate;
                  });

                  final updatedBook = widget.book.copyWith(
                    currentPage: newCurrentPage,
                    totalPages: targetTotalPages,
                    startDate: transition.startDate,
                    finishDate: transition.finishDate,
                    status: transition.status,
                  );
                  ref.read(bookProvider.notifier).updateBook(updatedBook);

                  if (logAsJournalSession && pagesReadDelta > 0) {
                    final entry = JournalEntry.create(pagesReadDelta);
                    ref.read(bookProvider.notifier).addJournalEntry(widget.book.id, entry);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    BookoraDialogService.showTotalPagesUpdatedToast(context, totalPages: targetTotalPages);
                  }
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(booksProvider);
    final colors = context.appColors;
    final progressPercent = _totalPages > 0 ? ((_currentPage + 1) / _totalPages).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 8.0,
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              'by ${widget.book.author}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(
              _swipeHorizontal ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
              color: colors.streakAmber,
              size: 20,
            ),
            tooltip: _swipeHorizontal ? 'Switch to Vertical Continuous Scroll' : 'Switch to Horizontal Chapter Flip',
            onPressed: () {
              setState(() {
                _swipeHorizontal = !_swipeHorizontal;
              });
              if (_swipeHorizontal) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_epubPageController?.hasClients == true) {
                    _epubPageController?.jumpToPage(_currentChapterIndex);
                  }
                });
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  (_webviewKey.currentState as dynamic)?.jumpToChapter(_currentChapterIndex);
                });
              }
            },
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber, size: 20),
            tooltip: 'Table of Contents',
            onPressed: _showChapterTocSheet,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(Icons.text_fields_rounded, color: colors.streakAmber, size: 20),
            tooltip: 'Typography & Paper Theme',
            onPressed: _showFontAndAppearanceSheet,
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(Icons.more_vert_rounded, color: colors.streakAmber, size: 20),
            color: colors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'soundscapes') {
                _showSoundscapesSheet();
              } else if (value == 'quote') {
                AddQuoteDialog.show(
                  context,
                  initialPage: _currentPage + 1,
                  onSave: (quote) {
                    ref.read(bookProvider.notifier).addQuote(widget.book.id, quote);
                    BookoraDialogService.showQuoteSavedSnackBar(context);
                  },
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'soundscapes',
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 10),
                    Text('Reading Soundscapes', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quote',
                child: Row(
                  children: [
                    Icon(Icons.format_quote_rounded, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 10),
                    Text('Add Quote / Note', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showPageProgressDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 12.0, left: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.cardBgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.streakAmber.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colors.streakAmber),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: TextStyle(color: colors.quoteGold, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasValidEpubFile)
            _buildEpubPagedReaderView(colors, progressPercent)
          else
            _buildNoEpubFileView(colors),

          // Bottom Floating Reading Progress Bar Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: colors.scaffoldBg.withValues(alpha: 0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 4,
                    backgroundColor: colors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () => _pickDate(isStartDate: true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.cardBgSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.play_circle_outline_rounded, size: 14, color: colors.streakAmber),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _startDate != null ? 'Start: ${DateFormat('MMM d').format(_startDate!)}' : 'Start Date',
                                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: InkWell(
                            onTap: () => _pickDate(isStartDate: false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.cardBgSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 14, color: colors.accentSage),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _finishDate != null ? 'End: ${DateFormat('MMM d').format(_finishDate!)}' : 'End Date',
                                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.edit_note_rounded, color: colors.streakAmber, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _showPageProgressDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Photorealistic Hardcover Print Book Page Reader View with Ribbons & Fleurons ---
  Widget _buildEpubPagedReaderView(ReadingAppColors colors, double progressPercent) {
    if (_isLoadingEpub) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.streakAmber),
            const SizedBox(height: 16),
            Text(
              'Unpacking & Loading eBook pages...',
              style: TextStyle(color: colors.quoteGold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (_epubData == null || _epubData!.chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: colors.streakAmber, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to extract text from EPUB file.',
                style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => FormatAndDocumentsSheet.show(context, book: widget.book, initialFormat: BookFormat.epub),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Re-upload EPUB File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.streakAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color pageBgColor;
    Color inkTextColor;

    switch (_paperTheme) {
      case EpubPaperTheme.parchment:
        pageBgColor = const Color(0xFFF7F3E9);
        inkTextColor = const Color(0xFF2C241E);
        break;
      case EpubPaperTheme.sepia:
        pageBgColor = const Color(0xFFEFE3D3);
        inkTextColor = const Color(0xFF3A2A1A);
        break;
      case EpubPaperTheme.emerald:
        pageBgColor = const Color(0xFF10281F);
        inkTextColor = const Color(0xFFE0F2E9);
        break;
      case EpubPaperTheme.celestial:
        pageBgColor = const Color(0xFF181930);
        inkTextColor = const Color(0xFFE8EAF6);
        break;
      case EpubPaperTheme.romance:
        pageBgColor = const Color(0xFFFDF0ED);
        inkTextColor = const Color(0xFF381A1A);
        break;
      case EpubPaperTheme.pureDark:
        pageBgColor = const Color(0xFF121212);
        inkTextColor = const Color(0xFFE5E5E5);
        break;
      case EpubPaperTheme.cleanWhite:
        pageBgColor = const Color(0xFFFFFFFF);
        inkTextColor = const Color(0xFF1A1A1A);
        break;
    }

    final activeTocItem = TocSyncService.resolveActiveChapter(
      currentPage: _currentChapterIndex,
      tocItems: _tocItemList,
    );
    final activeChapterTitle = activeTocItem.title;

    if (_useWebview) {
      return Stack(
        children: [
          // Bookora Webview Reader Engine
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 75),
            child: EpubWebviewReader(
              key: _webviewKey,
              epubData: _epubData!,
              initialChapterIndex: _currentChapterIndex,
              initialScrollAlignment: 0.0,
              fontSize: _readerFontSize,
              lineHeight: _readerLineHeight,
              textColor: inkTextColor,
              backgroundColor: pageBgColor,
              isHorizontal: _swipeHorizontal,
              onError: (err) {
                if (mounted) {
                  setState(() {
                    _useWebview = false;
                  });
                }
              },
              onChapterChanged: (idx) {
                if (mounted) {
                  final isFinalChapter = _epubData != null &&
                      _epubData!.chapters.isNotEmpty &&
                      idx >= _epubData!.chapters.length - 1;
                  setState(() {
                    _currentChapterIndex = idx;
                    _currentPage = isFinalChapter ? _totalPages : idx * 15;
                  });
                  if (isFinalChapter) {
                    ref.read(booksProvider.notifier).markBookCompleted(bookId: widget.book.id);
                  } else {
                    _debounceProgressUpdate(_currentPage);
                  }
                }
              },
              onScrollProgress: (chIdx, fraction) {
                if (mounted && _totalPages > 0) {
                  final totalProgressPages = ((chIdx + fraction) * 15).round();
                  final isFinalChapter = _epubData != null &&
                      _epubData!.chapters.isNotEmpty &&
                      chIdx >= _epubData!.chapters.length - 1;
                  if (isFinalChapter && fraction >= 0.99) {
                    ref.read(booksProvider.notifier).markBookCompleted(bookId: widget.book.id);
                  } else if ((totalProgressPages - _currentPage).abs() > 2) {
                    setState(() {
                      _currentPage = totalProgressPages.clamp(0, _totalPages - 1);
                    });
                    _debounceProgressUpdate(_currentPage);
                  }
                }
              },
              onTap: () {
                if (mounted) {
                  setState(() {
                    _showControls = !_showControls;
                  });
                }
              },
            ),
          ),

          // Floating Top Right Chapter Capsule Pill
          if (_showControls)
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: _showChapterTocSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.cardBg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.streakAmber.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.collections_bookmark_outlined, size: 12, color: colors.streakAmber),
                      const SizedBox(width: 6),
                      Text(
                        '$activeChapterTitle • ${(progressPercent * 100).toInt()}%',
                        style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Interactive Ribbon Bookmark
          Positioned(
            top: 0,
            right: 155,
            child: GestureDetector(
              onTap: () {
                final isBookmarked = _bookmarkedPages.contains(_currentPage);
                final willBookmark = !isBookmarked;
                setState(() {
                  if (isBookmarked) {
                    _bookmarkedPages.remove(_currentPage);
                  } else {
                    _bookmarkedPages.add(_currentPage);
                  }
                });
                if (willBookmark) {
                  BookoraDialogService.showBookmarkSavedToast(context, pageNum: _currentPage + 1);
                } else {
                  BookoraDialogService.showBookmarkRemovedSnackBar(context);
                }
              },
              child: Container(
                width: 22,
                height: _bookmarkedPages.contains(_currentPage) ? 48 : 30,
                decoration: BoxDecoration(
                  color: _bookmarkedPages.contains(_currentPage) ? const Color(0xFFB81D1D) : colors.streakAmber.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(1, 2)),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _bookmarkedPages.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Fallback: Pure Flutter Paged Reader View when webview is disabled or unregistered
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 70),
          child: Container(
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: colors.streakAmber.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: PageView.builder(
              controller: _epubPageController,
              scrollDirection: _swipeHorizontal ? Axis.horizontal : Axis.vertical,
              itemCount: _epubData!.chapters.length,
              onPageChanged: (idx) {
                final isFinalChapter = _epubData != null &&
                    _epubData!.chapters.isNotEmpty &&
                    idx >= _epubData!.chapters.length - 1;
                setState(() {
                  _currentChapterIndex = idx;
                  _currentPage = isFinalChapter ? _totalPages : idx * 15;
                });
                if (isFinalChapter) {
                  ref.read(booksProvider.notifier).markBookCompleted(bookId: widget.book.id);
                } else {
                  _debounceProgressUpdate(_currentPage);
                }
              },
              itemBuilder: (context, idx) {
                final chapter = _epubData!.chapters[idx];
                final rawContent = chapter.content;

                final rawText = rawContent
                    .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '')
                    .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '')
                    .replaceAll(RegExp(r'<\/(?:p|div|h[1-6]|li|blockquote)>\s*', caseSensitive: false), '\n\n')
                    .replaceAll(RegExp(r'<br\s*\/?>\s*', caseSensitive: false), '\n')
                    .replaceAll(RegExp(r'<[^>]*>'), ' ')
                    .replaceAll('&nbsp;', ' ')
                    .replaceAll('&quot;', '"')
                    .replaceAll('&#39;', "'")
                    .replaceAll('&amp;', '&')
                    .trim();

                final paragraphs = rawText
                    .split(RegExp(r'\n+'))
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty && !l.startsWith('@page') && !l.startsWith('@font-face') && !l.startsWith('{'))
                    .toList();

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: pageBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                chapter.title.toUpperCase(),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colors.streakAmber,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (chapter.imagePaths.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...chapter.imagePaths.map((imgPath) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 450),
                                        child: Image.file(
                                          File(imgPath),
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => const SizedBox(),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                            ],

                            if (paragraphs.isNotEmpty) ...[
                              _buildFirstParagraphWithDropCap(paragraphs.first, inkTextColor, colors.streakAmber),
                              ...paragraphs.skip(1).map((pText) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '      $pText',
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.crimsonPro(
                                      fontSize: _readerFontSize,
                                      height: _readerLineHeight,
                                      color: inkTextColor,
                                    ),
                                  ),
                                );
                              }),
                            ],

                            const SizedBox(height: 24),
                            Center(
                              child: Text('❦', style: TextStyle(color: colors.streakAmber, fontSize: 18)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (_showControls)
          Positioned(
            top: 12,
            right: 16,
            child: GestureDetector(
              onTap: _showChapterTocSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.cardBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.streakAmber.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.collections_bookmark_outlined, size: 12, color: colors.streakAmber),
                    const SizedBox(width: 6),
                    Text(
                      '$activeChapterTitle • ${(progressPercent * 100).toInt()}%',
                      style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFirstParagraphWithDropCap(String paragraphText, Color inkTextColor, Color headerGoldColor) {
    final clean = paragraphText.trim();
    if (clean.isEmpty) return const SizedBox();

    final firstLetter = clean[0].toUpperCase();
    final isAlpha = RegExp(r'[a-zA-Z]').hasMatch(firstLetter);

    if (!isAlpha || clean.length < 5) {
      return Text(
        clean,
        textAlign: TextAlign.justify,
        style: GoogleFonts.crimsonPro(
          fontSize: _readerFontSize,
          height: 1.75,
          color: inkTextColor,
        ),
      );
    }

    final remainingText = clean.length > 1 ? clean.substring(1) : '';

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: [
          TextSpan(
            text: firstLetter,
            style: GoogleFonts.playfairDisplay(
              fontSize: _readerFontSize * 2.8,
              fontWeight: FontWeight.bold,
              color: headerGoldColor,
              height: 0.9,
            ),
          ),
          TextSpan(
            text: remainingText,
            style: GoogleFonts.crimsonPro(
              fontSize: _readerFontSize,
              height: 1.75,
              color: inkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEpubFileView(ReadingAppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded, size: 64, color: colors.streakAmber),
            const SizedBox(height: 16),
            Text(
              'No EPUB File Attached',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload an .epub eBook file in book setup to read directly in Bookora.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                FormatAndDocumentsSheet.show(context, book: widget.book, initialFormat: BookFormat.epub);
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload EPUB eBook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.streakAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
