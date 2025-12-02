import 'dart:io';

import 'package:diary_for_me/DB/background_log/background_log_model.dart';
import 'package:diary_for_me/DB/daily_data/daily_data_model.dart';
import 'package:diary_for_me/DB/db_manager.dart';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:diary_for_me/collect/image.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

import 'api_service.dart';

Future<bool> generateTimeline() async {
  DateTime now = DateTime.now();
  DateTime targetDate = (now.hour >= 21)
      ? DateTime(now.year, now.month, now.day)
      : DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));

  print('>>targetDate: ${targetDate}');
  try {
    print("timeline generating...");

    final Map<String, dynamic> dailyData = await collectedDailyData(targetDate);

    if (dailyData.isEmpty) {
      print("수집된 데이터가 없습니다.");
      return false;
    }

    final apiService = DailyLogApiService();
    final Map<String, dynamic>? responseMap = await apiService.getTimelineFromAPI(dailyData);

    if (responseMap != null) {
      await _saveTimelineToDB(responseMap, targetDate);
      return true;
    } else {
      print("서버 응답이 비어있거나 실패했습니다.");
      return false;
    }
  } catch (e) {
    print("타임라인 생성 및 전송 실패: $e");
    return false;
  }
}

/// 일별 데이터 수집
Future<Map<String, dynamic>> collectedDailyData(DateTime targetDate) async {
  final start = DateTime(
    targetDate.year, targetDate.month, targetDate.day, 6, 0, 0,
  );
  final end = DateTime(
    targetDate.year, targetDate.month, targetDate.day, 20, 59, 59,
  );

  try {
    final isar = await DB().instance;

    final locationLogs = await isar.locationLogs
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();

    final notificationLogs = await isar.appNotificationLogs
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();

    List<Map<String, String>> collectedImages = await collectAndUploadImages(targetDate);

    final locationsJson = locationLogs
        .map(
          (log) => {
            'lat': log.lat,
            'lng': log.lng,
            'timestamp': log.timestamp.toIso8601String(),
            "place_name": null,
          },
        )
        .toList();

    final notificationsJson = notificationLogs
        .map(
          (log) => {
            'appname': log.appname,
            'text': log.text,
            'timestamp': log.timestamp.toIso8601String(),
          },
        )
        .toList();

    final Map<String, dynamic> result = {
      'target_date': DateFormat('yyyy-MM-dd').format(targetDate),
      'daily_data': {
        'location': locationsJson,
        'appnoti': notificationsJson,
        'gallery': collectedImages,
      },
    };

    return result;
  } catch (e) {
    print('❌ 데이터 집계 중 에러 발생: $e');
    return {};
  }
}

/// 서버 응답을 Isar에 저장
Future<void> _saveTimelineToDB(Map<String, dynamic> response, DateTime targetDate) async {
  final isar = await DB().instance;

  final responseData = response['data'];

  List<Event> parsedEvents = [];
  if (responseData['events'] != null) {
    for (var evtJson in responseData['events']) {
      parsedEvents.add(_parseEvent(evtJson));
    }
  }

  SelfSurvey? parsedSurvey;
  if (responseData['selfsurvey'] != null) {
    parsedSurvey = SelfSurvey(
      mood: responseData['selfsurvey']['mood'] ?? '',
      draft: responseData['selfsurvey']['draft'] ?? '',
    );
  }

  await isar.writeTxn(() async {
    final existing = await isar.timeLines
        .filter()
        .dateEqualTo(targetDate)
        .findFirst();

    if (existing != null) {
      existing.serverId = responseData['id'] ?? '';
      existing.title = responseData['title'] ?? '';
      existing.events = parsedEvents;
      existing.selfsurvey = parsedSurvey;

      await isar.timeLines.put(existing);
      print("🔄 기존 타임라인 업데이트 완료");
    } else {
      final newTimeline = TimeLine(
        serverId: responseData['id'] ?? '',
        date: targetDate,
        title: response['title'] ?? '',
        events: parsedEvents,
        selfsurvey: parsedSurvey,
      );
      newTimeline.status = TimelineStatus.pending;

      await isar.timeLines.put(newTimeline);
      print("✅ 새 타임라인 저장 완료");
    }
  });
}

/// JSON → Event 모델 변환
Event _parseEvent(Map<String, dynamic> json) {
  DailyData? dailyDataModel;

  if (json['dailydata'] != null) {
    final ddJson = json['dailydata'];

    List<String> galleryUrls = [];
    if (ddJson['gallery'] != null) {
      for (var imgItem in ddJson['gallery']) {
        if (imgItem is Map && imgItem.containsKey('url')) {
          galleryUrls.add(imgItem['url']);
        }
      }
    }

    List<Location> locations = [];
    if (ddJson['location'] != null) {
      for (var loc in ddJson['location']) {
        locations.add(
          Location(
            lat: loc['lat'],
            lng: loc['lng'],
            timestamp: loc['timestamp'] != null
                ? DateTime.parse(loc['timestamp'])
                : null,
          ),
        );
      }
    }

    List<AppNotification> notis = [];
    if (ddJson['appnoti'] != null) {
      for (var noti in ddJson['appnoti']) {
        notis.add(
          AppNotification(
            appname: noti['appname'],
            text: noti['text'],
            timestamp: noti['timestamp'] != null
                ? DateTime.parse(noti['timestamp'])
                : null,
          ),
        );
      }
    }

    dailyDataModel = DailyData(
      gallery: galleryUrls,
      location: locations,
      appnoti: notis,
    );
  }

  return Event(
    id: json['id'] ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : null,
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    feeling: json['feeling'] ?? '',
    dailydata: dailyDataModel,
  );
}
