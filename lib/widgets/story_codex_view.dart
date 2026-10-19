import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../models/story_codex.dart';
import '../services/book_color_engine.dart';
import '../services/book_metadata_sanitizer.dart';
import '../services/book_search_service.dart';
import '../repositories/book_repository.dart';
import '../services/story_codex_engine.dart';
import '../services/story_codex_service.dart';
import 'bookora_floral_dialog.dart';

class StoryCodexContentView extends StatefulWidget {
  final Book book;
  final StoryCodex? codex;
  final bool isModal;
  final ScrollController? scrollController;

  const StoryCodexContentView({
    super.key,
    required this.book,
    this.codex,
    this.isModal = false,
    this.scrollController,
  });

  @override
  State<StoryCodexContentView> createState() => _StoryCodexContentViewState();
}

/// Backward compatibility alias for StoryCodexContentView
typedef StoryCodexView = StoryCodexContentView;

class _StoryCodexContentViewState extends State<StoryCodexContentView> {
  late StoryCodex _codex;
  String _synopsis = '';
  bool _isLoadingSynopsis = false;
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    // 1. Instantaneous synchronous render from cache or fast engine (< 0.01ms)
    try {
      _codex =
          widget.codex ??
          StoryCodexService.getCachedCodexSync(widget.book.id) ??
          StoryCodexEngine.generateCodex(widget.book);
    } catch (_) {
      _codex = StoryCodexEngine.generateCodex(widget.book);
    }
    _synopsis = _codex.synopsis;
    _checkAndFetchSynopsis();
    _loadEnrichedCodexAsync();
  }

  Future<void> _loadEnrichedCodexAsync() async {
    if (widget.codex != null) return;
    try {
      final enriched = await StoryCodexService.getCodexForBook(widget.book);
      if (mounted) {
        setState(() {
          _codex = enriched;
          if (enriched.synopsis.isNotEmpty &&
              !BookMetadataSanitizer.isTruncatedSynopsis(enriched.synopsis)) {
            _synopsis = enriched.synopsis;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant StoryCodexContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.book.description != widget.book.description) {
      setState(() {
        try {
          _codex =
              widget.codex ??
              StoryCodexService.getCachedCodexSync(widget.book.id) ??
              StoryCodexEngine.generateCodex(widget.book);
        } catch (_) {
          _codex = StoryCodexEngine.generateCodex(widget.book);
        }
        _synopsis = _codex.synopsis;
      });
      _checkAndFetchSynopsis();
      _loadEnrichedCodexAsync();
    }
  }

  Future<void> _checkAndFetchSynopsis() async {
    final cleanDesc = widget.book.description.trim();
    final isTruncated = BookMetadataSanitizer.isTruncatedSynopsis(cleanDesc);

    if (!isTruncated) {
      final sanitized = BookMetadataSanitizer.sanitizeSynopsis(cleanDesc);
      if (mounted) {
        setState(() {
          _synopsis = sanitized;
          _codex = _codex.copyWith(synopsis: sanitized);
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingSynopsis = true);
    }

    try {
      final fetched = await BookSearchService.fetchSynopsisForBook(
        title: widget.book.title,
        author: widget.book.author,
      );

      if (mounted) {
        if (fetched != null &&
            fetched.trim().isNotEmpty &&
            !BookMetadataSanitizer.isTruncatedSynopsis(fetched)) {
          final cleanFetched = BookMetadataSanitizer.sanitizeSynopsis(fetched);
          setState(() {
            _synopsis = cleanFetched;
            _codex = _codex.copyWith(synopsis: cleanFetched);
            _isLoadingSynopsis = false;
          });
          // Heal persistence through repository
          final updated = widget.book.copyWith(description: cleanFetched);
          BookRepositoryImpl().updateBook(updated);
        } else {
          setState(() {
            _isLoadingSynopsis = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSynopsis = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dual Theme Tokens: Obsidian Library (Dark) vs. Warm Parchment (Light)
    final cardBg = isDark ? const Color(0xFF181A22) : const Color(0xFFFFFFFF);
    final cardBgSubtle = isDark
        ? const Color(0xFF1E212D)
        : const Color(0xFFF7F5F0);
    final borderColor = isDark
        ? const Color(0xFF282C3B)
        : const Color(0xFFE5DFC9);
    final textPrimary = isDark
        ? const Color(0xFFE0D8C3)
        : const Color(0xFF231F1C);
    final textSecondary = isDark
        ? const Color(0xFFA09B8E)
        : const Color(0xFF6B655B);
    final accentGold = isDark
        ? const Color(0xFFFFA726)
        : const Color(0xFFD97706);
    final accentParchment = isDark
        ? const Color(0xFFE0A96D)
        : const Color(0xFFB45309);
    final highlightPill = isDark
        ? const Color(0xFF2A2D3C)
        : const Color(0xFFEDE8DA);

    final titleInfo = BookMetadataSanitizer.parseTitleAndSeries(
      widget.book.title,
    );
    final spineColor = BookColorEngine.parseColor(
      BookColorEngine.nextSpineColor(seed: widget.book.title),
    );

    final content = <Widget>[
      // 1. Hero Identity Banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 104,
              decoration: BoxDecoration(
                color: spineColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: widget.book.coverUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackCover(),
                      ),
                    )
                  : _buildFallbackCover(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'STORY CODEX • NARRATIVE ANATOMY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: accentGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titleInfo.cleanTitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${widget.book.author}',
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (widget.book.genres.isNotEmpty)
                        ...widget.book.genres
                            .take(2)
                            .map(
                              (genre) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: highlightPill,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: accentParchment,
                                  ),
                                ),
                              ),
                            )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: highlightPill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            'Fiction',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: accentParchment,
                            ),
                          ),
                        ),
                      if ((_codex.timePeriod ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: highlightPill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            _codex.timePeriod!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
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
      const SizedBox(height: 14),

      // 2. PREMISE & SYNOPSIS HERO CARD (Uncapped maxLines: spans full length as needed)
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 17, color: accentGold),
                const SizedBox(width: 8),
                Text(
                  'PREMISE & SYNOPSIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accentGold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingSynopsis)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentGold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Lead Premise Hook - Styled blockquote hook
            Text(
              '“${_codex.premise.isNotEmpty ? _codex.premise : widget.book.effectiveTagline}”',
              style: GoogleFonts.crimsonPro(
                fontSize: 16.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: accentParchment,
                height: 1.38,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 14),

            // Complete Story Overview / Synopsis with deduplication and expandable Read more/less
            Builder(
              builder: (context) {
                final leadHook = _codex.premise.isNotEmpty
                    ? _codex.premise
                    : widget.book.effectiveTagline;
                String bodyText = _synopsis.isNotEmpty
                    ? _synopsis
                    : widget.book.effectiveBlurb;

                // Deduplicate if body starts with the lead hook
                final cleanHook = leadHook
                    .replaceAll('“', '')
                    .replaceAll('”', '')
                    .replaceAll('"', '')
                    .trim();
                if (cleanHook.isNotEmpty && bodyText.startsWith(cleanHook)) {
                  final remaining = bodyText.substring(cleanHook.length).trim();
                  if (remaining.length > 30) {
                    bodyText = remaining;
                  }
                }

                final bool canExpand =
                    bodyText.length > 220 || bodyText.contains('\n\n');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bodyText,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textPrimary,
                        height: 1.58,
                      ),
                      maxLines: (_isSynopsisExpanded || !canExpand) ? null : 6,
                      overflow: (_isSynopsisExpanded || !canExpand)
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (canExpand) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(
                            () => _isSynopsisExpanded = !_isSynopsisExpanded,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSynopsisExpanded
                                    ? 'Read less ∧'
                                    : 'Read more ∨',
                                style: TextStyle(
                                  color: accentGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 3. WORLDBUILDING & SETTING CARD
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public_rounded, size: 16, color: accentGold),
                const SizedBox(width: 8),
                Text(
                  'WORLDBUILDING & SETTING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSettingRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: _codex.setting,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentGold,
            ),
            const SizedBox(height: 10),
            _buildSettingRow(
              icon: Icons.schedule_rounded,
              label: 'Time Period',
              value: _codex.timePeriod ?? 'Contemporary Era',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentGold,
            ),
            const SizedBox(height: 10),
            _buildSettingRow(
              icon: Icons.wb_twilight_rounded,
              label: 'Atmosphere',
              value: _codex.atmosphere,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentGold,
            ),
            const SizedBox(height: 10),
            _buildSettingRow(
              icon: Icons.travel_explore_rounded,
              label: 'World Scope',
              value: _resolveWorldScope(_codex),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentGold,
            ),
            if (_codex.worldbuildingTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _codex.worldbuildingTags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: highlightPill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentParchment,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 4. FIGURES OF DESTINY (LEAD CHARACTERS & CAST)
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: accentGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIGURES OF DESTINY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: accentGold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The minds and souls driving the narrative',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showCharacterDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: accentGold),
                        const SizedBox(width: 4),
                        Text(
                          'Add Character',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_codex.characters.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBgSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 24,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cast details being chronicled',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The key figures and souls for this narrative are being charted.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showCharacterDialog(context),
                      icon: Icon(Icons.add_rounded, size: 15, color: accentGold),
                      label: Text(
                        'Add First Character',
                        style: TextStyle(
                          color: accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: accentGold.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._codex.characters.asMap().entries.map(
                (entry) => _buildCharacterCard(
                  entry.value,
                  cardBgSubtle: cardBgSubtle,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accentGold: accentGold,
                  accentParchment: accentParchment,
                  onEdit: () => _showCharacterDialog(
                    context,
                    character: entry.value,
                    index: entry.key,
                  ),
                  onDelete: () => _removeCharacter(entry.key),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 5. NARRATIVE DNA & TROPES
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 17,
                  color: accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'NARRATIVE DNA & TROPES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _codex.tropes.map((trope) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardBgSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 13,
                        color: accentGold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        trope,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'PACING',
                    value: _codex.pacing ?? 'Medium',
                    icon: Icons.speed_rounded,
                    bg: cardBgSubtle,
                    border: borderColor,
                    textPrimary: textPrimary,
                    accent: accentGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'TONE',
                    value: _codex.tone,
                    icon: Icons.psychology_rounded,
                    bg: cardBgSubtle,
                    border: borderColor,
                    textPrimary: textPrimary,
                    accent: accentGold,
                  ),
                ),
                if (_codex.povType != null && _codex.povType!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'POV',
                      value: _codex.povType!,
                      icon: Icons.visibility_outlined,
                      bg: cardBgSubtle,
                      border: borderColor,
                      textPrimary: textPrimary,
                      accent: accentParchment,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 6. 5D FLAVOR PROFILE METERS
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 17, color: accentGold),
                const SizedBox(width: 8),
                Text(
                  '5D NARRATIVE FLAVOR PROFILE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final spice = widget.book.spiceRating > 0
                    ? widget.book.spiceRating
                    : _codex.spiceLevel;
                final fluff = widget.book.fluffRating > 0
                    ? widget.book.fluffRating
                    : _codex.emotionalResonance;
                final tears = widget.book.tearRating > 0
                    ? widget.book.tearRating
                    : _codex.suspenseLevel;
                final humor = widget.book.humorRating > 0
                    ? widget.book.humorRating
                    : 3.5;
                final suspense = _codex.suspenseLevel > 0
                    ? _codex.suspenseLevel
                    : 3.0;

                return Column(
                  children: [
                    _buildRatingBar(
                      'Spice Level',
                      spice,
                      5.0,
                      accentGold,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildRatingBar(
                      'Fluff & Warmth',
                      fluff,
                      5.0,
                      accentParchment,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildRatingBar(
                      'Tears & Drama',
                      tears,
                      5.0,
                      accentGold,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildRatingBar(
                      'Humor & Wit',
                      humor,
                      5.0,
                      accentParchment,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildRatingBar(
                      'Suspense & Stakes',
                      suspense,
                      5.0,
                      accentGold,
                      textPrimary,
                      textSecondary,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 7. CONTENT THEMES & ADVISORY
      if (_codex.contentWarnings.isNotEmpty || _codex.themes.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: accentParchment),
                  const SizedBox(width: 8),
                  Text(
                    'CONTENT THEMES & ADVISORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: accentParchment,
                    ),
                  ),
                ],
              ),
              if (_codex.themes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'THEMATIC MOTIFS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: accentGold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _codex.themes.map((theme) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        theme,
                        style: TextStyle(
                          fontSize: 11,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_codex.contentWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (_codex.themes.isNotEmpty)
                  Text(
                    'CONTENT ADVISORY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _codex.contentWarnings.map((warning) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    ];

    if (widget.scrollController != null || widget.isModal) {
      return ListView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Center(
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
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: null,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(
    CodexCharacter char, {
    required Color cardBgSubtle,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentGold,
    required Color accentParchment,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      char.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        char.role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentGold,
                        ),
                      ),
                    ),
                    if (char.archetype.isNotEmpty && char.archetype != 'Archetype')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: textSecondary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          char.archetype,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            color: textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onEdit != null) ...[
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (onDelete != null)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          if (char.description != null && char.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              char.description!,
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
              maxLines: null,
            ),
          ],
          if (char.quote != null) ...[
            const SizedBox(height: 6),
            Text(
              '“${char.quote}”',
              style: GoogleFonts.crimsonPro(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: accentParchment,
              ),
              maxLines: null,
            ),
          ],
        ],
      ),
    );
  }

  void _showCharacterDialog(
    BuildContext context, {
    CodexCharacter? character,
    int? index,
  }) {
    final isEditing = character != null && index != null;
    final nameController = TextEditingController(
      text: isEditing ? character.name : '',
    );
    final descController = TextEditingController(
      text: isEditing ? (character.description ?? '') : '',
    );
    String selectedRole = isEditing ? character.role : 'Protagonist';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final labelColor = isDark
                ? const Color(0xFFFFA726)
                : const Color(0xFFB45309);
            final roles = [
              'Protagonist',
              'Antagonist',
              'Love Interest',
              'Supporting',
            ];

            return BookoraFloralDialog(
              headerIcon: Icon(
                isEditing
                    ? Icons.edit_note_rounded
                    : Icons.person_add_alt_1_rounded,
                size: 28,
                color: labelColor,
              ),
              title: isEditing ? 'Edit Character' : 'Add Character',
              subtitle: 'Document a persona for "${widget.book.title}"',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookoraPillTextField(
                    controller: nameController,
                    label: 'Character Name',
                    hint: 'e.g. Killian Carson, Jude Duarte',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Role in Narrative',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: roles.map((role) {
                      final isSelected = selectedRole == role;
                      return ChoiceChip(
                        label: Text(
                          role,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFE0D8C3)
                                    : const Color(0xFF2E1E12)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: isDark
                            ? const Color(0xFFE65100)
                            : const Color(0xFFD84315),
                        backgroundColor: isDark
                            ? const Color(0xFF1E212D)
                            : const Color(0xFFF0EBE0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? const Color(0xFF282C3B)
                                    : const Color(0xFFE5DFC9)),
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() => selectedRole = role);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  BookoraPillTextField(
                    controller: descController,
                    label: 'Character Description',
                    hint:
                        'Describe their personality, narrative arc, or motivations...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                ],
              ),
              actions: [
                BookoraPillButton.outlined(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                BookoraPillButton.primary(
                  text: isEditing ? 'Update' : 'Save Character',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a character name.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final newChar = CodexCharacter(
                      name: name,
                      role: selectedRole,
                      archetype: isEditing ? character.archetype : '',
                      description: descController.text.trim(),
                      quote: isEditing ? character.quote : null,
                    );

                    final updatedList = List<CodexCharacter>.from(
                      _codex.characters,
                    );
                    if (isEditing) {
                      updatedList[index] = newChar;
                    } else {
                      updatedList.add(newChar);
                    }

                    final updatedCodex = _codex.copyWith(
                      characters: updatedList,
                    );
                    setState(() {
                      _codex = updatedCodex;
                    });

                    await StoryCodexService.saveCodexToCache(updatedCodex);

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeCharacter(int index) async {
    if (index < 0 || index >= _codex.characters.length) return;
    final updatedList = List<CodexCharacter>.from(_codex.characters)
      ..removeAt(index);
    final updatedCodex = _codex.copyWith(characters: updatedList);
    setState(() {
      _codex = updatedCodex;
    });
    await StoryCodexService.saveCodexToCache(updatedCodex);
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color textPrimary,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(
    String label,
    double value,
    double max,
    Color activeColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final percent = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: textSecondary.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
      ],
    );
  }

  String _resolveWorldScope(StoryCodex codex) {
    final settingLower = codex.setting.toLowerCase();
    final genreLower = widget.book.genres.join(' ').toLowerCase();
    if (settingLower.contains('galaxy') ||
        settingLower.contains('space') ||
        settingLower.contains('universe') ||
        settingLower.contains('planet') ||
        genreLower.contains('space') ||
        genreLower.contains('sci-fi')) {
      return 'Galactic / Far Reach';
    } else if (settingLower.contains('kingdom') ||
        settingLower.contains('empire') ||
        settingLower.contains('realm') ||
        genreLower.contains('fantasy')) {
      return 'Continental Realm';
    } else if (settingLower.contains('city') ||
        settingLower.contains('town') ||
        settingLower.contains('london') ||
        settingLower.contains('york')) {
      return 'Urban / Localized';
    }
    return 'Expansive World';
  }
}
