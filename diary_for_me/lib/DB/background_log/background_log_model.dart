import 'package:isar/isar.dart';

part 'background_log_model.g.dart';

/// 위치 로그
@collection
class LocationLog {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime timestamp;

  double? lat;
  double? lng;

  LocationLog({required this.timestamp, this.lat, this.lng});
}

/// 앱 알림 로그
@collection
class AppNotificationLog {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime timestamp;

  String? appname;
  String? text;

  AppNotificationLog({required this.timestamp, this.appname, this.text});
}

/// 앱 서비스 상태
enum AppServiceState {
  collecting,
  processing,
  waiting,
}

/// 서비스 상태 저장 (단일 레코드)
@collection
class ServiceStatus {
  Id id = 0;

  @enumerated
  AppServiceState state;

  ServiceStatus({required this.state});
}
