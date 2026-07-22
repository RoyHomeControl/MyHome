import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/memo.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // Ignore and fall back to default timezone.
    }

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> rescheduleFromMemos(List<Memo> memos) async {
    await cancelAll();
    for (final memo in memos) {
      await scheduleMemoNotification(memo);
    }
  }

  Future<void> scheduleMemoNotification(Memo memo) async {
    if (memo.id == null || memo.dueAt == null) return;

    await cancelMemoNotification(memo);

    final now = DateTime.now();
    if (memo.dueAt!.isBefore(now)) return;

    final title = memo.title.trim().isNotEmpty ? memo.title : '메모 알림';
    final body = memo.content.trim().isNotEmpty ? memo.content : '알림 시간이 되었습니다.';

    final scheduledDate = tz.TZDateTime.from(memo.dueAt!, tz.local);

    await _plugin.zonedSchedule(
      notificationId(memo.id!),
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'memo_due_notifications',
          '메모 알림',
          channelDescription: '메모의 알림일이 되면 표시됩니다.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelMemoNotification(Memo memo) async {
    if (memo.id == null) return;
    await _plugin.cancel(notificationId(memo.id!));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int notificationId(String id) {
    return id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  }
}
