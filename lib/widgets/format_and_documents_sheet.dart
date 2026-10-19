import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../models/book.dart';
import '../models/book_format_config.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../providers/book_provider.dart';
import '../services/bookora_dialog_service.dart';
import '../providers/audiobook_provider.dart';
import '../services/file_service.dart';
import '../services/reading_status_resolver.dart';
import '../screens/pdf_reader_screen.dart';
import '../screens/epub_reader_screen.dart';
import 'full_screen_audio_player_sheet.dart';

final fileServiceProvider = Provider((ref) => FileService());

class FormatAndDocumentsSheet extends ConsumerStatefulWidget {
  final Book book;
  final BookFormat? initialFormat;
  final VoidCallback? onSaved;
  final ValueChanged<Book>? onSave;

  const FormatAndDocumentsSheet({
    super.key,
    required this.book,
    this.initialFormat,
    this.onSaved,
    this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    BookFormat? initialFormat,
    VoidCallback? onSaved,
    ValueChanged<Book>? onSave,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F0A07) : const Color(0xFFFAF6EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.90,
            child: FormatAndDocumentsSheet(
              book: book,
              initialFormat: initialFormat,
              onSaved: onSaved,
              onSave: onSave,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<FormatAndDocumentsSheet> createState() =>
      _FormatAndDocumentsSheetState();
}

class _FormatAndDocumentsSheetState
    extends ConsumerState<FormatAndDocumentsSheet> {
  late BookFormat _selectedFormat;
  late PaperbackTrackingMode _paperbackMode;
  late AudiobookTrackingMode _audiobookMode;
  late ReadingStatus _readingStatus;

  late int _currentPage;
  late int _totalPages;
  late int _currentChapter;
  late int _totalChapters;

  String? _localFilePath;
  String? _audioFilePath;
  Duration? _audioDuration;
  String? _audioTitle;
  String? _epubFilePath;
  String? _epubFileName;
  String? _pdfFilePath;
  String? _pdfFileName;
  DateTime? _startDate;
  DateTime? _endDate;

  late TextEditingController _titleController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat ?? widget.book.format;
    _paperbackMode = PaperbackTrackingMode.pages;
    _audiobookMode = AudiobookTrackingMode.fileUpload;
    _readingStatus = widget.book.status;

    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 300;

    _currentChapter = max(1, (_currentPage / 15).floor());
    _totalChapters = max(1, (_totalPages / 15).ceil());

    _localFilePath = widget.book.localFilePath;
    _audioFilePath = widget.book.audioFilePath ?? widget.book.localFilePath;

    final lower = widget.book.localFilePath?.toLowerCase() ?? '';
    if (widget.book.format == BookFormat.epub || lower.endsWith('.epub')) {
      _epubFilePath = widget.book.epubFilePath ?? widget.book.localFilePath;
      _epubFileName = _epubFilePath?.split('/').last;
    }
    if (widget.book.format == BookFormat.pdf || lower.endsWith('.pdf')) {
      _pdfFilePath = widget.book.pdfFilePath ?? widget.book.localFilePath;
      _pdfFileName = _pdfFilePath?.split('/').last;
    }

    _startDate = widget.book.startDate;
    _endDate = widget.book.endDate ?? widget.book.finishDate;

    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // --- Attach Document / Audio Files ---
  Future<void> _attachPdfFile() async {
    final fileService = ref.read(fileServiceProvider);
    final newPath = await fileService.pickAndSavePdfFile();
    if (newPath != null) {
      setState(() {
        _localFilePath = newPath;
        _pdfFilePath = newPath;
        _pdfFileName = newPath.split('/').last;
      });
      if (mounted) {
        BookoraDialogService.showPdfLoadedToast(
          context,
          fileName: newPath.split('/').last,
        );
      }
    }
  }

  Future<void> _attachEpubFile() async {
    final fileService = ref.read(fileServiceProvider);
    final newPath = await fileService.pickAndSaveEpubFile();
    if (newPath != null) {
      setState(() {
        _localFilePath = newPath;
        _epubFilePath = newPath;
        _epubFileName = newPath.split('/').last;
      });
      if (mounted) {
        BookoraDialogService.showEpubLoadedToast(
          context,
          fileName: newPath.split('/').last,
        );
      }
    }
  }

  Future<void> _attachAudioFile() async {
    final fileService = ref.read(fileServiceProvider);
    final newPath = await fileService.pickAndSaveAudioFile();
    if (newPath != null) {
      setState(() {
        _localFilePath = newPath;
        _audioFilePath = newPath;
      });
      if (mounted) {
        BookoraDialogService.showAudiobookAttachedToast(
          context,
          fileName: newPath.split('/').last,
        );
      }
    }
  }

  // --- Atomic Document Delete Handler (EPUB / PDF) ---
  Future<void> _handleDeleteDocument({required BookFormat format}) async {
    // 1. Identify the file path targeted for deletion
    final String? pathToDelete = format == BookFormat.epub
        ? (_epubFilePath ?? widget.book.epubFilePath ?? widget.book.localFilePath)
        : (_pdfFilePath ?? widget.book.pdfFilePath ?? widget.book.localFilePath);

    // 2. Clear local UI state immediately
    setState(() {
      if (format == BookFormat.epub) {
        _epubFilePath = null;
        _epubFileName = null;
        if (_selectedFormat == BookFormat.epub) {
          _localFilePath = null;
        }
      } else if (format == BookFormat.pdf) {
        _pdfFilePath = null;
        _pdfFileName = null;
        if (_selectedFormat == BookFormat.pdf) {
          _localFilePath = null;
        }
      }
    });

    // 3. Construct the updated book model with nulled paths
    final updatedBook = widget.book.copyWith(
      epubFilePath: format == BookFormat.epub ? null : widget.book.epubFilePath,
      pdfFilePath: format == BookFormat.pdf ? null : widget.book.pdfFilePath,
      localFilePath: (widget.book.format == format) ? null : widget.book.localFilePath,
      clearLocalFilePath: widget.book.format == format,
    );

    // 4. Commit null values to SQLite database and notify Riverpod
    await ref.read(booksProvider.notifier).updateBook(updatedBook);
    widget.onSave?.call(updatedBook);
    widget.onSaved?.call();

    // 5. Clean up cached file from local storage if applicable
    if (pathToDelete != null) {
      try {
        final file = File(pathToDelete);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local document file: $e');
      }
    }

    // 6. Provide lightweight feedback
    if (mounted) {
      BookoraDialogService.showSuccessToast(
        context,
        message: '${format == BookFormat.epub ? "EPUB" : "PDF"} file removed',
      );
    }
  }

  // --- Save Configuration & Persist ---
  Future<Book?> _commitChanges({bool shouldPop = false}) async {
    int updatedCurrentPage = _currentPage;
    int updatedTotalPages = _totalPages;

    if (_selectedFormat == BookFormat.paperback ||
        _selectedFormat == BookFormat.hardcover ||
        _selectedFormat == BookFormat.ebook) {
      if (_paperbackMode == PaperbackTrackingMode.chapters) {
        updatedCurrentPage = _currentChapter * 15;
        updatedTotalPages = _totalChapters * 15;
      }
    } else if (_selectedFormat == BookFormat.audiobook) {
      if (_audiobookMode == AudiobookTrackingMode.manualChapters) {
        updatedCurrentPage = _currentChapter * 15;
        updatedTotalPages = _totalChapters * 15;
      }
    }

    final pagesReadDelta = max(0, updatedCurrentPage - widget.book.currentPage);

    // Update JournalEntry log for today
    List<JournalEntry> updatedJournal = List.from(widget.book.journalEntries);
    if (pagesReadDelta > 0) {
      final today = DateTime.now();
      final todayIdx = updatedJournal.indexWhere((e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day);
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

    DateTime? effectiveStartDate = _startDate;
    DateTime? effectiveFinishDate = _endDate;
    if (effectiveFinishDate != null) {
      effectiveStartDate ??= effectiveFinishDate;
    } else if (effectiveStartDate == null &&
        (updatedCurrentPage > 0 || _selectedFormat != widget.book.format)) {
      effectiveStartDate = DateTime.now();
    }

    final effectiveTotal = updatedTotalPages > 0 ? updatedTotalPages : 300;
    final transition = ReadingStatusResolver.evaluateStatusTransition(
      currentStatus: effectiveFinishDate != null ? ReadingStatus.finished : _readingStatus,
      currentPage: effectiveFinishDate != null ? effectiveTotal : updatedCurrentPage,
      totalPages: effectiveTotal,
      existingStartDate: effectiveStartDate,
      existingFinishDate: effectiveFinishDate,
    );

    final updatedBook = widget.book.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : widget.book.title,
      author: _authorController.text.trim().isNotEmpty
          ? _authorController.text.trim()
          : widget.book.author,
      format: _selectedFormat,
      currentPage: effectiveFinishDate != null ? effectiveTotal : updatedCurrentPage,
      totalPages: effectiveTotal,
      localFilePath: _localFilePath,
      clearLocalFilePath: _localFilePath == null,
      startDate: transition.startDate,
      finishDate: transition.finishDate,
      finishDateValue: transition.finishDate,
      endDate: transition.finishDate,
      journalEntries: updatedJournal,
      status: transition.status,
    );

    ref.read(bookProvider.notifier).updateBook(updatedBook);

    if (!mounted) return updatedBook;

    if (widget.onSave != null) {
      widget.onSave!(updatedBook);
    }
    if (widget.onSaved != null) {
      widget.onSaved!();
    }

    if (shouldPop) {
      Navigator.pop(context);
    }

    BookoraDialogService.showTotalPagesUpdatedToast(
      context,
      totalPages: updatedBook.totalPages,
    );
    
    return updatedBook;
  }

  Future<void> _saveChanges() async {
    await _commitChanges(shouldPop: true);
  }

  double get _progressPercent {
    if (_selectedFormat == BookFormat.audiobook &&
        _audiobookMode == AudiobookTrackingMode.manualChapters) {
      return _totalChapters > 0
          ? (_currentChapter / _totalChapters).clamp(0.0, 1.0)
          : 0.0;
    } else if (_paperbackMode == PaperbackTrackingMode.chapters) {
      return _totalChapters > 0
          ? (_currentChapter / _totalChapters).clamp(0.0, 1.0)
          : 0.0;
    } else {
      return _totalPages > 0
          ? (_currentPage / _totalPages).clamp(0.0, 1.0)
          : 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCanvas = isDark ? const Color(0xFF0F0A07) : const Color(0xFFFAF6EF);
    final textPrimary = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF2A2018);
    final textSecondary = isDark ? const Color(0xFFA89A8B) : const Color(0xFF7A6B5D);
    final cardBg = isDark ? const Color(0xFF19120D) : const Color(0xFFFFFDF8);
    final cardBorder = isDark
        ? const Color(0xFFD97706).withValues(alpha: 0.25)
        : const Color(0xFFE6DAC8);
    const accentColor = Color(0xFFB45309);

    return Scaffold(
      backgroundColor: bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Persistent Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: textPrimary, size: 20),
                    ),
                  ),

                  // Reading Status Dropdown Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ReadingStatus>(
                        value: _readingStatus,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: accentColor, size: 18),
                        dropdownColor: cardBg,
                        isDense: true,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _readingStatus = val);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ReadingStatus.currentlyReading,
                            child: Text('⏳ In Progress'),
                          ),
                          DropdownMenuItem(
                            value: ReadingStatus.toRead,
                            child: Text('📖 To Read'),
                          ),
                          DropdownMenuItem(
                            value: ReadingStatus.finished,
                            child: Text('✅ Finished'),
                          ),
                          DropdownMenuItem(
                            value: ReadingStatus.abandoned,
                            child: Text('⏸️ Paused'),
                          ),
                          DropdownMenuItem(
                            value: ReadingStatus.wishlist,
                            child: Text('💫 Wishlist'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Block & Format Illustration Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFormat == BookFormat.paperback
                                    ? 'Add a Paperback'
                                    : 'Format & Progress',
                                style: GoogleFonts.playfairDisplay(
                                  color: textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose how you\'re reading and track your progress',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildFormatArtwork(_selectedFormat),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Step 1: Select Book Format Strip
                    _buildStepTitle(1, 'Select Book Format', textPrimary, accentColor),
                    const SizedBox(height: 12),
                    _buildFormatGrid(cardBg, cardBorder, textPrimary, accentColor),
                    const SizedBox(height: 24),

                    // Step 2 & Contextual Sections by Selected Format
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedFormat),
                        child: _buildContextualSection(
                          isDark,
                          cardBg,
                          cardBorder,
                          textPrimary,
                          textSecondary,
                          accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reading Timeline & Dates
                    _buildStepTitle(
                      _selectedFormat == BookFormat.paperback ? 5 : 4,
                      'Reading Timeline & Dates',
                      textPrimary,
                      accentColor,
                      subtitle: 'Track when you started and plan your finish date.',
                    ),
                    const SizedBox(height: 12),
                    _buildTimelineCards(cardBg, cardBorder, textPrimary, textSecondary, accentColor),
                    const SizedBox(height: 28),

                    // Dynamic Sticky Save Action Bar
                    _buildSaveButton(isDark, accentColor),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step Section Title Header ---
  Widget _buildStepTitle(int stepNumber, String title, Color textPrimary, Color accentColor, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber.',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8A7B6E), fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  // --- Format Artwork Corner ---
  Widget _buildFormatArtwork(BookFormat format) {
    IconData iconData = Icons.menu_book_rounded;
    if (format == BookFormat.audiobook) iconData = Icons.headphones_rounded;
    if (format == BookFormat.pdf) iconData = Icons.picture_as_pdf_rounded;
    if (format == BookFormat.epub) iconData = Icons.phonelink_rounded;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFB45309).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB45309).withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Icon(iconData, color: const Color(0xFFB45309), size: 32),
      ),
    );
  }

