import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../screens/book_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';

enum SpineIllustrationType {
  botanicalBranch,
  leafSprig,
  floralHeart,
  moonAndStars,
  leafyStem,
  dragonCrest,
  classicFleuron,
}

class RealisticBookSpineWidget extends StatefulWidget {
  final Book book;
  final double spineWidth;
  final double spineHeight;
  final Color spineColor;
  final Color textColor;
  final Color accentColor;
  final double tiltAngle;
  final SpineIllustrationType illustrationType;

  const RealisticBookSpineWidget({
    super.key,
    required this.book,
    this.spineWidth = 28.0,
    this.spineHeight = 136.0,
    required this.spineColor,
    required this.textColor,
    this.accentColor = const Color(0xFFD4AF37),
    this.tiltAngle = 0.0,
    this.illustrationType = SpineIllustrationType.botanicalBranch,
  });

  factory RealisticBookSpineWidget.fromBook(Book book, {int index = 0}) {
    final titleUpper = book.title.toUpperCase();

    // Specific preset themes matching reference design for known titles
    if (titleUpper.contains('TWISTED LIES')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 28,
        spineHeight: 138,
        spineColor: const Color(0xFFF1E9DA), // Cream Ivory Leather
        textColor: const Color(0xFF2B2118),   // Deep Espresso Ink
        accentColor: const Color(0xFF8B6B3E),
        illustrationType: SpineIllustrationType.botanicalBranch,
      );
    } else if (titleUpper.contains('LOVE THEORY')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 28,
        spineHeight: 136,
        spineColor: const Color(0xFF334B3B), // Sage Green
        textColor: const Color(0xFFF3E5AB),   // Gold Foil
        accentColor: const Color(0xFFD4AF37),
        illustrationType: SpineIllustrationType.leafSprig,
      );
    } else if (titleUpper.contains('LOVE HYPOTHESIS')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 30,
        spineHeight: 138,
        spineColor: const Color(0xFF7D3C48), // Dusty Rose / Maroon
        textColor: const Color(0xFFF3E5AB),   // Gold Foil
        accentColor: const Color(0xFFE0A96D),
        illustrationType: SpineIllustrationType.floralHeart,
      );
    } else if (titleUpper.contains('IT ENDS WITH US')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 28,
        spineHeight: 135,
        spineColor: const Color(0xFF1B2840), // Midnight Navy
        textColor: const Color(0xFFF0D8A8),   // Gold Foil
        accentColor: const Color(0xFFD4AF37),
        illustrationType: SpineIllustrationType.moonAndStars,
      );
    } else if (titleUpper.contains('SILENT PATIENT')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 28,
        spineHeight: 138,
        spineColor: const Color(0xFFDDD0B9), // Warm Sand
        textColor: const Color(0xFF2C221A),   // Deep Charcoal Espresso
        accentColor: const Color(0xFF7A6246),
        illustrationType: SpineIllustrationType.leafyStem,
      );
    } else if (titleUpper.contains('FOURTH WING')) {
      return RealisticBookSpineWidget(
        book: book,
        spineWidth: 32,
        spineHeight: 140,
        spineColor: const Color(0xFF4A3428), // Dark Chocolate Bronze
        textColor: const Color(0xFFF0D8A8),   // Gold Foil
        accentColor: const Color(0xFFD4AF37),
        illustrationType: SpineIllustrationType.dragonCrest,
      );
    }

    // Dynamic 12-palette Dark Academia generator for ANY arbitrary book added by the user
    final List<Map<String, dynamic>> darkAcademiaPalettes = [
      {
        'color': const Color(0xFFF1E9DA), // Cream Ivory Leather
        'text': const Color(0xFF2B2118),
        'accent': const Color(0xFF8B6B3E),
        'icon': SpineIllustrationType.botanicalBranch,
      },
      {
        'color': const Color(0xFF334B3B), // Forest Sage Green
        'text': const Color(0xFFF3E5AB),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.leafSprig,
      },
      {
        'color': const Color(0xFF7D3C48), // Dusty Rose Maroon
        'text': const Color(0xFFF3E5AB),
        'accent': const Color(0xFFE0A96D),
        'icon': SpineIllustrationType.floralHeart,
      },
      {
        'color': const Color(0xFF1B2840), // Midnight Navy Morocco
        'text': const Color(0xFFF0D8A8),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.moonAndStars,
      },
      {
        'color': const Color(0xFFDDD0B9), // Warm Sand Linen
        'text': const Color(0xFF2C221A),
        'accent': const Color(0xFF7A6246),
        'icon': SpineIllustrationType.leafyStem,
      },
      {
        'color': const Color(0xFF4A3428), // Dark Chocolate Bronze
        'text': const Color(0xFFF0D8A8),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.dragonCrest,
      },
      {
        'color': const Color(0xFF5B1728), // Burgundy Velvet
        'text': const Color(0xFFF5E1B8),
        'accent': const Color(0xFFE5C158),
        'icon': SpineIllustrationType.classicFleuron,
      },
      {
        'color': const Color(0xFF2E4057), // Weathered Slate Blue
        'text': const Color(0xFFEFE6D5),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.moonAndStars,
      },
      {
        'color': const Color(0xFF6B1D1D), // Vintage Oxblood Red
        'text': const Color(0xFFF5E1B8),
        'accent': const Color(0xFFE0A96D),
        'icon': SpineIllustrationType.floralHeart,
      },
      {
        'color': const Color(0xFF1E1E24), // Midnight Ebony
        'text': const Color(0xFFE5C158),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.dragonCrest,
      },
      {
        'color': const Color(0xFF4A2545), // Deep Plum Velvet
        'text': const Color(0xFFF5E1B8),
        'accent': const Color(0xFFE0A96D),
        'icon': SpineIllustrationType.botanicalBranch,
      },
      {
        'color': const Color(0xFF8B4513), // Cinnamon Leather
        'text': const Color(0xFFFFF3CD),
        'accent': const Color(0xFFD4AF37),
        'icon': SpineIllustrationType.leafSprig,
      },
    ];

    // Compute deterministic palette index from book properties
    final seed = (index * 7 + book.id.hashCode.abs() + book.title.hashCode.abs());
    final palette = darkAcademiaPalettes[seed % darkAcademiaPalettes.length];

    // Compute dynamic slim spine height & width (varying dynamically between 24px and 34px)
    final pageCount = book.totalPages > 0 ? book.totalPages : 300;
    final height = 126.0 + ((pageCount + seed) % 15);
    final width = 24.0 + ((book.title.length + seed) % 10);

    return RealisticBookSpineWidget(
      book: book,
      spineWidth: width.clamp(24.0, 34.0),
      spineHeight: height.clamp(126.0, 142.0),
      spineColor: palette['color'] as Color,
      textColor: palette['text'] as Color,
      accentColor: palette['accent'] as Color,
      tiltAngle: 0.0,
      illustrationType: palette['icon'] as SpineIllustrationType,
    );
  }

  @override
  State<RealisticBookSpineWidget> createState() => _RealisticBookSpineWidgetState();
}

