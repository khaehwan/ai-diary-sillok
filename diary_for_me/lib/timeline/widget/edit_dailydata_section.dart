import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:flutter/material.dart';
import 'edit_event_cards/app_noti_card.dart';
import 'edit_event_cards/location_card.dart';
import 'edit_event_cards/related_photo_card.dart';

Widget dailyDataEdit({required Event event}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Column(
      children: [
        // 사진
        RelatedPhotoCard(event: event),
        // 위치
        LocationCard(event: event),
        // 알림
        AppNotiCard(event: event),

        SizedBox(height: 80),
      ],
    ),
  );
}
