enum ReadingStatus {
  currentlyReading,
  toRead,
  finished,
  abandoned,
  wishlist;

  static const ReadingStatus completed = ReadingStatus.finished;
}


enum BookFormat {
  paperback,
  hardcover,
  ebook,
  audiobook,
  pdf,
  epub,
}

enum ShelfLayoutView {
  darkAcademiaShelf,
  carouselShowcase,
  polaroidScrapbook,
  skeuomorphicShelf,
  coverGrid,
  detailedList,
}
