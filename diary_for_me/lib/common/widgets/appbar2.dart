import 'dart:ui';
import 'package:flutter/material.dart';

PreferredSizeWidget blurryAppBar({required List<Widget> children, required Color color}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: AppBar(
          backgroundColor: color.withAlpha(224),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 20,
          title: SizedBox(
            width: double.infinity, height: kToolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children
            ),
          ),
        ),
      ),
    ),
  );
}