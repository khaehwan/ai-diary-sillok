import 'package:isar/isar.dart';
import '../timeline/timeline_model.dart';

part 'diary_model.g.dart';

@embedded
class DiaryContent {

  String text;

  List<String> image;

  List<String> music;

  DiaryContent({
    this.text = '',
    this.image = const [],
    this.music = const []
  });
}

@collection
class Tag {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  int count;

  Tag({
    required this.name,
    required this.count
  });
}

@collection
class Diary {
  Id id = Isar.autoIncrement;

  String serverId;

  final timeline = IsarLink<TimeLine>();

  String title;

  DiaryContent? content;

  List<String> tag;

  Diary({
    this.serverId = '',
    this.title = '',
    this.content,
    this.tag = const []
  });
}