import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/layout_provider.dart';
import '../models/enums.dart';

class LayoutSwitcher extends ConsumerWidget {
  const LayoutSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ShelfLayoutView>(
      icon: const Icon(Icons.dashboard_customize),
      onSelected: (view) => ref.read(layoutProvider.notifier).state = view,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ShelfLayoutView.darkAcademiaShelf,
          child: ListTile(
            leading: Icon(Icons.auto_stories),
            title: Text('3D Dark Academia Shelf'),
          ),
        ),
        const PopupMenuItem(
          value: ShelfLayoutView.carouselShowcase,
          child: ListTile(
            leading: Icon(Icons.view_carousel),
            title: Text('3D Carousel Showcase'),
          ),
        ),
        const PopupMenuItem(
          value: ShelfLayoutView.polaroidScrapbook,
          child: ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Polaroid Scrapbook Gallery'),
          ),
        ),
        const PopupMenuItem(
          value: ShelfLayoutView.skeuomorphicShelf,
          child: ListTile(
            leading: Icon(Icons.table_rows),
            title: Text('3D Classic Wooden Shelf'),
          ),
        ),
        const PopupMenuItem(
          value: ShelfLayoutView.coverGrid,
          child: ListTile(
            leading: Icon(Icons.grid_view),
            title: Text('Cover Grid'),
          ),
        ),
        const PopupMenuItem(
          value: ShelfLayoutView.detailedList,
          child: ListTile(
            leading: Icon(Icons.view_list),
            title: Text('Detailed List'),
          ),
        ),
      ],
    );
  }
}
