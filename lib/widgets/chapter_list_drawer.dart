import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audiobook_model.dart';
import '../providers/audiobook_provider.dart';
import '../theme/reading_app_colors.dart';

class ChapterListDrawer extends ConsumerWidget {
  const ChapterListDrawer({super.key});

  static Future<void> show(BuildContext context) {
    final colors = context.appColors;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: ChapterListDrawer(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final playerState = ref.watch(audiobookPlayerProvider);
    final ab = playerState.currentAudiobook;

    if (ab == null || ab.chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text('No Chapters Available', style: TextStyle(color: colors.textSecondary)),
        ),
      );
    }

    final activeChapter = playerState.activeChapter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle Bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded, color: colors.streakAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chapters & Timestamps',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Chapters
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ab.chapters.length,
          separatorBuilder: (context, index) => Divider(color: colors.borderSubtle, height: 1),
          itemBuilder: (context, index) {
            final chapter = ab.chapters[index];
            final isCurrent = activeChapter?.chapterIndex == chapter.chapterIndex;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colors.streakAmber.withValues(alpha: 0.2)
                      : colors.cardBgSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? colors.streakAmber : colors.borderSubtle,
                  ),
                ),
                child: Icon(
                  isCurrent ? Icons.graphic_eq : Icons.headphones_outlined,
                  size: 16,
                  color: isCurrent ? colors.streakAmber : colors.textSecondary,
                ),
              ),
              title: Text(
                chapter.title,
                style: TextStyle(
                  color: isCurrent ? colors.quoteGold : colors.textPrimary,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Start: ${AudioChapter.formatDuration(chapter.startTimestamp)} • Length: ${AudioChapter.formatDuration(chapter.duration)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
              trailing: isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.streakAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Playing',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Icon(Icons.play_arrow_rounded, color: colors.textSecondary, size: 18),
              onTap: () {
                ref.read(audiobookPlayerProvider.notifier).seekToChapter(chapter);
                Navigator.pop(context);
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
