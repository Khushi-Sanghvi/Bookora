import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../models/enums.dart';
import '../providers/book_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/layout_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/reading_app_colors.dart';
import '../services/audiobook_audio_handler.dart';
import '../services/bookora_notification_service.dart';
import '../repositories/repositories.dart';
import '../widgets/csv_import_dialog.dart';
import '../widgets/online_book_search_modal.dart';
import '../widgets/bookora_floral_dialog.dart';
import '../widgets/bookora_snack_bar.dart';
import '../widgets/about_app_dialog.dart';
import '../widgets/reader_walkthrough_modal.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> navigate(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final profile = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notificationSettings = ref.watch(notificationProvider);
    final currentLayout = ref.watch(layoutProvider);
    final readingGoal = ref.watch(readingGoalProvider);

    final booksState = ref.watch(bookProvider);
    final allBooks = booksState.maybeWhen(
      data: (list) => list,
      orElse: () => <Book>[],
    );
    final finishedCount = allBooks
        .where((b) => b.status == ReadingStatus.finished)
        .length;
    final goalPercent = readingGoal > 0
        ? (finishedCount / readingGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings & Preferences',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // -------------------------------------------------------------------
          // 1. VISUAL & DISPLAY PREFERENCES
          // -------------------------------------------------------------------
          _buildSectionHeader('VISUAL & DISPLAY PREFERENCES', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      color: colors.streakAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'App Visual Theme',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeSelectCard(
                        title: 'Midnight Library',
                        subtitle: 'Dark Academia',
                        color: const Color(0xFF141210),
                        borderColor: const Color(0xFF2E2620),
                        isSelected: themeMode == ThemeMode.dark,
                        accentColor: colors.streakAmber,
                        textColor: const Color(0xFFEFE8DC),
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildThemeSelectCard(
                        title: 'Parchment & Ivory',
                        subtitle: 'Ivory Light',
                        color: const Color(0xFFF7F4EC),
                        borderColor: const Color(0xFFDED2BD),
                        isSelected: themeMode == ThemeMode.light,
                        accentColor: const Color(0xFFB45309),
                        textColor: const Color(0xFF2A2017),
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white10),
                Text(
                  'Library Display Layout',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLayoutChip(
                      label: '3D Dark Academia Shelf',
                      icon: Icons.auto_stories,
                      isSelected:
                          currentLayout == ShelfLayoutView.darkAcademiaShelf,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.darkAcademiaShelf,
                    ),
                    _buildLayoutChip(
                      label: '3D Carousel Showcase',
                      icon: Icons.view_carousel_rounded,
                      isSelected:
                          currentLayout == ShelfLayoutView.carouselShowcase,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.carouselShowcase,
                    ),
                    _buildLayoutChip(
                      label: 'Polaroid Scrapbook Gallery',
                      icon: Icons.photo_library_outlined,
                      isSelected:
                          currentLayout == ShelfLayoutView.polaroidScrapbook,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.polaroidScrapbook,
                    ),
                    _buildLayoutChip(
                      label: '3D Classic Wooden Shelf',
                      icon: Icons.table_rows_rounded,
                      isSelected:
                          currentLayout == ShelfLayoutView.skeuomorphicShelf,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.skeuomorphicShelf,
                    ),
                    _buildLayoutChip(
                      label: 'Cover Grid',
                      icon: Icons.grid_view_rounded,
                      isSelected: currentLayout == ShelfLayoutView.coverGrid,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.coverGrid,
                    ),
                    _buildLayoutChip(
                      label: 'Detailed List',
                      icon: Icons.view_headline_rounded,
                      isSelected: currentLayout == ShelfLayoutView.detailedList,
                      colors: colors,
                      onTap: () => ref.read(layoutProvider.notifier).state =
                          ShelfLayoutView.detailedList,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 2. READING GOALS & PACING
          // -------------------------------------------------------------------
          _buildSectionHeader('READING GOALS & PACING', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            color: colors.streakAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Annual Reading Challenge',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showEditGoalModal(context, ref, readingGoal, colors),
                      icon: const Icon(Icons.edit, size: 13),
                      label: const Text(
                        'Edit Goal',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.streakAmber,
                        side: BorderSide(
                          color: colors.streakAmber.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$finishedCount',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: colors.streakAmber,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  ' / $readingGoal books completed',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: goalPercent,
                              minHeight: 8,
                              backgroundColor: colors.cardBgSecondary,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.streakAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.cardBgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        '${(goalPercent * 100).toInt()}%',
                        style: TextStyle(
                          color: colors.quoteGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 3. DOCUMENT INGESTION & CATALOG IMPORT
          // -------------------------------------------------------------------
          _buildSectionHeader('DOCUMENT INGESTION & CATALOG IMPORT', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.travel_explore,
                      color: colors.streakAmber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Search & Ingest Books Online',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Directly import books & rich metadata from Open Library & Google Books',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => OnlineBookSearchModal.show(context),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.table_chart_rounded,
                      color: AppColors.goldAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Import Goodreads / StoryGraph CSV',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Import complete reading history, shelves & ratings',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.sepiaMuted,
                  ),
                  onTap: () => CsvImportDialog.show(context),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.purpleAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Add Demo / Sample Book',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Quickly insert a curated demo book with cover & metadata',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _showAddDemoBookDialog(context, ref, colors),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 4. NOTIFICATION REMINDERS & STREAK ALERTS (PRESERVED)
          // -------------------------------------------------------------------
          _buildSectionHeader('NOTIFICATION REMINDERS & STREAK ALERTS', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: colors.streakAmber,
                  ),
                  title: Text(
                    'Daily Reading Reminders',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Receive daily push notifications to read',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  value: notificationSettings.remindersEnabled,
                  activeTrackColor: colors.streakAmber,
                  onChanged: (val) {
                    ref
                        .read(notificationProvider.notifier)
                        .toggleReminders(val);
                  },
                ),
                if (notificationSettings.remindersEnabled) ...[
                  const Divider(height: 16, color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time, color: colors.quoteGold),
                    title: Text(
                      'Reminder Schedule Time',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Repeats daily at ${_formatTimeOfDay(notificationSettings.reminderTime)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Icon(
                      Icons.edit_calendar_outlined,
                      color: colors.streakAmber,
                      size: 18,
                    ),
                    onTap: () async {
                      final picked = await _showReadingReminderTimePickerDialog(
                        context,
                        notificationSettings.reminderTime,
                      );
                      if (picked != null) {
                        ref
                            .read(notificationProvider.notifier)
                            .setReminderTime(picked);
                      }
                    },
                  ),
                ],
                const Divider(height: 16, color: Colors.white10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.local_fire_department_outlined,
                    color: Colors.orangeAccent,
                  ),
                  title: Text(
                    'Streak Protection Alerts',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Warns before midnight if daily goal isn\'t met',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  value: notificationSettings.streakAlertsEnabled,
                  activeTrackColor: colors.streakAmber,
                  onChanged: (val) {
                    ref
                        .read(notificationProvider.notifier)
                        .toggleStreakAlerts(val);
                  },
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.send_outlined, color: colors.streakAmber),
                  title: Text(
                    'Test Instant Notification',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Triggers an immediate test notification now',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(notificationProvider.notifier)
                          .sendTestNotification();
                      BookoraSnackBar.show(
                        context,
                        type: BookoraSnackBarType.success,
                        title: 'Test notification sent!',
                        subtitle: 'Check your notification bar.',
                      );
                    },
                    icon: const Icon(Icons.notifications, size: 14),
                    label: const Text('Test', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.streakAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 5. PROFILE & ACCOUNT (PRESERVED)
          // -------------------------------------------------------------------
          _buildSectionHeader('PROFILE & ACCOUNT', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.cardBgSecondary,
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    color: colors.streakAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                profile.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                profile.username,
                style: TextStyle(color: colors.quoteGold, fontSize: 12),
              ),
              trailing: Icon(
                Icons.edit_outlined,
                color: colors.textSecondary,
                size: 18,
              ),
              onTap: () => _showEditProfileDialog(context, ref, colors),
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 6. BACKUP, EXPORT & DATA MANAGEMENT
          // -------------------------------------------------------------------
          _buildSectionHeader('BACKUP, EXPORT & DATA MANAGEMENT', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.save_rounded,
                      color: colors.streakAmber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Backup Database (.db)',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Export raw SQLite database file directly to local storage',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.download_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _backupDatabase(context, ref, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.quoteGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.file_download_outlined,
                      color: colors.quoteGold,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Export Library to CSV',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Generate Goodreads-compatible CSV file of your books',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.copy_outlined,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _exportCsv(context, ref, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentSage.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_backup_restore_rounded,
                      color: colors.accentSage,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Restore Database (.db)',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Replace database with a previously exported .db file',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _restoreDatabase(context, ref, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.upload_file_outlined,
                      color: colors.streakAmber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Export Library JSON Backup',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Export all books, quotes & journals to portable JSON',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.copy_outlined,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _handleExportBackup(context, ref, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentSage.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_for_offline_outlined,
                      color: colors.accentSage,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Restore Library JSON Backup',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Paste and restore a JSON backup payload',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _handleRestoreBackup(context, ref, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Wipe All Data',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently clear all books, quotes, notes, and reading history',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onTap: () => _showWipeDataConfirmation(context, ref, colors),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 7. SANCTUARY GUIDE & WALKTHROUGH
          // -------------------------------------------------------------------
          _buildSectionHeader('SANCTUARY GUIDE & WALKTHROUGH', colors),
          const SizedBox(height: 10),
          _buildCardContainer(
            colors,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.streakAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: colors.streakAmber,
                  size: 20,
                ),
              ),
              title: Text(
                'How to Use Bookora',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'A quick walkthrough for your reading sanctuary',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.streakAmber.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '5 Steps',
                      style: TextStyle(
                        color: colors.streakAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
              onTap: () => _showAppWalkthroughModal(context, colors),
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 8. PRIVACY, ABOUT & DEVELOPER SUPPORT
          // -------------------------------------------------------------------
          _buildSectionHeader('PRIVACY, ABOUT & SUPPORT', colors),
          const SizedBox(height: 10),

          // 100% Free & Private Sanctuary Banner
          InkWell(
            onTap: () => _showPrivacyPolicyDialog(context, colors),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    colors.cardBg,
                    colors.streakAmber.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: colors.streakAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: colors.streakAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Free & Private Sanctuary',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Zero ads • 100% local storage • No tracking or telemetry. Tap to view our privacy policy.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.streakAmber,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _buildCardContainer(
            colors,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.auto_stories_rounded,
                    color: colors.streakAmber,
                  ),
                  title: Text(
                    'About Bookora',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'The Obsidian Edition • Version 1.0.0 (Build 1)',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _showAboutAppDialog(context, colors),
                ),
                const Divider(height: 16, color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.lightBlueAccent,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Contact Developer & Support',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Feedback, feature requests, or bug reports',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  trailing: Icon(
                    Icons.send_rounded,
                    color: colors.textSecondary,
                    size: 16,
                  ),
                  onTap: () => _launchContactEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI HELPERS & COMPONENTS
  // ===========================================================================

  Widget _buildSectionHeader(String title, ReadingAppColors colors) {
    return Text(
      title,
      style: TextStyle(
        color: colors.streakAmber,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildCardContainer(ReadingAppColors colors, {required Widget child}) {
    return Material(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: child,
      ),
    );
  }

  Widget _buildThemeSelectCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color borderColor,
    required bool isSelected,
    required Color accentColor,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(radius: 6, backgroundColor: accentColor),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ReadingAppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.streakAmber.withValues(alpha: 0.15)
              : colors.cardBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.streakAmber : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.streakAmber : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.streakAmber : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INTERACTIVE MODALS & ACTION HANDLERS
  // ===========================================================================
  // 6. READING GOAL BOTTOM SHEET MODAL (REFERENCE SPEC MATCH)
  // ===========================================================================

  void _showEditGoalModal(
    BuildContext context,
    WidgetRef ref,
    int currentGoal,
    ReadingAppColors colors,
  ) {
    int target = currentGoal > 0 ? currentGoal : 12;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13161C) : const Color(0xFFFAF6EF);
    final borderColor = isDark ? const Color(0xFF2D3E50) : const Color(0xFFE8DECC);
    final titleColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final accentColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFD95D39);
    final subtitleColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFD95D39);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black87
                          : const Color(0xFF2E1E12).withValues(alpha: 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
                  child: Stack(
                    children: [
                      // 1. Botanical Corner Flourishes Framing the Modal (All 4 Corners)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GoalModalBotanicalPainter(isDark: isDark),
                          ),
                        ),
                      ),

                      // 2. Main Content Layout
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Drag Handle Pill
                            Center(
                              child: Container(
                                width: 44,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF333C4A) : const Color(0xFFE0D4C3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Main Title in Elegant Serif
                            Text(
                              'Set Your Reading Goal',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle in Warm Terracotta/Amber
                            Text(
                              'How many books do you want to read this year?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. Interactive Stepper & Central Value Capsule (Flanked by Botanicals)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Minus Button (-)
                                  GestureDetector(
                                    onTap: () {
                                      if (target > 1) {
                                        setModalState(() => target--);
                                      }
                                    },
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor,
                                          width: 1.6,
                                        ),
                                        color: accentColor.withValues(alpha: 0.04),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.remove_rounded,
                                          color: accentColor,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Central Value Capsule with Flanking Floral Branches
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Left Flanking Botanical Branch
                                      CustomPaint(
                                        size: const Size(20, 54),
                                        painter: _CapsuleFlankBotanicalPainter(
                                          isLeft: true,
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 2),

                                      // Central Value Capsule (Tap-to-Type Capable)
                                      GestureDetector(
                                        onTap: () {
                                          _showDirectGoalInputDialog(
                                            ctx,
                                            target,
                                            (newVal) {
                                              setModalState(() => target = newVal);
                                            },
                                          );
                                        },
                                        child: Container(
                                          height: 56,
                                          constraints: const BoxConstraints(minWidth: 154),
                                          padding: const EdgeInsets.symmetric(horizontal: 22),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(28),
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? const [Color(0xFF1E222B), Color(0xFF181B22)]
                                                  : const [Color(0xFFFFFBF5), Color(0xFFFFF6ED)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFFFFB74D).withValues(alpha: 0.55)
                                                  : const Color(0xFFE89C7D).withValues(alpha: 0.80),
                                              width: 1.4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.black.withValues(alpha: 0.4)
                                                    : const Color(0xFFD95D39).withValues(alpha: 0.10),
                                                blurRadius: 14,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Large Number Display
                                              Text(
                                                '$target',
                                                style: GoogleFonts.playfairDisplay(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(width: 4),

                                              // Blinking / Edit Cursor Bar
                                              Container(
                                                width: 2.2,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: accentColor,
                                                  borderRadius: BorderRadius.circular(1.2),
                                                ),
                                              ),
                                              const SizedBox(width: 14),

                                              // Pencil Edit Icon
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 19,
                                                color: isDark
                                                    ? const Color(0xFFCFD8DC)
                                                    : const Color(0xFF2E1E12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),

                                      // Right Flanking Botanical Branch
                                      CustomPaint(
                                        size: const Size(20, 54),
                                        painter: _CapsuleFlankBotanicalPainter(
                                          isLeft: false,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),

                                  // Plus Button (+)
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() => target++);
                                    },
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor,
                                          width: 1.6,
                                        ),
                                        color: accentColor.withValues(alpha: 0.04),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: accentColor,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // "books per year" centered label
                            Text(
                              'books per year',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // 4. Quick-Select Preset Value Chips (Exact 2 Rows)
                            // Row 1: [5], [10], [15], [20], [25]
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [5, 10, 15, 20, 25].map((preset) {
                                  final isSel = target == preset;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildGoalPresetChip(
                                      preset: preset,
                                      isSelected: isSel,
                                      isDark: isDark,
                                      titleColor: titleColor,
                                      accentColor: accentColor,
                                      onTap: () {
                                        setModalState(() => target = preset);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Row 2: [30], [50], [100]
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [30, 50, 100].map((preset) {
                                  final isSel = target == preset;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: SizedBox(
                                      width: 68,
                                      child: _buildGoalPresetChip(
                                        preset: preset,
                                        isSelected: isSel,
                                        isDark: isDark,
                                        titleColor: titleColor,
                                        accentColor: accentColor,
                                        onTap: () {
                                          setModalState(() => target = preset);
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // 5. Full-width "Save Goal" Action Button
                            Container(
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? const [Color(0xFFFF8F00), Color(0xFFE65100)]
                                      : const [Color(0xFFE65100), Color(0xFFD94E18)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFFFF8F00) : const Color(0xFFD94E18))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(26),
                                  onTap: () {
                                    ref.read(readingGoalProvider.notifier).setGoal(target);
                                    Navigator.pop(sheetContext);
                                    BookoraSnackBar.show(
                                      context,
                                      type: BookoraSnackBarType.readingGoal,
                                      title: 'Reading goal updated to $target books!',
                                      subtitle: "Keep going! You're on track.",
                                    );
                                  },
                                  child: Center(
                                    child: Text(
                                      'Save Goal',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper: Goal Preset Value Chip ---
  Widget _buildGoalPresetChip({
    required int preset,
    required bool isSelected,
    required bool isDark,
    required Color titleColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C241D) : const Color(0xFFFDEEE7))
              : (isDark ? const Color(0xFF20242D) : const Color(0xFFFBF6EE)),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFFFA726) : const Color(0xFFD95D39))
                : (isDark ? const Color(0xFF333B49) : const Color(0xFFEADBCA)),
            width: isSelected ? 1.5 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? const Color(0xFFFFA726) : const Color(0xFFD95D39))
                        .withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$preset',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? accentColor : titleColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper: Direct Tap-To-Type Input Dialog ---
  void _showDirectGoalInputDialog(
    BuildContext modalContext,
    int currentVal,
    ValueChanged<int> onValChanged,
  ) {
    final controller = TextEditingController(text: '$currentVal');
    showDialog(
      context: modalContext,
      builder: (inputCtx) => BookoraFloralDialog(
        title: 'Enter Target Goal',
        subtitle: 'How many books do you want to read this year?',
        content: BookoraPillTextField(
          controller: controller,
          label: 'Books per year',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.auto_stories_rounded,
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(inputCtx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            text: 'Set Goal',
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                onValChanged(val);
              }
              Navigator.pop(inputCtx);
            },
          ),
        ],
      ),
    );
  }

  void _showAddDemoBookDialog(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) {
    final titleController = TextEditingController(
      text: 'The Picture of Dorian Gray',
    );
    final authorController = TextEditingController(text: 'Oscar Wilde');
    final genreController = TextEditingController(
      text: 'Classics, Philosophical Fiction, Gothic',
    );
    final pagesController = TextEditingController(text: '254');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amberColor.withValues(alpha: 0.15),
            border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Icon(Icons.auto_stories_rounded, color: amberColor, size: 24),
        ),
        title: 'Add a New Book',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookoraPillTextField(
              controller: titleController,
              label: 'Title',
              hint: 'Book title',
            ),
            const SizedBox(height: 12),
            BookoraPillTextField(
              controller: authorController,
              label: 'Author',
              hint: 'Author name',
            ),
            const SizedBox(height: 12),
            BookoraPillTextField(
              controller: genreController,
              label: 'Genres (comma-separated)',
              hint: 'e.g. Fantasy, Adventure',
            ),
            const SizedBox(height: 12),
            BookoraPillTextField(
              controller: pagesController,
              label: 'Total Pages',
              hint: 'e.g. 320',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            text: 'Add Book',
            onPressed: () {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              final pages = int.tryParse(pagesController.text) ?? 250;
              final genres = genreController.text
                  .split(',')
                  .map((g) => g.trim())
                  .where((g) => g.isNotEmpty)
                  .toList();

              if (title.isNotEmpty) {
                final newBook = Book(
                  id: const Uuid().v4(),
                  title: title,
                  author: author.isNotEmpty ? author : 'Unknown',
                  description:
                      'A curated masterpiece added to your Bookora library.',
                  coverUrl: '',
                  totalPages: pages,
                  genres: genres.isNotEmpty ? genres : ['General'],
                  status: ReadingStatus.toRead,
                  startDate: DateTime.now(),
                );
                ref.read(bookProvider.notifier).addBook(newBook);
                Navigator.pop(ctx);
                BookoraSnackBar.show(
                  context,
                  type: BookoraSnackBarType.bookAdded,
                  title: '"$title" added to your library!',
                  subtitle: 'Happy Reading! ✨',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _backupDatabase(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) async {
    try {
      final dbPath = await ref.read(bookRepositoryProvider).getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (!context.mounted) return;
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.dbWarning,
          title: 'Database file does not exist yet.',
          subtitle: 'Create a backup to get started.',
        );
        return;
      }

      final bytes = await dbFile.readAsBytes();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'bookora_backup_$timestamp.db';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save SQLite Database Backup',
        fileName: backupFileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
        bytes: bytes,
      );

      if (!context.mounted) return;
      if (outputPath != null) {
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.dbSaved,
          title: 'Database backup saved to:',
          subtitle: outputPath,
        );
      } else {
        // Fallback copy to app documents
        final appDir = await getApplicationDocumentsDirectory();
        final backupCopy = await dbFile.copy('${appDir.path}/$backupFileName');
        if (!context.mounted) return;
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.dbSaved,
          title: 'Database backup saved at:',
          subtitle: backupCopy.path,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      BookoraSnackBar.show(
        context,
        type: BookoraSnackBarType.error,
        title: 'Error exporting database:',
        subtitle: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _restoreDatabase(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
            border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.4), width: 1.2),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD32F2F),
            size: 26,
          ),
        ),
        title: 'Restore Database?',
        content: Text(
          'This will replace your current library with the selected database file. Your existing data will be lost.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.4,
            color: isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12),
          ),
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.destructive(
            text: 'Restore',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final backupPath = result.files.single.path!;
        final backupFile = File(backupPath);
        final targetDbPath = await ref.read(bookRepositoryProvider).getDatabasePath();

        await ref.read(bookRepositoryProvider).closeDatabase();
        await backupFile.copy(targetDbPath);

        ref.read(bookProvider.notifier).loadBooks();

        if (!context.mounted) return;
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.dbRestored,
          title: 'Success! 12 books restored',
          subtitle: 'into your library.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      BookoraSnackBar.show(
        context,
        type: BookoraSnackBarType.error,
        title: 'Error restoring database:',
        subtitle: 'Invalid JSON structure.',
      );
    }
  }

  void _exportCsv(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) async {
    final booksState = ref.read(bookProvider);
    final books = booksState.maybeWhen(
      data: (list) => list,
      orElse: () => <Book>[],
    );

    if (books.isEmpty) {
      BookoraSnackBar.show(
        context,
        type: BookoraSnackBarType.emptyLibrary,
        title: 'Your library is currently empty.',
        subtitle: 'No books to export.',
      );
      return;
    }

    final csvString = ref.read(userSettingsRepositoryProvider).exportBooksToCsv(books);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
    final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);
    final textColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100)).withValues(alpha: 0.15),
            border: Border.all(
              color: (isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100)).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Icon(
            Icons.table_view_rounded,
            color: isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100),
            size: 24,
          ),
        ),
        title: 'Your Library (CSV)',
        subtitle: 'Preview your exported data below.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.1),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvString,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Close',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            icon: Icons.copy_rounded,
            text: 'Copy CSV',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvString));
              Navigator.pop(ctx);
              BookoraSnackBar.show(
                context,
                type: BookoraSnackBarType.copied,
                title: 'CSV copied to clipboard!',
                subtitle: 'You can now paste it anywhere.',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWipeDataConfirmation(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD32F2F),
              size: 26,
            ),
          ),
        ),
        title: 'Wipe All Data?',
        content: Text(
          'This will permanently delete all your books, reading progress, notes, and settings. This action cannot be undone.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12),
          ),
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.destructive(
            text: 'Yes, Wipe Everything',
            onPressed: () async {
              Navigator.pop(ctx);
              // 1. Atomically delete database tables
              await ref.read(bookRepositoryProvider).wipeAllData();
              // 2. Reset annual reading goal to default
              await ref.read(readingGoalProvider.notifier).resetGoal();
              // 3. Cancel and reset notification schedules and alarms
              await ref.read(notificationProvider.notifier).resetNotifications();
              // 4. Halt active audiobook playback and timers if running
              if (isAudioHandlerReady) {
                try {
                  await audioHandler.stop();
                } catch (_) {}
              }
              // 5. Reload books state to clear in-memory caches
              await ref.read(bookProvider.notifier).loadBooks();
              if (!context.mounted) return;
              BookoraSnackBar.show(
                context,
                type: BookoraSnackBarType.dataWiped,
                title: 'All library data has been wiped.',
                subtitle: 'This action cannot be undone.',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, ReadingAppColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amberColor.withValues(alpha: 0.15),
            border: Border.all(
              color: amberColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Icon(
            Icons.shield_rounded,
            color: amberColor,
            size: 26,
          ),
        ),
        title: 'Privacy & Data Sanctuary',
        subtitle:
            'Bookora is offline-first and values your privacy. We do not collect, track, or share your personal data. Your reading journey stays on your device, always.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPrivacyBullet(
              Icons.lock_outline,
              'Zero Tracking & Telemetry',
              'No analytics scripts, advertising identifiers, or background tracking.',
              colors,
            ),
            _buildPrivacyBullet(
              Icons.storage_rounded,
              '100% Local Storage',
              'All books, reading sessions, and quotes reside securely in SQLite on your device.',
              colors,
            ),
            _buildPrivacyBullet(
              Icons.cloud_off_rounded,
              'No Mandatory Accounts',
              'Read completely disconnected without giving your email or credentials.',
              colors,
            ),
            _buildPrivacyBullet(
              Icons.share_outlined,
              'Export Anytime',
              'Your data is yours. Export full JSON and CSV backups whenever you desire.',
              colors,
            ),
          ],
        ),
        actions: [
          BookoraPillButton.primary(
            text: 'Got It',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBullet(
    IconData icon,
    String title,
    String body,
    ReadingAppColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.streakAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppWalkthroughModal(BuildContext context, ReadingAppColors colors) {
    ReaderWalkthroughModal.show(context);
  }

  void _showAboutAppDialog(BuildContext context, ReadingAppColors colors) {
    AboutAppDialog.show(context);
  }

  Future<void> _launchContactEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'ark.dev.support@gmail.com',
      query: 'subject=Bookora%20Feedback%20%26%20Support',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Clipboard.setData(
          const ClipboardData(text: 'ark.dev.support@gmail.com'),
        );
        if (!context.mounted) return;
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.supportEmail,
          title: 'Support email copied to clipboard!',
          subtitle: 'ark.dev.support@gmail.com',
        );
      }
    } catch (_) {
      Clipboard.setData(const ClipboardData(text: 'ark.dev.support@gmail.com'));
      if (!context.mounted) return;
      BookoraSnackBar.show(
        context,
        type: BookoraSnackBarType.supportEmail,
        title: 'Support email copied to clipboard!',
        subtitle: 'ark.dev.support@gmail.com',
      );
    }
  }

  void _handleExportBackup(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) async {
    final profile = ref.read(profileProvider);
    final backupJson = await ref.read(userSettingsRepositoryProvider).createBackupJson(
      profileData: {
        'name': profile.name,
        'username': profile.username,
        'bio': profile.bio,
      },
    );

    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
    final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);
    final textColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amberColor.withValues(alpha: 0.15),
            border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Center(
            child: Text(
              '{ }',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: amberColor,
              ),
            ),
          ),
        ),
        title: 'Library Backup (JSON)',
        subtitle: 'Your complete library data (JSON format).',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.1),
              ),
              child: SingleChildScrollView(
                child: Text(
                  backupJson,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Close',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            icon: Icons.copy_rounded,
            text: 'Copy to Clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupJson));
              Navigator.pop(ctx);
              BookoraSnackBar.show(
                context,
                type: BookoraSnackBarType.copied,
                title: 'Backup JSON copied to clipboard!',
                subtitle: 'You can now save it safely.',
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleRestoreBackup(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
    final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);
    final textColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amberColor.withValues(alpha: 0.15),
            border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Icon(Icons.cloud_download_rounded, color: amberColor, size: 24),
        ),
        title: 'Restore from Backup',
        subtitle: 'Paste your JSON backup data below to restore your library.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              maxLines: 6,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'Paste JSON data here...',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF78909C) : const Color(0xFFA89F91),
                ),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor, width: 1.1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor, width: 1.1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: amberColor, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            text: 'Restore',
            onPressed: () async {
              final jsonText = controller.text.trim();
              if (jsonText.isEmpty) return;

              try {
                final restoredCount = await ref.read(userSettingsRepositoryProvider).restoreBackupJson(
                  jsonText,
                );
                ref.read(bookProvider.notifier).loadBooks();
                if (!context.mounted) return;

                Navigator.pop(ctx);
                BookoraSnackBar.show(
                  context,
                  type: BookoraSnackBarType.dbRestored,
                  title: 'Success! $restoredCount books restored',
                  subtitle: 'into your library.',
                );
              } catch (e) {
                if (!context.mounted) return;
                BookoraSnackBar.show(
                  context,
                  type: BookoraSnackBarType.error,
                  title: 'Error restoring database:',
                  subtitle: 'Invalid JSON structure.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    ReadingAppColors colors,
  ) {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile.name);
    final handleController = TextEditingController(text: profile.username);
    final bioController = TextEditingController(text: profile.bio);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

    showDialog(
      context: context,
      builder: (ctx) => BookoraFloralDialog(
        headerIcon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amberColor.withValues(alpha: 0.15),
            border: Border.all(color: amberColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: amberColor.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🐱',
              style: TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: 'Edit Profile',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookoraPillTextField(
              controller: nameController,
              label: 'Name',
              hint: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            BookoraPillTextField(
              controller: handleController,
              label: 'Username',
              hint: 'yourusername',
              prefixText: '@ ',
            ),
            const SizedBox(height: 12),
            BookoraPillTextField(
              controller: bioController,
              label: 'Bio',
              hint: 'Tell us a little about yourself...',
              maxLines: 3,
              maxLength: 160,
            ),
          ],
        ),
        actions: [
          BookoraPillButton.outlined(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          BookoraPillButton.primary(
            text: 'Save',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref
                    .read(profileProvider.notifier)
                    .updateProfile(
                      name: nameController.text,
                      username: handleController.text,
                      bio: bioController.text,
                    );
                Navigator.pop(ctx);
                BookoraNotificationService.showProfileUpdatedToast(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _showReadingReminderTimePickerDialog(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TimeOfDay selectedTime = initialTime;

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setPickerState) {
          final hour = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
          final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
          final periodStr = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
          final titleColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
          final cardBg = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
          final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);
          final amberColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);

          return BookoraFloralDialog(
            headerIcon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: amberColor.withValues(alpha: 0.15),
                border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Icon(Icons.access_time_rounded, color: amberColor, size: 24),
            ),
            title: 'Pick a Reminder Time',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Digital clock preview card matching showcase image
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, color: amberColor, size: 26),
                      const SizedBox(width: 14),
                      Text(
                        '$hour:$minuteStr',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: amberColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: amberColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          periodStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: amberColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Interactive stepper adjusters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Hour stepper
                    Column(
                      children: [
                        Text(
                          'Hour',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF795548),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: amberColor),
                              onPressed: () {
                                int newHour = (selectedTime.hour - 1) % 24;
                                if (newHour < 0) newHour += 24;
                                setPickerState(() {
                                  selectedTime = TimeOfDay(hour: newHour, minute: selectedTime.minute);
                                });
                              },
                            ),
                            Text(
                              '$hour',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: amberColor),
                              onPressed: () {
                                setPickerState(() {
                                  selectedTime = TimeOfDay(
                                    hour: (selectedTime.hour + 1) % 24,
                                    minute: selectedTime.minute,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Minute stepper
                    Column(
                      children: [
                        Text(
                          'Minute',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF795548),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: amberColor),
                              onPressed: () {
                                int newMin = (selectedTime.minute - 5) % 60;
                                if (newMin < 0) newMin += 60;
                                setPickerState(() {
                                  selectedTime = TimeOfDay(hour: selectedTime.hour, minute: newMin);
                                });
                              },
                            ),
                            Text(
                              minuteStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: amberColor),
                              onPressed: () {
                                setPickerState(() {
                                  selectedTime = TimeOfDay(
                                    hour: selectedTime.hour,
                                    minute: (selectedTime.minute + 5) % 60,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    // AM / PM toggle
                    Column(
                      children: [
                        Text(
                          'Period',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF90A4AE) : const Color(0xFF795548),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            final newHour = (selectedTime.hour + 12) % 24;
                            setPickerState(() {
                              selectedTime = TimeOfDay(hour: newHour, minute: selectedTime.minute);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: amberColor),
                            ),
                            child: Text(
                              periodStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: amberColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              BookoraPillButton.outlined(
                text: 'Cancel',
                onPressed: () => Navigator.pop(dialogCtx),
              ),
              const SizedBox(width: 8),
              BookoraPillButton.primary(
                text: 'Set',
                onPressed: () => Navigator.pop(dialogCtx, selectedTime),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dedicated botanical painter for the 4 corners of the Goal Modal sheet
/// strictly matching the reference design: delicate sage leaves, peach/coral buds, and golden pollen dots.
class _GoalModalBotanicalPainter extends CustomPainter {
  final bool isDark;

  const _GoalModalBotanicalPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final leafColor = isDark ? const Color(0xFF7A9A60) : const Color(0xFF8A9A5B);
    final budColor = isDark ? const Color(0xFFF4A261) : const Color(0xFFEA8D74);
    final stemColor = isDark
        ? const Color(0xFF8D6E63).withValues(alpha: 0.65)
        : const Color(0xFFB58A63).withValues(alpha: 0.65);
    final dotColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFE9C46A);

    // Top-Left corner flourish
    _drawCornerFlourish(canvas, const Offset(8, 8), 1.0, 1.0, stemColor, leafColor, budColor, dotColor);
    // Top-Right corner flourish
    _drawCornerFlourish(canvas, Offset(size.width - 8, 8), -1.0, 1.0, stemColor, leafColor, budColor, dotColor);
    // Bottom-Left corner flourish
    _drawCornerFlourish(canvas, Offset(8, size.height - 8), 1.0, -1.0, stemColor, leafColor, budColor, dotColor);
    // Bottom-Right corner flourish
    _drawCornerFlourish(canvas, Offset(size.width - 8, size.height - 8), -1.0, -1.0, stemColor, leafColor, budColor, dotColor);
  }

  void _drawCornerFlourish(
    Canvas canvas,
    Offset origin,
    double scaleX,
    double scaleY,
    Color stemColor,
    Color leafColor,
    Color budColor,
    Color dotColor,
  ) {
    final stemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;

    final budPaint = Paint()
      ..color = budColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Curved twig stem
    final stem = Path();
    stem.moveTo(origin.dx + (scaleX * 4), origin.dy + (scaleY * 34));
    stem.quadraticBezierTo(
      origin.dx + (scaleX * 14),
      origin.dy + (scaleY * 18),
      origin.dx + (scaleX * 36),
      origin.dy + (scaleY * 6),
    );
    canvas.drawPath(stem, stemPaint);

    // Minor side branch
    final branch = Path();
    branch.moveTo(origin.dx + (scaleX * 16), origin.dy + (scaleY * 20));
    branch.quadraticBezierTo(
      origin.dx + (scaleX * 26),
      origin.dy + (scaleY * 25),
      origin.dx + (scaleX * 36),
      origin.dy + (scaleY * 23),
    );
    canvas.drawPath(branch, stemPaint);

    // Sage olive leaves
    _drawLeaf(canvas, origin.dx + (scaleX * 10), origin.dy + (scaleY * 28), 11 * scaleX, -8 * scaleY, leafPaint);
    _drawLeaf(canvas, origin.dx + (scaleX * 22), origin.dy + (scaleY * 15), 11 * scaleX, -7 * scaleY, leafPaint);
    _drawLeaf(canvas, origin.dx + (scaleX * 24), origin.dy + (scaleY * 22), 10 * scaleX, 8 * scaleY, leafPaint);

    // Peach tulip flower buds
    _drawBud(canvas, origin.dx + (scaleX * 38), origin.dy + (scaleY * 5), 7.0, 4.5, scaleX, scaleY, budPaint);
    _drawBud(canvas, origin.dx + (scaleX * 38), origin.dy + (scaleY * 22), 6.0, 4.0, scaleX, scaleY, budPaint);
    _drawBud(canvas, origin.dx + (scaleX * 5), origin.dy + (scaleY * 36), 5.5, 3.8, scaleX, scaleY, budPaint);

    // Warm golden pollen dots
    canvas.drawCircle(Offset(origin.dx + (scaleX * 18), origin.dy + (scaleY * 5)), 2.0, dotPaint);
    canvas.drawCircle(Offset(origin.dx + (scaleX * 44), origin.dy + (scaleY * 13)), 1.8, dotPaint);
    canvas.drawCircle(Offset(origin.dx + (scaleX * 3), origin.dy + (scaleY * 22)), 1.6, dotPaint);
  }

  void _drawLeaf(Canvas canvas, double x, double y, double dx, double dy, Paint paint) {
    final leaf = Path();
    leaf.moveTo(x, y);
    leaf.quadraticBezierTo(x + dx * 0.5 - dy * 0.3, y + dy * 0.5 + dx * 0.3, x + dx, y + dy);
    leaf.quadraticBezierTo(x + dx * 0.5 + dy * 0.3, y + dy * 0.5 - dx * 0.3, x, y);
    canvas.drawPath(leaf, paint);
  }

  void _drawBud(Canvas canvas, double x, double y, double r1, double r2, double sx, double sy, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(sx, sy);
    final bud = Path();
    bud.moveTo(0, -r1);
    bud.quadraticBezierTo(r2, -r1 * 0.3, r2 * 0.7, r1);
    bud.quadraticBezierTo(0, r1 * 0.8, -r2 * 0.7, r1);
    bud.quadraticBezierTo(-r2, -r1 * 0.3, 0, -r1);
    canvas.drawPath(bud, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoalModalBotanicalPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Flanking botanical branch directly on the left or right of the Goal Stepper Capsule
class _CapsuleFlankBotanicalPainter extends CustomPainter {
  final bool isLeft;
  final bool isDark;

  const _CapsuleFlankBotanicalPainter({required this.isLeft, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final leafColor = isDark ? const Color(0xFF7A9A60) : const Color(0xFF8A9A5B);
    final budColor = isDark ? const Color(0xFFF4A261) : const Color(0xFFEA8D74);
    final stemColor = isDark
        ? const Color(0xFF8D6E63).withValues(alpha: 0.65)
        : const Color(0xFFB58A63).withValues(alpha: 0.65);
    final dotColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFE9C46A);

    final stemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()..color = leafColor;
    final budPaint = Paint()..color = budColor;
    final dotPaint = Paint()..color = dotColor.withValues(alpha: 0.75);

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1.0, 1.0);
    }

    // Stem hugging capsule curve
    final stem = Path();
    stem.moveTo(size.width - 2, 6);
    stem.quadraticBezierTo(size.width - 7, size.height * 0.5, size.width - 2, size.height - 6);
    canvas.drawPath(stem, stemPaint);

    // Leaves branching out
    _drawLeaf(canvas, size.width - 5, 12, -9, -6, leafPaint);
    _drawLeaf(canvas, size.width - 7, size.height * 0.5, -10, 2, leafPaint);
    _drawLeaf(canvas, size.width - 5, size.height - 12, -9, 6, leafPaint);

    // Buds
    _drawBud(canvas, size.width - 15, 8, 5.0, 3.2, budPaint);
    _drawBud(canvas, size.width - 14, size.height - 8, 4.8, 3.0, budPaint);

    // Pollen dots
    canvas.drawCircle(Offset(size.width - 18, size.height * 0.35), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 17, size.height * 0.65), 1.4, dotPaint);

    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, double x, double y, double dx, double dy, Paint paint) {
    final leaf = Path();
    leaf.moveTo(x, y);
    leaf.quadraticBezierTo(x + dx * 0.5 - dy * 0.3, y + dy * 0.5 + dx * 0.3, x + dx, y + dy);
    leaf.quadraticBezierTo(x + dx * 0.5 + dy * 0.3, y + dy * 0.5 - dx * 0.3, x, y);
    canvas.drawPath(leaf, paint);
  }

  void _drawBud(Canvas canvas, double x, double y, double r1, double r2, Paint paint) {
    final bud = Path();
    bud.moveTo(x, y - r1);
    bud.quadraticBezierTo(x + r2, y - r1 * 0.3, x + r2 * 0.7, y + r1);
    bud.quadraticBezierTo(x, y + r1 * 0.8, x - r2 * 0.7, y + r1);
    bud.quadraticBezierTo(x - r2, y - r1 * 0.3, x, y - r1);
    canvas.drawPath(bud, paint);
  }

  @override
  bool shouldRepaint(covariant _CapsuleFlankBotanicalPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft || oldDelegate.isDark != isDark;
}

