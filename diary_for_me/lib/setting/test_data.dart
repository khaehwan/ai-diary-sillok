import 'package:diary_for_me/DB/background_log/background_log_model.dart';
import 'package:diary_for_me/DB/db_manager.dart';

Future<void> addTestData () async {
  DateTime now = DateTime.now();

  final isar = await DB().instance;

  final newLoc1 = LocationLog(
    timestamp: DateTime(
      now.year,
      now.month,
      now.day,
      9,
      0,
      0
    ),
    lat: 37.5665,
    lng: 126.978,
  );
  final newLoc2 = LocationLog(
    timestamp: DateTime(
      now.year,
      now.month,
      now.day,
      12,
      30,
      0
    ),
    lat: 37.57,
    lng: 126.985,
  );
  final newLoc3 = LocationLog(
    timestamp: DateTime(
      now.year,
      now.month,
      now.day,
      18,
      0,
      0
    ),
    lat: 37.558,
    lng: 126.977,
  );

  await isar.writeTxn(() async {
    await isar.locationLogs.put(newLoc1);
    await isar.locationLogs.put(newLoc2);
    await isar.locationLogs.put(newLoc3);
  });

  final newNoti1 = AppNotificationLog(
    appname: '카카오톡',
    text: '친구: 오늘 점심 같이 먹을래?',
    timestamp: DateTime(
        now.year,
        now.month,
        now.day,
        11,
        30,
        0
    ),
  );
  final newNoti2 = AppNotificationLog(
    appname: '배달의 민족',
    text: '주문하신 음식이 배달 완료되었습니다',
    timestamp: DateTime(
        now.year,
        now.month,
        now.day,
        12,
        45,
        0
    ),
  );
  final newNoti3 = AppNotificationLog(
    appname: '캘린더',
    text: '오후 3시 팀 미팅 알림',
    timestamp: DateTime(
        now.year,
        now.month,
        now.day,
        14,
        50,
        0
    ),
  );
  final newNoti4 = AppNotificationLog(
    appname: 'YouTube',
    text: '구독한 채널에 새 동영상이 업로드되었습니다',
    timestamp: DateTime(
        now.year,
        now.month,
        now.day,
        19,
        30,
        0
    ),
  );

  await isar.writeTxn(() async {
    await isar.appNotificationLogs.put(newNoti1);
    await isar.appNotificationLogs.put(newNoti2);
    await isar.appNotificationLogs.put(newNoti3);
    await isar.appNotificationLogs.put(newNoti4);
  });
}