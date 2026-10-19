import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _keyThemeMode = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.light) {
    _loadPersistedTheme();
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_keyThemeMode);
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[modeIndex];
        _updateSystemOverlays(state);
      }
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _updateSystemOverlays(mode);
    _persistTheme(mode);
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }

  void _updateSystemOverlays(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? const Color(0xFF13161C) : const Color(0xFFFFFDF8),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
