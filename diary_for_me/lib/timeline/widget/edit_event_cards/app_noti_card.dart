import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:flutter/material.dart';
import 'section_card.dart'; // 기존 경로 유지
import 'package:diary_for_me/common/ui_kit.dart';

class AppNotiCard extends StatelessWidget {
  final Event event;
  const AppNotiCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // 1. DailyData가 null일 경우를 대비해 안전하게 리스트 가져오기
    final notifications = event.dailydata?.appnoti ?? [];

    return SectionCard(
      title: '앱 알림에서 찾은 내용',
      children: [
        // 2. 리스트가 비어있는지 확인
        notifications.isNotEmpty
            ? contents(
          children: [
            ...notifications.map((notification) {
              return Text(
                // 3. text 필드가 Nullable이므로 안전 처리
                notification.text ?? '',
                style: TextStyle(
                  color: textPrimary,
                  height: 1.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                ),
              );
            })
          ],
        )
            : contents(
          children: [
            Text(
              '관련 알림이 없어요',
              style: TextStyle(
                color: textTertiary,
                height: 1.8,
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
              ),
            ),
          ],
        )
      ],
    );
  }
}