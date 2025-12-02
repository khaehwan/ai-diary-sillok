import 'package:flutter/material.dart';
// import 'package:smooth_corner/smooth_corner.dart';
import 'package:diary_for_me/common/colors.dart';

Widget tagBox({required String text, bool activated = false}) {
  return Container(
    margin: EdgeInsets.only(right: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: activated ? themeColor : themePageColor,
      border: Border.all(
        color: activated ? Colors.transparent : themeDeepColor,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    ),
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 18.0),
    alignment: Alignment.center,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: activated ? Colors.white : textTertiary,
        height: 1.2,
      ),
    ),
  );
}
