import 'package:diary_for_me/common/colors.dart';
import 'package:diary_for_me/common/text_style.dart';
import 'package:diary_for_me/common/path_util.dart';
import 'package:diary_for_me/diary/screen/diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/widgets/buttons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

// [필수] Isar 모델 import
import '../../DB/diary/diary_model.dart';

class DiaryTile extends StatefulWidget {
  final Diary diary;

  const DiaryTile({super.key, required this.diary});

  @override
  State<DiaryTile> createState() => _DiaryTileState();
}

class _DiaryTileState extends State<DiaryTile> {
  /// URL 경로를 전체 URL로 변환
  String _getFullUrl(String path) {
    if (path.startsWith('/api/')) {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      return '$baseUrl$path';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // 1. 날짜 가져오기 (IsarLink 활용)
    // 연결된 타임라인이 없거나 날짜가 없으면 현재 시간 표시 (안전장치)
    final date = widget.diary.timeline.value?.date ?? DateTime.now();

    // 2. 썸네일 이미지 가져오기
    final images = widget.diary.content?.image ?? [];
    final hasImage = images.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 간격 미세 조정
      child: ContainerButton(
        borderRadius: BorderRadius.circular(26),
        // 터치 시 동작
        // 일기 페이지로 이동
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => DiaryScreen(
                // [변경] Hive Key 대신 Isar ID(int) 전달
                diaryId: widget.diary.id,
              ),
            ),
          );
        },
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 이미지 영역
            SmoothClipRRect(
              borderRadius: BorderRadius.circular(20),
              smoothness: 0.6,
              child: Container(
                width: 88,
                height: 88,
                color: themeColor.withAlpha(24),
                child: hasImage
                    ? Image.network(
                        _getFullUrl(images.first),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) {
                          return Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: themeColor.withAlpha(64),
                              size: 32,
                            ),
                          );
                        },
                        loadingBuilder: (ctx, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: themeColor,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.auto_stories_outlined,
                          color: themeColor.withAlpha(64),
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // 제목 및 내용
            // [추가] Expanded로 감싸야 텍스트가 길 때 오버플로우가 안 납니다.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [변경] 실제 날짜 표시
                  Text(
                    DateFormat('yyyy.MM.dd(E)', 'ko').format(date),
                    style: cardDetail(),
                  ),
                  const SizedBox(height: 6),
                  // 제목
                  Text(
                    widget.diary.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: contentTitle(),
                  ),
                  const SizedBox(height: 6),
                  // 내용 (Null Safety 적용)
                  Text(
                    widget.diary.content?.text ?? '', // 내용이 없으면 빈 문자열
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: contentDetail(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}