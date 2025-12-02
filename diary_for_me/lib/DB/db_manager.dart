import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'background_log/background_log_model.dart';
import 'diary/diary_model.dart';
import 'timeline/timeline_model.dart';

/// Isar DB 싱글톤 매니저
class DB {
  static final DB _instance = DB._internal();
  factory DB() => _instance;
  DB._internal();

  Isar? _isar;

  Future<Isar> get instance async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    _isar = await _openIsar();
    return _isar!;
  }

  Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();

    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [
          LocationLogSchema,
          AppNotificationLogSchema,
          ServiceStatusSchema,
          DiarySchema,
          TagSchema,
          TimeLineSchema,
        ],
        directory: dir.path,
        name: 'diary_db',
        inspector: true,
      );
    }

    return Isar.getInstance('diary_db')!;
  }
}