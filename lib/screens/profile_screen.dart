import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/book_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/reading_app_colors.dart';
import '../services/bookora_notification_service.dart';
import '../widgets/dual_view_reading_calendar.dart';
import 'settings_screen.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers/goal_provider.dart';

enum CalendarMode { heatmap, covers }

class ProfileScreen extends ConsumerStatefulWidget {
  final Function(ReadingStatus?)? onSelectShelfFilter;

  const ProfileScreen({super.key, this.onSelectShelfFilter});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider);
    final streak = ref.watch(streakProvider);
    final colors = context.appColors;

    final books = bookState.maybeWhen(
      data: (list) => list,
      orElse: () => <Book>[],
    );

    // Overview Stats
    final totalBooks = books.length;
    final finishedBooksCount = books.where((b) => b.status == ReadingStatus.finished).length;

    // Calculate Total Pages Read across journal entries + current page positions
    final totalPagesRead = books.fold(0, (sum, b) {
      final journalSum = b.journalEntries.fold(0, (s, e) => s + e.pagesRead);
      return sum + max(b.currentPage, journalSum);
    });

    final daysReadSet = <String>{};
    for (var b in books) {
      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          daysReadSet.add(DateFormat('yyyy-MM-dd').format(e.date));
        }
      }
      if (b.currentPage > 0) {
        final activeDate = b.finishDate ?? b.startDate ?? DateTime.now();
        daysReadSet.add(DateFormat('yyyy-MM-dd').format(activeDate));
      }
    }
    final daysReadCount = daysReadSet.length;

    // Challenge Progress
    final targetGoalBooks = ref.watch(readingGoalProvider);
    final challengePercent = targetGoalBooks > 0
        ? (finishedBooksCount / targetGoalBooks).clamp(0.0, 1.0)
        : 0.0;
    final yearEnd = DateTime(_selectedMonth.year, 12, 31);
    final daysRemaining = max(0, yearEnd.difference(DateTime.now()).inDays);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Profile Header Bar
              _buildTopProfileBar(context, colors),
              const SizedBox(height: 16),

              // 2. Reading Overview Stats & Challenge Block
              _buildOverviewAndChallengeCard(
                context: context,
                colors: colors,
                totalBooks: totalBooks,
                daysReadCount: daysReadCount,
                totalPagesRead: totalPagesRead,
                finishedBooksCount: finishedBooksCount,
                targetBooks: targetGoalBooks,
                challengePercent: challengePercent,
                daysRemaining: daysRemaining,
              ),
              const SizedBox(height: 20),

              // 3. Dual-Mode Reading Calendar Dashboard
              _buildDualModeCalendarSection(books, streak),
              const SizedBox(height: 24),

              // 4. Shelves Grid
              _buildShelvesGrid(context, colors, books),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Top Profile Bar ---
  Widget _buildTopProfileBar(BuildContext context, ReadingAppColors colors) {
    final profile = ref.watch(profileProvider);

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showEditProfileDialog(context, colors),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.streakAmber, colors.quoteGold],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.cardBg,
                  backgroundImage: profile.avatarPath != null 
                      ? FileImage(File(profile.avatarPath!)) 
                      : null,
                  child: profile.avatarPath == null
                      ? Text(
                          profile.initials,
                          style: TextStyle(color: colors.streakAmber, fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.streakAmber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 8, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showEditProfileDialog(context, colors),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 14, color: colors.textSecondary),
                  ],
                ),
                Text(
                  profile.username,
                  style: TextStyle(color: colors.quoteGold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        _buildHeaderActionPill(context, colors),
      ],
    );
  }

  Widget _buildHeaderActionPill(BuildContext context, ReadingAppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: IconButton(
        icon: Icon(Icons.settings_outlined, size: 20, color: colors.textSecondary),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: 'Settings & Preferences',
        onPressed: () {
          SettingsScreen.navigate(context);
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ReadingAppColors colors) {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile.name);
    final handleController = TextEditingController(text: profile.username);
    final bioController = TextEditingController(text: profile.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_outline, color: colors.streakAmber),
            const SizedBox(width: 8),
            Text('Edit Profile', style: TextStyle(color: colors.quoteGold, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(color: colors.streakAmber),
                  prefixIcon: Icon(Icons.person, color: colors.streakAmber),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: colors.streakAmber),
                  prefixText: '@ ',
                  prefixStyle: TextStyle(color: colors.quoteGold, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 2,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Bio / Tagline',
                  labelStyle: TextStyle(color: colors.streakAmber),
                  prefixIcon: const Icon(Icons.description, color: Colors.grey),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(profileProvider.notifier).updateProfile(
                      name: nameController.text,
                      username: handleController.text,
                      bio: bioController.text,
                    );
                Navigator.pop(context);
                BookoraNotificationService.showProfileUpdatedToast(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.streakAmber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 2. Unified Overview & Annual Reading Challenge Widget ---
  Widget _buildOverviewAndChallengeCard({
    required BuildContext context,
    required ReadingAppColors colors,
    required int totalBooks,
    required int daysReadCount,
    required int totalPagesRead,
    required int finishedBooksCount,
    required int targetBooks,
    required double challengePercent,
    required int daysRemaining,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.3) : const Color(0x0F3A2E24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Side: 3 Key Metrics
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewStatRow(Icons.auto_stories, '$totalBooks Books', 'In Library', colors.streakAmber, colors),
                const SizedBox(height: 12),
                _buildOverviewStatRow(Icons.calendar_today, '$daysReadCount Days', 'Active Days', colors.quoteGold, colors),
                const SizedBox(height: 12),
                _buildOverviewStatRow(Icons.menu_book, '$totalPagesRead Pages', 'Total Read', colors.accentSage, colors),
              ],
            ),
          ),
          Container(height: 100, width: 1, color: colors.borderSubtle),
          // Right Side: Radial Goal Ring
          Expanded(
            flex: 12,
            child: GestureDetector(
              onTap: () => _showGoalEditDialog(context, colors),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: challengePercent,
                          strokeWidth: 9,
                          backgroundColor: colors.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(challengePercent * 100).toInt()}%',
                            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            '$finishedBooksCount / $targetBooks Books',
                            style: TextStyle(color: colors.quoteGold, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.cardBgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Text(
                      '2026 Challenge • $daysRemaining Days Left',
                      style: TextStyle(color: colors.textSecondary, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatRow(IconData icon, String value, String label, Color iconColor, ReadingAppColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // --- 3. Dual-Mode Reading Calendar Section ---
  Widget _buildDualModeCalendarSection(List<Book> books, StreakInfo streak) {
    final List<BookSpanInfo> spans = [];
    final Map<DateTime, int> activityMap = {};

    final colors = [
      const Color(0xFFE07A38),
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.lightBlueAccent,
      Colors.amberAccent,
    ];

    int colorIdx = 0;
    for (var b in books) {
      // Abandoned books won't show on dual reading calendar spans or cover decks
      if (b.status == ReadingStatus.abandoned) {
        continue;
      }

      if (b.startDate != null) {
        final start = b.startDate!.toLocal();
        final isCompleted = b.status == ReadingStatus.finished || b.finishDate != null;
        final end = (b.finishDate ?? DateTime.now()).toLocal();
        spans.add(BookSpanInfo(
          id: b.id,
          bookTitle: b.title,
          author: b.author,
          coverUrl: b.coverUrl,
          startDate: DateTime(start.year, start.month, start.day),
          endDate: DateTime(end.year, end.month, end.day),
          color: colors[colorIdx % colors.length],
          isFinished: isCompleted,
          currentPage: b.currentPage,
          totalPages: b.totalPages,
          book: b,
        ));
        colorIdx++;
      }

      for (var e in b.journalEntries) {
        if (e.pagesRead > 0) {
          final localDate = e.date.toLocal();
          final normalizedDate = DateTime(localDate.year, localDate.month, localDate.day);
          activityMap[normalizedDate] = (activityMap[normalizedDate] ?? 0) + e.pagesRead;
        }
      }

      if (b.currentPage > 0 && b.journalEntries.isEmpty) {
        final localDate = (b.finishDate ?? b.startDate ?? DateTime.now()).toLocal();
        final normalizedDate = DateTime(localDate.year, localDate.month, localDate.day);
        activityMap[normalizedDate] = (activityMap[normalizedDate] ?? 0) + b.currentPage;
      }
    }

    final totalPagesRead = books.fold(0, (sum, b) => sum + max(b.currentPage, b.journalEntries.fold(0, (s, e) => s + e.pagesRead)));

    return DualViewReadingCalendar(
      bookSpans: spans,
      readingActivityMap: activityMap,
      bestStreak: streak.currentStreak,
      daysRead: activityMap.length,
      totalPages: totalPagesRead,
      initialMonth: _selectedMonth,
    );
  }

  // --- 4. Categorized Shelves Grid ---
  Widget _buildShelvesGrid(BuildContext context, ReadingAppColors colors, List<Book> books) {
    final readingCount = books.where((b) => b.status == ReadingStatus.currentlyReading).length;
    final toReadCount = books.where((b) => b.status == ReadingStatus.toRead).length;
    final finishedCount = books.where((b) => b.status == ReadingStatus.finished).length;
    final wishlistCount = books.where((b) => b.status == ReadingStatus.wishlist).length;
    final abandonedCount = books.where((b) => b.status == ReadingStatus.abandoned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Shelves',
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildShelfTile(context, colors, 'Reading', readingCount, Icons.book, colors.streakAmber, ReadingStatus.currentlyReading),
            _buildShelfTile(context, colors, 'To Read', toReadCount, Icons.bookmark_border, colors.quoteGold, ReadingStatus.toRead),
            _buildShelfTile(context, colors, 'Finished', finishedCount, Icons.check_circle_outline, colors.accentSage, ReadingStatus.finished),
            _buildShelfTile(context, colors, 'Wishlist', wishlistCount, Icons.favorite_border, colors.accentAmethyst, ReadingStatus.wishlist),
            _buildShelfTile(context, colors, 'Abandoned', abandonedCount, Icons.remove_circle_outline, Colors.redAccent, ReadingStatus.abandoned),
          ],
        ),
      ],
    );
  }

  Widget _buildShelfTile(BuildContext context, ReadingAppColors colors, String title, int count, IconData icon, Color color, ReadingStatus status) {
    return InkWell(
      onTap: () {
        if (widget.onSelectShelfFilter != null) {
          widget.onSelectShelfFilter!(status);
        } else {
          ref.read(bookFilterProvider.notifier).state = status;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Filtered by $title in Library tab'), behavior: SnackBarBehavior.floating),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '$count Books',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalEditDialog(BuildContext context, ReadingAppColors colors) {
    final currentGoal = ref.read(readingGoalProvider);
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        title: Text('Edit 2026 Reading Goal', style: TextStyle(color: colors.quoteGold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(labelText: 'Target Number of Books', labelStyle: TextStyle(color: colors.streakAmber)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                ref.read(readingGoalProvider.notifier).setGoal(val);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.streakAmber, foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
