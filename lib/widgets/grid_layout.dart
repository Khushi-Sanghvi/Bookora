import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

class GridLayout extends StatefulWidget {
  final List<Book> books;
  const GridLayout({super.key, required this.books});

  @override
  State<GridLayout> createState() => _GridLayoutState();
}

class _GridLayoutState extends State<GridLayout> {
  String _selectedSort = 'Recently Added';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Use provided books or sample reference books matching the image if empty
    final displayBooks = widget.books.isNotEmpty ? widget.books : _getSampleBooks();

    // Apply sorting
    final sortedBooks = List<Book>.from(displayBooks);
    if (_selectedSort == 'Title A-Z') {
      sortedBooks.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == 'Progress') {
      sortedBooks.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return Column(
      children: [
        // 1. Controls Header Bar (My Books (count) + Sort Dropdown)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: My Books (Count)
              Text(
                'My Books (${sortedBooks.length})',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),

              // Right: Sort Dropdown
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSort,
                  icon: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary, size: 18),
                  dropdownColor: colors.cardBg,
                  isDense: true,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
        ),

        // 2. 4-Column Grid View of Book Covers
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.44,
              crossAxisSpacing: 6,
              mainAxisSpacing: 10,
            ),
            itemCount: sortedBooks.length,
            itemBuilder: (context, index) {
              final book = sortedBooks[index];
              return _buildGridBookCard(context, book, colors, isLight);
            },
          ),
        ),
      ],
    );
  }

  // --- Sample Reference Books Matching Image ---
  List<Book> _getSampleBooks() {
    return [
      Book(id: '1', title: 'Twisted Love', author: 'Ana Huang', description: '', totalPages: 381, currentPage: 232, status: ReadingStatus.currentlyReading, coverUrl: ''),
      Book(id: '2', title: 'Twisted Games', author: 'Ana Huang', description: '', totalPages: 380, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '3', title: 'Love Theory', author: 'Ali Hazelwood', description: '', totalPages: 380, currentPage: 380, status: ReadingStatus.finished, coverUrl: ''),
      Book(id: '4', title: 'It Ends With Us', author: 'Colleen Hoover', description: '', totalPages: 385, currentPage: 146, status: ReadingStatus.currentlyReading, coverUrl: ''),
      Book(id: '5', title: 'The Silent Patient', author: 'Alex Michaelides', description: '', totalPages: 336, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '6', title: 'Fourth Wing', author: 'Rebecca Yarros', description: '', totalPages: 528, currentPage: 528, status: ReadingStatus.finished, coverUrl: ''),
      Book(id: '7', title: 'Atomic Habits', author: 'James Clear', description: '', totalPages: 320, currentPage: 86, status: ReadingStatus.currentlyReading, coverUrl: ''),
      Book(id: '8', title: 'The Midnight Library', author: 'Matt Haig', description: '', totalPages: 304, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '9', title: 'Verity', author: 'Colleen Hoover', description: '', totalPages: 400, currentPage: 0, status: ReadingStatus.wishlist, coverUrl: ''),
      Book(id: '10', title: 'Daisy Jones & The Six', author: 'Taylor Jenkins Reid', description: '', totalPages: 368, currentPage: 265, status: ReadingStatus.currentlyReading, coverUrl: ''),
      Book(id: '11', title: 'Clean Code', author: 'Robert C. Martin', description: '', totalPages: 464, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '12', title: 'Ikigai', author: 'Héctor García', description: '', totalPages: 208, currentPage: 208, status: ReadingStatus.finished, coverUrl: ''),
    ];
  }

  // --- Grid Book Card Item ---
  Widget _buildGridBookCard(BuildContext context, Book book, ReadingAppColors colors, bool isLight) {
    final double rawProgress = book.progress;
    final double safeProgress = (rawProgress.isNaN || rawProgress.isInfinite) ? 0.0 : rawProgress.clamp(0.0, 1.0);
    final progressPct = (safeProgress * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cover Image with Top-Right Percentage Badge Overlay
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BookCoverImage(
                      coverUrl: book.coverUrl,
                      title: book.title,
                      author: book.author,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$progressPct%',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 2. Title
            Text(
              book.title,
              style: GoogleFonts.crimsonPro(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),

            // 3. Author
            Text(
              book.author,
              style: TextStyle(
                fontSize: 8.5,
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 4. Bottom Status Badge & Options Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildStatusPill(book.status, colors, isLight)),
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () => _showBookOptionsSheet(context, book, colors),
                  child: Icon(Icons.more_horiz, size: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Status Pill Badge ---
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- Quick Options Sheet ---
  void _showBookOptionsSheet(BuildContext context, Book book, ReadingAppColors colors) {
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
