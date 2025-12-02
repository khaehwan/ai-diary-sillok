import 'package:diary_for_me/new_diary/screen/select_mood_screen.dart';
import 'package:diary_for_me/timeline/widget/add_event_button.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart'; // [필수] Isar 패키지
import 'package:smooth_corner/smooth_corner.dart';

import 'package:diary_for_me/timeline/widget/event_card.dart';
import 'package:diary_for_me/timeline/screen/edit_event_screen.dart';

// [필수] DB 매니저 및 모델 import
import '../../DB/db_manager.dart';
import '../../DB/timeline/timeline_model.dart';

class EventListScreen extends StatefulWidget {
  // [변경] String Key -> int ID
  final int timelineId;
  const EventListScreen({super.key, required this.timelineId});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  // DB 연결 Future 캐싱
  late Future<Isar> _dbFuture;

  @override
  void initState() {
    super.initState();
    _dbFuture = DB().instance;
  }

  /// 이벤트 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(BuildContext context, Event event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('활동 삭제'),
          content: Text(
            '"${event.title}" 활동을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  /// 이벤트 삭제 실행
  Future<void> _deleteEvent(
    BuildContext context,
    Isar isar,
    TimeLine timeline,
    int eventIndex,
  ) async {
    // UI와 DB 정합성을 위해 먼저 정렬
    timeline.events.sort();

    final event = timeline.events[eventIndex];
    final confirmed = await _showDeleteConfirmDialog(context, event);

    if (confirmed) {
      await isar.writeTxn(() async {
        final currentEvents = [...timeline.events];
        currentEvents.removeAt(eventIndex);
        timeline.events = currentEvents;
        await isar.timeLines.put(timeline);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('활동이 삭제되었습니다.')),
        );
      }
    }
  }

  // [기능] 이벤트 추가/수정 모달 및 DB 저장
  Future<void> _showEventModal(
      BuildContext context,
      Isar isar,
      TimeLine timeline,
      int? eventIndex,
      ) async {
    // UI와 DB의 정합성을 위해 리스트를 먼저 정렬합니다. (UI가 정렬된 상태로 보여지므로)
    // Isar 객체의 리스트는 수정 가능하므로 직접 sort 해도 됩니다.
    timeline.events.sort();

    final Event? initialEvent =
    (eventIndex != null) ? timeline.events[eventIndex] : null;

    // 모달 띄우기 (수정/추가)
    final Event? resultEvent = await ActivityEditSheet.show(
      context,
      initialEvent: initialEvent,
    );

    if (resultEvent != null) {
      await isar.writeTxn(() async {
        // 리스트를 수정 가능한 상태로 복사 (안전장치)
        final currentEvents = [...timeline.events];

        if (eventIndex != null) {
          // 수정
          currentEvents[eventIndex] = resultEvent;
        } else {
          // 추가
          currentEvents.add(resultEvent);
        }

        // 타임라인 객체 업데이트
        timeline.events = currentEvents;

        // 정렬된 상태로 저장 (선택 사항)
        timeline.events.sort();

        await isar.timeLines.put(timeline);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 레벨의 context를 저장하여 모달에서 사용
    final scaffoldContext = context;

    return Scaffold(
      appBar: blurryAppBar(
        color: Colors.white,
        actions: [
          Text('1', style: appbarButton(color: textPrimary)),
          Text('/3', style: appbarButton(color: textTertiary)),
          const SizedBox(width: 20),
        ],
      ),
      backgroundColor: Colors.white,
      // 1. DB 인스턴스 확보
      body: FutureBuilder<Isar>(
        future: _dbFuture,
        builder: (context, dbSnapshot) {
          if (!dbSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isar = dbSnapshot.data!;

          // 2. 타임라인 데이터 감시 (StreamBuilder)
          return StreamBuilder<TimeLine?>(
            stream: isar.timeLines.watchObject(widget.timelineId, fireImmediately: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('타임라인을 불러올 수 없습니다.'));
              }

              final timeline = snapshot.data!;
              final events = timeline.events;

              // 날짜순 정렬 (Event 클래스에 Comparable 구현됨)
              events.sort();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text("하루 돌아보기", style: pageTitle()),
                    const SizedBox(height: 8),
                    Text(
                      "수집된 정보들을 바탕으로 생성된 타임라인이에요.\n"
                          "실제 있었던 일과 다르다면 카드를 눌러 수정해 주세요.",
                      style: cardDetail(),
                    ),
                    const SizedBox(height: 16),

                    // 이벤트 목록
                    Expanded(
                      child: SmoothClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: events.length + 1,
                          itemBuilder: (context, index) {
                            // 마지막 아이템: 추가 버튼
                            if (index == events.length) {
                              return AddEventButton(
                                onTap: () => _showEventModal(
                                  scaffoldContext, // Scaffold 레벨의 context 사용
                                  isar,
                                  timeline,
                                  null, // null이면 추가 모드
                                ),
                              );
                            }

                            final e = events[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: EventCard(
                                event: e,
                                onEdit: () {
                                  _showEventModal(
                                    scaffoldContext, // Scaffold 레벨의 context 사용
                                    isar,
                                    timeline,
                                    index, // index 전달하여 수정 모드
                                  );
                                },
                                onDelete: () {
                                  _deleteEvent(
                                    scaffoldContext,
                                    isar,
                                    timeline,
                                    index,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 다음 버튼
                    ContainerButton(
                      borderRadius: BorderRadius.circular(24),
                      height: 68,
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            // [변경] timelineId(int) 전달
                            // SelectMoodScreen도 int ID를 받도록 수정 필요
                            builder: (context) => SelectMoodScreen(
                              timelineId: widget.timelineId,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('다음으로', style: mainButton(color: textPrimary)),
                            Icon(Icons.navigate_next, size: 24, color: textPrimary),
                          ],
                        ),
                      ),
                    ),

                    const SafeArea(top: false, child: SizedBox()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}