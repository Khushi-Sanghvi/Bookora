import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../providers/layout_provider.dart';
import '../models/enums.dart';
import '../theme/reading_app_colors.dart';
import '../widgets/layout_switcher.dart';
import '../widgets/shelf_layout.dart';
import '../widgets/classic_shelf_layout.dart';
import '../widgets/polaroid_scrapbook_layout.dart';
import '../widgets/grid_layout.dart';
import '../widgets/list_layout.dart';
import '../widgets/carousel_showcase_layout.dart';
import '../widgets/streak_badge.dart';
import '../widgets/filter_and_sort_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(filteredBookProvider);
    final currentLayout = ref.watch(layoutProvider);
    final currentShelfCategory = ref.watch(shelfCategoryProvider);
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12.0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bookora Library',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.eco, size: 15, color: Color(0xFF2E7D32)),
                ],
              ),
              Text(
                'YOUR STORIES, YOUR SPACE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isLight ? const Color(0xFF8D6E63) : const Color(0xFF9C948B),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune),
                if (ref.watch(advancedFilterProvider).isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.streakAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter & Sort',
            onPressed: () => FilterAndSortSheet.show(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 2.0),
            child: StreakBadge(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Library',
            onPressed: () => ref.read(bookProvider.notifier).loadBooks(),
          ),
          const LayoutSwitcher(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _FilterChip(
                      icon: Icons.label_outlined,
                      label: 'All Books',
                      isSelected: currentShelfCategory == ShelfCategory.all,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.all,
                    ),
                    _FilterChip(
                      icon: Icons.favorite_rounded,
                      label: 'Favorites',
                      isSelected: currentShelfCategory == ShelfCategory.favorites,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.favorites,
                      activeIconColor: Colors.redAccent,
                    ),
                    _FilterChip(
                      icon: Icons.menu_book,
                      label: 'Reading',
                      isSelected: currentShelfCategory == ShelfCategory.reading,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.reading,
                    ),
                    _FilterChip(
                      icon: Icons.bookmark_border,
                      label: 'To Read',
                      isSelected: currentShelfCategory == ShelfCategory.toRead,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.toRead,
                    ),
                    _FilterChip(
                      icon: Icons.check_circle_outline,
                      label: 'Finished',
                      isSelected: currentShelfCategory == ShelfCategory.finished,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.finished,
                    ),
                    _FilterChip(
                      icon: Icons.close_outlined,
                      label: 'Abandoned',
                      isSelected: currentShelfCategory == ShelfCategory.abandoned,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.abandoned,
                    ),
                    _FilterChip(
                      icon: Icons.bookmark_outlined,
                      label: 'Wishlist',
                      isSelected: currentShelfCategory == ShelfCategory.wishlist,
                      onSelected: () => ref.read(shelfCategoryProvider.notifier).state = ShelfCategory.wishlist,
                    ),
                  ],
                ),
              ),
            ),
          ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            String emptyMessage = 'Your library is empty. Add some books!';
            switch (currentShelfCategory) {
              case ShelfCategory.all:
                emptyMessage = 'Your library is empty. Add some books!';
                break;
              case ShelfCategory.favorites:
                emptyMessage = 'No favorite books yet.\nTap the heart icon on any book details page to keep your most loved stories here.';
                break;
              case ShelfCategory.reading:
                emptyMessage = 'No books currently being read.';
                break;
              case ShelfCategory.toRead:
                emptyMessage = 'No books in your "To Read" list.';
                break;
              case ShelfCategory.finished:
                emptyMessage = 'No finished books yet.';
                break;
              case ShelfCategory.abandoned:
                emptyMessage = 'No abandoned books.';
                break;
              case ShelfCategory.wishlist:
                emptyMessage = 'Your wishlist is empty.';
                break;
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.4),
                ),
              ),
            );
          }
          switch (currentLayout) {
            case ShelfLayoutView.darkAcademiaShelf:
              return ShelfLayout(books: books);
            case ShelfLayoutView.carouselShowcase:
              return CarouselShowcaseLayout(books: books);
            case ShelfLayoutView.polaroidScrapbook:
              return PolaroidScrapbookLayout(books: books);
            case ShelfLayoutView.skeuomorphicShelf:
              return ClassicShelfLayout(books: books);
            case ShelfLayoutView.coverGrid:
              return GridLayout(books: books);
            case ShelfLayoutView.detailedList:
              return ListLayout(books: books);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFA726))),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? activeIconColor;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.activeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 13,
          color: isSelected ? (activeIconColor ?? Colors.black) : (activeIconColor ?? colors.streakAmber),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : colors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: colors.streakAmber,
        backgroundColor: colors.cardBgSecondary,
        side: BorderSide(
          color: isSelected ? colors.streakAmber : colors.borderSubtle,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
