import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:intl/intl.dart';
import 'package:smooth_corner/smooth_corner.dart';

// [변경] Isar 모델 import
import '../../DB/timeline/timeline_model.dart';
import '../screen/event_list_screen.dart';

class TimeLineCard extends StatelessWidget {
  final TimeLine timeline;
  final VoidCallback? onDelete;

  const TimeLineCard({super.key, required this.timeline, this.onDelete});

  int countCollectedData(TimeLine timeline) {
    int total = 0;

    for (final event in timeline.events) {
      final daily = event.dailydata;
      if (daily != null) {
        total += daily.gallery.length;
        total += daily.location.length;
        total += daily.appnoti.length;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    // [안전 장치] 날짜가 null일 경우 현재 시간 사용
    final date = timeline.date;
    final collectedCount = countCollectedData(timeline);

    return Container(
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          smoothness: 0.6,
          side: BorderSide(color: themeDeepColor, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // [변경] Null safe한 date 변수 사용
                  DateFormat('yyyy년 MM/dd (E)').format(date),
                  style: cardTitle(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    // [참고] date.second는 임시 로직으로 보이며, 추후 실제 수집 데이터 개수 로직으로 변경 필요
                    '수집된 정보 $collectedCount개',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: textTertiary,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '생성된 활동 ${timeline.events.length}개',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: textTertiary,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: textTertiary),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ContainerButton(
            color: themeColor.withAlpha(24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) =>
                      // [변경] timelineKey(String) -> timelineId(int) 전달
                      EventListScreen(timelineId: timeline.id),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '일기 생성하기',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                Icon(Icons.keyboard_arrow_right, size: 24, color: themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
