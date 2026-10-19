import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

class ListLayout extends StatefulWidget {
  final List<Book> books;
  const ListLayout({super.key, required this.books});

  @override
  State<ListLayout> createState() => _ListLayoutState();
}

class _ListLayoutState extends State<ListLayout> {
  String _selectedSort = 'Recently Added';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Apply sorting
    final sortedBooks = List<Book>.from(widget.books);
    if (_selectedSort == 'Title A-Z') {
      sortedBooks.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == 'Progress') {
      sortedBooks.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return Column(
      children: [
        // 1. Controls Header Bar (Sort Dropdown + View Indicator)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Book Icon + Sort Dropdown
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_stories, color: colors.streakAmber, size: 16),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary, size: 18),
                      dropdownColor: colors.cardBg,
                      isDense: true,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSort = val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'Recently Added', child: Text('Recently Added')),
                        DropdownMenuItem(value: 'Title A-Z', child: Text('Title A-Z')),
                        DropdownMenuItem(value: 'Progress', child: Text('Reading Progress')),
                      ],
                    ),
                  ),
                ],
              ),

              // Right: Detailed List Indicator Badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.streakAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.streakAmber.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber, size: 16),
              ),
            ],
          ),
        ),

        // 2. ListView of Detailed Book Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedBooks.length,
            itemBuilder: (context, index) {
              final book = sortedBooks[index];
              return _buildDetailedListBookCard(context, book, colors, isLight);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedListBookCard(BuildContext context, Book book, ReadingAppColors colors, bool isLight) {
    final totalPages = book.totalPages > 0 ? book.totalPages : 300;
    final progressPct = book.progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. Left Book Cover Image
                BookCoverImage(
                  coverUrl: book.coverUrl,
                  title: book.title,
                  author: book.author,
                  width: 62,
                  height: 90,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 14),

                // 2. Middle Details Column (Title, Author, Status Pill + Progress Bar)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Author
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Status Pill + Progress Bar Row
                      Row(
                        children: [
                          // Status Badge Pill
                          _buildStatusPill(book.status, colors, isLight),
                          const SizedBox(width: 10),

                          // Progress Bar & Page Fraction Text
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progressPct,
                                      minHeight: 5,
                                      backgroundColor: isLight ? const Color(0xFFEBE3D5) : Colors.white10,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        book.status == ReadingStatus.finished
                                            ? colors.accentSage
                                            : colors.streakAmber,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${book.currentPage} / $totalPages',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Right Action Menu Button
                GestureDetector(
                  onTap: () => _showBookActionSheet(context, book, colors),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.cardBgSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Icon(Icons.more_horiz, size: 16, color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Status Badge Pill Helper ---
  Widget _buildStatusPill(ReadingStatus status, ReadingAppColors colors, bool isLight) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ReadingStatus.currentlyReading:
        bg = isLight ? const Color(0xFFF3C89B) : const Color(0xFF5B3920);
        fg = isLight ? const Color(0xFF5C2B05) : const Color(0xFFFFB74D);
        label = 'Reading';
        break;
      case ReadingStatus.toRead:
        bg = isLight ? const Color(0xFFEFE8DD) : const Color(0xFF2C241E);
        fg = isLight ? const Color(0xFF4E342E) : const Color(0xFFD7CCC8);
        label = 'To Read';
        break;
      case ReadingStatus.finished:
        bg = isLight ? const Color(0xFFC8E6C9) : const Color(0xFF1B3E2B);
        fg = isLight ? const Color(0xFF1B5E20) : const Color(0xFF81C784);
        label = 'Finished';
        break;
      case ReadingStatus.abandoned:
        bg = isLight ? const Color(0xFFFFCDD2) : const Color(0xFF4A1C1C);
        fg = isLight ? const Color(0xFFB71C1C) : const Color(0xFFE57373);
        label = 'Abandoned';
        break;
      case ReadingStatus.wishlist:
        bg = isLight ? const Color(0xFFE1BEE7) : const Color(0xFF381A4A);
        fg = isLight ? const Color(0xFF4A148C) : const Color(0xFFBA68C8);
        label = 'Wishlist';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // --- Quick Options Sheet ---
  void _showBookActionSheet(BuildContext context, Book book, ReadingAppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                book.title,
                style: GoogleFonts.crimsonPro(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('by ${book.author}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.streakAmber),
                title: const Text('View Book Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.menu_book, color: colors.streakAmber),
                title: const Text('Open Reader'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
