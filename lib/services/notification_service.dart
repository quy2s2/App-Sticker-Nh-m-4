import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/database/app_database.dart';
import '../data/database/reminder_database.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Nhắc nhở';
  static const String _channelDesc = 'Thông báo nhắc nhở';

  // ================= INIT =================
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
        InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onAction,
    );

    await _createAndroidChannel();

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // ✅ Android 13+ xin quyền notification
    await androidPlugin?.requestNotificationsPermission();

    // ✅ Android 12+ xin quyền exact alarm
    final canExact =
        await androidPlugin?.canScheduleExactNotifications();

    if (canExact == false) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  // ================= CREATE CHANNEL =================
  Future<void> _createAndroidChannel() async {
    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  // ================= HANDLE ACTION =================
  Future<void> _onAction(NotificationResponse response) async {
    final id = response.id;
    if (id == null) return;

    // Đánh dấu reminder đã được thông báo khi user nhận được notification
    await ReminderDatabase.instance.markAsNotified(id);

    if (response.actionId == 'dismiss') {
      await _plugin.cancel(id);
      return;
    }

    if (response.actionId == 'snooze') {
      await _handleSnooze(id);
    }
  }

  // ================= SCHEDULE =================
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required String stickerPath,
  }) async {
    // 🔴 tránh thời gian quá khứ
    final now = DateTime.now();
    final safeTime =
        dateTime.isBefore(now.add(const Duration(seconds: 5)))
            ? now.add(const Duration(seconds: 5))
            : dateTime;

    final hasImage =
        stickerPath.isNotEmpty && File(stickerPath).existsSync();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      styleInformation: hasImage
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(stickerPath),
              contentTitle: title,
              summaryText: body,
            )
          : null,
      actions: const [
        AndroidNotificationAction(
          'snooze',
          'Nhắc lại 5 phút',
        ),
        AndroidNotificationAction(
          'dismiss',
          'Tắt',
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(safeTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // KHÔNG đánh dấu ngay khi schedule
    // Sẽ đánh dấu khi:
    // 1. Notification được hiển thị (thông qua _onAction callback)
    // 2. Hoặc khi load reminders và kiểm tra thời gian đã qua

    print('✅ Đã đặt thông báo: $id – $safeTime');
  }

  // ================= SNOOZE =================
  Future<void> _handleSnooze(int oldId) async {
    final stickers = await AppDatabase.instance.getAllStickers();
    if (stickers.isEmpty) return;

    final random = Random();
    final nextSticker =
        stickers[random.nextInt(stickers.length)]['imagePath'] as String;

    final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await scheduleReminder(
      id: newId,
      title: 'Nhắc nhở',
      body: 'Nhắc lại sau 5 phút ⏰',
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
      stickerPath: nextSticker,
    );
  }

  // ================= CANCEL =================
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  // ================= TEST NGAY =================
  Future<void> testNow() async {
    await _plugin.show(
      999,
      'TEST',
      'Nếu thấy thông báo này là OK',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
