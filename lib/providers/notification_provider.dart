import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_settings_repository.dart';
import '../services/notification_service.dart';

export '../repositories/user_settings_repository.dart'
    show userSettingsRepositoryProvider, UserSettingsRepository, UserSettingsRepositoryImpl;

class NotificationSettings {
  final bool remindersEnabled;
  final TimeOfDay reminderTime;
  final bool streakAlertsEnabled;

  const NotificationSettings({
    this.remindersEnabled = true,
    this.reminderTime = const TimeOfDay(hour: 20, minute: 0), // 8:00 PM
    this.streakAlertsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? remindersEnabled,
    TimeOfDay? reminderTime,
    bool? streakAlertsEnabled,
  }) {
    return NotificationSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      streakAlertsEnabled: streakAlertsEnabled ?? this.streakAlertsEnabled,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettings> {
  final UserSettingsRepository _repository;

  NotificationNotifier([UserSettingsRepository? repository])
      : _repository = repository ?? UserSettingsRepositoryImpl(),
        super(const NotificationSettings()) {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final prefs = await _repository.loadNotificationPreferences();
    final remindersEnabled = prefs['remindersEnabled'] as bool? ?? state.remindersEnabled;
    final hour = prefs['reminderHour'] as int?;
    final minute = prefs['reminderMinute'] as int?;
    final streakAlerts = prefs['streakAlertsEnabled'] as bool? ?? state.streakAlertsEnabled;
    final time = (hour != null && minute != null)
        ? TimeOfDay(hour: hour, minute: minute)
        : state.reminderTime;

    state = NotificationSettings(
      remindersEnabled: remindersEnabled,
      reminderTime: time,
      streakAlertsEnabled: streakAlerts,
    );

    await _repository.initializeNotifications();
    if (state.remindersEnabled) {
      _rescheduleDailyReminder();
    }
  }

  void toggleReminders(bool enabled) {
    state = state.copyWith(remindersEnabled: enabled);
    _repository.persistNotificationPreferences(remindersEnabled: enabled);
    if (enabled) {
      _rescheduleDailyReminder();
    } else {
      _repository.cancelDailyReminder();
    }
  }

  void setReminderTime(TimeOfDay time) {
    state = state.copyWith(reminderTime: time);
    _repository.persistNotificationPreferences(reminderTime: time);
    if (state.remindersEnabled) {
      _rescheduleDailyReminder();
    }
  }

  void toggleStreakAlerts(bool enabled) {
    state = state.copyWith(streakAlertsEnabled: enabled);
    _repository.persistNotificationPreferences(streakAlertsEnabled: enabled);
  }

  void sendTestNotification() {
    final dialogue = NotificationService.getRandomRomanticDialogue();
    _repository.showInstantNotification(
      title: dialogue['title']!,
      body: dialogue['body']!,
    );
  }

  Future<void> resetNotifications() async {
    state = const NotificationSettings();
    await _repository.cancelAllNotifications();
    await _repository.persistNotificationPreferences(
      remindersEnabled: true,
      streakAlertsEnabled: true,
    );
  }

  void _rescheduleDailyReminder() {
    final dialogue = NotificationService.getRandomRomanticDialogue();
    _repository.scheduleDailyReminder(
      time: state.reminderTime,
      title: dialogue['title']!,
      body: dialogue['body']!,
    );
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationSettings>((ref) {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return NotificationNotifier(repository);
});
