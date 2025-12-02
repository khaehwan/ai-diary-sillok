import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/timeline/screen/event_list_screen.dart';
import 'package:diary_for_me/common/ui_kit.dart';

class GenerateButton extends StatelessWidget {
  // [변경] String Key -> int ID
  final int timelineId;

  const GenerateButton({super.key, required this.timelineId});

  @override
  Widget build(BuildContext context) {
    return ContainerButton(
      borderRadius: BorderRadius.circular(20),
      color: themeColor,
      height: 56,
      shadows: [
        BoxShadow(
          color: themeColor.withAlpha(128),
          spreadRadius: -12,
          blurRadius: 18,
          offset: const Offset(0, 18),
        ),
      ],
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => EventListScreen(
              // [변경] timelineId 전달
              timelineId: timelineId,
            ),
          ),
        );
      },
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('일기 생성하기', style: mainButton()),
            const Icon(Icons.navigate_next, size: 24, color: Colors.white),
          ],
        ),
      ),
    );
  }
}