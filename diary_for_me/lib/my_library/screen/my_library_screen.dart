import 'package:diary_for_me/DB/db_manager.dart'; // [필수] DB 매니저
import 'package:diary_for_me/DB/diary/diary_model.dart'; // [필수] 모델
import 'package:diary_for_me/my_library/widgets/diary_empty.dart';
import 'package:diary_for_me/my_library/widgets/diary_tile.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:isar/isar.dart'; // [필수] Isar 패키지

import '../widgets/tag_box.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  String? _selectedTag;

  // DB 인스턴스 Future 저장용
  late Future<Isar> _dbFuture;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 DB 연결 준비
    _dbFuture = DB().instance;
  }

  // 즐겨찾기(@f) 토글 함수
  Future<void> _toggleFavorite(Isar isar, Diary diary) async {
    await isar.writeTxn(() async {
      // 리스트는 수정 가능한 새 리스트로 복사해서 조작해야 안전함
      final List<String> currentTags = [...diary.tag];

      if (currentTags.contains('@f')) {
        currentTags.remove('@f');
      } else {
        currentTags.add('@f');
      }

      diary.tag = currentTags;
      await isar.diarys.put(diary);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: blurryAppBar(color: Colors.white),
      backgroundColor: Colors.white,
      // 1. DB 인스턴스 확보
      body: FutureBuilder<Isar>(
        future: _dbFuture,
        builder: (context, dbSnapshot) {
          if (!dbSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isar = dbSnapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SafeArea(bottom: false, child: SizedBox()),

                  // === 페이지 제목 ===
                  contents(
                    children: [
                      Text('나의 서고', style: pageTitle()),
                      const SizedBox(height: 8),
                      Text('저장된 일기들을 이곳에서 볼 수 있어요.', style: cardDetail()),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // === 태그 선택창 (StreamBuilder #1) ===
                  StreamBuilder<List<Tag>>(
                    stream: isar.tags.where().watch(fireImmediately: true),
                    builder: (context, tagSnapshot) {
                      final tags = tagSnapshot.data ?? [];

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            // 1. 전체 버튼
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTag = null;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: tagBox(
                                text: '전체',
                                activated: _selectedTag == null,
                              ),
                            ),
                            // 2. 즐겨찾기 버튼
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTag = '@f';
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: tagBox(
                                text: '즐겨찾기',
                                activated: _selectedTag == '@f',
                              ),
                            ),
                            // 3. DB에 저장된 태그 목록
                            ...tags.map((tag) {
                              // '@f'는 위에서 처리했으므로 숨김 (만약 DB에 들어있다면)
                              if (tag.name == '@f') return const SizedBox();

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTag = tag.name;
                                  });
                                },
                                child: tagBox(
                                  text: '#${tag.name}',
                                  activated: _selectedTag == tag.name,
                                ),
                              );
                            }),
                            const SizedBox(width: 14),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // === 일기 목록 (StreamBuilder #2) ===
                  StreamBuilder<List<Diary>>(
                    stream: isar.diarys.where().watch(fireImmediately: true),
                    builder: (context, diarySnapshot) {
                      if (!diarySnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var diaries = diarySnapshot.data!;

                      if (diaries.isEmpty) {
                        return const DiaryEmpty();
                      }

                      // 1. 태그 필터링
                      if (_selectedTag != null) {
                        diaries = diaries.where((diary) {
                          final tags = diary.tag; //?? [];
                          return tags.contains(_selectedTag);
                        }).toList();
                      }

                      // 필터링 결과가 없으면 태그 엠티 표시
                      // (단, '전체'일 때 비어있는 것과 구분하기 위해 원본 리스트 체크 필요하지만, 기존 로직 유지하여 필터 후 비었으면 TagEmpty 표시)
                      if (diaries.isEmpty) {
                        // TagEmpty 위젯이 없다면 DiaryEmpty나 SizedBox로 대체
                        return const DiaryEmpty(); // 혹은 TagEmpty()
                      }

                      // 2. 날짜별 정렬 (최신순)
                      diaries.sort((a, b) {
                        final dateA = a.timeline.value?.date ?? DateTime(0);
                        final dateB = b.timeline.value?.date ?? DateTime(0);
                        return dateB.compareTo(dateA); // 내림차순
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: diaries.length,
                        itemBuilder: (BuildContext context, int index) {
                          final diary = diaries[index];
                          final isFavorite = diary.tag.contains('@f');

                          return Row(
                            children: [
                              Expanded(child: DiaryTile(diary: diary)),
                              ContainerButton(
                                height: 40,
                                width: 40,
                                onTap: () => _toggleFavorite(isar, diary),
                                child: Center(
                                  child: Icon(
                                    Icons.bookmark,
                                    size: 26,
                                    color: isFavorite
                                        ? themeColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SafeArea(top: false, child: SizedBox()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
