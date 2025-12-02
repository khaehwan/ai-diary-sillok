import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';

Widget contentsCard({required List<Widget> children}) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    width: double.maxFinite,
    clipBehavior: Clip.antiAlias,
    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
    decoration: ShapeDecoration(
      shape: SmoothRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        smoothness: 0.6
      ),
      color: Colors.white,
      shadows: [
        BoxShadow(
          color: Colors.black.withAlpha(16),
          spreadRadius: 0,
          blurRadius: 36,
          offset: Offset(0, 12)
        )
      ]
    ),
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget contents({required List<Widget> children,
  crossAxisAlignment = CrossAxisAlignment.start,}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Column(
      crossAxisAlignment: crossAxisAlignment,
      children: children
    ),
  );
}