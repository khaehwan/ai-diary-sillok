import 'db_manager.dart';
import 'background_log/background_log_model.dart';

/// 앱 서비스 상태 관리자
class ServiceStatusManager {
  static const int _uniqueId = 0;

  /// 상태 저장
  Future<void> updateServiceStatus(AppServiceState newState) async {
    final isar = await DB().instance;
    final newStatusObj = ServiceStatus(state: newState);
    newStatusObj.id = _uniqueId;

    await isar.writeTxn(() async {
      await isar.serviceStatus.put(newStatusObj);
    });
  }

  /// 상태 불러오기
  Future<AppServiceState?> getServiceStatus() async {
    final isar = await DB().instance;
    final statusObj = await isar.serviceStatus.get(_uniqueId);
    return statusObj?.state;
  }

  /// 상태 변화 감지
  Stream<AppServiceState> watchServiceStatus() async* {
    final isar = await DB().instance;
    yield* isar.serviceStatus
        .watchObject(_uniqueId, fireImmediately: true)
        .map((statusObj) => statusObj?.state ?? AppServiceState.waiting);
  }
}