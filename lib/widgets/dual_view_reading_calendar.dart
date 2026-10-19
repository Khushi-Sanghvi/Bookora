import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../theme/reading_app_colors.dart';
import '../screens/reader_screen.dart';
import '../screens/pdf_reader_screen.dart';
import '../screens/epub_reader_screen.dart';
import 'book_cover_image.dart';

class BookSpanInfo {
  final String id;
  final String bookTitle;
  final String author;
  final String coverUrl;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final bool isFinished;
  final int currentPage;
  final int totalPages;
  final Book? book;

  BookSpanInfo({
    required this.id,
    required this.bookTitle,
    this.author = '',
    required this.coverUrl,
    required this.startDate,
    required this.endDate,
    required this.color,
    this.isFinished = false,
    this.currentPage = 0,
    this.totalPages = 300,
    this.book,
  });
}

class DualViewReadingCalendar extends StatefulWidget {
  final List<BookSpanInfo> bookSpans;
  final Map<DateTime, int> readingActivityMap;
  final int bestStreak;
  final int daysRead;
  final int totalPages;
  final DateTime initialMonth;

  const DualViewReadingCalendar({
    super.key,
    required this.bookSpans,
    required this.readingActivityMap,
    this.bestStreak = 0,
    this.daysRead = 0,
    this.totalPages = 0,
    required this.initialMonth,
  });

  @override
  State<DualViewReadingCalendar> createState() => _DualViewReadingCalendarState();
}

