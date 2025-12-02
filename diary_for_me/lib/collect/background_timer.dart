import 'dart:async';
import 'dart:ui';

import 'package:diary_for_me/DB/service_status_manager.dart';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:diary_for_me/api_service/generate_timeline.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';

import '../DB/db_manager.dart';
import '../DB/background_log/background_log_model.dart';
import 'location_collector.dart';

const notificationChannelId = 'my_foreground';
const notificationId = 888;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  print('백그라운드 서비스 시작됨');

  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    await service.setForegroundNotificationInfo(
      title: 'MY FOREGROUND SERVICE',
      content: '서비스 초기화 중...',
    );
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> showNotification(String content) async {
    if (service is AndroidServiceInstance) {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        '나의 일기장',
        content,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'MY FOREGROUND SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true, // 지울 수 없음
            autoCancel: false, // 터치해도 안 사라짐
            showWhen: true,
          ),
        ),
      );

      service.setForegroundNotificationInfo(title: '나의 일기장', content: content);
    }
  }

  await showNotification('서비스가 시작되는 중입니다');

  final isar = await DB().instance;
  final statusManager = ServiceStatusManager();

  Future<AppServiceState> updatedState() async {
    final now = DateTime.now();

    if (now.hour >= 6 && now.hour < 21) {
      statusManager.updateServiceStatus(AppServiceState.collecting);
      return AppServiceState.collecting;
    } else {
      DateTime targetDate = (now.hour >= 21)
          ? DateTime(now.year, now.month, now.day)
          : DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 1));
      final latestTimeLine = await isar.timeLines
          .where()
          .sortByDateDesc()
          .findFirst();

      if (latestTimeLine != null) {
        if (latestTimeLine.date.year == targetDate.year &&
            latestTimeLine.date.month == targetDate.month &&
            latestTimeLine.date.day == targetDate.day) {
          statusManager.updateServiceStatus(AppServiceState.waiting);
          return AppServiceState.waiting;
        }
      } else {
        statusManager.updateServiceStatus(AppServiceState.processing);
        return AppServiceState.processing;
      }
    }

    return AppServiceState.waiting;
  }

  AppServiceState currentState = await updatedState();

  bool isAnalysisRunning = false;

  switch (currentState) {
    case AppServiceState.collecting:
      await showNotification('정보를 수집중이에요');
      break;
    case AppServiceState.processing:
      await showNotification('타임라인을 생성중이에요');
      break;
    case AppServiceState.waiting:
      await showNotification('기록이 끝났어요');
      break;
  }

  // 1분마다 반복
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    print('백그라운드 서비스 실행됨');

    AppServiceState targetState = await updatedState();

    if (currentState != targetState && !isAnalysisRunning) {
      currentState = targetState;
      switch (currentState) {
        case AppServiceState.collecting:
          await showNotification('정보를 수집중이에요');
          break;
        case AppServiceState.processing:
          await showNotification('타임라인을 생성중이에요');
          break;
        case AppServiceState.waiting:
          await showNotification('기록이 끝났어요');
          break;
      }
    }

    switch (currentState) {
      case AppServiceState.collecting:
        await saveLocation();
        break;

      case AppServiceState.processing:
        if (!isAnalysisRunning) {
          isAnalysisRunning = true;
          bool success = await generateTimeline();
          isAnalysisRunning = false;

          if (success) {
            currentState = AppServiceState.waiting;
            await showNotification('타임라인 생성 성공');
          }
        }
        break;

      case AppServiceState.waiting:
        break;
    }
  });
}
