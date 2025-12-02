import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../../DB/db_manager.dart';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:diary_for_me/DB/daily_data/daily_data_model.dart';

/// JSON 파일에서 타임라인 읽어서 Isar에 저장
Future<TimeLine?> readAndImport({
  required BuildContext context,
  String assetPath = 'lib/timeline/timeline.json',
}) async {
  try {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonMap =
        json.decode(raw) as Map<String, dynamic>;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DailyData parseDailyData(Map<String, dynamic>? m) {
      if (m == null) return DailyData();
      final g = <String>[];
      final galleryJson = m['gallery'] as List<dynamic>?;
      if (galleryJson != null) {
        for (final e in galleryJson) {
          if (e is Map<String, dynamic>) {
            final url = e['url'] as String?;
            if (url != null && url.isNotEmpty) g.add(url);
          } else if (e is String) {
            g.add(e);
          }
        }
      }

      final locs = <Location>[];
      final locJson = m['location'] as List<dynamic>?;
      if (locJson != null) {
        for (final e in locJson) {
          if (e is Map<String, dynamic>) {
            double? lat;
            double? lng;
            if (e['lat'] is num) lat = (e['lat'] as num).toDouble();
            if (e['lng'] is num) lng = (e['lng'] as num).toDouble();
            locs.add(
              Location(
                lat: lat,
                lng: lng,
                timestamp: parseDate(e['timestamp']),
              ),
            );
          }
        }
      }

      final appnotis = <AppNotification>[];
      final appJson = m['appnoti'] as List<dynamic>?;
      if (appJson != null) {
        for (final e in appJson) {
          if (e is Map<String, dynamic>) {
            appnotis.add(
              AppNotification(
                appname: e['appname'] as String?,
                text: e['text'] as String?,
                timestamp: parseDate(e['timestamp']),
              ),
            );
          }
        }
      }

      return DailyData(gallery: g, location: locs, appnoti: appnotis);
    }

    Event parseEvent(Map<String, dynamic> emap) {
      return Event(
        id: emap['id'] as String? ?? DateTime.now().toIso8601String(),
        timestamp: parseDate(emap['timestamp']),
        title: emap['title'] as String? ?? '',
        content: emap['content'] as String? ?? '',
        feeling: (emap['feeling'] as String?) ?? '',
        dailydata: parseDailyData(emap['dailydata'] as Map<String, dynamic>?),
      );
    }

    SelfSurvey parseSurvey(Map<String, dynamic>? s) {
      if (s == null) return SelfSurvey();
      return SelfSurvey(
        mood: s['mood'] as String?,
        draft: s['draft'] as String?,
      );
    }

    final eventsJson = (jsonMap['events'] as List<dynamic>?) ?? [];
    final events = <Event>[];
    for (final e in eventsJson) {
      if (e is Map<String, dynamic>) events.add(parseEvent(e));
    }

    final tl = TimeLine(
      title: jsonMap['title'] as String? ?? '',
      date: parseDate(jsonMap['date']) ?? DateTime.now(),
      events: events,
      selfsurvey: parseSurvey(jsonMap['selfsurvey'] as Map<String, dynamic>?),
    );

    final statusStr = jsonMap['status'] as String?;
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

    final isar = await DB().instance;
    TimeLine? saved;
    await isar.writeTxn(() async {
      final id = await isar.timeLines.put(tl);
      saved = await isar.timeLines.get(id);
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로컬 JSON -> 타임라인 저장 완료')));
    }
    return saved;
  } catch (e, st) {
    debugPrint('readAssetAndImport error: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('임포트 실패: $e')));
    }
    return null;
  }
}
