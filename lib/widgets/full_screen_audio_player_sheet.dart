import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audiobook_model.dart';
import '../providers/audiobook_provider.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';
import 'chapter_list_drawer.dart';

class FullScreenAudioPlayerSheet extends ConsumerWidget {
  const FullScreenAudioPlayerSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = context.appColors;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: const FullScreenAudioPlayerSheet(),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    return AudioChapter.formatDuration(d);
  }

  String _formatRemaining(Duration pos, Duration total) {
    final rem = total - pos;
    if (rem.isNegative) return '-00:00';
    return '-${_formatDuration(rem)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final playerState = ref.watch(audiobookPlayerProvider);
    final notifier = ref.read(audiobookPlayerProvider.notifier);
    final ab = playerState.currentAudiobook;

    if (ab == null) {
      return Center(
        child: Text('No Audiobook Loaded', style: TextStyle(color: colors.textSecondary)),
      );
    }

    final activeChapter = playerState.activeChapter;
    final pos = playerState.currentPosition;
    final total = playerState.totalDuration;

    // Calculate progress within active chapter
    String chapterProgressText = '';
    if (activeChapter != null) {
      final chPos = pos - activeChapter.startTimestamp;
      chapterProgressText = '${activeChapter.title} • ${_formatDuration(chPos)} / ${_formatDuration(activeChapter.duration)}';
    } else {
      chapterProgressText = 'Playing Audiobook';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Top Handle & Header Bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down, size: 28, color: colors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                children: [
                  Text(
                    'PLAYING AUDIOBOOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: colors.streakAmber,
                    ),
                  ),
                  Text(
                    'Bookora Audio',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.format_list_bulleted_rounded, color: colors.textPrimary, size: 22),
                onPressed: () => ChapterListDrawer.show(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 3D Book Cover Card with Soft Glow
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.streakAmber.withValues(alpha: isLight ? 0.2 : 0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: BookCoverImage(
                coverUrl: ab.coverUrl,
                title: ab.title,
                author: ab.author,
                width: 180,
                height: 250,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Book Title & Author
          Text(
            ab.title,
            style: GoogleFonts.crimsonPro(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'by ${ab.author}',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // 4. Active Chapter Sub-Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.cardBgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.graphic_eq, color: colors.streakAmber, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    chapterProgressText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.quoteGold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Interactive Scrubber Slider Bar & Formatted Time
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colors.streakAmber,
                  inactiveTrackColor: colors.borderSubtle,
                  thumbColor: colors.streakAmber,
                  trackHeight: 5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: pos.inMilliseconds.toDouble().clamp(0.0, total.inMilliseconds.toDouble()),
                  min: 0.0,
                  max: total.inMilliseconds.toDouble() > 0 ? total.inMilliseconds.toDouble() : 1.0,
                  onChanged: (val) {
                    notifier.seek(Duration(milliseconds: val.round()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(pos),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatRemaining(pos, total),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6. Playback Controls Row (Skip -15s, Play/Pause, Skip +30s)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Playback Speed Switcher
              GestureDetector(
                onTap: () {
                  final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
                  final currentIdx = speeds.indexOf(playerState.playbackSpeed);
                  final nextIdx = (currentIdx + 1) % speeds.length;
                  notifier.setSpeed(speeds[nextIdx]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.cardBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    '${playerState.playbackSpeed}x',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.streakAmber),
                  ),
                ),
              ),

              // Skip Backward 15s
              IconButton(
                icon: Icon(Icons.replay_10_rounded, size: 36, color: colors.textPrimary),
                onPressed: notifier.skipBackward15,
              ),

              // Play / Pause Toggle Button
              GestureDetector(
                onTap: notifier.togglePlayPause,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.streakAmber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.streakAmber.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 36,
                    color: Colors.black,
                  ),
                ),
              ),

              // Skip Forward 30s
              IconButton(
                icon: Icon(Icons.forward_30_rounded, size: 36, color: colors.textPrimary),
                onPressed: notifier.skipForward30,
              ),

              // Chapter Drawer Toggle Button
              IconButton(
                icon: Icon(Icons.format_list_bulleted_rounded, size: 22, color: colors.textSecondary),
                onPressed: () => ChapterListDrawer.show(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
