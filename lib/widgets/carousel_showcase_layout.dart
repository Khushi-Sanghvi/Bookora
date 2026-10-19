import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../screens/pdf_reader_screen.dart';
import '../screens/epub_reader_screen.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

class CarouselShowcaseLayout extends StatefulWidget {
  final List<Book> books;

  const CarouselShowcaseLayout({super.key, required this.books});

  @override
  State<CarouselShowcaseLayout> createState() => _CarouselShowcaseLayoutState();
}

class _CarouselShowcaseLayoutState extends State<CarouselShowcaseLayout> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.58,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.books.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    if (widget.books.isEmpty) {
      return Scaffold(
        backgroundColor: isLightMode ? const Color(0xFFFAF7F2) : const Color(0xFF141210),
        body: Center(
          child: Text('Your library is empty. Add some books!', style: TextStyle(color: colors.textSecondary)),
        ),
      );
    }

    final activeBook = widget.books[_currentIndex.clamp(0, widget.books.length - 1)];
    final progressPercent = activeBook.progress.clamp(0.0, 1.0);

    final bgGradient = isLightMode
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF7F2),
              Color(0xFFF3ECE2),
              Color(0xFFEBE3D5),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF181614),
              Color(0xFF141210),
              Color(0xFF0F0D0C),
            ],
          );

    return Scaffold(
      backgroundColor: isLightMode ? const Color(0xFFFAF7F2) : const Color(0xFF141210),
      body: Stack(
        children: [
          // 1. Background Paper Gradient
          Positioned.fill(
            child: Container(decoration: BoxDecoration(gradient: bgGradient)),
          ),

          // 2. Main Carousel & Focus Content Column
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                // 3D Carousel Stage with Left/Right Arrows
                SizedBox(
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.books.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 0.0;
                              if (_pageController.position.haveDimensions) {
                                value = index - (_pageController.page ?? 0);
                              } else {
                                value = (index - _currentIndex).toDouble();
                              }

                              final isCenter = index == _currentIndex;
                              final scale = (1 - (value.abs() * 0.22)).clamp(0.75, 1.0);
                              final opacity = (1 - (value.abs() * 0.4)).clamp(0.5, 1.0);

                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!isCenter) {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => BookDetailScreen(book: activeBook)),
                                        );
                                      }
                                    },
                                    child: Center(
                                      child: BookCoverImage(
                                        coverUrl: widget.books[index].coverUrl,
                                        title: widget.books[index].title,
                                        author: widget.books[index].author,
                                        width: isCenter ? 160 : 135,
                                        height: isCenter ? 230 : 190,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Left Arrow Button
                      if (_currentIndex > 0)
                        Positioned(
                          left: 12,
                          child: GestureDetector(
                            onTap: _previousPage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isLightMode ? Colors.white : const Color(0xFF1E1F24)).withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.borderSubtle),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Icon(Icons.chevron_left, color: colors.textPrimary, size: 20),
                            ),
                          ),
                        ),

                      // Right Arrow Button
                      if (_currentIndex < widget.books.length - 1)
                        Positioned(
                          right: 12,
                          child: GestureDetector(
                            onTap: _nextPage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isLightMode ? Colors.white : const Color(0xFF1E1F24)).withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.borderSubtle),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Icon(Icons.chevron_right, color: colors.textPrimary, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Featured Active Book Title & Author
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        activeBook.title,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${activeBook.author}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Reading Progress Slider Track & Pages
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                minHeight: 8,
                                backgroundColor: colors.borderSubtle,
                                valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${activeBook.currentPage} / ${activeBook.totalPages} pages',
                                style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Prominent "Continue Reading" Action Button
                      SizedBox(
                        width: 220,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (activeBook.format == BookFormat.pdf) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PdfReaderScreen(book: activeBook)));
                            } else if (activeBook.format == BookFormat.epub) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EpubReaderScreen(book: activeBook)));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailScreen(book: activeBook)));
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Continue Reading', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.streakAmber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Center Quote Motto Banner ("Good books, brighter days.")
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 30, height: 1, color: colors.borderSubtle),
                    const SizedBox(width: 10),
                    Text(
                      '“Good books, brighter days.”',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: colors.quoteGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.eco, size: 14, color: isLightMode ? const Color(0xFF2E7D32) : const Color(0xFF629677)),
                    const SizedBox(width: 10),
                    Container(width: 30, height: 1, color: colors.borderSubtle),
                  ],
                ),

                const SizedBox(height: 20),

                // Decorative Stack of Hardcovers & Coffee Mug Section
                _buildBottomDecorProps(isLightMode, colors),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDecorProps(bool isLightMode, ReadingAppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Stack of Hardcover Books on Bottom Left
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLightMode ? const Color(0xFFEFE8DD) : const Color(0xFF221E1B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A NEW\nCHAPTER\nEVERYDAY',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Coffee Mug on Bottom Right
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLightMode ? Colors.white : const Color(0xFF1E1F24),
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderSubtle, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Books\n&\nBetter\nDays ♡',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: colors.textPrimary,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
