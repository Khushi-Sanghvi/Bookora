import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../theme/reading_app_colors.dart';

class PolaroidScrapbookLayout extends StatelessWidget {
  final List<Book> books;

  const PolaroidScrapbookLayout({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

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
          // 1. Scrapbook Paper Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: bgGradient),
            ),
          ),

          // 2. Main Scrollable Scrapbook Canvas
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calligraphy Header Note & String Lights
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Books Make Life',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: isLightMode ? const Color(0xFF3E2723) : const Color(0xFFE0A96D),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Prettier ♡',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: isLightMode ? const Color(0xFFB8521B) : const Color(0xFFFFA726),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (!isLightMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'A Happier You ♡',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFE0A96D),
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.nightlight_round, color: Color(0xFFFFD54F), size: 14),
                              SizedBox(width: 4),
                              Icon(Icons.star, color: Color(0xFFFFD54F), size: 10),
                            ],
                          ),
                        ],
                      )
                    else
                      const Icon(Icons.eco, color: Color(0xFF388E3C), size: 28),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Dynamic Staggered Polaroid Photo Grid
                if (books.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'No books found in this shelf view.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: books.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final book = entry.value;
                      return _buildPolaroidCard(context, book, idx, isLightMode, colors);
                    }).toList(),
                  ),

                const SizedBox(height: 30),

                // 4. Decorative Scrapbook Paper Notes & Coffee Cup Section
                _buildScrapbookDecoSection(isLightMode, colors),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Single Polaroid Photo Frame Widget ---
  Widget _buildPolaroidCard(
    BuildContext context,
    Book book,
    int index,
    bool isLightMode,
    ReadingAppColors colors,
  ) {
    // Alternate subtle rotations for organic scrapbook look
    final rotations = [-0.04, 0.03, -0.02, 0.04, -0.03, 0.02];
    final angle = rotations[index % rotations.length];

    String statusLabel = 'Story ♡';
    switch (book.status) {
      case ReadingStatus.currentlyReading:
        statusLabel = 'Currently Read ♡';
        break;
      case ReadingStatus.toRead:
        statusLabel = 'Next ♡';
        break;
      case ReadingStatus.finished:
        statusLabel = 'Finished ♡';
        break;
      case ReadingStatus.wishlist:
        statusLabel = 'Wishlist ♡';
        break;
      case ReadingStatus.abandoned:
        statusLabel = 'Paused ♡';
        break;
    }

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
          );
        },
        child: Container(
          width: 155,
          padding: const EdgeInsets.only(top: 12, left: 10, right: 10, bottom: 14),
          decoration: BoxDecoration(
            color: isLightMode ? const Color(0xFFFDFBF7) : const Color(0xFFF9F7F1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isLightMode ? const Color(0xFFE8E2D5) : const Color(0xFFD7CCC8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLightMode ? 0.12 : 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Washi Tape on Top Center
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 45,
                  height: 12,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (isLightMode ? const Color(0xFFE0D5C1) : const Color(0xFFBCAAA4))
                        .withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Polaroid Photo Window (Book Cover)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  width: 135,
                  height: 185,
                  color: const Color(0xFF1E1F24),
                  child: CachedNetworkImage(
                    imageUrl: book.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[800]),
                    errorWidget: (context, url, error) => _buildFallbackCover(book),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Handwritten Script Label
              Text(
                statusLabel,
                style: GoogleFonts.crimsonPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF3E2723),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(Book book) {
    return Container(
      color: const Color(0xFF2E241E),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories, color: Color(0xFFE0A96D), size: 24),
          const SizedBox(height: 6),
          Text(
            book.title.toUpperCase(),
            style: GoogleFonts.crimsonPro(
              color: const Color(0xFFE0A96D),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Decorative Scrapbook Paper Notes & Coffee Cup Section ---
  Widget _buildScrapbookDecoSection(bool isLightMode, ReadingAppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Torn Craft Paper Note 1
        Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLightMode ? const Color(0xFFEFE8DD) : const Color(0xFF2E2722),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isLightMode ? const Color(0xFFD7CCC8) : const Color(0xFF4E342E)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Same\nBooks\nBrighter\nDays',
                style: GoogleFonts.crimsonPro(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: isLightMode ? const Color(0xFF3E2723) : const Color(0xFFE0A96D),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text('♡', style: TextStyle(color: Color(0xFFC66323), fontSize: 10)),
            ],
          ),
        ),

        // Heart Latte Art Coffee Cup
        Container(
          width: 75,
          height: 75,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : const Color(0xFF231C18),
            shape: BoxShape.circle,
            border: Border.all(color: isLightMode ? const Color(0xFFD7CCC8) : const Color(0xFF5D4037), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6D4C41),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.favorite, color: Color(0xFFD7CCC8), size: 28),
                  Icon(Icons.coffee, color: Color(0xFF3E2723), size: 16),
                ],
              ),
            ),
          ),
        ),

        // Torn Craft Paper Note 2
        Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLightMode ? const Color(0xFFEFE8DD) : const Color(0xFF2E2722),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isLightMode ? const Color(0xFFD7CCC8) : const Color(0xFF4E342E)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good\nBooks\nGood Mood',
                style: GoogleFonts.crimsonPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: isLightMode ? const Color(0xFF3E2723) : const Color(0xFFE0A96D),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text('♡', style: TextStyle(color: Color(0xFFC66323), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
