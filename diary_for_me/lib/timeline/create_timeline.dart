import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import '../../DB/daily_data/daily_data_model.dart';

// [필수] DB 매니저 및 모델 import
import '../../DB/db_manager.dart';
// import '../../DB/diary/diary_model.dart';
// import '../../DB/timeline/timeline_model.dart';
// import '../../DB/daily_data/daily_data_model.dart';

/// JSON 문자열을 받아 파싱 + 저장
Future<TimeLine?> importTimelineFromJsonString(
  BuildContext context,
  String jsonString,
) async {
  try {
    final Map<String, dynamic> map =
        json.decode(jsonString) as Map<String, dynamic>;
    return await importTimelineFromMap(context, map);
  } catch (e, st) {
    debugPrint('importTimelineFromJsonString parse error: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JSON 파싱 오류: $e')));
    }
    return null;
  }
}

/// JSON Map -> TimeLine 객체 생성 및 Isar에 저장
Future<TimeLine?> importTimelineFromMap(
  BuildContext context,
  Map<String, dynamic> json,
) async {
  try {
    // --- 헬퍼: DateTime 파싱 안전하게 ---
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          // 로컬 포맷 등 예외가 있다면 null 반환
          return null;
        }
      }
      return null;
    }

    // --- DailyData 하위 항목 파서 (모델에 맞춤) ---
    AppNotification parseAppNoti(Map<String, dynamic> m) {
      return AppNotification(
        appname: m['appname'] as String?,
        text: m['text'] as String?,
        timestamp: parseDate(m['timestamp']),
      );
    }

    Location parseLocation(Map<String, dynamic> m) {
      double? lat;
      double? lng;
      if (m['lat'] is num) lat = (m['lat'] as num).toDouble();
      if (m['lng'] is num) lng = (m['lng'] as num).toDouble();
      return Location(lat: lat, lng: lng, timestamp: parseDate(m['timestamp']));
    }

    // gallery는 단순 String 리스트
    List<String> parseGallery(List<dynamic>? arr) {
      if (arr == null) return [];
      return arr.whereType<String>().toList();
    }

    DailyData parseDailyData(Map<String, dynamic>? m) {
      if (m == null) return DailyData();
      final galleryJson = m['gallery'] as List<dynamic>?;
      final locationJson = m['location'] as List<dynamic>?;
      final appnotiJson = m['appnoti'] as List<dynamic>?;

      return DailyData(
        gallery: parseGallery(galleryJson),
        location: locationJson == null
            ? []
            : locationJson
                  .whereType<Map<String, dynamic>>()
                  .map((e) => parseLocation(e))
                  .toList(),
        appnoti: appnotiJson == null
            ? []
            : appnotiJson
                  .whereType<Map<String, dynamic>>()
                  .map((e) => parseAppNoti(e))
                  .toList(),
      );
    }

    // --- Event 파싱 ---
    Event parseEvent(Map<String, dynamic> emap) {
      final dt = parseDate(emap['timestamp']);
      final feeling = (emap['feeling'] as String?) ?? ''; // 모델에 맞게 null -> ''
      return Event(
        id: emap['id'] as String? ?? DateTime.now().toIso8601String(),
        timestamp: dt,
        title: emap['title'] as String? ?? '',
        content: emap['content'] as String? ?? '',
        feeling: feeling,
        dailydata: parseDailyData(emap['dailydata'] as Map<String, dynamic>?),
      );
    }

    // --- SelfSurvey 파싱 ---
    SelfSurvey parseSelfSurvey(Map<String, dynamic>? s) {
      if (s == null) return SelfSurvey();
      return SelfSurvey(
        mood: s['mood'] as String?,
        draft: s['draft'] as String?,
      );
    }

    // --- TimeLine 생성 ---
    final eventsJson = (json['events'] as List<dynamic>?) ?? [];
    final events = <Event>[];
    for (final e in eventsJson) {
      if (e is Map<String, dynamic>) {
        events.add(parseEvent(e));
      }
    }

    final tl = TimeLine(
      title: json['title'] as String? ?? '',
      date: parseDate(json['date']) ?? DateTime.now(),
      events: events,
      selfsurvey: parseSelfSurvey(json['selfsurvey'] as Map<String, dynamic>?),
    );

    // status 문자열을 enum으로 변환 (옵션 필드)
    final statusStr = json['status'] as String?;
    if (statusStr != null) {
      switch (statusStr) {
        case 'processing':
          tl.status = TimelineStatus.processing;
          break;
        case 'completed':
          tl.status = TimelineStatus.completed;
          break;
        case 'pending':
        default:
          tl.status = TimelineStatus.pending;
      }
    }

    // --- 저장(트랜잭션) ---
    final isar = await DB().instance;
    TimeLine? saved;
    await isar.writeTxn(() async {
      final newId = await isar.timeLines.put(tl);
      saved = await isar.timeLines.get(newId);
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('타임라인 임포트/저장 완료')));
    }
    return saved;
  } catch (e, st) {
    debugPrint('importTimelineFromMap error: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('타임라인 저장 중 오류: $e')));
    }
    return null;
  }
}
