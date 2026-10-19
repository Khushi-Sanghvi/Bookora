import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../providers/book_provider.dart';
import '../services/epub_service.dart';
import '../widgets/add_quote_dialog.dart';
import '../widgets/format_and_documents_sheet.dart';
import '../services/bookora_dialog_service.dart';
import '../services/reading_status_resolver.dart';
import '../widgets/book_metadata_summary_bar.dart';
import '../providers/audiobook_provider.dart';
import '../widgets/full_screen_audio_player_sheet.dart';
import '../widgets/reader_story_overview_modal.dart';

enum EpubPaperTheme { parchment, emerald, celestial, romance, sepia, pureWhite }

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _totalPages;
  late int _currentPage;
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _isReady = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  PDFViewController? _pdfViewController;

  EpubBookData? _epubData;
  int _currentChapterIndex = 0;
  bool _isLoadingEpub = false;
  PageController? _epubPageController;

  double _readerFontSize = 16.5;
  EpubPaperTheme _paperTheme = EpubPaperTheme.parchment;
  final Set<int> _bookmarkedPages = {};
  String _activeSoundscape = 'Quiet Library 📖';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 300;
    _startDate = widget.book.startDate ?? DateTime.now();
    _finishDate = widget.book.finishDate;

    if (_isEpubFile) {
      _loadEpubContent();
    }

    if (_isAudiobook) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audiobookPlayerProvider.notifier).loadAndPlay(widget.book);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _epubPageController?.dispose();
    _pdfViewController = null;
    super.dispose();
  }

  bool get _isAudiobook {
    if (widget.book.format == BookFormat.audiobook) return true;
    final path = widget.book.localFilePath;
    if (path == null || path.isEmpty) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4b') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a');
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

  bool get _isPdfFile {
    final book = _currentBook;
    final path = book.pdfFilePath ?? book.localFilePath;
    if (path == null || path.isEmpty) return false;
    return (book.format == BookFormat.pdf || path.toLowerCase().endsWith('.pdf')) && File(path).existsSync();
  }

  bool get _isEpubFile {
    final book = _currentBook;
    final path = book.epubFilePath ?? book.localFilePath;
    if (path == null || path.isEmpty) return false;
    return (book.format == BookFormat.epub || path.toLowerCase().endsWith('.epub')) && File(path).existsSync();
  }

  Future<void> _loadEpubContent() async {
    final book = _currentBook;
    final path = book.epubFilePath ?? book.localFilePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) return;
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

  void _onPageChanged(int? page, int? total) {
    if (page != null) {
      setState(() {
        _currentPage = page;
        if (total != null && total > 0 && _totalPages == 0) {
          _totalPages = total;
        }
      });
      final effectiveTotal = (total != null && total > 0)
          ? total
          : (_totalPages > 0 ? _totalPages : widget.book.totalPages);
      if (effectiveTotal > 0 && (page == effectiveTotal || page + 1 >= effectiveTotal)) {
        ref.read(booksProvider.notifier).markBookCompleted(bookId: widget.book.id);
      } else {
        _debounceProgressUpdate(page);
      }
    }
  }

  void _debounceProgressUpdate(int page) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
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

      final updatedBook = widget.book.copyWith(
        currentPage: page,
        totalPages: effectiveTotal,
        status: transition.status,
        startDate: transition.startDate,
        finishDate: transition.finishDate,
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFA726),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1F24),
              onSurface: Colors.white,
            ),
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

      if (isStartDate) {
        final updatedBook = widget.book.copyWith(
          startDate: picked,
        );
        ref.read(bookProvider.notifier).updateBook(updatedBook);
      } else {
        await ref.read(booksProvider.notifier).markBookCompleted(
          bookId: widget.book.id,
          customFinishDate: picked,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isStartDate ? 'Start Date' : 'End Date'} updated to ${DateFormat('MMM d, yyyy').format(picked)}!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[800],
          ),
        );
      }
    }
  }

  void _showChapterTocSheet() {
    if (_epubData == null || _epubData!.chapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
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
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.format_list_bulleted, color: Color(0xFFFFA726)),
                  SizedBox(width: 8),
                  Text('Table of Contents', style: TextStyle(color: Color(0xFFE0A96D), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _epubData!.chapters.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final chapter = _epubData!.chapters[index];
                    final isSelected = index == _currentChapterIndex;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        isSelected ? Icons.bookmark : Icons.bookmark_border,
                        color: isSelected ? const Color(0xFFFFA726) : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        chapter.title,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFFA726) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text('Chapter ${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFFA726).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Text('Active', style: TextStyle(color: Color(0xFFFFA726), fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _currentChapterIndex = index;
                          _currentPage = index * 15;
                        });
                        _epubPageController?.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.text_fields, color: Color(0xFFFFA726)),
                      SizedBox(width: 8),
                      Text('Typography & Paper Aesthetics', style: TextStyle(color: Color(0xFFE0A96D), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text('Font Size:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFFA726)),
                        onPressed: () {
                          if (_readerFontSize > 13.0) {
                            setState(() => _readerFontSize -= 1.0);
                            setSheetState(() {});
                          }
                        },
                      ),
                      Text('${_readerFontSize.toInt()} pt', style: const TextStyle(color: Color(0xFFE0A96D), fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA726)),
                        onPressed: () {
                          if (_readerFontSize < 26.0) {
                            setState(() => _readerFontSize += 1.0);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Paper Color & Ink Tint:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaperThemeChoiceChip(setSheetState, '📜 Parchment', EpubPaperTheme.parchment, const Color(0xFFF7F3E9), const Color(0xFF2C241E)),
                      _buildPaperThemeChoiceChip(setSheetState, '🌿 Emerald', EpubPaperTheme.emerald, const Color(0xFF10281F), const Color(0xFFE0F2E9)),
                      _buildPaperThemeChoiceChip(setSheetState, '🌌 Celestial', EpubPaperTheme.celestial, const Color(0xFF181930), const Color(0xFFE8EAF6)),
                      _buildPaperThemeChoiceChip(setSheetState, '🌸 Rose Quartz', EpubPaperTheme.romance, const Color(0xFFFDF0ED), const Color(0xFF381A1A)),
                      _buildPaperThemeChoiceChip(setSheetState, '☕ Sepia', EpubPaperTheme.sepia, const Color(0xFFEFE3D3), const Color(0xFF3A2A1A)),
                      _buildPaperThemeChoiceChip(setSheetState, '📄 White', EpubPaperTheme.pureWhite, const Color(0xFFFFFFFF), const Color(0xFF1A1A1A)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaperThemeChoiceChip(StateSetter setSheetState, String label, EpubPaperTheme theme, Color bg, Color text) {
    final isSelected = _paperTheme == theme;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: bg, radius: 6),
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: const Color(0xFFFFA726),
      backgroundColor: Colors.black26,
      side: BorderSide(color: isSelected ? const Color(0xFFFFA726) : Colors.white24),
      onSelected: (_) {
        setState(() => _paperTheme = theme);
        setSheetState(() {});
      },
    );
  }

  void _showSoundscapesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
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
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.graphic_eq, color: Color(0xFFFFA726)),
                      SizedBox(width: 8),
                      Text('Cozy Reading Soundscapes', style: TextStyle(color: Color(0xFFE0A96D), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSoundscapeOption(setSheetState, 'Quiet Library 📖', 'Subtle, peaceful reading room atmosphere'),
                  _buildSoundscapeOption(setSheetState, 'Cozy Rain on Window 🌧️', 'Gentle raindrops pattering on glass'),
                  _buildSoundscapeOption(setSheetState, 'Flickering Fireplace 🕯️', 'Warm crackling wood fire ambiance'),
                  _buildSoundscapeOption(setSheetState, 'Coffeehouse Jazz ☕', 'Soft background acoustic coffeehouse'),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSoundscapeOption(StateSetter setSheetState, String name, String subtitle) {
    final isSelected = _activeSoundscape == name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: TextStyle(color: isSelected ? const Color(0xFFFFA726) : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFFFA726)) : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() => _activeSoundscape = name);
        setSheetState(() {});
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched ambiance to $name'), behavior: SnackBarBehavior.floating),
        );
      },
    );
  }

  void _showPageProgressDialog() {
    final pageController = TextEditingController(text: '${_currentPage + 1}');
    final totalPagesController = TextEditingController(text: '$_totalPages');
    bool logAsJournalSession = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1F24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFFFFA726)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Page & Progress Settings',
                    style: const TextStyle(color: Color(0xFFE0A96D), fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Jump to Page / Position',
                      labelStyle: const TextStyle(color: Color(0xFFFFA726)),
                      prefixIcon: const Icon(Icons.menu_book, color: Color(0xFFFFA726)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalPagesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Total Pages / Units',
                      labelStyle: const TextStyle(color: Color(0xFFFFA726)),
                      prefixIcon: const Icon(Icons.auto_stories, color: Color(0xFFFFA726)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Log pages read in daily session', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: logAsJournalSession,
                    activeColor: const Color(0xFFFFA726),
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
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final targetPageDisplay = int.tryParse(pageController.text) ?? (_currentPage + 1);
                  final targetTotalPages = int.tryParse(totalPagesController.text) ?? _totalPages;

                  final newCurrentPage = (targetPageDisplay - 1).clamp(0, max(0, targetTotalPages - 1)).toInt();
                  final pagesReadDelta = max(0, newCurrentPage - _currentPage);

                  setState(() {
                    _currentPage = newCurrentPage;
                    _totalPages = targetTotalPages;
                  });

                  if (_isPdfFile) {
                    _pdfViewController?.setPage(newCurrentPage);
                  } else if (_isEpubFile && _epubData != null && _epubData!.chapters.isNotEmpty) {
                    final targetCh = (newCurrentPage / 15).floor().clamp(0, _epubData!.chapters.length - 1);
                    _epubPageController?.animateToPage(targetCh, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }

                  final updatedBook = widget.book.copyWith(
                    currentPage: newCurrentPage,
                    totalPages: targetTotalPages,
                    startDate: _startDate,
                    finishDate: _finishDate,
                    status: (newCurrentPage + 1 >= targetTotalPages && targetTotalPages > 0)
                        ? ReadingStatus.finished
                        : widget.book.status,
                  );
                  ref.read(bookProvider.notifier).updateBook(updatedBook);

                  if (logAsJournalSession && pagesReadDelta > 0) {
                    final entry = JournalEntry.create(pagesReadDelta);
                    ref.read(bookProvider.notifier).addJournalEntry(widget.book.id, entry);
                  }

                  Navigator.pop(context);
                  BookoraDialogService.showTotalPagesUpdatedToast(context, totalPages: targetTotalPages);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddQuoteDialog() {
    AddQuoteDialog.show(
      context,
      initialPage: _currentPage + 1,
      onSave: (quote) {
        ref.read(bookProvider.notifier).addQuote(widget.book.id, quote);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote & Annotation saved!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final currentBook = booksAsync.whenOrNull(
      data: (books) => books.firstWhere(
        (b) => b.id == widget.book.id,
        orElse: () => widget.book,
      ),
    ) ?? widget.book;

    final bool hasEpubAttached = (currentBook.format == BookFormat.epub ||
            (currentBook.localFilePath != null && currentBook.localFilePath!.toLowerCase().endsWith('.epub'))) &&
        (currentBook.localFilePath != null && currentBook.localFilePath!.isNotEmpty) &&
        File(currentBook.localFilePath!).existsSync();

    final bool hasPdfAttached = (currentBook.format == BookFormat.pdf ||
            (currentBook.localFilePath != null && currentBook.localFilePath!.toLowerCase().endsWith('.pdf'))) &&
        (currentBook.localFilePath != null && currentBook.localFilePath!.isNotEmpty) &&
        File(currentBook.localFilePath!).existsSync();

    ref.listen<AsyncValue<List<Book>>>(booksProvider, (previous, next) {
      next.whenData((books) {
        final updated = books.firstWhere(
          (b) => b.id == widget.book.id,
          orElse: () => widget.book,
        );
        if (mounted) {
          setState(() {
            _startDate = updated.startDate;
            _finishDate = updated.finishDate;
            _totalPages = updated.totalPages > 0 ? updated.totalPages : _totalPages;
            _currentPage = updated.currentPage;
            if (updated.localFilePath == null) {
              _epubData = null;
            }
          });
        }
      });
    });

    final progressPercent = _totalPages > 0 ? ((_currentPage + 1) / _totalPages).clamp(0.0, 1.0) : 0.0;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightMode ? const Color(0xFFF6F0E2) : const Color(0xFF141210),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.crimsonPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE0A96D),
            height: 1.15,
          ),
        ),
        backgroundColor: isLightMode ? const Color(0xFFF6F0E2) : const Color(0xFF141210),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFA726), size: 20),
            tooltip: 'Story Codex & Overview',
            onPressed: () => ReaderStoryOverviewModal.show(context, book: currentBook),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFFA726), size: 22),
            tooltip: 'Reader Options',
            color: isLightMode ? const Color(0xFFFAF7F2) : const Color(0xFF1E1F24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'quote') {
                _showAddQuoteDialog();
              } else if (val == 'progress') {
                _showPageProgressDialog();
              } else if (val == 'soundscapes') {
                _showSoundscapesSheet();
              } else if (val == 'toc') {
                _showChapterTocSheet();
              } else if (val == 'appearance') {
                _showFontAndAppearanceSheet();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'quote',
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, color: Color(0xFFFFA726), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Add Quote / Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLightMode ? const Color(0xFF141210) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isAudiobook && _totalPages > 0)
                PopupMenuItem(
                  value: 'progress',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_border_rounded, color: Color(0xFFFFA726), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Page ${_currentPage + 1}/$_totalPages (${(progressPercent * 100).toInt()}%)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLightMode ? const Color(0xFF141210) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasEpubAttached) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'soundscapes',
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq, color: Color(0xFFFFA726), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Soundscapes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLightMode ? const Color(0xFF141210) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toc',
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted, color: Color(0xFFFFA726), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Table of Contents',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLightMode ? const Color(0xFF141210) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'appearance',
                  child: Row(
                    children: [
                      const Icon(Icons.text_fields, color: Color(0xFFFFA726), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Typography & Theme',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLightMode ? const Color(0xFF141210) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          if (_isAudiobook)
            const FullScreenAudioPlayerSheet()
          else if (hasPdfAttached)
            PDFView(
              key: ValueKey('pdf_${currentBook.id}_${currentBook.localFilePath}'),
              filePath: currentBook.localFilePath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: false,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
              defaultPage: _currentPage,
              onViewCreated: (PDFViewController controller) {
                _pdfViewController = controller;
              },
              onRender: (pages) {
                setState(() {
                  if (pages != null && pages > 0) {
                    _totalPages = pages;
                  }
                  _isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  _errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  _errorMessage = '$page: ${error.toString()}';
                });
              },
              onPageChanged: _onPageChanged,
            )
          else if (hasEpubAttached)
            _buildEpubPagedReaderView(isLightMode, progressPercent)
          else if (currentBook.format == BookFormat.audiobook)
            _buildAudiobookLaunchCard(isLightMode, currentBook)
          else
            _buildNoFileAttachedView(currentBook),

          if (hasPdfAttached && !_isReady && _errorMessage.isEmpty)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFFA726))),

          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Bottom Floating Reading Progress Bar Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: (isLightMode ? const Color(0xFFFAF7F2) : const Color(0xFF1E1F24)).withValues(alpha: 0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _pickDate(isStartDate: true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLightMode ? const Color(0xFFEFE8DD) : Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline, size: 14, color: Color(0xFFFFA726)),
                                const SizedBox(width: 4),
                                Text(
                                  _startDate != null ? 'Start: ${DateFormat('MMM d').format(_startDate!)}' : 'Start Date',
                                  style: TextStyle(color: isLightMode ? Colors.black87 : Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _pickDate(isStartDate: false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLightMode ? const Color(0xFFEFE8DD) : Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flag_outlined, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  _finishDate != null ? 'End: ${DateFormat('MMM d').format(_finishDate!)}' : 'End Date',
                                  style: TextStyle(color: isLightMode ? Colors.black87 : Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Color(0xFFFFA726), size: 22),
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
  Widget _buildEpubPagedReaderView(bool isLightMode, double progressPercent) {
    if (_isLoadingEpub) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFA726)),
            SizedBox(height: 16),
            Text('Unpacking & Loading eBook pages...', style: TextStyle(color: Color(0xFFE0A96D))),
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
              const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to extract text from EPUB file.', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => FormatAndDocumentsSheet.show(context, book: widget.book, initialFormat: BookFormat.epub),
                icon: const Icon(Icons.upload_file),
                label: const Text('Re-upload EPUB File'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726), foregroundColor: Colors.black),
              ),
            ],
          ),
        ),
      );
    }

    Color pageBgColor;
    Color inkTextColor;
    Color headerGoldColor;

    switch (_paperTheme) {
      case EpubPaperTheme.parchment:
        pageBgColor = const Color(0xFFF7F3E9);
        inkTextColor = const Color(0xFF2C241E);
        headerGoldColor = const Color(0xFFC66323);
        break;
      case EpubPaperTheme.emerald:
        pageBgColor = const Color(0xFF10281F);
        inkTextColor = const Color(0xFFE0F2E9);
        headerGoldColor = const Color(0xFF00E676);
        break;
      case EpubPaperTheme.celestial:
        pageBgColor = const Color(0xFF181930);
        inkTextColor = const Color(0xFFE8EAF6);
        headerGoldColor = const Color(0xFFBA68C8);
        break;
      case EpubPaperTheme.romance:
        pageBgColor = const Color(0xFFFDF0ED);
        inkTextColor = const Color(0xFF381A1A);
        headerGoldColor = const Color(0xFFD81B60);
        break;
      case EpubPaperTheme.sepia:
        pageBgColor = const Color(0xFFEFE3D3);
        inkTextColor = const Color(0xFF3A2A1A);
        headerGoldColor = const Color(0xFFB8521B);
        break;
      case EpubPaperTheme.pureWhite:
        pageBgColor = const Color(0xFFFFFFFF);
        inkTextColor = const Color(0xFF1A1A1A);
        headerGoldColor = const Color(0xFFBD5818);
        break;
    }

    return Stack(
      children: [
        // Main Hardcover Outer Binding Container
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 70),
          child: Container(
            decoration: BoxDecoration(
              color: isLightMode ? const Color(0xFF2E241E) : const Color(0xFF100E0C),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: headerGoldColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _epubPageController,
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
                      final isBookmarked = _bookmarkedPages.contains(idx);

                      final wordCount = rawContent.split(RegExp(r'\s+')).length;
                      final minutesLeft = max(1, (wordCount / 200).ceil());

                      final rawParagraphs = rawContent
                          .split(RegExp(r'\n+'))
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();

                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: pageBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              // Corner Filigree Frame Accents
                              Positioned(top: 10, left: 14, child: Text('⚜', style: TextStyle(color: headerGoldColor.withValues(alpha: 0.3), fontSize: 14))),
                              Positioned(top: 10, right: 14, child: Text('⚜', style: TextStyle(color: headerGoldColor.withValues(alpha: 0.3), fontSize: 14))),
                              Positioned(bottom: 10, left: 14, child: Text('❖', style: TextStyle(color: headerGoldColor.withValues(alpha: 0.3), fontSize: 12))),
                              Positioned(bottom: 10, right: 14, child: Text('❖', style: TextStyle(color: headerGoldColor.withValues(alpha: 0.3), fontSize: 12))),

                              // 3D Inner Spine Gutter Shadow
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                width: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.22),
                                        Colors.black.withValues(alpha: 0.06),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // 3D Stacked Deckle Paper Edge Shadow
                              Positioned(
                                top: 6,
                                bottom: 6,
                                right: 0,
                                width: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.08),
                                        Colors.black.withValues(alpha: 0.22),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Interactive Ribbon Bookmark
                              Positioned(
                                top: -4,
                                right: 38,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isBookmarked) {
                                        _bookmarkedPages.remove(idx);
                                      } else {
                                        _bookmarkedPages.add(idx);
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isBookmarked ? 'Bookmark removed' : 'Page bookmarked in reading journal!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 22,
                                    height: isBookmarked ? 54 : 32,
                                    decoration: BoxDecoration(
                                      color: isBookmarked ? const Color(0xFFB81D1D) : headerGoldColor.withValues(alpha: 0.5),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(1, 2)),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Main Book Page Content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            widget.book.title.toUpperCase(),
                                            style: GoogleFonts.crimsonPro(
                                              color: inkTextColor.withValues(alpha: 0.4),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '⏳ ~$minutesLeft min read',
                                            style: GoogleFonts.crimsonPro(
                                              color: headerGoldColor.withValues(alpha: 0.7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(height: 1, color: inkTextColor.withValues(alpha: 0.12)),
                                      const SizedBox(height: 18),

                                      // Centered Page Number Header: — 8 / 80 —
                                      Center(
                                        child: Text(
                                          '—  ${idx + 1} / ${_epubData!.chapters.length}  —',
                                          style: GoogleFonts.crimsonPro(
                                            color: inkTextColor.withValues(alpha: 0.5),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Chapter Header / Character Name
                                      Center(
                                        child: Text(
                                          chapter.title.toUpperCase(),
                                          style: GoogleFonts.crimsonPro(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.2,
                                            color: headerGoldColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Paragraph Flow with Drop Cap & First-Line Indents
                                      if (rawParagraphs.isNotEmpty) ...[
                                        _buildFirstParagraphWithDropCap(rawParagraphs.first, inkTextColor, headerGoldColor),
                                        ...rawParagraphs.skip(1).map((pText) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '      $pText',
                                              textAlign: TextAlign.justify,
                                              style: GoogleFonts.crimsonPro(
                                                fontSize: _readerFontSize,
                                                height: 1.75,
                                                color: inkTextColor,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],

                                      // Extracted Embedded Images (Handwritten letters, maps, logos)
                                      if (chapter.imagePaths.isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        ...chapter.imagePaths.map((imgPath) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                File(imgPath),
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => const SizedBox(),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],

                                      // End-of-Chapter Ornamental Fleuron Divider
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(width: 30, height: 0.8, color: headerGoldColor.withValues(alpha: 0.4)),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                child: Text('❦', style: TextStyle(color: headerGoldColor, fontSize: 18)),
                                              ),
                                              Container(width: 30, height: 0.8, color: headerGoldColor.withValues(alpha: 0.4)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Page Jump Controls
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentChapterIndex > 0
                          ? () {
                              final prevIdx = _currentChapterIndex - 1;
                              _epubPageController?.animateToPage(prevIdx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left, size: 16),
                      label: const Text('Prev Page', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        foregroundColor: inkTextColor,
                        side: BorderSide(color: inkTextColor.withValues(alpha: 0.3)),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          'Page ${_currentChapterIndex + 1} of ${_epubData!.chapters.length}',
                          style: TextStyle(color: inkTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _currentChapterIndex < _epubData!.chapters.length - 1
                          ? () {
                              final nextIdx = _currentChapterIndex + 1;
                              _epubPageController?.animateToPage(nextIdx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      label: const Text('Next Chapter', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        foregroundColor: inkTextColor,
                        side: BorderSide(color: inkTextColor.withValues(alpha: 0.3)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating Top Right Chapter Capsule Pill
        Positioned(
          top: 16,
          right: 20,
          child: GestureDetector(
            onTap: _showChapterTocSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.collections_bookmark_outlined, size: 12, color: Color(0xFFFFA726)),
                  const SizedBox(width: 6),
                  Text(
                    '${_epubData!.chapters[_currentChapterIndex].title} • ${(progressPercent * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFFEDE6DD), fontSize: 10, fontWeight: FontWeight.bold),
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
            style: GoogleFonts.crimsonPro(
              fontSize: _readerFontSize * 2.8,
              fontWeight: FontWeight.w900,
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

  // --- No File Attached View ---

  Future<void> _launchAudiobookPlayer(Book currentBook) async {
    final hasAudioFile = currentBook.localFilePath != null && File(currentBook.localFilePath!).existsSync();
    
    if (hasAudioFile) {
      if (currentBook.status != ReadingStatus.currentlyReading) {
        final updated = currentBook.copyWith(
          status: ReadingStatus.currentlyReading,
          startDate: currentBook.startDate ?? DateTime.now(),
        );
        await ref.read(bookProvider.notifier).updateBook(updated);
      }
      ref.read(audiobookPlayerProvider.notifier).loadAndPlay(currentBook, audioPath: currentBook.localFilePath);
      
      if (mounted) {
        FullScreenAudioPlayerSheet.show(context);
      }
    } else {
      FormatAndDocumentsSheet.show(context, book: currentBook, initialFormat: BookFormat.audiobook);
    }
  }

  Widget _buildAudiobookLaunchCard(bool isLightMode, Book currentBook) {
    final hasAudioFile = currentBook.localFilePath != null && File(currentBook.localFilePath!).existsSync();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isLightMode ? const Color(0xFFFAF7F0) : const Color(0xFF1E1712),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLightMode ? const Color(0xFFB45309) : const Color(0xFFD97706).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLightMode ? const Color(0xFFB45309) : const Color(0xFFD97706)).withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: 64,
              color: isLightMode ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 24),
            Text(
              'Audiobook Format',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isLightMode ? const Color(0xFF2A2017) : const Color(0xFFF8F4EC),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasAudioFile 
                ? 'Your audio file is securely attached and ready to play.'
                : 'No audio file attached yet. Tap below to upload one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isLightMode ? const Color(0xFF5C4738) : const Color(0xFFD6C8B4),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _launchAudiobookPlayer(currentBook),
                icon: Icon(
                  hasAudioFile ? Icons.play_circle_fill_rounded : Icons.upload_file_rounded, 
                  color: isLightMode ? Colors.white : const Color(0xFF1E1712)
                ),
                label: Text(
                  hasAudioFile ? 'Open Audiobook Player' : 'Attach Audio File',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isLightMode ? Colors.white : const Color(0xFF1E1712),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLightMode ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFileAttachedView(Book currentBook) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.file_present_outlined, size: 54, color: const Color(0xFFFFA726).withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No Document File Attached',
                style: GoogleFonts.crimsonPro(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFE0A96D)),
              ),
              const SizedBox(height: 6),
              Text(
                'Attach a PDF or EPUB file to read directly in Bookora.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              BookMetadataSummaryBar(book: currentBook),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  FormatAndDocumentsSheet.show(context, book: currentBook, initialFormat: currentBook.format);
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA726),
                  side: const BorderSide(color: Color(0xFFFFA726), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
