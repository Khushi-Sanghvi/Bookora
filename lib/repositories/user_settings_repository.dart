import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/user_profile.dart';
import '../services/backup_service.dart';
import '../services/csv_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Single source of truth repository for User Settings, Profile, Goals, Backups, and CSV data.
abstract class UserSettingsRepository {
  // User Profile
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);

  // Reading Goal
  Future<int> getReadingGoal();
  Future<void> setReadingGoal(int goal);
  Future<void> resetReadingGoal();

  // Backup & Restore
  Future<String> createBackupJson({Map<String, dynamic>? profileData});
  Future<int> restoreBackupJson(String jsonString);

  // CSV Import & Export
  String exportBooksToCsv(List<Book> books);
  List<Book> parseCsv(
    String csvContent, {
    String? titleCol,
    String? authorCol,
    String? genreCol,
    String? pagesCol,
  });

  // Notifications
  Future<void> initializeNotifications();
  Future<Map<String, dynamic>> loadNotificationPreferences();
  Future<void> persistNotificationPreferences({
    bool? remindersEnabled,
    TimeOfDay? reminderTime,
    bool? streakAlertsEnabled,
  });
  void scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  });
  void cancelDailyReminder();
  Future<void> cancelAllNotifications();
  void showInstantNotification({
    required String title,
    required String body,
  });
}

/// Concrete implementation coordinating local database, shared preferences, backup, and CSV routines.
class UserSettingsRepositoryImpl implements UserSettingsRepository {
  static const String _goalKey = 'yearly_reading_goal_target';
  static const String _keyRemindersEnabled = 'reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyStreakAlerts = 'streak_alerts_enabled';

  final DatabaseService _db;
  final BackupService _backup;
  final NotificationService _notification;

  UserSettingsRepositoryImpl({
    DatabaseService? databaseService,
    BackupService? backupService,
    NotificationService? notificationService,
  })  : _db = databaseService ?? DatabaseService(),
        _backup = backupService ?? BackupService(),
        _notification = notificationService ?? NotificationService();

  // User Profile
  @override
  Future<UserProfile?> getUserProfile() => _db.getUserProfile();

  @override
  Future<void> saveUserProfile(UserProfile profile) => _db.saveUserProfile(profile);

  // Reading Goal
  @override
  Future<int> getReadingGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_goalKey) ?? 25;
    } catch (_) {
      return 25;
    }
  }

  @override
  Future<void> setReadingGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalKey, goal);
    } catch (_) {}
  }

  @override
  Future<void> resetReadingGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_goalKey);
    } catch (_) {}
  }

  // Backup & Restore
  @override
  Future<String> createBackupJson({Map<String, dynamic>? profileData}) {
    return _backup.createBackupJson(profileData: profileData);
  }

  @override
  Future<int> restoreBackupJson(String jsonString) {
    return _backup.restoreBackupJson(jsonString);
  }

  // CSV
  @override
  String exportBooksToCsv(List<Book> books) {
    return CsvService.exportBooksToCsv(books);
  }

  @override
  List<Book> parseCsv(
    String csvContent, {
    String? titleCol,
    String? authorCol,
    String? genreCol,
    String? pagesCol,
  }) {
    return CsvService.parseCsv(
      csvContent,
      titleCol: titleCol,
      authorCol: authorCol,
      genreCol: genreCol,
      pagesCol: pagesCol,
    );
  }

  // Notifications
  @override
  Future<void> initializeNotifications() => _notification.initialize();

  @override
  Future<Map<String, dynamic>> loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'remindersEnabled': prefs.getBool(_keyRemindersEnabled) ?? true,
        'reminderHour': prefs.getInt(_keyReminderHour),
        'reminderMinute': prefs.getInt(_keyReminderMinute),
        'streakAlertsEnabled': prefs.getBool(_keyStreakAlerts) ?? true,
      };
    } catch (_) {
      return {
        'remindersEnabled': true,
        'reminderHour': 20,
        'reminderMinute': 0,
        'streakAlertsEnabled': true,
      };
    }
  }

  @override
  Future<void> persistNotificationPreferences({
    bool? remindersEnabled,
    TimeOfDay? reminderTime,
    bool? streakAlertsEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (remindersEnabled != null) {
        await prefs.setBool(_keyRemindersEnabled, remindersEnabled);
      }
      if (reminderTime != null) {
        await prefs.setInt(_keyReminderHour, reminderTime.hour);
        await prefs.setInt(_keyReminderMinute, reminderTime.minute);
      }
      if (streakAlertsEnabled != null) {
        await prefs.setBool(_keyStreakAlerts, streakAlertsEnabled);
      }
    } catch (_) {}
  }

  @override
  void scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) {
    _notification.scheduleDailyReminder(
      time: time,
      title: title,
      body: body,
    );
  }

  @override
  void cancelDailyReminder() => _notification.cancelDailyReminder();

  @override
  Future<void> cancelAllNotifications() => _notification.cancelAllNotifications();

  @override
  void showInstantNotification({
    required String title,
    required String body,
  }) {
    _notification.showInstantNotification(title: title, body: body);
  }
}

/// Riverpod provider for UserSettingsRepository
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return UserSettingsRepositoryImpl(
    databaseService: DatabaseService(),
    backupService: BackupService(),
    notificationService: NotificationService(),
  );
});
