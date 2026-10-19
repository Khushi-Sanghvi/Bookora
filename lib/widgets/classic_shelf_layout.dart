import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

class ClassicShelfLayout extends StatefulWidget {
  final List<Book> books;
  const ClassicShelfLayout({super.key, required this.books});

  @override
  State<ClassicShelfLayout> createState() => _ClassicShelfLayoutState();
}

class _ClassicShelfLayoutState extends State<ClassicShelfLayout> {
  String _selectedSort = 'Recently Added';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Use provided books or default sample books matching the reference image
    final displayBooks = widget.books.isNotEmpty ? widget.books : _getSampleBooks();

    // Apply sorting
    final sortedBooks = List<Book>.from(displayBooks);
    if (_selectedSort == 'Title A-Z') {
      sortedBooks.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == 'Progress') {
      sortedBooks.sort((a, b) => b.progress.compareTo(a.progress));
    }

    // Group books into rows of 4 per shelf tier
    List<List<Book>> shelfTiers = [];
    const int itemsPerTier = 4;
    for (var i = 0; i < sortedBooks.length; i += itemsPerTier) {
      shelfTiers.add(sortedBooks.sublist(
        i,
        i + itemsPerTier > sortedBooks.length ? sortedBooks.length : i + itemsPerTier,
      ));
    }

