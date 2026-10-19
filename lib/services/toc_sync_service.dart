class TocItem {
  final String title;
  final int pageIndex;
  final String? anchor;

  TocItem({
    required this.title,
    required this.pageIndex,
    this.anchor,
  });
}

class TocSyncService {
  /// Resolves the active TOC item/chapter using exact lower-bound range comparison
  /// or prioritized visible on-screen heading matches.
  static TocItem resolveActiveChapter({
    required int currentPage,
    required List<TocItem> tocItems,
    String? visibleOnScreenHeading,
  }) {
    if (visibleOnScreenHeading != null && visibleOnScreenHeading.trim().isNotEmpty) {
      final cleanHeading = visibleOnScreenHeading.trim().toUpperCase();
      for (final item in tocItems) {
        if (item.title.trim().toUpperCase() == cleanHeading) {
          return item;
        }
      }
      return TocItem(
        title: visibleOnScreenHeading.trim(),
        pageIndex: currentPage,
      );
    }

    if (tocItems.isEmpty) {
      return TocItem(title: 'Reading', pageIndex: currentPage);
    }

    TocItem active = tocItems.first;
    for (final item in tocItems) {
      if (item.pageIndex <= currentPage) {
        active = item;
      } else {
        break;
      }
    }
    return active;
  }
}
