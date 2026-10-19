import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/models/book.dart';
import 'package:between_world/models/bookshelf_config.dart';
import 'package:between_world/models/enums.dart';
import 'package:between_world/models/journal_entry.dart';
import 'package:between_world/providers/bookshelf_config_provider.dart';
import 'package:between_world/providers/profile_provider.dart';
import 'package:between_world/providers/streak_provider.dart';
import 'package:between_world/providers/theme_provider.dart';

void main() {
  group('BookshelfConfigNotifier Tests', () {
    test('initial state is default BookshelfConfig', () {
      final container = ProviderContainer();
      final config = container.read(bookshelfConfigProvider);

      expect(config.woodFinish, BookshelfWoodFinish.mahogany);
      expect(config.vineDensity, VineDensity.lush);
      expect(config.candlesEnabled, isTrue);
      expect(config.showTrinkets, isTrue);
    });

    test('setWoodFinish updates state', () {
      final container = ProviderContainer();
      final notifier = container.read(bookshelfConfigProvider.notifier);

      notifier.setWoodFinish(BookshelfWoodFinish.weatheredOak);
      final updated = container.read(bookshelfConfigProvider);

      expect(updated.woodFinish, BookshelfWoodFinish.weatheredOak);
    });

    test('setVineDensity updates vine density', () {
      final container = ProviderContainer();
      final notifier = container.read(bookshelfConfigProvider.notifier);

      notifier.setVineDensity(VineDensity.none);
      final updated = container.read(bookshelfConfigProvider);

      expect(updated.vineDensity, VineDensity.none);
    });

    test('toggleCandles and toggleTrinkets', () {
      final container = ProviderContainer();
      final notifier = container.read(bookshelfConfigProvider.notifier);

      notifier.toggleCandles(false);
      notifier.toggleTrinkets(false);
      final updated = container.read(bookshelfConfigProvider);

      expect(updated.candlesEnabled, isFalse);
      expect(updated.showTrinkets, isFalse);
    });
  });

  group('UserProfileNotifier Tests', () {
    test('initial state and initials calculation', () {
      final container = ProviderContainer();
      final profile = container.read(profileProvider);

      expect(profile.name, 'Avid Reader');
      expect(profile.username, '@booklover');
      expect(profile.initials, 'AR');
    });

    test('updateProfile updates name, cleaned username, and bio', () {
      final container = ProviderContainer();
      final notifier = container.read(profileProvider.notifier);

      notifier.updateProfile(
        name: 'Eleanor Vance',
        username: '@eleanor_books',
        bio: 'Avid gothic fiction reader',
      );

      final updated = container.read(profileProvider);
      expect(updated.name, 'Eleanor Vance');
      expect(updated.username, '@eleanor_books');
      expect(updated.bio, 'Avid gothic fiction reader');
      expect(updated.initials, 'EV');
    });
  });

  group('ThemeNotifier Tests', () {
    test('initial theme is ThemeMode.light', () {
      final container = ProviderContainer();
      final mode = container.read(themeModeProvider);

      expect(mode, ThemeMode.light);
    });

    test('toggleTheme switches between dark and light', () {
      final container = ProviderContainer();
      final notifier = container.read(themeModeProvider.notifier);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('setThemeMode updates mode directly', () {
      final container = ProviderContainer();
      final notifier = container.read(themeModeProvider.notifier);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('Streak Calculation Tests', () {
    test('calculateStreak with empty books returns 0 streak', () {
      final streak = calculateStreak([]);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.readToday, isFalse);
    });

    test('calculateStreak with book read today returns streak >= 1', () {
      final now = DateTime.now();
      final book = Book(
        id: '1',
        title: 'Active Book',
        author: 'Author',
        description: 'Desc',
        coverUrl: '',
        totalPages: 300,
        currentPage: 50,
        status: ReadingStatus.currentlyReading,
        startDate: now,
        journalEntries: [
          JournalEntry(
            id: 'j1',
            date: now,
            pagesRead: 20,
          ),
        ],
      );

      final streak = calculateStreak([book]);
      expect(streak.readToday, isTrue);
      expect(streak.currentStreak, greaterThanOrEqualTo(1));
    });
  });
}
