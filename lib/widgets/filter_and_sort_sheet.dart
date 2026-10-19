import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/enums.dart';
import '../providers/book_provider.dart';
import '../theme/reading_app_colors.dart';

class FilterAndSortSheet extends ConsumerStatefulWidget {
  const FilterAndSortSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = context.appColors;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: const SingleChildScrollView(
            child: FilterAndSortSheet(),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<FilterAndSortSheet> createState() => _FilterAndSortSheetState();
}

class _FilterAndSortSheetState extends ConsumerState<FilterAndSortSheet> {
  late Set<BookFormat> _selectedFormats;
  late ProgressFilterRange _selectedProgressRange;
  late Set<String> _selectedGenres;
  late double _selectedMinRating;
  late BookSortOption _selectedSortOption;

  final List<String> _popularGenres = const [
    'Romance',
    'Thriller',
    'Fantasy',
    'Sci-Fi',
    'Fiction',
    'Non-Fiction',
    'Young Adult',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(advancedFilterProvider);
    _selectedFormats = Set.from(current.formats);
    _selectedProgressRange = current.progressRange;
    _selectedGenres = Set.from(current.genres);
    _selectedMinRating = current.minRating;
    _selectedSortOption = current.sortOption;
  }

  void _resetFilters() {
    setState(() {
      _selectedFormats.clear();
      _selectedProgressRange = ProgressFilterRange.all;
      _selectedGenres.clear();
      _selectedMinRating = 0.0;
      _selectedSortOption = BookSortOption.recentlyAdded;
    });
  }

  void _applyFilters() {
    final newFilter = AdvancedFilterState(
      formats: _selectedFormats,
      progressRange: _selectedProgressRange,
      genres: _selectedGenres,
      minRating: _selectedMinRating,
      sortOption: _selectedSortOption,
    );
    ref.read(advancedFilterProvider.notifier).setFilter(newFilter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle Bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title Header Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: colors.streakAmber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Filter & Sort',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _resetFilters,
              child: Text(
                'Reset All',
                style: TextStyle(color: colors.streakAmber, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 12),

        // 1. Sort By
        _buildSectionTitle('Sort By', colors),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortChip('Recently Added', BookSortOption.recentlyAdded, colors),
            _buildSortChip('Recently Updated', BookSortOption.recentlyUpdated, colors),
            _buildSortChip('Title A-Z', BookSortOption.titleAZ, colors),
            _buildSortChip('Author A-Z', BookSortOption.authorAZ, colors),
            _buildSortChip('Progress', BookSortOption.progress, colors),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Format
        _buildSectionTitle('Format', colors),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFormatChip('Paperback', BookFormat.paperback, colors),
            _buildFormatChip('Audiobook', BookFormat.audiobook, colors),
            _buildFormatChip('PDF', BookFormat.pdf, colors),
            _buildFormatChip('EPUB', BookFormat.epub, colors),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Progress Range
        _buildSectionTitle('Progress Range', colors),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildProgressChip('All', ProgressFilterRange.all, colors),
            _buildProgressChip('Not Started (0%)', ProgressFilterRange.notStarted, colors),
            _buildProgressChip('In Progress (1-99%)', ProgressFilterRange.inProgress, colors),
            _buildProgressChip('Completed (100%)', ProgressFilterRange.completed, colors),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Minimum Rating
        _buildSectionTitle('Rating', colors),
        Wrap(
          spacing: 8,
          children: [
            _buildRatingChip('All Ratings', 0.0, colors),
            _buildRatingChip('⭐ 4+ Stars', 4.0, colors),
            _buildRatingChip('⭐ 3+ Stars', 3.0, colors),
          ],
        ),
        const SizedBox(height: 20),

        // 5. Genre
        _buildSectionTitle('Genre', colors),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularGenres.map((g) => _buildGenreChip(g, colors)).toList(),
        ),
        const SizedBox(height: 28),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: colors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: colors.streakAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ReadingAppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
      ),
    );
  }

  Widget _buildSortChip(String label, BookSortOption option, ReadingAppColors colors) {
    final isSelected = _selectedSortOption == option;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (_) {
        setState(() => _selectedSortOption = option);
      },
    );
  }

  Widget _buildFormatChip(String label, BookFormat format, ReadingAppColors colors) {
    final isSelected = _selectedFormats.contains(format);
    return FilterChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedFormats.add(format);
          } else {
            _selectedFormats.remove(format);
          }
        });
      },
    );
  }

  Widget _buildProgressChip(String label, ProgressFilterRange range, ReadingAppColors colors) {
    final isSelected = _selectedProgressRange == range;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (_) {
        setState(() => _selectedProgressRange = range);
      },
    );
  }

  Widget _buildRatingChip(String label, double rating, ReadingAppColors colors) {
    final isSelected = _selectedMinRating == rating;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (_) {
        setState(() => _selectedMinRating = rating);
      },
    );
  }

  Widget _buildGenreChip(String genre, ReadingAppColors colors) {
    final isSelected = _selectedGenres.contains(genre);
    return FilterChip(
      showCheckmark: false,
      label: Text(genre),
      selected: isSelected,
      selectedColor: colors.streakAmber,
      backgroundColor: colors.cardBgSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedGenres.add(genre);
          } else {
            _selectedGenres.remove(genre);
          }
        });
      },
    );
  }
}
