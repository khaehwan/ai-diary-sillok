import 'package:diary_for_me/DB/daily_data/daily_data_model.dart';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:diary_for_me/common/ui_kit.dart';

// [변경] Isar 모델 import
import 'section_card.dart';

class LocationCard extends StatefulWidget {
  final Event event;
  const LocationCard({super.key, required this.event});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  // [안전장치] dailydata가 null이거나 리스트가 비었을 때를 대비
  List<Location> get locations => widget.event.dailydata?.location ?? [];

  @override
  Widget build(BuildContext context) {
    // 1. 유효한 위치 데이터가 있는지 검사
    // 리스트가 있어야 하고, 첫 번째 좌표 값들이 null이 아니어야 함
    final bool hasValidLocation =
        locations.isNotEmpty &&
        locations.first.lat != null &&
        locations.first.lng != null;

    final Location? firstLocation = hasValidLocation ? locations.first : null;

    return SectionCard(
      title: '위치',
      children: [
        contents(
          children: [
              // 2. 좌표 텍스트 표시 (데이터 유무에 따라 분기)
              Text(
                hasValidLocation
                    ? '위도: ${firstLocation!.lat}, 경도: ${firstLocation.lng}'
                    : '위치 정보가 없는 이벤트에요',
                style: cardTitle(),
              ),

            if(hasValidLocation)
              const SizedBox(height: 16),

            // 3. 지도 표시
            if (hasValidLocation)
              Container(
                height: 160,
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    smoothness: 0.6,
                  ),
                  color: themeDeepColor,
                ),
                padding: const EdgeInsets.all(1),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      smoothness: 0.6,
                    ),
                  ),
                  // 네이버 지도 위젯
                  child: NaverMap(
                    options: NaverMapViewOptions(
                      scrollGesturesEnable: false,
                      zoomGesturesEnable: false,
                      rotationGesturesEnable: false,
                      initialCameraPosition: NCameraPosition(
                        target: NLatLng(
                          firstLocation!.lat!,
                          firstLocation.lng!,
                        ),
                        zoom: 14,
                      ),
                    ),
                    onMapReady: (controller) {
                      final marker = NMarker(
                        id: 'loc',
                        position: NLatLng(
                          firstLocation.lat!,
                          firstLocation.lng!,
                        ),
                      );
                      controller.addOverlay(marker);
                    },
                  ),
                ),
              )
            else
              // 위치 정보가 없을 때 보여줄 플레이스홀더
              // Container(
              //   height: 160,
              //   width: double.infinity,
              //   decoration: ShapeDecoration(
              //     shape: SmoothRectangleBorder(
              //       borderRadius: BorderRadius.circular(22),
              //       smoothness: 0.6,
              //     ),
              //     color: Colors.grey.withAlpha(20),
              //   ),
              //   child: Center(
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(
              //           Icons.map_outlined,
              //           color: textTertiary.withAlpha(128),
              //           size: 40,
              //         ),
              //         const SizedBox(height: 8),
              //         Text(
              //           '지도를 불러올 수 없습니다',
              //           style: cardDetail(color: textTertiary),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

            const SizedBox(height: 16),
            // borderHorizontal(),
          ],
        ),
        // bottomButton(
        //   child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.end,
        //     children: [
        //       Text('위치 변경', style: cardDetail(color: textTertiary)),
        //       const Icon(Icons.arrow_forward, size: 19, color: textTertiary),
        //     ],
        //   ),
        //   onTap: () {
        //     // 위치 변경 로직 구현 필요
        //   },
        // ),
      ],
    );
  }
}
