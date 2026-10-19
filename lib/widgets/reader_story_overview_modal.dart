import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../services/book_analyzer_service.dart';
import '../services/book_color_engine.dart';
import '../services/book_metadata_sanitizer.dart';
import '../services/book_search_service.dart';
import '../repositories/book_repository.dart';
import '../theme/reading_app_colors.dart';

class ReaderStoryOverviewModal extends StatefulWidget {
  final Book book;

  const ReaderStoryOverviewModal({super.key, required this.book});

  static Future<void> show(BuildContext context, {required Book book}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReaderStoryOverviewModal(book: book),
    );
  }

  @override
  State<ReaderStoryOverviewModal> createState() =>
      _ReaderStoryOverviewModalState();
}

class _ReaderStoryOverviewModalState extends State<ReaderStoryOverviewModal> {
  late BookAnalysisResult _analysis;
  String _synopsisText = '';
  bool _isLoadingSynopsis = false;

  @override
  void initState() {
    super.initState();
    _analysis = BookAnalyzerService.analyze(widget.book);
    _initSynopsis();
  }

  Future<void> _initSynopsis() async {
    final localDesc = widget.book.description.trim();
    if (localDesc.isNotEmpty &&
        !BookMetadataSanitizer.isTruncatedSynopsis(localDesc)) {
      setState(() {
        _synopsisText = BookMetadataSanitizer.sanitizeSynopsis(localDesc);
      });
      return;
    }

    setState(() => _isLoadingSynopsis = true);

    final fetched = await BookSearchService.fetchSynopsisForBook(
      title: widget.book.title,
      author: widget.book.author,
    );

    if (mounted) {
      if (fetched != null &&
          fetched.trim().isNotEmpty &&
          !BookMetadataSanitizer.isTruncatedSynopsis(fetched)) {
        final clean = BookMetadataSanitizer.sanitizeSynopsis(fetched);
        setState(() {
          _synopsisText = clean;
          _isLoadingSynopsis = false;
        });
        // Persist complete synopsis via repository so book is permanently healed
        final updated = widget.book.copyWith(description: clean);
        BookRepositoryImpl().updateBook(updated);
      } else {
        final sanitizedLocal = BookMetadataSanitizer.sanitizeSynopsis(localDesc);
        setState(() {
          _synopsisText = (sanitizedLocal.isNotEmpty &&
                  !BookMetadataSanitizer.isTruncatedSynopsis(sanitizedLocal))
              ? sanitizedLocal
              : widget.book.effectiveBlurb;
          _isLoadingSynopsis = false;
        });
      }
    }
  }

  Color _getScoreColor(double score, ReadingAppColors colors) {
    if (score >= 0.75) return colors.streakAmber;
    if (score >= 0.50) return colors.quoteGold;
    if (score >= 0.30) return colors.accentSage;
    return colors.accentOcean;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleInfo = BookMetadataSanitizer.parseTitleAndSeries(
      widget.book.title,
    );
    final colorHex = BookColorEngine.nextSpineColor(seed: widget.book.title);
    final spineColor = BookColorEngine.parseColor(colorHex);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: colors.streakAmber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Story Codex',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NARRATIVE ANATOMY & STORY OVERVIEW',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: colors.streakAmber,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scrollable Content
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Hero Identity Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover Thumbnail
                      Container(
                        width: 68,
                        height: 98,
                        decoration: BoxDecoration(
                          color: spineColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: widget.book.coverUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  widget.book.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        widget.book.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    widget.book.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleInfo.cleanTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'by ${widget.book.author}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.streakAmber.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: colors.streakAmber,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        widget.book.overallRating > 0
                                            ? widget.book.overallRating
                                                  .toStringAsFixed(1)
                                            : '9.4',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colors.streakAmber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.cardBgSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    _analysis.dominantGenre,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.quoteGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline Hook & Synopsis Section
                Container(
                  padding: const EdgeInsets.all(16),
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
                          Icon(
                            Icons.format_quote_rounded,
                            size: 16,
                            color: colors.quoteGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PREMISE & SYNOPSIS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: colors.quoteGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Lead Tagline Hook
                      Text(
                        '“${widget.book.effectiveTagline}”',
                        style: GoogleFonts.crimsonPro(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: colors.streakAmber,
                          height: 1.35,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 12),

                      // Plot Synopsis Body
                      _isLoadingSynopsis
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colors.streakAmber,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                String bodyText = _synopsisText.isNotEmpty
                                    ? _synopsisText
                                    : widget.book.effectiveBlurb;
                                final cleanHook = widget.book.effectiveTagline
                                    .replaceAll('“', '')
                                    .replaceAll('”', '')
                                    .replaceAll('"', '')
                                    .trim();
                                if (cleanHook.isNotEmpty &&
                                    bodyText.startsWith(cleanHook)) {
                                  final remaining = bodyText
                                      .substring(cleanHook.length)
                                      .trim();
                                  if (remaining.length > 30) {
                                    bodyText = remaining;
                                  }
                                }
                                return Text(
                                  bodyText,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.textPrimary,
                                    height: 1.5,
                                  ),
                                  maxLines: null,
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Narrative DNA & Tropes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.style_rounded,
                            size: 16,
                            color: colors.streakAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NARRATIVE DNA & TROPES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: colors.streakAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _analysis.tropesAndThemes.map((trope) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardBgSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.streakAmber.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 13,
                                  color: colors.streakAmber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trope,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Pacing & Tone Pills
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoPill(
                              colors,
                              label: 'PACING',
                              value: _analysis.pacing,
                              icon: Icons.speed_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoPill(
                              colors,
                              label: 'TONE',
                              value: _analysis.tone,
                              icon: Icons.psychology_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thematic Heat Spectrum
                Container(
                  padding: const EdgeInsets.all(16),
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
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 16,
                            color: colors.quoteGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'THEMATIC HEAT SPECTRUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: colors.quoteGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._analysis.thematicScores.entries.map((e) {
                        final scorePct = (e.value * 100).toInt();
                        final meterColor = _getScoreColor(e.value, colors);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$scorePct%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: meterColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: e.value,
                                  minHeight: 6,
                                  backgroundColor: colors.cardBg,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    meterColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(
    ReadingAppColors colors, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: colors.streakAmber),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
