import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calendar_book_entry.dart';
import '../providers/reading_calendar_provider.dart';
import '../theme/reading_app_colors.dart';

/// Reusable widget rendering the "DUAL READING LOGS / DAILY CHRONICLES" section
/// modeled directly after the "Figures of Destiny" character codex pattern.
class CalendarBookEntriesSection extends ConsumerStatefulWidget {
  final DateTime date;
  final List<CalendarBookEntry>? initialEntries;
  final bool showHeader;
  final String sectionTitle;
  final String sectionSubtitle;
  final void Function(CalendarBookEntry entry)? onEntryAdded;
  final void Function(CalendarBookEntry entry)? onEntryUpdated;
  final void Function(String entryId)? onEntryDeleted;

  const CalendarBookEntriesSection({
    super.key,
    required this.date,
    this.initialEntries,
    this.showHeader = true,
    this.sectionTitle = 'DUAL READING LOGS',
    this.sectionSubtitle = 'The tomes and narratives accompanying this day',
    this.onEntryAdded,
    this.onEntryUpdated,
    this.onEntryDeleted,
  });

  @override
  ConsumerState<CalendarBookEntriesSection> createState() =>
      _CalendarBookEntriesSectionState();
}

class _CalendarBookEntriesSectionState
    extends ConsumerState<CalendarBookEntriesSection> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgSubtle = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF9F5EC);
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2D9C8);
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final accentGold = colors.streakAmber;
    final accentParchment = colors.quoteGold;

    // Reactively watch entries from Riverpod provider with fallback to initialEntries
    final providerEntries = ref.watch(calendarBookEntriesForDateProvider(widget.date));
    final entries = providerEntries.isNotEmpty
        ? providerEntries
        : (widget.initialEntries ?? []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. SECTION HEADER
          if (widget.showHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_edu_rounded,
                  size: 18,
                  color: accentGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sectionTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: accentGold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.sectionSubtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Warm-toned outline pill button: + Add Book Entry
                InkWell(
                  onTap: () => _showBookEntryDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: accentGold),
                        const SizedBox(width: 4),
                        Text(
                          'Add Book Entry',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 2. EMPTY STATE OR LIST OF INDIVIDUAL BOOK ENTRY CARDS
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBgSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 24,
                    color: textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reading chronicles logged for this day',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Book Entry" above to attach tomes, audiobooks, or notes.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...entries.map(
              (entry) => _buildBookEntryCard(
                entry,
                cardBgSubtle: cardBgSubtle,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                accentGold: accentGold,
                accentParchment: accentParchment,
                onEdit: () => _showBookEntryDialog(context, entry: entry),
                onDelete: () => _confirmDeleteEntry(context, entry),
              ),
            ),
        ],
      ),
    );
  }

  /// Individual Book Entry Card modeled after _buildCharacterCard in story_codex_view
  Widget _buildBookEntryCard(
    CalendarBookEntry entry, {
    required Color cardBgSubtle,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentGold,
    required Color accentParchment,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final statusColor = _getStatusColor(entry.readingStatusTag, accentGold);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Book Title, Status Pill Badge, and Action Icons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Title in bold serif font
                    Text(
                      entry.bookTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    // Tinted category pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        entry.readingStatusTag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Icons: edit and close
              if (onEdit != null) ...[
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (onDelete != null)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),

          // Second Row: Secondary muted metadata badge
          if (entry.archetypeOrRoleTag.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: textSecondary.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                entry.archetypeOrRoleTag,
                style: TextStyle(
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ),
          ],

          // Body Text: Clean multi-line notes / reflections
          if (entry.entryNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.entryNotes,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String tag, Color fallback) {
    final lower = tag.toLowerCase();
    if (lower.contains('shelved') || lower.contains('dnf') || lower.contains('abandoned')) {
      return Colors.deepOrangeAccent;
    }
    if (lower.contains('finished') || lower.contains('completed')) {
      return Colors.green;
    }
    if (lower.contains('companion') || lower.contains('dual')) {
      return Colors.teal;
    }
    if (lower.contains('audio')) {
      return Colors.purpleAccent;
    }
    return fallback;
  }

  void _confirmDeleteEntry(BuildContext context, CalendarBookEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.appColors;
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderSubtle),
          ),
          title: Text(
            'Remove Entry?',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${entry.bookTitle}" from this calendar chronicle?',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(readingCalendarNotifierProvider.notifier)
                    .removeBookEntry(widget.date, entry.id);
                widget.onEntryDeleted?.call(entry.id);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showBookEntryDialog(BuildContext context, {CalendarBookEntry? entry}) {
    final titleController = TextEditingController(text: entry?.bookTitle ?? '');
    final notesController = TextEditingController(text: entry?.entryNotes ?? '');
    String status = entry?.readingStatusTag ?? 'Active Read';
    String role = entry?.archetypeOrRoleTag ?? 'Primary Focus';

    final statuses = [
      'Active Read',
      'Dual Companion',
      'Audiobook Companion',
      'Physical Copy',
      'Shelved / DNF',
      'Finished',
    ];

    final roles = [
      'Primary Focus',
      'Companion Tome',
      'Chapter Milestone',
      'Night Reading',
      'Study & Annotation',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final colors = context.appColors;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final inputBg = isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF9F5EC);

            return AlertDialog(
              backgroundColor: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.borderSubtle),
              ),
              title: Row(
                children: [
                  Icon(
                    entry == null ? Icons.add_circle_outline : Icons.edit_note,
                    color: colors.streakAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry == null ? 'Add Book Chronicle' : 'Edit Book Chronicle',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Title Input
                      Text(
                        'BOOK TITLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: colors.streakAmber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g., God of Malice',
                          hintStyle: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.streakAmber),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Selector
                      Text(
                        'STATUS TAG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: colors.streakAmber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: statuses.map((s) {
                          final isSelected = status == s;
                          return ChoiceChip(
                            label: Text(s),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => status = s);
                              }
                            },
                            labelStyle: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : colors.textSecondary,
                            ),
                            selectedColor: colors.streakAmber,
                            backgroundColor: inputBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.streakAmber
                                    : colors.borderSubtle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Role/Format Selector
                      Text(
                        'ROLE / FORMAT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: colors.quoteGold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: roles.map((r) {
                          final isSelected = role == r;
                          return ChoiceChip(
                            label: Text(r),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => role = r);
                              }
                            },
                            labelStyle: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : colors.textSecondary,
                            ),
                            selectedColor: colors.quoteGold,
                            backgroundColor: inputBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.quoteGold
                                    : colors.borderSubtle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Notes Input
                      Text(
                        'ENTRY NOTES & REFLECTIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: TextStyle(color: colors.textPrimary, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Add reading thoughts, page milestones, or reflections...',
                          hintStyle: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.streakAmber),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.pop(ctx);
                    if (entry == null) {
                      final newEntry = CalendarBookEntry(
                        bookTitle: title,
                        readingStatusTag: status,
                        archetypeOrRoleTag: role,
                        entryNotes: notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      ref
                          .read(readingCalendarNotifierProvider.notifier)
                          .addBookEntryToDate(widget.date, newEntry);
                      widget.onEntryAdded?.call(newEntry);
                    } else {
                      final updated = entry.copyWith(
                        bookTitle: title,
                        readingStatusTag: status,
                        archetypeOrRoleTag: role,
                        entryNotes: notesController.text.trim(),
                      );
                      ref
                          .read(readingCalendarNotifierProvider.notifier)
                          .updateBookEntry(widget.date, entry.id, updated);
                      widget.onEntryUpdated?.call(updated);
                    }
                  },
                  child: Text(
                    entry == null ? 'Add' : 'Save',
                    style: TextStyle(
                      color: colors.streakAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