class _RealisticBookSpineWidgetState extends State<RealisticBookSpineWidget> {
  bool _isHovered = false;

  void _showQuickPreviewSheet(BuildContext context) {
    final colors = context.appColors;
    final progressPct = widget.book.progress.clamp(0.0, 1.0);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCoverImage(
                    coverUrl: widget.book.coverUrl,
                    title: widget.book.title,
                    author: widget.book.author,
                    width: 80,
                    height: 115,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${widget.book.author}',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.streakAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.streakAmber),
                              ),
                              child: Text(
                                widget.book.format.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colors.streakAmber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progressPct * 100).toInt()}% Read',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.quoteGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookDetailScreen(book: widget.book)),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Book Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReaderScreen(book: widget.book)),
                        );
                      },
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Open Reader'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.streakAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpineIllustration() {
    final color = widget.accentColor;

    switch (widget.illustrationType) {
      case SpineIllustrationType.botanicalBranch:
      case SpineIllustrationType.leafSprig:
        return Icon(Icons.eco_outlined, size: 12, color: color);
      case SpineIllustrationType.floralHeart:
        return Icon(Icons.favorite_border, size: 11, color: color);
      case SpineIllustrationType.moonAndStars:
        return Icon(Icons.nightlight_round, size: 10, color: color);
      case SpineIllustrationType.leafyStem:
        return Icon(Icons.grass, size: 12, color: color);
      case SpineIllustrationType.dragonCrest:
        return Icon(Icons.auto_awesome_motion, size: 12, color: color);
      case SpineIllustrationType.classicFleuron:
        return Icon(Icons.auto_awesome_sharp, size: 11, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.book.status == ReadingStatus.finished;
    final isReading = widget.book.status == ReadingStatus.currentlyReading;

    Widget spineContent = GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: widget.book)),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showQuickPreviewSheet(context);
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 3D Leather/Cloth Spine Body
            Container(
              width: widget.spineWidth,
              height: widget.spineHeight,
              decoration: BoxDecoration(
                color: widget.spineColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                  bottom: Radius.circular(2),
                ),
                // Photorealistic 3D Cylindrical Shading
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    widget.spineColor.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.35), // Center specular light sheen
                    widget.spineColor,
                    Colors.black.withValues(alpha: 0.60),
                  ],
                  stops: const [0.0, 0.18, 0.44, 0.78, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: _isHovered ? 10 : 6,
                    offset: Offset(_isHovered ? -3 : -2, _isHovered ? 5 : 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gold Ribbed Bands (Top Spine)
                  Positioned(top: 6, left: 0, right: 0, child: _buildRibbedLine(widget.accentColor)),
                  Positioned(top: 9, left: 0, right: 0, child: _buildRibbedLine(widget.accentColor)),

                  // Gold Ribbed Bands (Bottom Spine)
                  Positioned(bottom: 6, left: 0, right: 0, child: _buildRibbedLine(widget.accentColor)),
                  Positioned(bottom: 9, left: 0, right: 0, child: _buildRibbedLine(widget.accentColor)),

                  // Content Column (Top Ornament, Vertical Title, Botanical Emblem, Author)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Illustration Emblem
                        _buildSpineIllustration(),

                        // Vertical Title & Author
                        Expanded(
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.book.title.toUpperCase(),
                                      style: GoogleFonts.crimsonPro(
                                        color: widget.textColor,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        height: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: widget.textColor == Colors.white || widget.textColor.computeLuminance() > 0.5
                                                ? Colors.black87
                                                : Colors.white54,
                                            blurRadius: 1,
                                            offset: const Offset(0.5, 0.5),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.book.author.toUpperCase(),
                                      style: TextStyle(
                                        color: widget.textColor.withValues(alpha: 0.8),
                                        fontSize: 6.0,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Emblem
                        _buildSpineIllustration(),
                      ],
                    ),
                  ),

                  // Reading Status Finished Badge
                  if (isFinished)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bookmark Ribbon Tail (for reading books)
            if (isReading || widget.book.progress > 0)
              Positioned(
                bottom: -10,
                child: Container(
                  width: 6,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.tiltAngle != 0.0) {
      spineContent = Transform.rotate(
        angle: widget.tiltAngle * pi / 180,
        alignment: Alignment.bottomCenter,
        child: spineContent,
      );
    }

    return spineContent;
  }

  Widget _buildRibbedLine(Color accent) {
    return Container(
      height: 1.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            accent,
            accent.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}
