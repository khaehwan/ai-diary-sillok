import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';

class DiaryEmpty extends StatelessWidget {
  const DiaryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            smoothness: 0.6,
          ),
          color: themeColor.withAlpha(24),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아직 작성된 일기가 없어요',
              style: cardTitle(),
            ),
            SizedBox(height: 8,),
            Text(
              '새 일기를 작성해 보세요. ',
              style: cardDetail(),
            ),
          ],
        ),
      ),
    );
  }
}

class TagEmpty extends StatelessWidget {
  const TagEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            smoothness: 0.6,
          ),
          color: themeColor.withAlpha(24),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '해당하는 일기가 없어요',
              style: cardTitle(),
            ),
            SizedBox(height: 8,),
            Text(
              '다른 태그를 검색해보세요',
              style: cardDetail(),
            ),
          ],
        ),
      ),
    );
  }
}
