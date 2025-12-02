import 'package:flutter/material.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:diary_for_me/timeline/widget/time_line_card.dart';
import 'package:isar/isar.dart'; // [필수] Isar 패키지

// [필수] DB 매니저 및 모델 import
import '../../DB/db_manager.dart';
import '../../DB/timeline/timeline_model.dart';
import 'package:diary_for_me/DB/import_timeline.dart';

class TimelineListScreen extends StatefulWidget {
  const TimelineListScreen({super.key});

  @override
  State<TimelineListScreen> createState() => _TimelineListScreenState();
}

class _TimelineListScreenState extends State<TimelineListScreen> {
  // DB 연결 Future 캐싱
  late Future<Isar> _dbFuture;

  @override
  void initState() {
    super.initState();
    _dbFuture = DB().instance;
  }

  /// 타임라인 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(BuildContext context, TimeLine timeline) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('타임라인 삭제'),
          content: Text(
            '${timeline.date.year}년 ${timeline.date.month}월 ${timeline.date.day}일 타임라인을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
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

  /// 타임라인 삭제 실행
  Future<void> _deleteTimeline(Isar isar, TimeLine timeline) async {
    await isar.writeTxn(() async {
      await isar.timeLines.delete(timeline.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: blurryAppBar(color: Colors.white),
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      // 1. DB 인스턴스 확보
      body: FutureBuilder<Isar>(
        future: _dbFuture,
        builder: (context, dbSnapshot) {
          if (!dbSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isar = dbSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SafeArea(bottom: false, child: SizedBox()),
                // 제목
                Text("나의 타임라인", style: pageTitle()),
                const SizedBox(height: 8),
                Text(
                  "사관이 기록한 타임라인이에요\n모인 타임라인으로 일기를 생성할 수 있어요.",
                  style: cardDetail(),
                ),

                const SizedBox(height: 16),

                // 2. 타임라인 목록 감시 (StreamBuilder)
                StreamBuilder<List<TimeLine>>(
                  stream: isar.timeLines.where().watch(fireImmediately: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final timelines = snapshot.data!;

                    if (timelines.isEmpty) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: Text("저장된 타임라인이 없습니다.")),
                      );
                    }

                    // 3. 최신순 정렬 (내림차순)
                    timelines.sort((a, b) {
                      final dateA = a.date; //?? DateTime(0);
                      final dateB = b.date; //?? DateTime(0);
                      return dateB.compareTo(dateA);
                    });

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: timelines.length,
                      itemBuilder: (BuildContext context, int index) {
                        final timeline = timelines[index];
                        return TimeLineCard(
                          timeline: timeline,
                          onDelete: () async {
                            final confirmed = await _showDeleteConfirmDialog(context, timeline);
                            if (confirmed) {
                              await _deleteTimeline(isar, timeline);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('타임라인이 삭제되었습니다.')),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: '로컬 JSON 임포트',
                  onPressed: () async {
                    final saved = await readAndImport(context: context);
                    if (saved != null) {
                      // 성공하면 자동으로 StreamBuilder가 갱신된다.
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
