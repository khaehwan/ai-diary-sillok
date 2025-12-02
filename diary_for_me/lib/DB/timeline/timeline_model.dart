import 'package:isar/isar.dart';
import '../daily_data/daily_data_model.dart';

part 'timeline_model.g.dart';

@embedded
class Event implements Comparable<Event> {
  String id;

  DateTime? timestamp;

  String title;

  String content;

  String feeling;

  DailyData? dailydata;

  Event({
    this.id = '',
    this.timestamp,
    this.title = '',
    this.content = '',
    this.feeling = '',
    this.dailydata,
  });


  Event clone() {
    return Event(
      id: this.id,
      timestamp: this.timestamp,
      title: this.title,
      content: this.content,
      feeling: this.feeling,
      dailydata: this.dailydata?.clone(),
    );
  }

  @override
  int compareTo(Event other) {
    final thisTime = timestamp ?? DateTime.now();
    final otherTime = other.timestamp ?? DateTime.now();
    return thisTime.compareTo(otherTime);
  }

  void addPicture(String picture) {
    dailydata ??= DailyData();
    dailydata!.gallery.add(picture);
  }

  void removePicture(String picture) {
    if (dailydata == null) return;

    if (dailydata!.gallery.contains(picture)) {
      dailydata!.gallery.remove(picture);
    }
  }
}

/// 타임라인 처리 상태
enum TimelineStatus {
  pending,
  processing,
  completed,
}

@embedded
class SelfSurvey {
  String? mood;
  String? draft;

  SelfSurvey({
    this.mood,
    this.draft
  });
}

@collection
class TimeLine {
  Id id = Isar.autoIncrement;

  String serverId;

  @Enumerated(EnumType.ordinal)
  TimelineStatus status = TimelineStatus.pending;

  String title;

  @Index()
  DateTime date;

  List<Event> events;

  SelfSurvey? selfsurvey;

  TimeLine({
    this.serverId = '',
    this.title = '',
    required this.date,
    this.events = const [],
    this.selfsurvey,
  });
}