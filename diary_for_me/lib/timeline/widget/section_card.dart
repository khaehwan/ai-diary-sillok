import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5.0,
            spreadRadius: 0.3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class SectionCard2 extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SectionCard2({super.key, required this.title, required this.children});

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
              color: textTertiary
            ),
          ),
        ),
        ...children
      ]
    );
  }
}

