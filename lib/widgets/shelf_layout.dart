import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../theme/reading_app_colors.dart';
import 'flickering_candle_widget.dart';
import 'realistic_book_spine_widget.dart';

class ShelfLayout extends ConsumerWidget {
  final List<Book> books;
  const ShelfLayout({super.key, required this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    // Default reference books if empty, or use provided list
    final displayBooks = books.isNotEmpty ? books : _getSampleBooks();

    // Calculate dynamic row capacity based on screen width and slim spine widths
    final screenWidth = MediaQuery.of(context).size.width;
    final availableSpineWidth = screenWidth - 140; // Subtract padding & decor prop width
    final avgSpineWidth = 28.0;
    final maxBooksPerTier = (availableSpineWidth / avgSpineWidth).floor().clamp(5, 8);

    // Group books into dynamic shelf tiers
    List<List<Book>> shelfTiers = [];
    for (var i = 0; i < displayBooks.length; i += maxBooksPerTier) {
      shelfTiers.add(displayBooks.sublist(
        i,
        i + maxBooksPerTier > displayBooks.length ? displayBooks.length : i + maxItemsCount(displayBooks.length, i, maxBooksPerTier),
      ));
    }

    return Scaffold(
      backgroundColor: isLightMode ? const Color(0xFFF5EFE6) : const Color(0xFF100E0D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: Column(
          children: [
            // 1. Handwritten Italic Quote Subtitle & Heart Divider
            _buildHeaderQuoteSection(colors, isLightMode),
            const SizedBox(height: 12),

            // 2. Top Decorative Shelf Deck (Ivy Plant, Stacked Books, Mushroom Lamp, Picture Frame)
            _buildTopDecorationDeck(colors, isLightMode),
            _buildWoodenPlank(colors, isLightMode),
            const SizedBox(height: 16),

            // 3. Dynamic Multi-Tier 3D Dark Academia Bookshelf (Automatic Row Expansion)
            ...shelfTiers.asMap().entries.map((entry) {
              final tierIdx = entry.key;
              final tierBooks = entry.value;

              return Column(
                children: [
                  _buildMainBookshelfTier(context, tierBooks, tierIdx, colors, isLightMode),
                  _buildWoodenPlank(colors, isLightMode),
                  const SizedBox(height: 16),
                ],
              );
            }),

            // 4. Bottom Parchment Note Card Banner
            _buildBottomNoteCardBanner(colors, isLightMode),
          ],
        ),
      ),
    );
  }

  int maxItemsCount(int total, int start, int maxPerTier) {
    return (start + maxPerTier > total) ? (total - start) : maxPerTier;
  }

  // --- Sample Reference Books Matching Reference Screenshots if User Library is Empty ---
  List<Book> _getSampleBooks() {
    return [
      Book(id: '1', title: 'TWISTED LIES', author: 'ANA HUANG', description: '', totalPages: 480, coverUrl: ''),
      Book(id: '2', title: 'LOVE THEORY', author: 'ALI HAZELWOOD', description: '', totalPages: 380, coverUrl: ''),
      Book(id: '3', title: 'THE LOVE HYPOTHESIS', author: 'ALI HAZELWOOD', description: '', totalPages: 360, coverUrl: ''),
      Book(id: '4', title: 'IT ENDS WITH US', author: 'COLLEEN HOOVER', description: '', totalPages: 384, coverUrl: ''),
      Book(id: '5', title: 'SILENT PATIENT', author: 'ALEX MICHAELIDES', description: '', totalPages: 336, coverUrl: ''),
      Book(id: '6', title: 'FOURTH WING', author: 'REBECCA YARROS', description: '', totalPages: 528, coverUrl: ''),

      Book(id: '7', title: 'Atomic Habits', author: 'JAMES CLEAR', description: '', totalPages: 320, coverUrl: ''),
      Book(id: '8', title: 'Daisy Jones & The Six', author: 'TAYLOR JENKINS REID', description: '', totalPages: 368, coverUrl: ''),
      Book(id: '9', title: 'Verity', author: 'COLLEEN HOOVER', description: '', totalPages: 336, coverUrl: ''),
      Book(id: '10', title: 'The Midnight Library', author: 'MATT HAIG', description: '', totalPages: 304, coverUrl: ''),
      Book(id: '11', title: 'IKIGAI', author: 'HECTOR GARCIA', description: '', totalPages: 208, coverUrl: ''),
      Book(id: '12', title: 'A LITTLE LIFE', author: 'HANYA YANAGIHARA', description: '', totalPages: 720, coverUrl: ''),

      Book(id: '13', title: 'The Seven Husbands of Evelyn Hugo', author: 'TAYLOR JENKINS REID', description: '', totalPages: 400, coverUrl: ''),
      Book(id: '14', title: 'Project Hail Mary', author: 'ANDY WEIR', description: '', totalPages: 496, coverUrl: ''),
      Book(id: '15', title: 'The Song of Achilles', author: 'MADELINE MILLER', description: '', totalPages: 416, coverUrl: ''),
      Book(id: '16', title: 'Normal People', author: 'SALLY ROONEY', description: '', totalPages: 273, coverUrl: ''),
      Book(id: '17', title: 'Educated', author: 'TARA WESTOVER', description: '', totalPages: 352, coverUrl: ''),
      Book(id: '18', title: 'The Book Thief', author: 'MARKUS ZUSAK', description: '', totalPages: 584, coverUrl: ''),
      Book(id: '19', title: 'Where the Crawdads Sing', author: 'DELIA OWENS', description: '', totalPages: 384, coverUrl: ''),
      Book(id: '20', title: 'The Night Circus', author: 'ERIN MORGENSTERN', description: '', totalPages: 400, coverUrl: ''),
      Book(id: '21', title: 'Dune', author: 'FRANK HERBERT', description: '', totalPages: 688, coverUrl: ''),
      Book(id: '22', title: 'Sapiens', author: 'YUVAL NOAH HARARI', description: '', totalPages: 464, coverUrl: ''),
    ];
  }

  // --- 1. Header Quote & Heart Divider ---
  Widget _buildHeaderQuoteSection(ReadingAppColors colors, bool isLight) {
    final textColor = isLight ? const Color(0xFF5A3E2B) : const Color(0xFFE0C898);

    return Column(
      children: [
        Text(
          '“A home for every story you love”',
          style: GoogleFonts.playfairDisplay(
            fontSize: 19,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 1,
              color: textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.favorite,
              size: 9,
              color: textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 1,
              color: textColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. Top Decorative Shelf Deck ---
  Widget _buildTopDecorationDeck(ReadingAppColors colors, bool isLight) {
    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Mushroom Lamp Light Radial Glow
          Positioned(
            right: 110,
            bottom: 15,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFA726).withValues(alpha: isLight ? 0.35 : 0.45),
                    const Color(0xFFFFB74D).withValues(alpha: isLight ? 0.15 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Pothos Ivy Plant in Pot + Trailing Vines
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE8DFD1) : const Color(0xFF2C241E),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                        bottom: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.green[800],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -24,
                    left: -12,
                    child: SizedBox(
                      width: 68,
                      height: 48,
                      child: Stack(
                        children: const [
                          Positioned(top: 10, left: 0, child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 26)),
                          Positioned(top: 0, left: 16, child: Icon(Icons.grass, color: Color(0xFF388E3C), size: 30)),
                          Positioned(top: 8, left: 34, child: Icon(Icons.eco, color: Color(0xFF1B5E20), size: 24)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Stacked 3 Horizontal Beige Books ("Good Books", "Brighter", "Days ♥")
              _buildStackedHorizontalBooks(isLight),

              // Center: Cozy Mushroom Table Lamp
              _buildCozyMushroomLamp(isLight),

              // Right: Tilted Wooden Picture Frame ("More Stories Happier Days ♥")
              _buildTiltedPictureFrame(isLight),
            ],
          ),
        ],
      ),
    );
  }

  // --- Stacked Horizontal Books ("Good Books", "Brighter", "Days ♥") ---
  Widget _buildStackedHorizontalBooks(bool isLight) {
    final spineBg = isLight ? const Color(0xFFF0E8D9) : const Color(0xFFDCD2C0);
    final textColor = const Color(0xFF3E2D22);

    return Container(
      width: 78,
      height: 50,
      margin: const EdgeInsets.only(bottom: 2),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 15,
            width: 78,
            decoration: BoxDecoration(
              color: spineBg,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black26),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
            ),
            child: Center(
              child: Text(
                'Days ♥',
                style: GoogleFonts.crimsonPro(fontSize: 8.0, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
          Positioned(
            bottom: 13,
            child: Container(
              height: 15,
              width: 72,
              decoration: BoxDecoration(
                color: spineBg.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
              child: Center(
                child: Text(
                  'Brighter',
                  style: GoogleFonts.crimsonPro(fontSize: 8.0, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            child: Container(
              height: 15,
              width: 66,
              decoration: BoxDecoration(
                color: spineBg,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black26),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
              child: Center(
                child: Text(
                  'Good Books',
                  style: GoogleFonts.crimsonPro(fontSize: 8.0, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Center Cozy Vintage Mushroom Table Lamp ---
  Widget _buildCozyMushroomLamp(bool isLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warm Glowing Dome Mushroom Shade
        Container(
          width: 44,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF59D),
                Color(0xFFFFB74D),
                Color(0xFFF57C00),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withValues(alpha: 0.85),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Wooden Base
        Container(
          width: 12,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF3E2723),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            gradient: const LinearGradient(
              colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
            ),
          ),
        ),
      ],
    );
  }

  // --- Right Tilted Wooden Picture Frame ---
  Widget _buildTiltedPictureFrame(bool isLight) {
    final frameColor = const Color(0xFF4E342E);
    final innerBg = isLight ? const Color(0xFFFAF4EA) : const Color(0xFFF0E6D2);
    final textColor = const Color(0xFF3E2D22);

    return Transform.rotate(
      angle: 0.05,
      child: Container(
        width: 58,
        height: 78,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF6D4C41), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          color: innerBg,
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'More\nStories\nHappier\nDays ♥',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 8.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: textColor,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Main Bookcase Shelf Tier (Dynamic Multi-Tier Rows) ---
  Widget _buildMainBookshelfTier(
    BuildContext context,
    List<Book> tierBooks,
    int tierIndex,
    ReadingAppColors colors,
    bool isLight,
  ) {
    final decorMode = tierIndex % 3;

    return Container(
      height: 185,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFEBE2D3) : const Color(0xFF181412),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isLight ? const Color(0xFFD6C8B4) : const Color(0xFF2C221C)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Trailing Ivy Vines from Top Left
          Positioned(
            top: 0,
            left: -12,
            child: SizedBox(
              width: 36,
              height: 160,
              child: Column(
                children: const [
                  Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(height: 6),
                  Icon(Icons.grass, color: Color(0xFF1B5E20), size: 20),
                  SizedBox(height: 8),
                  Icon(Icons.eco, color: Color(0xFF388E3C), size: 18),
                  SizedBox(height: 10),
                  Icon(Icons.grass, color: Color(0xFF2E7D32), size: 16),
                ],
              ),
            ),
          ),

          // Main Books & Decor Row
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 10, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Slim Book Spines
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: tierBooks.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final book = entry.value;
                      return RealisticBookSpineWidget.fromBook(book, index: idx + (tierIndex * 8));
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 6),

                // Right Side Props & Fillers Matching Reference Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (decorMode == 0) ...[
                      _buildFlowerVase(isLight),
                      const SizedBox(width: 6),
                      _buildAmberCandleJar(isLight),
                    ] else if (decorMode == 1) ...[
                      _buildCelestialGlobe(isLight),
                      const SizedBox(width: 6),
                      _buildFramedQuoteProp('Collect\nBetter\nVersions\nOf Yourself', isLight),
                    ] else ...[
                      _buildMiniHorizontalBookStack(isLight),
                      const SizedBox(width: 6),
                      _buildPillarCandle(isLight),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Ceramic Vase with White Baby's Breath Flowers ---
  Widget _buildFlowerVase(bool isLight) {
    return SizedBox(
      height: 85,
      width: 32,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 26,
            height: 48,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF3EDE2) : const Color(0xFFD9CFBE),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(14),
              ),
              border: Border.all(color: Colors.black26),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: const [
                  Positioned(top: 0, left: 4, child: Icon(Icons.filter_vintage, color: Colors.white, size: 13)),
                  Positioned(top: 6, left: 18, child: Icon(Icons.filter_vintage, color: Colors.white, size: 15)),
                  Positioned(top: 16, left: 8, child: Icon(Icons.filter_vintage, color: Colors.white, size: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Amber Glass Candle Jar ("GOOD READS BRIGHTER DAYS ♥") ---
  Widget _buildAmberCandleJar(bool isLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FlickeringCandleWidget(height: 10, animate: true),
        const SizedBox(height: 2),
        Container(
          width: 34,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFB76E28),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF8C4A14)),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF8C4A14),
                Color(0xFFD98A38),
                Color(0xFF8C4A14),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2E8),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GOOD\nREADS',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 5.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 0.9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text('♥', style: TextStyle(fontSize: 4.5, color: Colors.brown)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Antique Celestial Globe ---
  Widget _buildCelestialGlobe(bool isLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            gradient: const RadialGradient(
              colors: [Color(0xFFA1887F), Color(0xFF4E342E)],
            ),
          ),
          child: const Icon(Icons.public, color: Color(0xFFD4AF37), size: 20),
        ),
        Container(
          width: 10,
          height: 12,
          color: const Color(0xFF4E342E),
        ),
      ],
    );
  }

  // --- Mini Framed Quote Prop ("Collect Better Versions Of Yourself") ---
  Widget _buildFramedQuoteProp(String text, bool isLight) {
    final frameColor = const Color(0xFF4E342E);
    final innerBg = isLight ? const Color(0xFFFAF4EA) : const Color(0xFFF0E6D2);
    final textColor = const Color(0xFF3E2D22);

    return Container(
      width: 52,
      height: 68,
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF6D4C41), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        color: innerBg,
        padding: const EdgeInsets.all(2),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.playfairDisplay(
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // --- Mini Horizontal Stack of Books ---
  Widget _buildMiniHorizontalBookStack(bool isLight) {
    final spineBg = isLight ? const Color(0xFFF0E8D9) : const Color(0xFFDCD2C0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 12,
          decoration: BoxDecoration(color: spineBg, borderRadius: BorderRadius.circular(2), border: Border.all(color: Colors.black26)),
        ),
        Container(
          width: 48,
          height: 12,
          decoration: BoxDecoration(color: spineBg.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(2), border: Border.all(color: Colors.black26)),
        ),
      ],
    );
  }

  // --- Pillar Candle ---
  Widget _buildPillarCandle(bool isLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FlickeringCandleWidget(height: 10, animate: true),
        Container(
          width: 22,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EFE6),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black26),
          ),
        ),
      ],
    );
  }

  // --- 3D Bevelled Wooden Shelf Plank ---
  Widget _buildWoodenPlank(ReadingAppColors colors, bool isLight) {
    final woodTop = isLight ? const Color(0xFFA1887F) : const Color(0xFF4E342E);
    final woodMid = isLight ? const Color(0xFF8D6E63) : const Color(0xFF3E2723);

    return Container(
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: woodMid,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            woodTop,
            woodMid,
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }

  // --- 4. Bottom Parchment Note Card Banner ---
  Widget _buildBottomNoteCardBanner(ReadingAppColors colors, bool isLight) {
    final bgCardColor = isLight ? const Color(0xFFEFE8DD) : const Color(0xFF1E1A17);
    final textColor = isLight ? const Color(0xFF3E2D22) : const Color(0xFFE0C898);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE0D6C8) : const Color(0xFF322822)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Open Book Icon + "Small steps Bigger stories ♥"
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFAF7F2) : Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 24,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Small steps',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Bigger stories ♥',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Taped Parchment Scrap Note ("Just one more chapter...")
          Transform.rotate(
            angle: -0.06,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFE3),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                  child: Text(
                    'Just one\nmore chapter...',
                    style: GoogleFonts.dancingScript(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C221A),
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  top: -6,
                  left: 10,
                  child: Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
