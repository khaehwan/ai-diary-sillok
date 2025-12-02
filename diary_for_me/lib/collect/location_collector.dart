import 'package:diary_for_me/DB/background_log/background_log_model.dart';
import 'package:diary_for_me/DB/db_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

/// 위치 수집 및 저장
Future<void> saveLocation() async {
  print('#################### 위치 저장 시도 ####################');
  final now = DateTime.now();

  bool isTimeSlot = (now.minute >= 0 && now.minute <= 5) ||
      (now.minute >= 30 && now.minute <= 35);

  if (!isTimeSlot) return;

  try {
    final isar = await DB().instance;

    final count = await isar.locationLogs.count();
    print('$count 개의 위치가 수집됨');

    final lastLog = await isar.locationLogs.where().sortByTimestampDesc().findFirst();
    if (lastLog != null && now.difference(lastLog.timestamp).inMinutes < 20) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final newLog = LocationLog(
      timestamp: now,
      lat: position.latitude,
      lng: position.longitude,
    );

    await isar.writeTxn(() async {
      await isar.locationLogs.put(newLog);
    });

    print("✅ [LocationTask] 위치 저장 완료: ${DateFormat('HH:mm').format(now)}");

  } catch (e) {
    print("❌ [LocationTask] 에러 발생: $e");
  }
}