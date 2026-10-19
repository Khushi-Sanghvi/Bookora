import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audiobook_model.dart';
import '../providers/audiobook_provider.dart';
import '../services/audiobook_audio_handler.dart';
import '../theme/reading_app_colors.dart';
import 'book_cover_image.dart';
import 'full_screen_audio_player_sheet.dart';

class MiniAudioPlayerWidget extends ConsumerWidget {
  const MiniAudioPlayerWidget({super.key});

  String _formatDuration(Duration d) {
    return AudioChapter.formatDuration(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAudioHandlerReady) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final playerState = ref.watch(audiobookPlayerProvider);
    final notifier = ref.read(audiobookPlayerProvider.notifier);
    final ab = playerState.currentAudiobook;

    if (!playerState.isMiniPlayerVisible || ab == null) {
      return const SizedBox.shrink();
    }

    final activeChapter = playerState.activeChapter;
    final pos = playerState.currentPosition;
    final rawProgress = playerState.progressPercentage;
    final progressPct = (rawProgress.isNaN || rawProgress.isInfinite) ? 0.0 : rawProgress.clamp(0.0, 1.0);

    String chapterText = activeChapter != null ? activeChapter.title : ab.title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.1) : Colors.black45,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linear Progress Bar Top Line
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 3,
              backgroundColor: colors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(colors.streakAmber),
            ),
          ),

          // Main Mini Player Bar Content
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: () => FullScreenAudioPlayerSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Mini Cover Image
                  BookCoverImage(
                    coverUrl: ab.coverUrl,
                    title: ab.title,
                    author: ab.author,
                    width: 38,
                    height: 48,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(width: 10),

                  // Title & Chapter Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ab.title,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(Icons.graphic_eq, color: colors.streakAmber, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$chapterText • ${_formatDuration(pos)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play / Pause Toggle Button
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: colors.streakAmber,
                      size: 32,
                    ),
                    onPressed: notifier.togglePlayPause,
                  ),

                  // Close Button
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 18),
                    onPressed: notifier.hideMiniPlayer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