class _DualViewReadingCalendarState extends State<DualViewReadingCalendar> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0x0F3A2E24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Bar Header
          Text(
            'READING CALENDAR',
            style: TextStyle(
              color: colors.streakAmber,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Month Selector Navigation Header
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: colors.textSecondary, size: 22),
                onPressed: _previousMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  monthTitle,
                  style: GoogleFonts.crimsonPro(
                    color: colors.quoteGold,
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.chevron_right, color: colors.textSecondary, size: 22),
                onPressed: _nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Quick-Stat Metrics Row (3 Cards)
          Row(
            children: [
              _buildMetricCard(
                icon: Icons.local_fire_department_outlined,
                value: '${widget.bestStreak}',
                label: 'STREAK',
                colors: colors,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                icon: Icons.calendar_today_outlined,
                value: '${widget.daysRead}',
                label: 'DAYS READ',
                colors: colors,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                icon: Icons.menu_book_outlined,
                value: '${widget.totalPages}',
                label: 'PAGES',
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Monthly Calendar Span Grid
          _buildMonthSpanGridView(colors),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required ReadingAppColors colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.cardBgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.streakAmber, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Monthly Calendar Span Grid with Connector Lines, Stacked Cover Decks & Finish Badges ---
  Widget _buildMonthSpanGridView(ReadingAppColors colors) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    final prevMonthDays = DateTime(_selectedMonth.year, _selectedMonth.month, 0).day;
    final totalCells = daysInMonth + firstWeekday;
    final numRows = (totalCells / 7).ceil();
    final gridTotalCells = numRows * 7;

    final today = DateTime.now();

    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final displaySpans = widget.bookSpans
        .where((span) => span.book?.status != ReadingStatus.abandoned)
        .toList();

    final monthSpans = displaySpans.where((span) {
      return !span.endDate.isBefore(monthStart) && !span.startDate.isAfter(monthEnd);
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((d) => Text(d, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)))
              .toList(),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            const cellHeight = 66.0;
            final totalHeight = numRows * cellHeight;

            return SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // Horizontal Span Connecting Lines
                  CustomPaint(
                    size: Size(constraints.maxWidth, totalHeight),
                    painter: CalendarSpanPainter(
                      spans: monthSpans,
                      selectedMonth: _selectedMonth,
                      firstWeekday: firstWeekday,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                    ),
                  ),

                  // Calendar Grid Cells
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: cellWidth / cellHeight,
                    ),
                    itemCount: gridTotalCells,
                    itemBuilder: (context, index) {
                      final isPrevMonth = index < firstWeekday;
                      final isNextMonth = index >= totalCells;
                      final isCurrentMonthDay = !isPrevMonth && !isNextMonth;

                      int displayDay = 0;
                      DateTime date;

                      if (isPrevMonth) {
                        displayDay = prevMonthDays - firstWeekday + index + 1;
                        date = DateTime(_selectedMonth.year, _selectedMonth.month - 1, displayDay);
                      } else if (isNextMonth) {
                        displayDay = index - totalCells + 1;
                        date = DateTime(_selectedMonth.year, _selectedMonth.month + 1, displayDay);
                      } else {
                        displayDay = index - firstWeekday + 1;
                        date = DateTime(_selectedMonth.year, _selectedMonth.month, displayDay);
                      }

                      final isToday = today.year == date.year && today.month == date.month && today.day == date.day;

                      // Find all books active, started, or finished on this date
                      final startingBooks = monthSpans.where((span) {
                        return span.startDate.year == date.year &&
                            span.startDate.month == date.month &&
                            span.startDate.day == date.day;
                      }).toList();

                      final endingBooks = monthSpans.where((span) {
                        return span.isFinished &&
                            span.endDate.year == date.year &&
                            span.endDate.month == date.month &&
                            span.endDate.day == date.day;
                      }).toList();

                      final activeSpansOnDate = monthSpans.where((span) {
                        return !date.isBefore(span.startDate) && !date.isAfter(span.endDate);
                      }).toList();

                      return GestureDetector(
                        onTap: () {
                          if (activeSpansOnDate.isNotEmpty) {
                            _showDayActivitySheet(context, date, activeSpansOnDate, colors);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: colors.streakAmber, width: 1.5)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 2,
                                left: 6,
                                child: Text(
                                  '$displayDay',
                                  style: TextStyle(
                                    color: isCurrentMonthDay
                                        ? (isToday ? colors.streakAmber : colors.textPrimary)
                                        : colors.textSecondary.withValues(alpha: 0.5),
                                    fontWeight: isToday || activeSpansOnDate.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              // Display Stacked Cover Deck or Finished Cover Badge
                              if (startingBooks.isNotEmpty)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    child: _buildStackedCoversDeck(startingBooks, colors),
                                  ),
                                )
                              else if (endingBooks.isNotEmpty)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    child: _buildSingleFinishedCoverBadge(endingBooks.first, colors),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Stacked Cover Deck with +N Badge for Multiple Started Books ---
  Widget _buildStackedCoversDeck(List<BookSpanInfo> startingBooks, ReadingAppColors colors) {
    final extraCount = startingBooks.length - 1;
    final topBook = startingBooks.first;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (extraCount > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 26,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white30, width: 0.5),
              ),
            ),
          ),
        Container(
          width: 28,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BookCoverImage(
              coverUrl: topBook.coverUrl,
              title: topBook.bookTitle,
              author: topBook.author,
              width: 28,
              height: 38,
            ),
          ),
        ),
        if (extraCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: colors.streakAmber,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '+$extraCount',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- Single Finished Cover Badge ---
  Widget _buildSingleFinishedCoverBadge(BookSpanInfo book, ReadingAppColors colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 28,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BookCoverImage(
              coverUrl: book.coverUrl,
              title: book.bookTitle,
              author: book.author,
              width: 28,
              height: 38,
            ),
          ),
        ),
        Positioned(
          top: -3,
          left: -3,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colors.accentSage,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Icon(
              Icons.check,
              size: 8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // --- "Book activity on [Date]" Modal Bottom Sheet ---
  void _showDayActivitySheet(BuildContext context, DateTime date, List<BookSpanInfo> activeSpans, ReadingAppColors colors) {
    final filteredSpans = activeSpans
        .where((span) => span.book?.status != ReadingStatus.abandoned)
        .toList();
    final formattedDate = DateFormat('d MMM yyyy').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: colors.streakAmber),
                      const SizedBox(width: 8),
                      Text(
                        'Book activity on $formattedDate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Activity Sub-header
              Text(
                'Reading Activity',
                style: GoogleFonts.crimsonPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${filteredSpans.length} book${filteredSpans.length == 1 ? '' : 's'} active on this day',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),

              // List of Active Book Cards
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredSpans.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final span = filteredSpans[index];
                    final startStr = DateFormat('d MMM yyyy').format(span.startDate);
                    final endStr = span.isFinished
                        ? DateFormat('d MMM yyyy').format(span.endDate)
                        : '-';
                    final isStartedToday = span.startDate.year == date.year &&
                        span.startDate.month == date.month &&
                        span.startDate.day == date.day;
                    final isFinishedToday = span.isFinished &&
                        span.endDate.year == date.year &&
                        span.endDate.month == date.month &&
                        span.endDate.day == date.day;

                    int pagesReadOnThisDate = 0;
                    if (span.book != null) {
                      for (var entry in span.book!.journalEntries) {
                        final local = entry.date.toLocal();
                        if (local.year == date.year &&
                            local.month == date.month &&
                            local.day == date.day) {
                          pagesReadOnThisDate += entry.pagesRead;
                        }
                      }
                    }

                    String caption = 'Active reading session';
                    if (isStartedToday && isFinishedToday) {
                      caption = 'Started and finished on this day!';
                    } else if (isStartedToday) {
                      caption = 'Started on this day!';
                    } else if (isFinishedToday) {
                      caption = 'Finished on this day!';
                    }

                    final progressPct = (span.totalPages > 0 ? (span.currentPage / span.totalPages) : 0.0).clamp(0.0, 1.0);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Safe dismissal of modal
                          Navigator.pop(context);

                          // Intelligent routing based on format
                          if (span.book != null) {
                            if (span.book!.format == BookFormat.pdf && span.book!.localFilePath != null && span.book!.localFilePath!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PdfReaderScreen(book: span.book!)),
                              );
                            } else if (span.book!.format == BookFormat.epub && span.book!.localFilePath != null && span.book!.localFilePath!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EpubReaderScreen(book: span.book!)),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ReaderScreen(book: span.book!)),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        splashColor: colors.streakAmber.withValues(alpha: 0.1),
                        highlightColor: colors.streakAmber.withValues(alpha: 0.05),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.cardBgSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              BookCoverImage(
                                coverUrl: span.coverUrl,
                                title: span.bookTitle,
                                author: span.author,
                                width: 52,
                                height: 78,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            span.bookTitle.toUpperCase(),
                                            style: GoogleFonts.crimsonPro(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: colors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'by ${span.author.isEmpty ? "Author" : span.author}',
                                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    // Format Pill & Pages Read Volume Badge
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colors.streakAmber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: colors.streakAmber.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            '${(span.book?.format.name ?? "paperback").toUpperCase()} ${_getFormatIcon(span.book?.format)}',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: colors.streakAmber,
                                            ),
                                          ),
                                        ),
                                        if (pagesReadOnThisDate > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colors.accentSage.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: colors.accentSage.withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              '+$pagesReadOnThisDate pgs today',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: colors.accentSage,
                                              ),
                                            ),
                                          ),
                                        if (isStartedToday)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text(
                                              '🚀 Started',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ),
                                        if (isFinishedToday)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text(
                                              '🏆 Completed',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Started', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                                            Text(startStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Finished', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                                            Text(endStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colors.streakAmber, size: 20),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPct,
                              minHeight: 5,
                              backgroundColor: colors.borderSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              caption,
                              style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  String _getFormatIcon(BookFormat? format) {
    if (format == null) return '📖';
    switch (format) {
      case BookFormat.epub:
        return '📱';
      case BookFormat.pdf:
        return '📄';
      case BookFormat.audiobook:
        return '🎧';
      case BookFormat.hardcover:
        return '📚';
      case BookFormat.ebook:
        return '💻';
      case BookFormat.paperback:
        return '📖';
    }
  }
}

class CalendarSpanPainter extends CustomPainter {
  final List<BookSpanInfo> spans;
  final DateTime selectedMonth;
  final int firstWeekday;
  final double cellWidth;
  final double cellHeight;

  CalendarSpanPainter({
    required this.spans,
    required this.selectedMonth,
    required this.firstWeekday,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    for (var span in spans) {
      final Paint linePaint = Paint()
        ..color = span.color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      int startIndex = firstWeekday;
      if (span.startDate.isAfter(monthStart)) {
        startIndex = firstWeekday + (span.startDate.day - 1);
      }

      int endIndex = firstWeekday + daysInMonth - 1;
      if (!span.endDate.isAfter(DateTime(selectedMonth.year, selectedMonth.month, daysInMonth))) {
        endIndex = firstWeekday + (span.endDate.day - 1);
      }

      if (startIndex > endIndex) continue;

      int startRow = startIndex ~/ 7;
      int startCol = startIndex % 7;
      int endRow = endIndex ~/ 7;
      int endCol = endIndex % 7;

      if (startRow == endRow) {
        double startX = (startCol + 0.5) * cellWidth;
        double endX = (endCol + 0.5) * cellWidth;
        double y = (startRow + 0.5) * cellHeight + 4;
        canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
      } else {
        for (int r = startRow; r <= endRow; r++) {
          double y = (r + 0.5) * cellHeight + 4;
          if (r == startRow) {
            double startX = (startCol + 0.5) * cellWidth;
            double endX = size.width;
            canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
          } else if (r == endRow) {
            double startX = 0;
            double endX = (endCol + 0.5) * cellWidth;
            canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
          } else {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CalendarSpanPainter oldDelegate) {
    return oldDelegate.spans != spans ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.firstWeekday != firstWeekday;
  }
}
