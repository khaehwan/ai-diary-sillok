import 'dart:ui';
import 'package:flutter/material.dart';

PreferredSizeWidget blurryAppBar({
  Widget? title,
  required Color color,
  List<Widget>? actions,
  bool? centerTitle
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY:18),
        child: AppBar(
          iconTheme: IconThemeData(
            size: 28.0
          ),
          backgroundColor: color.withAlpha(236),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 20,
          title: title,
          centerTitle: centerTitle,
          actions: actions
        ),
      ),
    ),
  );
}