import 'package:flutter/material.dart';

enum BookshelfWoodFinish { mahogany, weatheredOak, midnightEbony, antiquePine }
enum VineDensity { none, subtle, lush }
enum ShelfSortOption { defaultOrder, colorGradient, height, readingStatus }

class BookshelfConfig {
  final BookshelfWoodFinish woodFinish;
  final VineDensity vineDensity;
  final bool candlesEnabled;
  final bool candleFlickerEnabled;
  final bool showTrinkets;
  final ShelfSortOption sortOption;

  const BookshelfConfig({
    this.woodFinish = BookshelfWoodFinish.mahogany,
    this.vineDensity = VineDensity.lush,
    this.candlesEnabled = true,
    this.candleFlickerEnabled = true,
    this.showTrinkets = true,
    this.sortOption = ShelfSortOption.defaultOrder,
  });

  Color get woodColor {
    switch (woodFinish) {
      case BookshelfWoodFinish.mahogany:
        return const Color(0xFF3E2723);
      case BookshelfWoodFinish.weatheredOak:
        return const Color(0xFF4E342E);
      case BookshelfWoodFinish.midnightEbony:
        return const Color(0xFF1B1B1B);
      case BookshelfWoodFinish.antiquePine:
        return const Color(0xFF5D4037);
    }
  }

  Color get woodHighlightColor {
    switch (woodFinish) {
      case BookshelfWoodFinish.mahogany:
        return const Color(0xFF5D4037);
      case BookshelfWoodFinish.weatheredOak:
        return const Color(0xFF6D4C41);
      case BookshelfWoodFinish.midnightEbony:
        return const Color(0xFF333333);
      case BookshelfWoodFinish.antiquePine:
        return const Color(0xFF795548);
    }
  }

  String get woodName {
    switch (woodFinish) {
      case BookshelfWoodFinish.mahogany:
        return 'Vintage Mahogany';
      case BookshelfWoodFinish.weatheredOak:
        return 'Weathered Oak';
      case BookshelfWoodFinish.midnightEbony:
        return 'Midnight Ebony';
      case BookshelfWoodFinish.antiquePine:
        return 'Antique Pine';
    }
  }

  BookshelfConfig copyWith({
    BookshelfWoodFinish? woodFinish,
    VineDensity? vineDensity,
    bool? candlesEnabled,
    bool? candleFlickerEnabled,
    bool? showTrinkets,
    ShelfSortOption? sortOption,
  }) {
    return BookshelfConfig(
      woodFinish: woodFinish ?? this.woodFinish,
      vineDensity: vineDensity ?? this.vineDensity,
      candlesEnabled: candlesEnabled ?? this.candlesEnabled,
      candleFlickerEnabled: candleFlickerEnabled ?? this.candleFlickerEnabled,
      showTrinkets: showTrinkets ?? this.showTrinkets,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
