import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // --- Convincing Romantic & Spicy Bookish Notification Dialogue Vault ---
  static final List<Map<String, String>> romanticDialogues = [
    {
      'title': '💋 Your Fictional Man is Waiting...',
      'body': 'He\'s waiting for you on the next page. Don\'t keep him waiting tonight 🖤',
    },
    {
      'title': '🔥 Just One More Chapter?',
      'body': 'You know you can\'t resist the tension. Open Bookora and see what happens next 🌶️',
    },
    {
      'title': '✨ A Bookish Date Night',
      'body': 'You, a cozy blanket, and an irresistible plot twist. Let\'s read a few pages 💕',
    },
    {
      'title': '🖤 High Spice & Dangerous Obsession',
      'body': 'The heat is rising in your current read! Open Bookora and dive back into the drama 🔥',
    },
    {
      'title': '📖 "He\'d burn the world for her..."',
      'body': '...but he can\'t read this chapter for you! Steal 15 minutes of reading passion tonight 🕯️',
    },
    {
      'title': '⚡ Enemies to Lovers? Fake Dating?',
      'body': 'Your next favorite trope is waiting for you! Open Bookora and keep your streak alive 🔥',
    },
    {
      'title': '💕 Your Bookmark is Feeling Lonely...',
      'body': 'Your fictional lovers miss you! Turn a few pages before calling it a night 🌙',
    },
    {
      'title': '🌶️ Warning: Scorching Chemistry Ahead!',
      'body': 'Things are getting spicy in your library... Don\'t leave your story hanging on a cliffhanger 💋',
    },
  ];

  static Map<String, String> getRandomRomanticDialogue() {
    final rand = Random();
    return romanticDialogues[rand.nextInt(romanticDialogues.length)];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // --- 1. Instant Test / Trigger Notification ---
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'bookora_reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reading session reminders and streak alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  // --- 2. Schedule Daily Reading Reminder Notification ---
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancelDailyReminder();

    const androidDetails = AndroidNotificationDetails(
      'bookora_reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reading session reminders and streak alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        101, // Channel ID for daily reminder
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  // --- 3. Cancel Daily Reminder ---
  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(101);
  }

  // --- 4. Cancel All Notifications ---
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
