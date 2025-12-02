import 'package:flutter/material.dart';

Widget borderHorizontal() {
  return Container(
    height: 1,
    width: double.infinity,
    color: Colors.black.withAlpha(16),
  );
}

Widget borderVertical() {
  return Container(
    height: double.infinity,
    width: 1,
    color: Colors.black.withAlpha(16),
  );
}
