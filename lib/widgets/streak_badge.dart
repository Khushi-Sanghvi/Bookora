import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/streak_provider.dart';
import '../theme/reading_app_colors.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showStreakDetails(context, streak),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: streak.readToday
              ? colors.streakAmber.withValues(alpha: 0.2)
              : colors.cardBgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: streak.readToday
                ? colors.streakAmber
                : colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 18,
              color: streak.readToday ? colors.streakAmber : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${streak.currentStreak}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: streak.readToday ? colors.streakAmber : colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDetails(BuildContext context, StreakInfo streak) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  Icons.local_fire_department,
                  size: 64,
                  color: streak.readToday ? colors.streakAmber : colors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  '${streak.currentStreak} Day Reading Streak!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.quoteGold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streak.readToday
                      ? 'Great job! You kept your streak alive today.'
                      : 'Log pages read today to keep your streak going!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StreakStatTile(
                      label: 'Current Streak',
                      value: '${streak.currentStreak} Days',
                      icon: Icons.bolt,
                      color: colors.streakAmber,
                      colors: colors,
                    ),
                    _StreakStatTile(
                      label: 'Longest Streak',
                      value: '${streak.longestStreak} Days',
                      icon: Icons.emoji_events,
                      color: Colors.amber,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StreakStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ReadingAppColors colors;

  const _StreakStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.cardBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
