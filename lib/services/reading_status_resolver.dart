import '../models/enums.dart';

class ReadingStatusResolver {
  static ({ReadingStatus status, DateTime? startDate, DateTime? finishDate}) evaluateStatusTransition({
    required ReadingStatus currentStatus,
    required int currentPage,
    required int totalPages,
    DateTime? existingStartDate,
    DateTime? existingFinishDate,
  }) {
    // Clamping safeguard
    final safeTotal = totalPages > 0 ? totalPages : 1;
    final safeCurrent = currentPage.clamp(0, safeTotal);

    // 1. Finished check (reached or exceeded final page, explicitly finished, or finishDate set)
    if (safeCurrent >= safeTotal ||
        currentStatus == ReadingStatus.finished ||
        existingFinishDate != null) {
      final effectiveFinish = existingFinishDate ?? DateTime.now();
      return (
        status: ReadingStatus.finished,
        startDate: existingStartDate ?? effectiveFinish,
        finishDate: effectiveFinish,
      );
    }

    // 2. Reading active check (progress started: currentPage > 0)
    if (safeCurrent > 0) {
      return (
        status: ReadingStatus.currentlyReading,
        startDate: existingStartDate ?? DateTime.now(),
        finishDate: null, // Clear completion date if book was rewound from finished
      );
    }

    // 3. No progress made (remains toRead or wishlist)
    return (
      status: (currentStatus == ReadingStatus.wishlist)
          ? ReadingStatus.wishlist
          : ReadingStatus.toRead,
      startDate: existingStartDate,
      finishDate: null,
    );
  }
}
