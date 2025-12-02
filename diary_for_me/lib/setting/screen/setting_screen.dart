import 'package:diary_for_me/api_service/generate_timeline.dart';
import 'package:diary_for_me/setting/test_data.dart';
import 'package:diary_for_me/setting/widget/setting_category.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:isar/isar.dart'; // [필수] Isar 패키지

import '../../DB/background_log/background_log_model.dart';
import '../../common/ui_kit.dart';
// [필수] DB 매니저 및 모델 import
import '../../DB/db_manager.dart';
import '../../DB/diary/diary_model.dart';
import '../../DB/timeline/timeline_model.dart';
import '../../DB/daily_data/daily_data_model.dart';

import 'edit_collection_screen.dart';
import 'edit_profile_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  // [기능] DB 전체 초기화
  Future<void> _resetDatabase(BuildContext context) async {
    final isar = await DB().instance;

    await isar.writeTxn(() async {
      // 모든 컬렉션 비우기
      await isar.diarys.clear();
      await isar.tags.clear();
      await isar.timeLines.clear();
      await isar.locationLogs.clear();
      await isar.appNotificationLogs.clear();
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 데이터가 초기화되었습니다.')));
    }
  }

  // [기능] 테스트 타임라인 추가
  Future<void> _addTestTimeline(BuildContext context) async {
    final isar = await DB().instance;

    await isar.writeTxn(() async {
      // 1. 이벤트 생성 (Embedded)
      final newEvent1 = Event(
        id: DateTime.now().toIso8601String(), // String ID (Original ID)
        timestamp: DateTime.now(),
        title: '새 이벤트 1',
        content: '이벤트 내용 1',
        feeling: 'good',
        dailydata: DailyData(), // 빈 객체 (기본값으로 초기화됨)
      );

      final newEvent2 = Event(
        id: DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        timestamp: DateTime.now().add(const Duration(minutes: 30)),
        title: '새 이벤트 2',
        content: '이벤트 내용 2',
        feeling: 'bad',
        dailydata: DailyData(),
      );

      // 2. 타임라인 생성
      final newTimeLine = TimeLine(
        // id는 자동 증가(AutoIncrement)이므로 넣지 않습니다.
        title: '새 타임라인 ${DateTime.now().second}초',
        date: DateTime.now(),
        events: [newEvent1, newEvent2], // 리스트에 바로 추가
        // [변경] Map 대신 SelfSurvey 객체 사용
        selfsurvey: SelfSurvey(mood: 'good', draft: 'text'),
      );

      // 상태 설정 (Enum)
      newTimeLine.status = TimelineStatus.pending;

      // 3. 저장
      await isar.timeLines.put(newTimeLine);
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('테스트 타임라인이 추가되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textPrimary, size: 28.0),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정', style: pageTitle()),
              const SizedBox(height: 16),

              // 개인정보 변경
              SettingCategory(
                title: '개인정보 변경하기',
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 정보 수집 범위 변경
              SettingCategory(
                title: '정보 수집 범위 변경하기',
                icon: Icons.collections,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const EditCollectionScreen(),
                    ),
                  );
                },
              ),

              const Expanded(child: SizedBox()),
              Text('테스트용', style: pageTitle()),

              const SizedBox(height: 16),
              // [테스트용] 초기화 버튼
              SettingCategory(
                title: '초기화',
                icon: Icons.warning,
                onTap: () => _resetDatabase(context),
              ),
              const SizedBox(height: 16),

              // 임시 데이터 생성
              SettingCategory(
                title: '테스트용 수집 데이터 생성',
                icon: Icons.file_copy,
                onTap: () async {
                  await addTestData();
                },
              ),
              const SizedBox(height: 16),

              // [테스트용] 타임라인 생성 버튼
              SettingCategory(
                title: '타임라인 즉시 생성',
                icon: Icons.add_circle_outline,
                onTap: () async {
                  bool success = await generateTimeline();

                  if (success) {
                    print('타임라인 통신 성공');
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
