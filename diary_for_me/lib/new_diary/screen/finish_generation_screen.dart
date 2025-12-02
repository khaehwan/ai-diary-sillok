import 'package:diary_for_me/DB/db_manager.dart'; // [필수] DB 매니저
import 'package:diary_for_me/DB/diary/diary_model.dart'; // [필수] Diary 모델
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:diary_for_me/common/ui_kit.dart';
// import 'package:isar/isar.dart'; // [필수] Isar 패키지
import 'package:smooth_corner/smooth_corner.dart';

import '../../diary/screen/diary_screen.dart';

class FinishGenerationScreen extends StatefulWidget {
  // [변경] Hive Key(String) -> Isar ID(int)
  final int diaryId;

  const FinishGenerationScreen({super.key, required this.diaryId});

  @override
  State<FinishGenerationScreen> createState() => _FinishGenerationScreenState();
}

class _FinishGenerationScreenState extends State<FinishGenerationScreen> {
  // 데이터 로딩을 위한 Future 변수
  late Future<Diary?> _diaryFuture;

  @override
  void initState() {
    super.initState();
    // [변경] DB에서 다이어리 정보를 가져오는 Future 초기화
    _diaryFuture = _loadDiary();
  }

  // 비동기로 DB 연결 및 데이터 조회 함수
  Future<Diary?> _loadDiary() async {
    final isar = await DB().instance;
    return await isar.diarys.get(widget.diaryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      // [변경] FutureBuilder로 데이터 대기 및 표시
      body: FutureBuilder<Diary?>(
        future: _diaryFuture,
        builder: (context, snapshot) {
          // 1. 로딩 중이거나 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final diary = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_alt_circle_fill,
                  color: themeColor,
                  size: 76,
                ),
                const SizedBox(height: 16),
                Text(
                  '일기 생성을 완료했어요',
                  style: pageTitle(fontWeight: FontWeight.w500),
                ),
                const Expanded(child: SizedBox()),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      smoothness: 0.6,
                    ),
                    color: themePageColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 160,
                        decoration: ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            smoothness: 0.6,
                          ),
                          color: themeDeepColor,
                        ),
                        // 이미지 표시 로직이 있다면 여기에 추가 (diary.content?.image 등)
                      ),
                      const SizedBox(height: 16),
                      // 제목
                      Text(
                        diary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: contentTitle(),
                      ),
                      const SizedBox(height: 8),
                      // 내용 (Null Safety 적용)
                      Text(
                        diary.content?.text ?? '', // 내용이 없으면 빈 문자열
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: contentDetail(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ContainerButton(
                        side: BorderSide(color: themeDeepColor, width: 1.0),
                        height: 68,
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '홈으로',
                                style: mainButton(color: textTertiary),
                              ),
                              const Icon(
                                Icons.navigate_before,
                                size: 24,
                                color: textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ContainerButton(
                        color: themeColor.withAlpha(24),
                        height: 68,
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  // [변경] diaryKey 대신 diaryId 전달
                                  DiaryScreen(diaryId: widget.diaryId),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '바로 읽기',
                                style: mainButton(color: themeColor),
                              ),
                              const Icon(
                                Icons.navigate_next,
                                size: 24,
                                color: themeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SafeArea(top: false, child: SizedBox()),
              ],
            ),
          );
        },
      ),
    );
  }
}
