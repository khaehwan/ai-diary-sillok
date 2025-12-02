import 'package:isar/isar.dart';

part 'daily_data_model.g.dart';

@embedded
class AppNotification {
  String? appname;
  String? text;

  DateTime? timestamp;

  AppNotification({
    this.appname,
    this.text,
    this.timestamp
  });

  AppNotification clone() {
    return AppNotification(
      appname: this.appname,
      text: this.text,
      timestamp: this.timestamp
    );
  }
}

@embedded
class Location {
  double? lat;

  double? lng;

  DateTime? timestamp;

  Location({
    this.lat,
    this.lng,
    this.timestamp
  });

  Location clone() {
    return Location(
      lat: this.lat,
      lng: this.lng,
      timestamp: this.timestamp
    );
  }
}

@embedded
class DailyData {
  List<String> gallery;

  List<Location> location;

  List<AppNotification> appnoti;

  DailyData({
    this.gallery = const [],
    this.location = const [],
    this.appnoti = const []
  });

  DailyData clone() {
    return DailyData(
      gallery: List<String>.from(this.gallery),
      location: this.location.map((e) => e.clone()).toList(),
      appnoti: this.appnoti.map((e) => e.clone()).toList(),
    );
  }
}