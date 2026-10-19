import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';

final layoutProvider = StateProvider<ShelfLayoutView>((ref) {
  return ShelfLayoutView.darkAcademiaShelf;
});
