import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/streak_provider.dart';
import '../theme/reading_app_colors.dart';

class BookoraSideBar extends ConsumerWidget {
  const BookoraSideBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final streak = ref.watch(streakProvider);

    return Drawer(
      backgroundColor: colors.cardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header with Reading Streak Flame
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: colors.cardBgSecondary,
                border: Border(bottom: BorderSide(color: colors.borderSubtle)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.streakAmber.withValues(alpha: 0.2),
                    child: Icon(Icons.auto_stories_rounded, color: colors.streakAmber, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bookora Reader',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 16, color: colors.streakAmber),
                            const SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak} Day Streak 🔥',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.quoteGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Navigation Items with Active Amber Pill Wash
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.explore_outlined,
                    label: 'Explore & Search',
                    isActive: false,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    label: 'My Library Shelves',
                    isActive: true,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    label: 'Reading Statistics',
                    isActive: false,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.bookmark_border_rounded,
                    label: 'Saved Quotes & Notes',
                    isActive: false,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Divider(color: Colors.white12),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Settings & Themes',
                    isActive: false,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    label: 'About Bookora',
                    isActive: false,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 3. Footer Edition Note
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.eco_rounded, size: 16, color: colors.accentSage),
                  const SizedBox(width: 8),
                  Text(
                    'Bookora Literary v1.0',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required ReadingAppColors colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive ? colors.streakAmber.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: colors.streakAmber.withValues(alpha: 0.4)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? colors.streakAmber : colors.textSecondary, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}
