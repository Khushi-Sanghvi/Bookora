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
import '../theme/reading_app_colors.dart';
import '../widgets/add_quote_dialog.dart';
import '../widgets/format_and_documents_sheet.dart';
import '../services/bookora_dialog_service.dart';
import '../services/reading_status_resolver.dart';

enum PdfViewingTheme { light, sepia, night }

class PdfReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  const PdfReaderScreen({super.key, required this.book});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> with WidgetsBindingObserver {
  late int _totalPages;
  late int _currentPage;
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _isReady = false;
  bool _isBackgrounded = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  PDFViewController? _pdfViewController;

  // Enhanced PDF Reader Settings
  bool _swipeHorizontal = true;
  PdfViewingTheme _pdfTheme = PdfViewingTheme.light;
  final bool _showControls = true;
  final Set<int> _bookmarkedPages = {};
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 300;
    _startDate = widget.book.startDate ?? DateTime.now();
    _finishDate = widget.book.finishDate;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) setState(() => _isBackgrounded = true);
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _isBackgrounded = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _transformationController.dispose();
    try {
      _pdfViewController?.dispose();
    } catch (_) {}
    _pdfViewController = null;
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

  bool get _hasValidPdfFile {
    final book = _currentBook;
    final path = book.pdfFilePath ?? book.localFilePath;
    if (path == null || path.trim().isEmpty) return false;
    return path.toLowerCase().endsWith('.pdf') && File(path).existsSync();
  }

  // Removing _activeColorFilter since the library doesn't support color filters

  void _onPageChanged(int? page, int? total) {
    if (!mounted) return;
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

  void _showThemeSelectorSheet() {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined, color: colors.streakAmber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'PDF Viewing Mode & Display',
                                style: GoogleFonts.playfairDisplay(
                                  color: colors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('Paper & Color Theme', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOptionCard(
                          label: 'Clean Light',
                          icon: Icons.wb_sunny_outlined,
                          theme: PdfViewingTheme.light,
                          bgColor: const Color(0xFFF7F3E9),
                          textColor: const Color(0xFF121212),
                          colors: colors,
                          onTap: () {
                            setState(() => _pdfTheme = PdfViewingTheme.light);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionCard(
                          label: 'Warm Sepia',
                          icon: Icons.menu_book,
                          theme: PdfViewingTheme.sepia,
                          bgColor: const Color(0xFFEFE3D3),
                          textColor: const Color(0xFF3A2A1A),
                          colors: colors,
                          onTap: () {
                            setState(() => _pdfTheme = PdfViewingTheme.sepia);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionCard(
                          label: 'OLED Night',
                          icon: Icons.nightlight_round,
                          theme: PdfViewingTheme.night,
                          bgColor: const Color(0xFF121212),
                          textColor: const Color(0xFFE5E5E5),
                          colors: colors,
                          onTap: () {
                            setState(() => _pdfTheme = PdfViewingTheme.night);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Page Layout & Scroll', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
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
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionCard({
    required String label,
    required IconData icon,
    required PdfViewingTheme theme,
    required Color bgColor,
    required Color textColor,
    required ReadingAppColors colors,
    required VoidCallback onTap,
  }) {
    final isSelected = _pdfTheme == theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? colors.streakAmber : colors.borderSubtle, width: isSelected ? 2.0 : 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.edit_note, color: colors.streakAmber),
                const SizedBox(width: 8),
                Text('Jump to PDF Page', style: TextStyle(color: colors.quoteGold, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      labelText: 'Target Page Number',
                      labelStyle: TextStyle(color: colors.streakAmber),
                      prefixIcon: Icon(Icons.picture_as_pdf, color: colors.streakAmber),
                      filled: true,
                      fillColor: colors.cardBgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalPagesController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Total PDF Pages',
                      labelStyle: TextStyle(color: colors.streakAmber),
                      prefixIcon: Icon(Icons.auto_stories, color: colors.streakAmber),
                      filled: true,
                      fillColor: colors.cardBgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

                  _pdfViewController?.setPage(newCurrentPage);

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

                  Navigator.pop(context);
                  BookoraDialogService.showTotalPagesUpdatedToast(context, totalPages: targetTotalPages);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.streakAmber,
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

  void _showPdfChapterJumpSheet() {
    final colors = context.appColors;

    final List<PdfTocItem> tocItems = [];

    if (_totalPages >= 1) {
      tocItems.add(const PdfTocItem(
        title: 'Cover Page',
        pageIndex: 0,
        subtitle: 'Page 1',
        icon: Icons.portrait_rounded,
      ));
    }

    if (_totalPages >= 2) {
      tocItems.add(const PdfTocItem(
        title: 'Title Page & Information',
        pageIndex: 1,
        subtitle: 'Page 2',
        icon: Icons.info_outline_rounded,
      ));
    }

    if (_totalPages >= 5) {
      tocItems.add(const PdfTocItem(
        title: 'Prologue / Preface',
        pageIndex: 2,
        subtitle: 'Pages 3 - 5',
        icon: Icons.auto_stories_rounded,
      ));
    }

    final int startBodyPage = _totalPages >= 5 ? 5 : (_totalPages >= 2 ? 2 : 1);
    final int endBodyPage = _totalPages >= 10 ? max(startBodyPage, _totalPages - 3) : _totalPages;
    final int bodyPages = max(0, endBodyPage - startBodyPage);
    final int pagesPerChapter = 15;
    final int totalChapters = max(1, (bodyPages / pagesPerChapter).ceil());

    for (int i = 0; i < totalChapters; i++) {
      final chStart = startBodyPage + (i * pagesPerChapter);
      if (chStart >= endBodyPage) break;
      final chEnd = min(endBodyPage, chStart + pagesPerChapter);

      tocItems.add(PdfTocItem(
        title: 'Chapter ${i + 1}',
        pageIndex: chStart,
        subtitle: 'Pages ${chStart + 1} - $chEnd',
        icon: Icons.bookmark_border_rounded,
      ));
    }

    if (_totalPages >= 10) {
      final epiloguePage = max(0, _totalPages - 3);
      tocItems.add(PdfTocItem(
        title: "Epilogue & Author's Note",
        pageIndex: epiloguePage,
        subtitle: 'Pages ${epiloguePage + 1} - $_totalPages',
        icon: Icons.military_tech_outlined,
      ));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PDF Table of Contents & Outline',
                            style: GoogleFonts.playfairDisplay(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Page Indicator & Custom Page Search Field
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.cardBgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently at Page ${_currentPage + 1} of $_totalPages',
                        style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPageProgressDialog();
                      },
                      icon: const Icon(Icons.edit_note, size: 14),
                      label: const Text('Exact Page', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.streakAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('DOCUMENT OUTLINE & SECTIONS', style: TextStyle(color: colors.streakAmber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),

              // Scrollable List of Chapter Breaks
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tocItems.length,
                  separatorBuilder: (context, index) => Divider(color: colors.borderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final item = tocItems[index];
                    final isCurrentSection = _currentPage >= item.pageIndex &&
                        (index == tocItems.length - 1 || _currentPage < tocItems[index + 1].pageIndex);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        isCurrentSection ? Icons.bookmark_rounded : item.icon,
                        color: isCurrentSection ? colors.streakAmber : colors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isCurrentSection ? colors.streakAmber : colors.textPrimary,
                          fontWeight: isCurrentSection ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      ),
                      trailing: isCurrentSection
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
                          : Icon(Icons.chevron_right, color: colors.textSecondary, size: 18),
                      onTap: () async {
                        final newPage = item.pageIndex.clamp(0, max(0, _totalPages - 1)).toInt();
                        final pagesReadDelta = max(0, newPage - _currentPage).toInt();

                        setState(() {
                          _currentPage = newPage;
                        });

                        _pdfViewController?.setPage(newPage);

                        final updatedBook = widget.book.copyWith(
                          currentPage: newPage,
                          totalPages: _totalPages,
                          startDate: _startDate,
                          finishDate: _finishDate,
                        );
                        ref.read(bookProvider.notifier).updateBook(updatedBook);

                        if (pagesReadDelta > 0) {
                          final entry = JournalEntry.create(pagesReadDelta);
                          ref.read(bookProvider.notifier).addJournalEntry(widget.book.id, entry);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          BookoraDialogService.showOutlineJumpSnackBar(
                            context,
                            title: item.title,
                            subtitle: item.subtitle,
                          );
                        }
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

  Widget _buildPdfViewerWidget() {
    if (_isBackgrounded) {
      return SizedBox.expand(
        child: ColoredBox(color: context.appColors.scaffoldBg),
      );
    }

    final current = _currentBook;
    final pdfPath = current.pdfFilePath ?? current.localFilePath;
    if (pdfPath == null || !File(pdfPath).existsSync()) {
      return const SizedBox.shrink();
    }

    Widget pdfWidget = PDFView(
      key: ValueKey('pdf_${current.id}_${pdfPath}_$_swipeHorizontal'),
      filePath: pdfPath,
      enableSwipe: true,
      swipeHorizontal: _swipeHorizontal,
      autoSpacing: true,
      pageFling: true,
      pageSnap: _swipeHorizontal,
      fitPolicy: FitPolicy.BOTH,
      defaultPage: _currentPage,
      onViewCreated: (PDFViewController controller) {
        if (!mounted) {
          try {
            controller.dispose();
          } catch (_) {}
          return;
        }
        _pdfViewController = controller;
      },
      onRender: (pages) {
        if (mounted) {
          setState(() {
            if (pages != null && pages > 0) {
              _totalPages = pages;
            }
            _isReady = true;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      },
      onPageError: (page, error) {
        if (mounted) {
          setState(() {
            _errorMessage = '$page: $error';
          });
        }
      },
      onPageChanged: _onPageChanged,
    );

    // Apply Real-Time Theme Overlay (Warm Sepia Parchment & OLED Night Mode)
    Widget overlay = const SizedBox();
    if (_pdfTheme == PdfViewingTheme.sepia) {
      overlay = IgnorePointer(
        child: Container(
          color: const Color(0xFF704214).withValues(alpha: 0.18),
        ),
      );
    } else if (_pdfTheme == PdfViewingTheme.night) {
      overlay = IgnorePointer(
        child: Container(
          color: const Color(0xFF101010).withValues(alpha: 0.85),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        pdfWidget,
        overlay,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(booksProvider);
    final colors = context.appColors;
    final progressPercent = _totalPages > 0 ? ((_currentPage + 1) / _totalPages).clamp(0.0, 1.0) : 0.0;
    final isBookmarked = _bookmarkedPages.contains(_currentPage);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: _showControls
          ? AppBar(
              title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
              backgroundColor: colors.scaffoldBg,
              actions: [
                IconButton(
                  icon: Icon(
                    _swipeHorizontal ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
                    color: colors.streakAmber,
                  ),
                  tooltip: _swipeHorizontal ? 'Switch to Vertical Scroll' : 'Switch to Horizontal Flip',
                  onPressed: () {
                    setState(() {
                      _swipeHorizontal = !_swipeHorizontal;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber),
                  tooltip: 'PDF Chapters & Table of Contents',
                  onPressed: _showPdfChapterJumpSheet,
                ),
                IconButton(
                  icon: Icon(Icons.palette_outlined, color: colors.streakAmber),
                  tooltip: 'PDF Display & Theme Modes',
                  onPressed: _showThemeSelectorSheet,
                ),
                IconButton(
                  icon: Icon(Icons.format_quote, color: colors.streakAmber),
                  tooltip: 'Add Quote or Annotation',
                  onPressed: () {
                    AddQuoteDialog.show(
                      context,
                      initialPage: _currentPage + 1,
                      onSave: (quote) {
                        ref.read(bookProvider.notifier).addQuote(widget.book.id, quote);
                        BookoraDialogService.showQuoteSavedSnackBar(context);
                      },
                    );
                  },
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.streakAmber),
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
                            style: TextStyle(color: colors.quoteGold, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          if (_hasValidPdfFile)
            _buildPdfViewerWidget()
          else
            _buildNoFileAttachedView(colors),

          if (_hasValidPdfFile && !_isReady && _errorMessage.isEmpty)
            Center(child: CircularProgressIndicator(color: colors.streakAmber)),

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

          // Interactive Top Right Ribbon Bookmark
          if (_hasValidPdfFile && _isReady)
            Positioned(
              top: _showControls ? 10 : 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
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
                  width: 24,
                  height: isBookmarked ? 48 : 32,
                  decoration: BoxDecoration(
                    color: isBookmarked ? const Color(0xFFB81D1D) : colors.streakAmber.withValues(alpha: 0.6),
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

          // Bottom Floating Reading Progress Bar Overlay
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: colors.cardBg.withValues(alpha: 0.95),
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
                          Expanded(
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
                                    Icon(Icons.play_circle_outline, size: 14, color: colors.streakAmber),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _startDate != null ? 'Start: ${DateFormat('MMM d').format(_startDate!)}' : 'Start Date',
                                        style: TextStyle(color: colors.textPrimary, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
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
                                    const Icon(Icons.flag_outlined, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _finishDate != null ? 'End: ${DateFormat('MMM d').format(_finishDate!)}' : 'End Date',
                                        style: TextStyle(color: colors.textPrimary, fontSize: 11),
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
                            icon: Icon(Icons.edit_note, color: colors.streakAmber, size: 22),
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

  Widget _buildNoFileAttachedView(ReadingAppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 64, color: colors.streakAmber.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No PDF Document Attached',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.quoteGold),
            ),
            const SizedBox(height: 8),
            Text(
              'Attach a .pdf file in Setup to open it in this reader.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                FormatAndDocumentsSheet.show(context, book: widget.book, initialFormat: BookFormat.pdf);
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Attach PDF File'),
              style: ElevatedButton.styleFrom(backgroundColor: colors.streakAmber, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfTocItem {
  final String title;
  final int pageIndex;
  final String subtitle;
  final IconData icon;

  const PdfTocItem({
    required this.title,
    required this.pageIndex,
    required this.subtitle,
    this.icon = Icons.bookmark_border_rounded,
  });
}
