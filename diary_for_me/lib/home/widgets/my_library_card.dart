import 'package:diary_for_me/DB/db_manager.dart';
import 'package:diary_for_me/DB/diary/diary_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../common/ui_kit.dart';
import '../../my_library/screen/my_library_screen.dart';
import '../../my_library/widgets/diary_tile.dart';

class MyLibraryCard extends StatelessWidget {
  const MyLibraryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DB().instance,
      builder: (context, dbSnapshot) {
        if (!dbSnapshot.hasData) {
          return contentsCard(
            children: [
              const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        final isar = dbSnapshot.data as Isar;

        return StreamBuilder<List<Diary>>(
          stream: isar.diarys.where().watch(fireImmediately: true),
          builder: (context, snapshot) {
            final allDiaries = snapshot.data ?? [];

            return contentsCard(
              children: [
                contents(
                  children: [
                    Text('나의 서고', style: cardTitle()),
                    const SizedBox(height: 8),
                    Text('저장된 일기들을 이곳에서 볼 수 있어요', style: cardDetail()),
                  ],
                ),

                if (allDiaries.isEmpty)
                  const SizedBox(
                    height: 50,
                    child: Center(child: Text("아직 작성된 일기가 없어요")),
                  )
                else
                  Builder(
                    builder: (context) {
                      allDiaries.sort((a, b) {
                        final dateA = a.timeline.value?.date ?? DateTime(0);
                        final dateB = b.timeline.value?.date ?? DateTime(0);
                        return dateB.compareTo(dateA);
                      });

                      final recentDiaries = allDiaries.take(2).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentDiaries.length,
                        itemBuilder: (BuildContext context, int index) {
                          return DiaryTile(diary: recentDiaries[index]);
                        },
                      );
                    },
                  ),

                contents(children: [borderHorizontal()]),

                bottomButton(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('모두 보기', style: cardDetail(color: textTertiary)),
                      const Icon(
                        Icons.arrow_forward,
                        size: 19,
                        color: textTertiary,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const MyLibraryScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
