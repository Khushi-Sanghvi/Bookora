import 'dart:math';

class ReadingStreakData {
  final int currentStreak;
  final int longestStreak;
  final bool hasReadToday;
  final DateTime? lastReadDate;

  const ReadingStreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.hasReadToday,
    this.lastReadDate,
  });

  bool get readToday => hasReadToday;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingStreakData &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          hasReadToday == other.hasReadToday &&
          lastReadDate == other.lastReadDate;

  @override
  int get hashCode => Object.hash(currentStreak, longestStreak, hasReadToday, lastReadDate);
}

class ReadingStreakCalculator {
  /// Computes active streak, longest streak, and grace period status from a set of qualified dates.
  static ReadingStreakData calculate({
    required Set<DateTime> qualifiedDates,
    DateTime? referenceDateTime,
  }) {
    if (qualifiedDates.isEmpty) {
      return const ReadingStreakData(
        currentStreak: 0,
        longestStreak: 0,
        hasReadToday: false,
        lastReadDate: null,
      );
    }

    // 1. Normalize all dates to local midnight (year, month, day)
    final Set<DateTime> normalizedDates = {};
    for (var dt in qualifiedDates) {
      final local = dt.toLocal();
      normalizedDates.add(DateTime(local.year, local.month, local.day));
    }

    final now = (referenceDateTime ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final hasReadToday = normalizedDates.contains(today);
    final hasReadYesterday = normalizedDates.contains(yesterday);

    // 2. Compute Current Streak with Grace Window Rule
    int currentStreak = 0;
    DateTime? lastReadDate = normalizedDates.isNotEmpty
        ? (normalizedDates.toList()..sort()).last
        : null;

    if (hasReadToday) {
      // Active: count backwards starting from today
      DateTime checkDate = today;
      while (normalizedDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (hasReadYesterday) {
      // Pending Grace Period: held yesterday's streak count until end of today
      DateTime checkDate = yesterday;
      int graceStreak = 0;
      while (normalizedDates.contains(checkDate)) {
        graceStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      currentStreak = graceStreak;
    } else {
      // Broken: no log yesterday and no log today -> 0
      currentStreak = 0;
    }

    // 3. Compute Longest Streak across all historical chains
    final sortedDates = normalizedDates.toList()..sort();
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (var date in sortedDates) {
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
      prevDate = date;
    }

    final finalCurrent = max(currentStreak, hasReadToday ? 1 : 0);
    final finalLongest = max(longestStreak, finalCurrent);

    return ReadingStreakData(
      currentStreak: finalCurrent,
      longestStreak: finalLongest,
      hasReadToday: hasReadToday,
      lastReadDate: lastReadDate,
    );
  }
}
