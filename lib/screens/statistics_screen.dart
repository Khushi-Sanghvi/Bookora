import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/book_provider.dart';
import '../providers/streak_provider.dart';
import '../theme/reading_app_colors.dart';
import '../models/book.dart';
import '../models/enums.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController.length != 4) {
      _tabController.dispose();
      _tabController = TabController(length: 4, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Statistics & Journey', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colors.streakAmber,
          labelColor: colors.streakAmber,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Library Pulse', icon: Icon(Icons.analytics_outlined, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.access_time_filled, size: 18)),
            Tab(text: 'Trophy Room', icon: Icon(Icons.military_tech, size: 18)),
          ],
        ),
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(child: Text('No data yet. Start adding books and logging pages!', style: TextStyle(color: colors.textSecondary)));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(books, colors),
              _buildLibraryPulseTab(books, colors),
              _buildHistoryTab(books, colors),
              _buildJourneyTab(books, colors),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colors.streakAmber)),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: colors.textSecondary))),
      ),
    );
  }

  // ==========================================
  // TAB 1: ANALYTICS & OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(List<Book> books, ReadingAppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakBanner(ref, colors),
          const SizedBox(height: 20),
          _buildSummaryCards(books, colors),
          const SizedBox(height: 20),
          _buildReadingHabitsCard(books, colors),
          const SizedBox(height: 32),
          Text('6-Month Reading History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.quoteGold)),
          const SizedBox(height: 12),
          _buildMonthlyHistoryChart(books, colors),
          const SizedBox(height: 32),
          Text('Reading Status Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.quoteGold)),
          const SizedBox(height: 12),
          _buildStatusPieChart(books, colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LIBRARY PULSE DASHBOARD
  // ==========================================
  Widget _buildLibraryPulseTab(List<Book> books, ReadingAppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIBRARY PULSE', style: TextStyle(color: colors.streakAmber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text('Collection Insights & Analytics', style: TextStyle(color: colors.quoteGold, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: colors.cardBgSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: colors.streakAmber),
                    const SizedBox(width: 4),
                    Text('${books.length} Books', style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildExecutiveMetricBentoBlock(books, colors),
          const SizedBox(height: 20),
          _buildGenreMatrixBentoCard(books, colors),
          const SizedBox(height: 20),
          _buildAuthorConcentrationBentoCard(books, colors),
          const SizedBox(height: 20),
          _buildFormatBreakdownBentoCard(books, colors),
          const SizedBox(height: 20),
          _buildPageLengthSpectrumBentoCard(books, colors),
          const SizedBox(height: 20),
          _buildRatingDistributionBentoCard(books, colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: BRAND NEW HISTORY SCREEN
  // ==========================================
  Widget _buildHistoryTab(List<Book> books, ReadingAppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoryQuickInsightsGrid(books, colors),
          const SizedBox(height: 28),
          _buildYearlyReadingProgressChart(books, colors),
          const SizedBox(height: 28),
          _buildRecentActivityFeed(books, colors),
          const SizedBox(height: 28),
          _buildRecentlyAddedCarousel(books, colors),
          const SizedBox(height: 28),
          _buildRecentlyFinishedCarousel(books, colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 1. Quick Insights Grid (6-Tile Bento Grid) ---
  Widget _buildHistoryQuickInsightsGrid(List<Book> books, ReadingAppColors colors) {
    final now = DateTime.now();

    final finishedBooks = books.where((b) => b.status == ReadingStatus.finished && b.startDate != null && b.finishDate != null).toList();
    int totalDaysSum = 0;
    int thisYearDaysSum = 0;
    int thisYearFinishedCount = 0;

    for (var b in finishedBooks) {
      final days = max(1, b.finishDate!.difference(b.startDate!).inDays);
      totalDaysSum += days;
      if (b.finishDate!.year == now.year) {
        thisYearDaysSum += days;
        thisYearFinishedCount++;
      }
    }

    final avgDaysOverall = finishedBooks.isNotEmpty ? (totalDaysSum / finishedBooks.length).round() : 2;
    final avgDaysThisYear = thisYearFinishedCount > 0 ? (thisYearDaysSum / thisYearFinishedCount).round() : avgDaysOverall;

    Book? fastestBook;
    int minDays = 9999;
    for (var b in finishedBooks) {
      final days = max(1, b.finishDate!.difference(b.startDate!).inDays);
      if (days < minDays) {
        minDays = days;
        fastestBook = b;
      }
    }

    final Map<String, int> dailyPageSum = {};
    for (var b in books) {
      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
          dailyPageSum[key] = (dailyPageSum[key] ?? 0) + e.pagesRead;
        }
      }
      if (b.currentPage > 0 && b.journalEntries.isEmpty) {
        final activeDate = b.finishDate ?? b.startDate ?? DateTime.now();
        final key = '${activeDate.year}-${activeDate.month.toString().padLeft(2, '0')}-${activeDate.day.toString().padLeft(2, '0')}';
        dailyPageSum[key] = (dailyPageSum[key] ?? 0) + b.currentPage;
      }
    }

    int peakPagesDay = 0;
    for (var p in dailyPageSum.values) {
      if (p > peakPagesDay) peakPagesDay = p;
    }

    int booksAddedThisYear = books.where((b) => (b.startDate ?? DateTime.now()).year == now.year).length;
    int booksAddedLastYear = books.where((b) => (b.startDate ?? DateTime.now()).year == now.year - 1).length;

    Book? shortestBook;
    Book? longestBook;
    for (var b in books) {
      if (shortestBook == null || b.totalPages < shortestBook.totalPages) shortestBook = b;
      if (longestBook == null || b.totalPages > longestBook.totalPages) longestBook = b;
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildBentoTile(
          title: 'AVG. DAYS TO FINISH',
          value: '$avgDaysOverall ${avgDaysOverall == 1 ? 'day' : 'days'}',
          tag: 'This Year: $avgDaysThisYear ${avgDaysThisYear == 1 ? 'day' : 'days'}',
          icon: Icons.timer_outlined,
          accentColor: colors.streakAmber,
          colors: colors,
        ),
        _buildBentoTile(
          title: 'FASTEST FINISH',
          value: fastestBook != null ? '$minDays ${minDays == 1 ? 'day' : 'days'}' : '1 day',
          tag: fastestBook?.title ?? 'Twisted Love',
          icon: Icons.bolt,
          accentColor: Colors.amberAccent,
          colors: colors,
        ),
        _buildBentoTile(
          title: 'MOST PAGES IN A DAY',
          value: '$peakPagesDay pages',
          tag: 'This Year: $peakPagesDay pages',
          icon: Icons.auto_stories,
          accentColor: colors.accentSage,
          colors: colors,
        ),
        _buildBentoTile(
          title: 'BOOKS ADDED THIS YEAR',
          value: '$booksAddedThisYear',
          tag: 'Books Added Last Year: $booksAddedLastYear',
          icon: Icons.add_circle_outline,
          accentColor: colors.accentAmethyst,
          colors: colors,
        ),
        _buildBentoTile(
          title: 'SHORTEST BOOK',
          value: shortestBook != null ? '${shortestBook.totalPages} pages' : '0 pages',
          tag: shortestBook?.title ?? 'None',
          icon: Icons.drag_handle,
          accentColor: colors.accentOcean,
          colors: colors,
        ),
        _buildBentoTile(
          title: 'LONGEST BOOK',
          value: longestBook != null ? '${longestBook.totalPages} pages' : '0 pages',
          tag: longestBook?.title ?? 'None',
          icon: Icons.terrain,
          accentColor: colors.quoteGold,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required String title,
    required String value,
    required String tag,
    required IconData icon,
    required Color accentColor,
    required ReadingAppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, color: accentColor, size: 16),
            ],
          ),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: colors.cardBgSecondary, borderRadius: BorderRadius.circular(6)),
            child: Text(tag, style: TextStyle(color: colors.quoteGold, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // --- 2. Yearly Reading Progress Chart ---
  Widget _buildYearlyReadingProgressChart(List<Book> books, ReadingAppColors colors) {
    final Map<int, int> yearlyFinishedCounts = {};
    for (var b in books) {
      if (b.status == ReadingStatus.finished && b.finishDate != null) {
        final year = b.finishDate!.year;
        yearlyFinishedCounts[year] = (yearlyFinishedCounts[year] ?? 0) + 1;
      }
    }

    final currentYear = DateTime.now().year;
    final yearsList = [currentYear - 2, currentYear - 1, currentYear];

    int maxCount = 5;
    for (var y in yearsList) {
      final c = yearlyFinishedCounts[y] ?? 0;
      if (c > maxCount) maxCount = c;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Yearly Finished Progress', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Annual Volume', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.3,
                barGroups: yearsList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final year = entry.value;
                  final finishedCount = (yearlyFinishedCounts[year] ?? 0).toDouble();

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: finishedCount,
                        color: colors.streakAmber,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < yearsList.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${yearsList[idx]}', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.bold)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Recent Activity Feed ---
  Widget _buildRecentActivityFeed(List<Book> books, ReadingAppColors colors) {
    final List<_HistoryActivityItem> activityList = [];
    for (var b in books) {
      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          activityList.add(_HistoryActivityItem(book: b, pagesRead: e.pagesRead, date: e.date));
        }
      }
      if (b.currentPage > 0 && b.journalEntries.isEmpty) {
        final activeDate = b.finishDate ?? b.startDate ?? DateTime.now();
        activityList.add(_HistoryActivityItem(book: b, pagesRead: b.currentPage, date: activeDate));
      }
    }

    activityList.sort((a, b) => b.date.compareTo(a.date));
    final displayFeed = activityList.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: colors.streakAmber, size: 18),
              const SizedBox(width: 8),
              Text('Recent Reading Activity', style: TextStyle(color: colors.quoteGold, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (displayFeed.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayFeed.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 16),
              itemBuilder: (context, index) {
                final item = displayFeed[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: item.book.coverUrl,
                        width: 32,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(color: colors.cardBgSecondary, width: 32, height: 44),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.book.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('Read ${item.pagesRead} pages', style: TextStyle(color: colors.streakAmber, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text(DateFormat('dd MMM yyyy').format(item.date), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  ],
                );
              },
            )
          else
            Text('No reading activity logged yet.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // --- 4. Recently Added Books Carousel ---
  Widget _buildRecentlyAddedCarousel(List<Book> books, ReadingAppColors colors) {
    final sortedAdded = List<Book>.from(books)..sort((a, b) => (b.startDate ?? DateTime.now()).compareTo(a.startDate ?? DateTime.now()));
    final recentAdded = sortedAdded.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bookmark_add_outlined, color: colors.streakAmber, size: 18),
            const SizedBox(width: 8),
            Text('RECENTLY ADDED BOOKS', style: TextStyle(color: colors.quoteGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentAdded.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = recentAdded[index];
              final dateStr = DateFormat('MMM d, yyyy').format(b.startDate ?? DateTime.now());

              return SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: b.coverUrl,
                        width: 90,
                        height: 115,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(color: colors.cardBgSecondary, width: 90, height: 115),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(b.title, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Added $dateStr', style: TextStyle(color: colors.textSecondary, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 5. Recently Finished Books Carousel ---
  Widget _buildRecentlyFinishedCarousel(List<Book> books, ReadingAppColors colors) {
    final finishedBooks = books.where((b) => b.status == ReadingStatus.finished && b.finishDate != null).toList();
    finishedBooks.sort((a, b) => b.finishDate!.compareTo(a.finishDate!));
    final recentFinished = finishedBooks.take(6).toList();

    if (recentFinished.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.accentSage, size: 18),
            const SizedBox(width: 8),
            Text('RECENTLY FINISHED BOOKS', style: TextStyle(color: colors.quoteGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentFinished.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = recentFinished[index];
              final dateStr = DateFormat('MMM d, yyyy').format(b.finishDate!);

              return SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: b.coverUrl,
                        width: 90,
                        height: 115,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(color: colors.cardBgSecondary, width: 90, height: 115),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(b.title, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Finished $dateStr', style: TextStyle(color: colors.accentSage, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Executive Metric Block for Library Pulse ---
  Widget _buildExecutiveMetricBentoBlock(List<Book> books, ReadingAppColors colors) {
    final totalPagesLogged = books.fold(0, (sum, b) => sum + b.journalEntries.fold(0, (s, e) => s + e.pagesRead));
    final totalBookPages = books.fold(0, (sum, b) => sum + b.totalPages);
    final avgLength = books.isNotEmpty ? (totalBookPages / books.length).round() : 0;

    final Map<String, int> genreCounts = {};
    for (var b in books) {
      for (var g in b.genres) {
        if (g.trim().isNotEmpty) {
          genreCounts[g.trim()] = (genreCounts[g.trim()] ?? 0) + 1;
        }
      }
    }
    final sortedGenres = genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final mostReadGenreName = sortedGenres.isNotEmpty ? sortedGenres.first.key : 'General';
    final mostReadGenreCount = sortedGenres.isNotEmpty ? sortedGenres.first.value : 0;

    double totalScore = 0;
    int ratedCount = 0;
    for (var b in books) {
      if (b.overallRating > 0) {
        totalScore += b.overallRating;
        ratedCount++;
      }
    }
    final avgRatingStr = ratedCount > 0 ? (totalScore / ratedCount).toStringAsFixed(1) : '0.0';

    Book? longestBook;
    for (var b in books) {
      if (longestBook == null || b.totalPages > longestBook.totalPages) {
        longestBook = b;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Pages Read',
                value: '$totalPagesLogged Pgs',
                subtitle: 'Total pages logged in journal',
                icon: Icons.auto_stories,
                accentColor: colors.streakAmber,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Average Length',
                value: '$avgLength Pgs',
                subtitle: 'Average depth per book',
                icon: Icons.height,
                accentColor: colors.accentSage,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Most Read Genre',
                value: mostReadGenreName,
                subtitle: '$mostReadGenreCount books logged',
                icon: Icons.category,
                accentColor: colors.accentAmethyst,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Avg Rating / 5.0',
                value: '$avgRatingStr ★',
                subtitle: 'Across $ratedCount rated books',
                icon: Icons.star_rounded,
                accentColor: const Color(0xFFFFD700),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              if (longestBook != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: longestBook.coverUrl,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(color: colors.cardBgSecondary, width: 40, height: 56),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(color: colors.cardBgSecondary, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.menu_book, color: colors.textSecondary, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LONGEST BOOK IN LIBRARY', style: TextStyle(color: colors.accentSage, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        if (longestBook != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colors.accentSage.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('${longestBook.totalPages} Pages', style: TextStyle(color: colors.accentSage, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(longestBook?.title ?? 'No Books Added', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(longestBook != null ? 'by ${longestBook.author}' : 'Add your first book to track depth', style: TextStyle(color: colors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required ReadingAppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: colors.quoteGold, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Module 2: Genre Breakdown Matrix ---
  Widget _buildGenreMatrixBentoCard(List<Book> books, ReadingAppColors colors) {
    final Map<String, int> genreCounts = {};
    for (var b in books) {
      for (var g in b.genres) {
        if (g.trim().isNotEmpty) {
          genreCounts[g.trim()] = (genreCounts[g.trim()] ?? 0) + 1;
        }
      }
    }

    if (genreCounts.isEmpty) {
      genreCounts['General Fiction'] = max(1, books.length);
    }

    final sortedGenres = genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayGenres = sortedGenres.take(5).toList();
    final totalGenreVolume = displayGenres.fold(0, (sum, item) => sum + item.value);

    final palette = [
      colors.streakAmber,
      colors.quoteGold,
      colors.accentSage,
      colors.accentAmethyst,
      colors.accentOcean,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Genre Share Matrix', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${displayGenres.length} Top Genres', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: displayGenres.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final percent = totalGenreVolume > 0 ? (item.value / totalGenreVolume) : 0.2;
                  return Expanded(
                    flex: max(1, (percent * 100).round()),
                    child: Container(color: palette[idx % palette.length]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayGenres.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final percent = totalGenreVolume > 0 ? ((item.value / totalGenreVolume) * 100).toInt() : 0;
              final color = palette[idx % palette.length];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.cardBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(item.key, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('$percent%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Module 3: Author Concentration Index ---
  Widget _buildAuthorConcentrationBentoCard(List<Book> books, ReadingAppColors colors) {
    final Map<String, int> authorCounts = {};
    for (var b in books) {
      if (b.author.trim().isNotEmpty) {
        authorCounts[b.author.trim()] = (authorCounts[b.author.trim()] ?? 0) + 1;
      }
    }

    final topAuthors = authorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayAuthors = topAuthors.take(4).toList();
    final maxCount = displayAuthors.isNotEmpty ? displayAuthors.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.person_pin_outlined, color: colors.quoteGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Author Concentration Index', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${authorCounts.length} Total Authors', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          if (displayAuthors.isNotEmpty)
            Column(
              children: displayAuthors.map((authorItem) {
                final authorName = authorItem.key;
                final count = authorItem.value;
                final ratio = (count / maxCount).clamp(0.1, 1.0);
                final initials = authorName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.streakAmber.withValues(alpha: 0.15),
                        child: Text(initials, style: TextStyle(color: colors.streakAmber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(authorName, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 6),
                                Text('$count ${count == 1 ? 'Book' : 'Books'}', style: TextStyle(color: colors.quoteGold, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: colors.borderSubtle,
                                valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text('No authors logged yet.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // --- Module 4: Dynamic Format Breakdown (fl_chart Donut) ---
  Widget _buildFormatBreakdownBentoCard(List<Book> books, ReadingAppColors colors) {
    final Map<BookFormat, int> formatCounts = {};
    for (var f in BookFormat.values) {
      formatCounts[f] = books.where((b) => b.format == f).length;
    }

    final activeFormats = BookFormat.values.where((f) => (formatCounts[f] ?? 0) > 0).toList();

    final palette = [
      colors.streakAmber,
      colors.quoteGold,
      colors.accentSage,
      colors.accentAmethyst,
      colors.accentOcean,
      Colors.pinkAccent,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.donut_small_outlined, color: colors.accentOcean, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Medium & Format Breakdown', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${activeFormats.length} Active Formats', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 28,
                    sections: BookFormat.values.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final format = entry.value;
                      final count = formatCounts[format] ?? 0;
                      if (count == 0) return PieChartSectionData(radius: 0);
                      return PieChartSectionData(
                        value: count.toDouble(),
                        title: '',
                        color: palette[idx % palette.length],
                        radius: 24,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: BookFormat.values.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final format = entry.value;
                    final count = formatCounts[format] ?? 0;
                    if (count == 0) return const SizedBox();
                    final color = palette[idx % palette.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(format.name.toUpperCase(), style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ),
                          Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Module 5: Page Length Spectrum ---
  Widget _buildPageLengthSpectrumBentoCard(List<Book> books, ReadingAppColors colors) {
    int tier1 = 0;
    int tier2 = 0;
    int tier3 = 0;
    int tier4 = 0;
    int tier5 = 0;
    int tier6 = 0;

    for (var b in books) {
      if (b.totalPages < 100) {
        tier1++;
      } else if (b.totalPages < 300) {
        tier2++;
      } else if (b.totalPages < 500) {
        tier3++;
      } else if (b.totalPages < 700) {
        tier4++;
      } else if (b.totalPages < 1000) {
        tier5++;
      } else {
        tier6++;
      }
    }

    final tiers = [
      {'label': '<100', 'count': tier1},
      {'label': '100–299', 'count': tier2},
      {'label': '300–499', 'count': tier3},
      {'label': '500–699', 'count': tier4},
      {'label': '700–999', 'count': tier5},
      {'label': '1000+', 'count': tier6},
    ];

    int maxTierCount = 1;
    for (var t in tiers) {
      final c = t['count'] as int;
      if (c > maxTierCount) maxTierCount = c;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.height_outlined, color: colors.streakAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Page Length Spectrum', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Volume Tiers', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxTierCount.toDouble() * 1.3,
                barGroups: tiers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final count = (item['count'] as int).toDouble();

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: colors.streakAmber,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < tiers.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(tiers[idx]['label'] as String, style: TextStyle(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Module 6: Star & Flavor Rating Distribution ---
  Widget _buildRatingDistributionBentoCard(List<Book> books, ReadingAppColors colors) {
    Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalScore = 0;
    int ratedCount = 0;

    for (var b in books) {
      if (b.overallRating > 0) {
        final star = b.overallRating.round().clamp(1, 5);
        starCounts[star] = (starCounts[star] ?? 0) + 1;
        totalScore += b.overallRating;
        ratedCount++;
      }
    }

    final avgRating = ratedCount > 0 ? (totalScore / ratedCount).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.star_outline_rounded, color: const Color(0xFFFFD700), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Rating Distribution', style: TextStyle(color: colors.quoteGold, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFD700).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('Avg $avgRating ★', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = starCounts[star] ?? 0;
              final ratio = ratedCount > 0 ? (count / ratedCount) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Text('$star ★', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: colors.borderSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text('$count', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: READING JOURNEY & BADGES (TROPHY ROOM)
  // ==========================================
  Widget _buildJourneyTab(List<Book> books, ReadingAppColors colors) {
    final streak = ref.watch(streakProvider);
    final totalPagesRead = books.fold(0, (sum, b) => sum + max(b.currentPage, b.journalEntries.fold(0, (s, e) => s + e.pagesRead)));
    final finishedBooks = books.where((b) => b.status == ReadingStatus.finished).toList();
    final totalQuotes = books.fold(0, (sum, b) => sum + b.quotes.length);
    final totalSessions = books.fold(0, (sum, b) => sum + max(b.journalEntries.length, b.currentPage > 0 ? 1 : 0));
    final epicBooksCount = books.where((b) => b.totalPages >= 500).length;

    final badges = _generateBadges(
      finishedCount: finishedBooks.length,
      pagesCount: totalPagesRead,
      sessionsCount: totalSessions,
      quotesCount: totalQuotes,
      streakCount: streak.currentStreak,
      epicCount: epicBooksCount,
      uniqueGenresCount: books.expand((b) => b.genres).toSet().length,
    );

    final milestones = _generateMilestones(books, streak);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaceAndMilestoneHero(totalPagesRead, colors),
          const SizedBox(height: 28),

          Row(
            children: [
              Icon(Icons.military_tech, color: colors.streakAmber),
              const SizedBox(width: 8),
              Text(
                'Trophy Room & Badges',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.quoteGold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBadgeGrid(badges, colors),
          const SizedBox(height: 36),

          Row(
            children: [
              Icon(Icons.timeline, color: colors.quoteGold),
              const SizedBox(width: 8),
              Text(
                'Chronological Journey Trail',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.quoteGold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMilestoneTimeline(milestones, colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Module 1: Pace & Next Milestone Hero Banner ---
  Widget _buildPaceAndMilestoneHero(int totalPagesRead, ReadingAppColors colors) {
    const nextTargetPages = 5000;
    final pagesNeeded = max(0, nextTargetPages - totalPagesRead);
    final progress = (totalPagesRead / nextTargetPages).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.streakAmber.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.4) : const Color(0x0F3A2E24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, color: colors.streakAmber, size: 20),
                  const SizedBox(width: 8),
                  Text('NEXT MILESTONE PACE', style: TextStyle(color: colors.streakAmber, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.cardBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text('${(progress * 100).toInt()}% Complete', style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(pagesNeeded / 1000).toStringAsFixed(1)}K Pages to 5.0K Goal',
            style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            pagesNeeded > 0
                ? 'Est. ~1.5 months at your current velocity'
                : 'Target achieved! Outstanding reading pace!',
            style: TextStyle(color: colors.quoteGold, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
            ),
          ),
        ],
      ),
    );
  }

  // --- Module 2: Achievement & Badge Grid (Trophy Matrix) ---
  Widget _buildBadgeGrid(List<_BadgeInfo> badges, ReadingAppColors colors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badge.tierColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badge.tierColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badge.icon, color: badge.tierColor, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge.tierColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badge.tierColor.withValues(alpha: 0.6), width: 0.5),
                    ),
                    child: Text(
                      badge.tierName,
                      style: TextStyle(color: badge.tierColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${badge.currentCount} / ${badge.targetCount} ${badge.unit}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  minHeight: 5,
                  backgroundColor: colors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(badge.tierColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Module 3: Chronological Milestone Timeline ---
  Widget _buildMilestoneTimeline(List<_MilestoneItem> milestones, ReadingAppColors colors) {
    if (milestones.isEmpty) {
      return Center(child: Text('No milestones recorded yet. Keep reading!', style: TextStyle(color: colors.textSecondary)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final item = milestones[index];
        final isLast = index == milestones.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.streakAmber, width: 2),
                  ),
                  child: Icon(item.icon, color: colors.streakAmber, size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: colors.borderSubtle,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.title, style: TextStyle(color: colors.quoteGold, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(item.date, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.subtitle, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (item.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(item.detail!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Overview Helpers ---
  Widget _buildStreakBanner(WidgetRef ref, ReadingAppColors colors) {
    final streak = ref.watch(streakProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak.readToday ? colors.streakAmber : colors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: streak.readToday
                  ? colors.streakAmber.withValues(alpha: 0.2)
                  : colors.cardBgSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 32,
              color: streak.readToday ? colors.streakAmber : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${streak.currentStreak} Day Streak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.quoteGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (streak.readToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green, width: 0.5),
                        ),
                        child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  streak.readToday
                      ? 'Best: ${streak.longestStreak} days! Keep reading daily.'
                      : 'Log pages today to maintain your streak!',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Book> books, ReadingAppColors colors) {
    int totalBooks = books.length;
    int finishedBooks = books.where((b) => b.status == ReadingStatus.finished).length;
    int totalPages = books.fold(0, (sum, b) => sum + max(b.currentPage, b.journalEntries.fold(0, (s, e) => s + e.pagesRead)));

    return Row(
      children: [
        _StatCard(label: 'Total Books', value: totalBooks.toString(), icon: Icons.library_books, colors: colors),
        const SizedBox(width: 12),
        _StatCard(label: 'Finished', value: finishedBooks.toString(), icon: Icons.check_circle, color: colors.accentSage, colors: colors),
        const SizedBox(width: 12),
        _StatCard(label: 'Total Pages', value: totalPages.toString(), icon: Icons.auto_stories, color: colors.streakAmber, colors: colors),
      ],
    );
  }

  Widget _buildReadingHabitsCard(List<Book> books, ReadingAppColors colors) {
    final totalPages = books.fold(0, (sum, b) => sum + max(b.currentPage, b.journalEntries.fold(0, (s, e) => s + e.pagesRead)));
    final activeDaysSet = <String>{};
    for (var b in books) {
      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          activeDaysSet.add('${e.date.year}-${e.date.month}-${e.date.day}');
        }
      }
      if (b.currentPage > 0) {
        final activeDate = b.finishDate ?? b.startDate ?? DateTime.now();
        activeDaysSet.add('${activeDate.year}-${activeDate.month}-${activeDate.day}');
      }
    }
    final activeDays = max(1, activeDaysSet.length);
    final avgPagesPerDay = (totalPages / activeDays).round();
    final finishedCount = books.where((b) => b.status == ReadingStatus.finished).length;
    final avgDaysPerBook = finishedCount > 0 ? (activeDays / finishedCount).toStringAsFixed(1) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: colors.streakAmber, size: 20),
              const SizedBox(width: 8),
              Text('Reading Habits & Velocity', style: TextStyle(color: colors.quoteGold, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHabitItem('Avg Speed', '$avgPagesPerDay Pgs/Day', Icons.bolt, colors.streakAmber, colors),
              _buildHabitItem('Pace', '$avgDaysPerBook Days/Book', Icons.timer_outlined, colors.quoteGold, colors),
              _buildHabitItem('Peak Time', 'Evening 🌙', Icons.nightlight_round, colors.accentAmethyst, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(String label, String value, IconData icon, Color iconColor, ReadingAppColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colors.cardBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyHistoryChart(List<Book> books, ReadingAppColors colors) {
    final Map<int, int> monthlyPages = {};
    final now = DateTime.now();

    for (var b in books) {
      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          final m = e.date.month;
          monthlyPages[m] = (monthlyPages[m] ?? 0) + e.pagesRead;
        }
      }
      if (b.currentPage > 0 && b.journalEntries.isEmpty) {
        final activeDate = b.finishDate ?? b.startDate ?? DateTime.now();
        final m = activeDate.month;
        monthlyPages[m] = (monthlyPages[m] ?? 0) + b.currentPage;
      }
    }

    final recentMonths = List.generate(6, (i) {
      return DateTime(now.year, now.month - 5 + i);
    });

    int maxPages = 100;
    for (var m in recentMonths) {
      final p = monthlyPages[m.month] ?? 0;
      if (p > maxPages) maxPages = p;
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxPages.toDouble() * 1.2,
          barGroups: recentMonths.asMap().entries.map((entry) {
            final idx = entry.key;
            final monthDate = entry.value;
            final pages = (monthlyPages[monthDate.month] ?? 0).toDouble();

            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: pages,
                  color: colors.streakAmber,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < recentMonths.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM').format(recentMonths[idx]),
                        style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(List<Book> books, ReadingAppColors colors) {
    Map<ReadingStatus, int> counts = {};
    for (var status in ReadingStatus.values) {
      counts[status] = books.where((b) => b.status == status).length;
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: ReadingStatus.values.map((status) {
            final count = counts[status] ?? 0;
            if (count == 0) return PieChartSectionData(radius: 0);
            return PieChartSectionData(
              value: count.toDouble(),
              title: '${status.name}\n($count)',
              color: _getStatusColor(status, colors),
              radius: 60,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(ReadingStatus status, ReadingAppColors colors) {
    switch (status) {
      case ReadingStatus.currentlyReading: return colors.accentOcean;
      case ReadingStatus.toRead: return colors.streakAmber;
      case ReadingStatus.finished: return colors.accentSage;
      case ReadingStatus.abandoned: return Colors.redAccent;
      case ReadingStatus.wishlist: return colors.accentAmethyst;
    }
  }

  List<_BadgeInfo> _generateBadges({
    required int finishedCount,
    required int pagesCount,
    required int sessionsCount,
    required int quotesCount,
    required int streakCount,
    required int epicCount,
    required int uniqueGenresCount,
  }) {
    return [
      _BadgeInfo(
        title: 'Books Finished',
        icon: Icons.emoji_events,
        currentCount: finishedCount,
        targetCount: 25,
        tierName: finishedCount >= 25 ? 'Gold' : finishedCount >= 5 ? 'Silver' : 'Bronze',
        tierColor: finishedCount >= 25 ? const Color(0xFFFFD700) : finishedCount >= 5 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Books',
      ),
      _BadgeInfo(
        title: 'Pages Logged',
        icon: Icons.auto_stories,
        currentCount: pagesCount,
        targetCount: 5000,
        tierName: pagesCount >= 5000 ? 'Gold' : pagesCount >= 1000 ? 'Silver' : 'Bronze',
        tierColor: pagesCount >= 5000 ? const Color(0xFFFFD700) : pagesCount >= 1000 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Pages',
      ),
      _BadgeInfo(
        title: 'Streak Master',
        icon: Icons.local_fire_department,
        currentCount: streakCount,
        targetCount: 30,
        tierName: streakCount >= 30 ? 'Gold' : streakCount >= 7 ? 'Silver' : 'Bronze',
        tierColor: streakCount >= 30 ? const Color(0xFFFFD700) : streakCount >= 7 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Days',
      ),
      _BadgeInfo(
        title: 'Quotes Saved',
        icon: Icons.format_quote,
        currentCount: quotesCount,
        targetCount: 20,
        tierName: quotesCount >= 20 ? 'Gold' : quotesCount >= 5 ? 'Silver' : 'Bronze',
        tierColor: quotesCount >= 20 ? const Color(0xFFFFD700) : quotesCount >= 5 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Quotes',
      ),
      _BadgeInfo(
        title: 'Reading Sessions',
        icon: Icons.history,
        currentCount: sessionsCount,
        targetCount: 50,
        tierName: sessionsCount >= 50 ? 'Gold' : sessionsCount >= 10 ? 'Silver' : 'Bronze',
        tierColor: sessionsCount >= 50 ? const Color(0xFFFFD700) : sessionsCount >= 10 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Sessions',
      ),
      _BadgeInfo(
        title: 'Epic Tomes (500+ pgs)',
        icon: Icons.terrain,
        currentCount: epicCount,
        targetCount: 5,
        tierName: epicCount >= 5 ? 'Gold' : epicCount >= 1 ? 'Silver' : 'Bronze',
        tierColor: epicCount >= 5 ? const Color(0xFFFFD700) : epicCount >= 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
        unit: 'Books',
      ),
    ];
  }

  List<_MilestoneItem> _generateMilestones(List<Book> books, StreakInfo streak) {
    final List<_MilestoneItem> list = [];

    if (books.isNotEmpty) {
      final firstBook = books.first;
      list.add(_MilestoneItem(
        title: 'First Book Added',
        subtitle: firstBook.title,
        detail: 'by ${firstBook.author}',
        date: 'Sept 2026',
        icon: Icons.book,
      ));
    }

    final finished = books.where((b) => b.status == ReadingStatus.finished).toList();
    if (finished.isNotEmpty) {
      final firstFinished = finished.first;
      list.add(_MilestoneItem(
        title: 'First Book Finished',
        subtitle: firstFinished.title,
        detail: '${firstFinished.totalPages} pages completed',
        date: 'Sept 2026',
        icon: Icons.emoji_events,
      ));
    }

    if (books.isNotEmpty) {
      Book longest = books.first;
      for (var b in books) {
        if (b.totalPages > longest.totalPages) longest = b;
      }
      list.add(_MilestoneItem(
        title: 'Longest Book in Library',
        subtitle: longest.title,
        detail: '${longest.totalPages} pages',
        date: 'Sept 2026',
        icon: Icons.nature_people,
      ));
    }

    if (streak.currentStreak > 0) {
      list.add(_MilestoneItem(
        title: 'Active Reading Streak',
        subtitle: '${streak.currentStreak} Days Consecutive Reading',
        detail: 'Best: ${streak.longestStreak} days record',
        date: 'Today',
        icon: Icons.local_fire_department,
      ));
    }

    return list;
  }
}

class _HistoryActivityItem {
  final Book book;
  final int pagesRead;
  final DateTime date;

  _HistoryActivityItem({
    required this.book,
    required this.pagesRead,
    required this.date,
  });
}

class _BadgeInfo {
  final String title;
  final IconData icon;
  final int currentCount;
  final int targetCount;
  final String tierName;
  final Color tierColor;
  final String unit;

  _BadgeInfo({
    required this.title,
    required this.icon,
    required this.currentCount,
    required this.targetCount,
    required this.tierName,
    required this.tierColor,
    required this.unit,
  });

  double get progress => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;
}

class _MilestoneItem {
  final String title;
  final String subtitle;
  final String? detail;
  final String date;
  final IconData icon;

  _MilestoneItem({
    required this.title,
    required this.subtitle,
    this.detail,
    required this.date,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final ReadingAppColors colors;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final iconC = color ?? colors.streakAmber;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconC, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
