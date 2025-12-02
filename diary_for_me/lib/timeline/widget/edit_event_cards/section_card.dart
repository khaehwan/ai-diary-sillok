import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return contentsCard(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0),
          child: Text(title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: textSecondary
            ),
          ),
        ),
        ...children
      ]
    );
  }
}