    final woodColor = isLight ? const Color(0xFF8D6E63) : const Color(0xFF3E2723);
    final woodHighlight = isLight ? const Color(0xFFA1887F) : const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF5EFE6) : const Color(0xFF100E0D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: Column(
          children: [
            // 1. Top Hero Banner Card ("A Good Book Always Finds You")
            _buildHeroBannerCard(colors, isLight),
            const SizedBox(height: 10),

            // 2. Controls Header (Only "Recently Added ˅" Dropdown)
            _buildBookshelfControlsHeader(colors, isLight),
            const SizedBox(height: 8),

            // 3. Multi-Tier 3D Classic Wooden Bookshelf
            _buildClassicWoodenBookcase(context, shelfTiers, woodColor, woodHighlight, colors, isLight),
          ],
        ),
      ),
    );
  }

  // --- Sample Reference Books Matching Image ---
  List<Book> _getSampleBooks() {
    return [
      Book(id: '1', title: 'Twisted Love', author: 'Ana Huang', description: '', totalPages: 358, currentPage: 0, status: ReadingStatus.finished, coverUrl: ''),
      Book(id: '2', title: 'Twisted Games', author: 'Ana Huang', description: '', totalPages: 380, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '3', title: 'Harry Potter', author: 'J.K. Rowling', description: '', totalPages: 300, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '4', title: 'The Love Hypothesis', author: 'Ali Hazelwood', description: '', totalPages: 390, currentPage: 15, status: ReadingStatus.finished, coverUrl: ''),
      Book(id: '5', title: 'Fourth Wing', author: 'Rebecca Yarros', description: '', totalPages: 528, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '6', title: 'Verity', author: 'Colleen Hoover', description: '', totalPages: 400, currentPage: 98, status: ReadingStatus.currentlyReading, coverUrl: ''),
      Book(id: '7', title: 'Atomic Habits', author: 'James Clear', description: '', totalPages: 320, currentPage: 0, status: ReadingStatus.toRead, coverUrl: ''),
      Book(id: '8', title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid', description: '', totalPages: 400, currentPage: 400, status: ReadingStatus.finished, coverUrl: ''),
    ];
  }

  // --- 1. Top Hero Banner Card ("A Good Book Always Finds You") ---
  Widget _buildHeroBannerCard(ReadingAppColors colors, bool isLight) {
    final cardBg = isLight ? const Color(0xFFEFE8DD) : const Color(0xFF1E1714);
    final textColor = isLight ? const Color(0xFF3E2D22) : const Color(0xFFE0C898);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE0D6C8) : const Color(0xFF322822)),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Pothos Ivy Plant in Ceramic Pot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 40,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFAF7F2) : const Color(0xFF2C241E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(10)),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              Positioned(
                top: -16,
                left: -8,
                child: SizedBox(
                  width: 52,
                  height: 42,
                  child: Stack(
                    children: const [
                      Positioned(top: 4, left: 0, child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22)),
                      Positioned(top: 0, left: 14, child: Icon(Icons.grass, color: Color(0xFF388E3C), size: 26)),
                      Positioned(top: 6, left: 28, child: Icon(Icons.eco, color: Color(0xFF1B5E20), size: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Center: Title Quote & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A Good Book\nAlways Finds You',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SAME SHELF, NEW WORLDS',
                  style: TextStyle(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Right: Handwritten Script Note ("Just one more chapter...")
          Column(
            children: [
              Text(
                '“Just one\nmore chapter...”',
                style: GoogleFonts.dancingScript(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              const Text('♥', style: TextStyle(fontSize: 8, color: Colors.amber)),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Controls Header (Only "Recently Added ˅" Dropdown) ---
  Widget _buildBookshelfControlsHeader(ReadingAppColors colors, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary, size: 18),
              dropdownColor: colors.cardBg,
              isDense: true,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
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
    );
  }

  // --- 3. Multi-Tier 3D Classic Wooden Bookcase ---
  Widget _buildClassicWoodenBookcase(
    BuildContext context,
    List<List<Book>> shelfTiers,
    Color woodColor,
    Color woodHighlight,
    ReadingAppColors colors,
    bool isLight,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFEBE2D3) : const Color(0xFF181412),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? const Color(0xFFD6C8B4) : const Color(0xFF2C221C)),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black45,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Trailing Pothos Vines Cascading Down Left Side of Entire Bookcase
          Positioned(
            top: 4,
            left: -10,
            bottom: 4,
            child: SizedBox(
              width: 32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Icon(Icons.eco, color: Color(0xFF2E7D32), size: 24),
                  Icon(Icons.grass, color: Color(0xFF388E3C), size: 22),
                  Icon(Icons.eco, color: Color(0xFF1B5E20), size: 20),
                  Icon(Icons.grass, color: Color(0xFF2E7D32), size: 20),
                  Icon(Icons.eco, color: Color(0xFF388E3C), size: 18),
                ],
              ),
            ),
          ),

          // Tiers Column
          Column(
            children: shelfTiers.asMap().entries.map((entry) {
              final tierBooks = entry.value;

              return Column(
                children: [
                  // Book Tier Row
                  Container(
                    height: 172,
                    padding: const EdgeInsets.only(left: 14, right: 6, top: 12, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: tierBooks.map((b) {
                        return Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomCenter,
                            child: _build3DFrontCoverBookItem(context, b, colors, isLight),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 3D Wooden Shelf Plank
                  _buildWoodenPlank(woodColor, woodHighlight),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 3D Front-Facing Book Item on Shelf ---
  Widget _build3DFrontCoverBookItem(BuildContext context, Book book, ReadingAppColors colors, bool isLight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Front Book Cover
          BookCoverImage(
            coverUrl: book.coverUrl,
            title: book.title,
            author: book.author,
            width: 68,
            height: 102,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 4),

          // Status & Progress Pill Badge Resting Below Cover
          _buildShelfBookPillBadge(book, colors, isLight),
        ],
      ),
    );
  }

  // --- Status & Page Fraction Pill Badge ---
  Widget _buildShelfBookPillBadge(Book book, ReadingAppColors colors, bool isLight) {
    final totalPages = book.totalPages > 0 ? book.totalPages : 300;
    Color bg;
    Color fg;
    String label;

    switch (book.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12, width: 0.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: fg),
          ),
          if (book.status == ReadingStatus.currentlyReading || book.status == ReadingStatus.finished) ...[
            const SizedBox(width: 4),
            Text(
              '${book.currentPage}/$totalPages',
              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }

  // --- 3D Bevelled Wooden Shelf Plank ---
  Widget _buildWoodenPlank(Color woodColor, Color woodHighlight) {
    return Container(
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: woodColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            woodHighlight,
            woodColor,
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }
}
