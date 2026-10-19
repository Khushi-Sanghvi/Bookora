import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookshelf_config.dart';

class BookshelfConfigNotifier extends StateNotifier<BookshelfConfig> {
  BookshelfConfigNotifier() : super(const BookshelfConfig());

  void updateConfig(BookshelfConfig config) {
    state = config;
  }

  void setWoodFinish(BookshelfWoodFinish wood) {
    state = state.copyWith(woodFinish: wood);
  }

  void setVineDensity(VineDensity density) {
    state = state.copyWith(vineDensity: density);
  }

  void toggleCandles(bool enabled) {
    state = state.copyWith(candlesEnabled: enabled);
  }

  void toggleTrinkets(bool enabled) {
    state = state.copyWith(showTrinkets: enabled);
  }
}

final bookshelfConfigProvider = StateNotifierProvider<BookshelfConfigNotifier, BookshelfConfig>((ref) {
  return BookshelfConfigNotifier();
});
