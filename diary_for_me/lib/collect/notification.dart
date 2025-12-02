import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';

import 'package:diary_for_me/DB/db_manager.dart';
import 'package:diary_for_me/DB/background_log/background_log_model.dart';

/// 백그라운드 알림 수신 콜백
@pragma('vm:entry-point')
Future<void> backgroundCallback(NotificationEvent evt) async {
  print('[BG] callback: ${evt.packageName}');
  DartPluginRegistrant.ensureInitialized();

  try {
    final isar = await DB().instance;
    final log = _eventToLog(evt);

    await isar.writeTxn(() async {
      await isar.appNotificationLogs.put(log);
    });
    debugPrint('[BG] Saved to Isar: ${log.text}');


  } catch (e, st) {
    print('error in background callback: $e\n$st');
  }
}

/// NotificationEvent → AppNotificationLog 변환
AppNotificationLog _eventToLog(NotificationEvent evt) {
  try {
    final dynamic e = evt;

    final String pkg = (e.packageName ?? 'unknown').toString();
    final String title = (e.title ?? '').toString();
    final String body = (e.text ?? e.content ?? '').toString();

    final String text = title.isNotEmpty
        ? (body.isNotEmpty ? '$title: $body' : title)
        : body;

    return AppNotificationLog(
      timestamp: DateTime.now(),
      appname: pkg,
      text: text,
    );
  } catch (_) {
    return AppNotificationLog(
      timestamp: DateTime.now(),
      appname: 'unknown',
      text: evt.toString(),
    );
  }
}