  // --- 4-Column Book Format Selection Grid ---
  Widget _buildFormatGrid(Color cardBg, Color cardBorder, Color textPrimary, Color accentColor) {
    final formats = [
      {'format': BookFormat.paperback, 'label': 'Paperback', 'icon': Icons.menu_book_rounded},
      {'format': BookFormat.audiobook, 'label': 'Audiobook', 'icon': Icons.headphones_rounded},
      {'format': BookFormat.pdf, 'label': 'PDF', 'icon': Icons.picture_as_pdf_rounded},
      {'format': BookFormat.epub, 'label': 'EPUB', 'icon': Icons.phonelink_rounded},
    ];

    return Row(
      children: formats.map((item) {
        final fmt = item['format'] as BookFormat;
        final label = item['label'] as String;
        final icon = item['icon'] as IconData;
        final isSelected = _selectedFormat == fmt;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _selectedFormat = fmt);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Color(0xFFB45309), size: 10),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color: isSelected ? Colors.white : accentColor,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Dynamic Contextual Section Router ---
  Widget _buildContextualSection(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    switch (_selectedFormat) {
      case BookFormat.audiobook:
        return _buildAudiobookView(isDark, cardBg, cardBorder, textPrimary, textSecondary, accentColor);
      case BookFormat.pdf:
        return _buildPdfView(isDark, cardBg, cardBorder, textPrimary, textSecondary, accentColor);
      case BookFormat.epub:
        return _buildEpubView(isDark, cardBg, cardBorder, textPrimary, textSecondary, accentColor);
      default:
        return _buildPaperbackView(isDark, cardBg, cardBorder, textPrimary, textSecondary, accentColor);
    }
  }

  // --- A. Audiobook Contextual View ---
  Widget _buildAudiobookView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final bool hasAttachedAudio = (_audioFilePath != null && _audioFilePath!.isNotEmpty) ||
        (_localFilePath != null && _localFilePath!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(2, 'Audiobook Mode', textPrimary, accentColor, subtitle: 'Choose how you want to track your listening.'),
        const SizedBox(height: 12),

        // Mode Switcher Pill
        _buildDualPillToggle(
          leftLabel: 'File Upload',
          leftIcon: Icons.upload_file_rounded,
          rightLabel: 'Manual Chapters',
          rightIcon: Icons.format_list_bulleted_rounded,
          isLeftActive: _audiobookMode == AudiobookTrackingMode.fileUpload,
          onLeftTap: () => setState(() => _audiobookMode = AudiobookTrackingMode.fileUpload),
          onRightTap: () => setState(() => _audiobookMode = AudiobookTrackingMode.manualChapters),
          cardBg: cardBg,
          cardBorder: cardBorder,
          accentColor: accentColor,
        ),
        const SizedBox(height: 20),

        if (_audiobookMode == AudiobookTrackingMode.fileUpload) ...[
          if (hasAttachedAudio) ...[
            _buildAttachedFileBar(
              'audio',
              _audioFilePath ?? _localFilePath!,
              cardBg,
              cardBorder,
              textPrimary,
              accentColor,
            ),
            const SizedBox(height: 12),
            _buildOpenPlayerButton(accentColor),
          ] else ...[
            _buildFileUploadCard(
              title: 'Upload Audio File',
              subtitle: 'Choose an audiobook from your device.',
              icon: Icons.headphones_rounded,
              buttonText: 'Browse Audio Files',
              formats: ['MP3', 'M4B', 'AAC', 'WAV', 'M4A'],
              onTap: _attachAudioFile,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentColor,
            ),
          ],
        ] else ...[
          // Manual Chapters Steppers
          Row(
            children: [
              Expanded(
                child: _buildNumericStepperCard(
                  title: 'Completed Chapters',
                  value: _currentChapter,
                  onMin: () => setState(() => _currentChapter = max(0, _currentChapter - 1)),
                  onPlus: () => setState(() => _currentChapter = min(_totalChapters, _currentChapter + 1)),
                  icon: Icons.headphones_rounded,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumericStepperCard(
                  title: 'Total Chapters',
                  value: _totalChapters,
                  onMin: () => setState(() => _totalChapters = max(1, _totalChapters - 1)),
                  onPlus: () => setState(() => _totalChapters += 1),
                  icon: Icons.format_list_bulleted_rounded,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        _buildStepTitle(3, 'Listening Progress (Chapters)', textPrimary, accentColor),
        const SizedBox(height: 12),
        _buildProgressRingSection(
          progress: _progressPercent,
          centerText: '${(_progressPercent * 100).toInt()}%',
          subText: '$_currentChapter of $_totalChapters chapters',
          icon: Icons.headphones_rounded,
          card1Title: 'Completed Chapters',
          card1Value: '$_currentChapter / $_totalChapters',
          card1Icon: Icons.headphones_rounded,
          card2Title: 'Remaining Chapters',
          card2Value: '${max(0, _totalChapters - _currentChapter)}',
          card2Icon: Icons.format_list_bulleted_rounded,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          accentColor: accentColor,
        ),
      ],
    );
  }

  // --- B. Paperback Contextual View ---
  Widget _buildPaperbackView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(1, 'Add Book Details', textPrimary, accentColor),
        const SizedBox(height: 12),
        _buildBookDetailsCard(cardBg, cardBorder, textPrimary, textSecondary, accentColor),
        const SizedBox(height: 20),

        _buildStepTitle(2, 'Tracking Mode', textPrimary, accentColor, subtitle: 'Choose how you want to track your progress.'),
        const SizedBox(height: 12),
        _buildDualPillToggle(
          leftLabel: 'Pages Mode',
          leftIcon: Icons.menu_book_rounded,
          rightLabel: 'Chapters Mode',
          rightIcon: Icons.collections_bookmark_rounded,
          isLeftActive: _paperbackMode == PaperbackTrackingMode.pages,
          onLeftTap: () => setState(() => _paperbackMode = PaperbackTrackingMode.pages),
          onRightTap: () => setState(() => _paperbackMode = PaperbackTrackingMode.chapters),
          cardBg: cardBg,
          cardBorder: cardBorder,
          accentColor: accentColor,
        ),
        const SizedBox(height: 20),

        if (_paperbackMode == PaperbackTrackingMode.pages) ...[
          _buildStepTitle(3, 'Book Details (Pages)', textPrimary, accentColor),
          const SizedBox(height: 12),
          _buildSingleDialCard('Total Pages', _totalPages, (v) => setState(() => _totalPages = max(1, v)), cardBg, cardBorder, textPrimary, accentColor),
          const SizedBox(height: 20),

          _buildStepTitle(4, 'Your Progress', textPrimary, accentColor),
          const SizedBox(height: 12),
          _buildProgressRingSection(
            progress: _progressPercent,
            centerText: '${(_progressPercent * 100).toInt()}%',
            subText: '$_currentPage of $_totalPages pages',
            icon: Icons.menu_book_rounded,
            card1Title: 'Pages Read',
            card1Value: '$_currentPage',
            card1Icon: Icons.description_rounded,
            card1Min: () => setState(() => _currentPage = max(0, _currentPage - 1)),
            card1Plus: () => setState(() => _currentPage = min(_totalPages, _currentPage + 1)),
            card2Title: 'Pages Remaining',
            card2Value: '${max(0, _totalPages - _currentPage)}',
            card2Icon: Icons.format_list_numbered_rounded,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            accentColor: accentColor,
          ),
        ] else ...[
          _buildStepTitle(3, 'Book Details (Chapters)', textPrimary, accentColor),
          const SizedBox(height: 12),
          _buildSingleDialCard('Total Chapters', _totalChapters, (v) => setState(() => _totalChapters = max(1, v)), cardBg, cardBorder, textPrimary, accentColor),
          const SizedBox(height: 20),

          _buildStepTitle(4, 'Your Progress', textPrimary, accentColor),
          const SizedBox(height: 12),
          _buildProgressRingSection(
            progress: _progressPercent,
            centerText: '${(_progressPercent * 100).toInt()}%',
            subText: '$_currentChapter of $_totalChapters chapters',
            icon: Icons.collections_bookmark_rounded,
            card1Title: 'Completed Chapters',
            card1Value: '$_currentChapter',
            card1Icon: Icons.bookmark_added_rounded,
            card1Min: () => setState(() => _currentChapter = max(0, _currentChapter - 1)),
            card1Plus: () => setState(() => _currentChapter = min(_totalChapters, _currentChapter + 1)),
            card2Title: 'Remaining Chapters',
            card2Value: '${max(0, _totalChapters - _currentChapter)}',
            card2Icon: Icons.format_list_bulleted_rounded,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            accentColor: accentColor,
          ),
        ],
      ],
    );
  }

  // --- C. PDF Contextual View ---
  Widget _buildPdfView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final bool hasPdfAttached = (_pdfFilePath != null && _pdfFilePath!.isNotEmpty) ||
        (_selectedFormat == BookFormat.pdf && _localFilePath != null && _localFilePath!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(2, 'PDF Document', textPrimary, accentColor, subtitle: 'Choose a PDF from your device.'),
        const SizedBox(height: 12),
        if (hasPdfAttached) ...[
          _buildAttachedFileBar(
            'pdf',
            _pdfFilePath ?? _localFilePath!,
            cardBg,
            cardBorder,
            textPrimary,
            accentColor,
            onDelete: () => _handleDeleteDocument(format: BookFormat.pdf),
          ),
          const SizedBox(height: 12),
          _buildOpenReaderButton('pdf', accentColor),
        ] else ...[
          _buildFileUploadCard(
            title: 'Upload PDF Document',
            subtitle: 'Choose a PDF from your device.',
            icon: Icons.picture_as_pdf_rounded,
            buttonText: 'Browse PDF Files',
            formats: ['PDF'],
            onTap: _attachPdfFile,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
        ],
        const SizedBox(height: 24),

        _buildStepTitle(3, 'Reading Progress (Pages)', textPrimary, accentColor),
        const SizedBox(height: 12),
        _buildProgressRingSection(
          progress: _progressPercent,
          centerText: '${(_progressPercent * 100).toInt()}%',
          subText: '$_currentPage of $_totalPages pages',
          icon: Icons.picture_as_pdf_rounded,
          card1Title: 'Completed Pages',
          card1Value: '$_currentPage',
          card1Icon: Icons.description_rounded,
          card1Min: () => setState(() => _currentPage = max(0, _currentPage - 1)),
          card1Plus: () => setState(() => _currentPage = min(_totalPages, _currentPage + 1)),
          card2Title: 'Remaining Pages',
          card2Value: '${max(0, _totalPages - _currentPage)}',
          card2Icon: Icons.format_list_numbered_rounded,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          accentColor: accentColor,
        ),
      ],
    );
  }

  // --- D. EPUB Contextual View ---
  Widget _buildEpubView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final bool hasEpubAttached = (_epubFilePath != null && _epubFilePath!.isNotEmpty) ||
        (_selectedFormat == BookFormat.epub && _localFilePath != null && _localFilePath!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(2, 'EPUB Document', textPrimary, accentColor, subtitle: 'Choose an EPUB from your device.'),
        const SizedBox(height: 12),
        if (hasEpubAttached) ...[
          _buildAttachedFileBar(
            'epub',
            _epubFilePath ?? _localFilePath!,
            cardBg,
            cardBorder,
            textPrimary,
            accentColor,
            onDelete: () => _handleDeleteDocument(format: BookFormat.epub),
          ),
          const SizedBox(height: 12),
          _buildOpenReaderButton('epub', accentColor),
        ] else ...[
          _buildFileUploadCard(
            title: 'Upload EPUB Document',
            subtitle: 'Choose an EPUB from your device.',
            icon: Icons.phonelink_rounded,
            buttonText: 'Browse EPUB Files',
            formats: ['EPUB'],
            onTap: _attachEpubFile,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
        ],
        const SizedBox(height: 24),

        _buildStepTitle(3, 'Reading Progress (Pages)', textPrimary, accentColor),
        const SizedBox(height: 12),
        _buildProgressRingSection(
          progress: _progressPercent,
          centerText: '${(_progressPercent * 100).toInt()}%',
          subText: '$_currentPage of $_totalPages pages',
          icon: Icons.phonelink_rounded,
          card1Title: 'Completed Pages',
          card1Value: '$_currentPage',
          card1Icon: Icons.description_rounded,
          card1Min: () => setState(() => _currentPage = max(0, _currentPage - 1)),
          card1Plus: () => setState(() => _currentPage = min(_totalPages, _currentPage + 1)),
          card2Title: 'Remaining Pages',
          card2Value: '${max(0, _totalPages - _currentPage)}',
          card2Icon: Icons.format_list_numbered_rounded,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          accentColor: accentColor,
        ),
      ],
    );
  }

  // --- Reusable Dual Pill Toggle ---
  Widget _buildDualPillToggle({
    required String leftLabel,
    required IconData leftIcon,
    required String rightLabel,
    required IconData rightIcon,
    required bool isLeftActive,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
    required Color cardBg,
    required Color cardBorder,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onLeftTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isLeftActive ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(leftIcon, size: 16, color: isLeftActive ? Colors.white : const Color(0xFFA89A8B)),
                    const SizedBox(width: 6),
                    Text(
                      leftLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isLeftActive ? Colors.white : const Color(0xFFA89A8B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onRightTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isLeftActive ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(rightIcon, size: 16, color: !isLeftActive ? Colors.white : const Color(0xFFA89A8B)),
                    const SizedBox(width: 6),
                    Text(
                      rightLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: !isLeftActive ? Colors.white : const Color(0xFFA89A8B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- File Upload Card ---
  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonText,
    required List<String> formats,
    required VoidCallback onTap,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: accentColor),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: formats.map((fmt) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fmt, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Attached File Bar ---
  Widget _buildAttachedFileBar(
    String fileType,
    String filePath,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color accentColor, {
    VoidCallback? onDelete,
  }) {
    final fileName = filePath.split('/').last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              fileType == 'pdf'
                  ? Icons.picture_as_pdf_rounded
                  : (fileType == 'epub'
                      ? Icons.phonelink_rounded
                      : Icons.audiotrack_rounded),
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (fileType == 'audio' && _audioTitle != null)
                      ? _audioTitle!
                      : (fileType == 'pdf' && _pdfFileName != null)
                          ? _pdfFileName!
                          : (fileType == 'epub' && _epubFileName != null)
                              ? _epubFileName!
                              : fileName,
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileType == 'audio' && _audioDuration != null
                      ? 'Attached Audiobook (${_audioDuration!.inMinutes}m)'
                      : 'Attached File',
                  style: const TextStyle(color: Color(0xFF8A7B6E), fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            onPressed: onDelete ?? () async {
              if (fileType == 'audio') {
                // 1. Capture the existing file path for disk cleanup
                final String? pathToDelete = _audioFilePath ?? widget.book.audioFilePath ?? widget.book.localFilePath;

                // 2. Halt playback and wipe active player state if this book is loaded
                ref.read(audiobookPlayerProvider.notifier).stopAndClear();

                // 3. Immediately clear local UI state
                setState(() {
                  _audioFilePath = null;
                  _audioDuration = null;
                  _audioTitle = null;
                  _localFilePath = null;
                });

                // 4. Update the book model to remove audio file paths
                final updatedBook = widget.book.copyWith(
                  audioFilePath: null,
                  localFilePath: null,
                  clearLocalFilePath: true,
                );

                // 5. Commit null values to SQLite database and notify Riverpod
                await ref.read(booksProvider.notifier).updateBook(updatedBook);
                widget.onSave?.call(updatedBook);
                widget.onSaved?.call();

                // 6. Safely remove cached file from device cache directory (if local)
                if (pathToDelete != null) {
                  try {
                    final file = File(pathToDelete);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  } catch (e) {
                    debugPrint('Error removing cached audio file: $e');
                  }
                }

                // 7. Show confirmation toast
                if (mounted) {
                  BookoraDialogService.showSuccessToast(context, message: 'Audiobook removed');
                }
              } else {
                await _handleDeleteDocument(format: fileType == 'pdf' ? BookFormat.pdf : BookFormat.epub);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Open Audiobook Player Button ---
  Widget _buildOpenPlayerButton(Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final audioPath = _audioFilePath ?? _localFilePath;
          if (audioPath == null || !File(audioPath).existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please attach an audio file first'), behavior: SnackBarBehavior.floating),
            );
            return;
          }
          
          final updatedBook = await _commitChanges(shouldPop: false);
          if (!mounted || updatedBook == null) return;
          
          ref.read(audiobookPlayerProvider.notifier).loadAndPlay(updatedBook, audioPath: audioPath);
          
          Navigator.pop(context);
          FullScreenAudioPlayerSheet.show(context);
        },
        icon: const Icon(Icons.headphones_rounded, size: 18),
        label: const Text('Open Audiobook Player >'),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  // --- Open PDF / EPUB Reader Button ---
  Widget _buildOpenReaderButton(String type, Color accentColor) {
    final label = type == 'pdf' ? '📖 Open PDF Reader >' : '📖 Open EPUB Reader >';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final docPath = type == 'pdf'
              ? (_pdfFilePath ?? _localFilePath)
              : (_epubFilePath ?? _localFilePath);
          if (docPath == null || !File(docPath).existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please attach a ${type.toUpperCase()} file first'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final updatedBook = await _commitChanges(shouldPop: false);
          if (!mounted || updatedBook == null) return;
          
          Navigator.pop(context); // Pop the sheet
          
          if (type == 'pdf') {
            Navigator.push(
              context, // Uses root navigator as fallback or parent context if possible, but actually since we popped it's safer to use the root navigator.
              MaterialPageRoute(builder: (context) => PdfReaderScreen(book: updatedBook)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EpubReaderScreen(book: updatedBook)),
            );
          }
        },
        icon: Icon(type == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.phonelink_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  // --- Book Details Editable Card (Paperback Step 1) ---
  Widget _buildBookDetailsCard(
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Book Title',
              labelStyle: TextStyle(color: accentColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Author (Optional)',
              labelStyle: TextStyle(color: textSecondary, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Single Total Dial Stepper Card ---
  Widget _buildSingleDialCard(
    String title,
    int value,
    Function(int) onChange,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: accentColor,
                onPressed: () => onChange(value - 10),
              ),
              Text('$value', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: accentColor,
                onPressed: () => onChange(value + 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Numeric Stepper Card ---
  Widget _buildNumericStepperCard({
    required String title,
    required int value,
    required VoidCallback onMin,
    required VoidCallback onPlus,
    required IconData icon,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded),
                color: accentColor,
                onPressed: onMin,
              ),
              Text(
                '$value',
                style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                color: accentColor,
                onPressed: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Circular Progress Ring & Detail Cards Section ---
  Widget _buildProgressRingSection({
    required double progress,
    required String centerText,
    required String subText,
    required IconData icon,
    required String card1Title,
    required String card1Value,
    required IconData card1Icon,
    VoidCallback? card1Min,
    VoidCallback? card1Plus,
    required String card2Title,
    required String card2Value,
    required IconData card2Icon,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color accentColor,
  }) {
    return Row(
      children: [
        // Circular Progress Ring Dial
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: cardBorder),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: CircularProgressDialPainter(
                    progress: progress,
                    accentColor: accentColor,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(height: 2),
                  Text(
                    centerText,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subText,
                    style: const TextStyle(color: Color(0xFF8A7B6E), fontSize: 8),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Stacked Progress Detail Cards
        Expanded(
          child: Column(
            children: [
              _buildProgressDetailCard(card1Title, card1Value, card1Icon, card1Min, card1Plus, cardBg, cardBorder, textPrimary, accentColor),
              const SizedBox(height: 10),
              _buildProgressDetailCard(card2Title, card2Value, card2Icon, null, null, cardBg, cardBorder, textPrimary, accentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDetailCard(
    String title,
    String value,
    IconData icon,
    VoidCallback? onMin,
    VoidCallback? onPlus,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Color(0xFF8A7B6E), fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        value,
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onMin != null && onPlus != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onMin,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.remove_circle_outline_rounded, size: 18, color: accentColor),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onPlus,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.add_circle_outline_rounded, size: 18, color: accentColor),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- Reading Timeline & Dates Section ---
  Widget _buildTimelineCards(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary, Color accentColor) {
    final startDateStr = _startDate != null ? DateFormat('d MMM, yyyy').format(_startDate!) : 'Not set';
    final endDateStr = _endDate != null ? DateFormat('d MMM, yyyy').format(_endDate!) : 'Not finished yet';

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: accentColor),
                      if (_startDate != null)
                        InkWell(
                          onTap: () => setState(() => _startDate = null),
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF8A7B6E)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Start Date', style: TextStyle(color: textSecondary, fontSize: 10)),
                  Text(startDateStr, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final initial = _endDate ?? widget.book.endDate ?? DateTime.now();
              final first = _startDate ?? widget.book.startDate ?? DateTime(2000);
              final last = DateTime.now().add(const Duration(days: 365));

              final picked = await showDatePicker(
                context: context,
                initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
                firstDate: first,
                lastDate: last,
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                  _readingStatus = ReadingStatus.completed;
                });
                await ref.read(booksProvider.notifier).markBookCompleted(
                  bookId: widget.book.id,
                  customFinishDate: picked,
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.flag_rounded, size: 16, color: accentColor),
                      if (_endDate != null)
                        InkWell(
                          onTap: () async {
                            setState(() {
                              _endDate = null;
                              _readingStatus = _currentPage > 0 ? ReadingStatus.currentlyReading : ReadingStatus.toRead;
                            });
                            final updated = widget.book.copyWith(
                              finishDateValue: null,
                              status: _currentPage > 0 ? ReadingStatus.currentlyReading : ReadingStatus.toRead,
                            );
                            ref.read(bookProvider.notifier).updateBook(updated);
                          },
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF8A7B6E)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Finish Date', style: TextStyle(color: textSecondary, fontSize: 10)),
                  Text(endDateStr, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dynamic Save Action Bar ---
  Widget _buildSaveButton(bool isDark, Color accentColor) {
    String formatName = 'PAPERBACK';
    if (_selectedFormat == BookFormat.audiobook) formatName = 'AUDIOBOOK';
    if (_selectedFormat == BookFormat.pdf) formatName = 'PDF';
    if (_selectedFormat == BookFormat.epub) formatName = 'EPUB';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Save $formatName Setup',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const Spacer(),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CIRCULAR PROGRESS DIAL PAINTER
// =============================================================================

class CircularProgressDialPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  CircularProgressDialPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressDialPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
