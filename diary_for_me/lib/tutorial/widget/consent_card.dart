import 'package:flutter/material.dart';
import 'package:diary_for_me/common/colors.dart';
import 'package:smooth_corner/smooth_corner.dart';

/// 개별 카드 위젯
class ConsentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const ConsentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 카드 배경(약한 회색), 둥근 모서리, 내부 패딩
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              smoothness: 0.6,
              side: BorderSide(
                color: selected ? themeColor.withAlpha(120) : themeDeepColor.withAlpha(255),
                width: selected ? 2.0 : 1.0
              )
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 (상단 좌측)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 56, color: textTertiary),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? themeColor : themeDeepColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? themeColor : themeDeepColor,
                        width: 1.2,
                      ),
                    ),
                    child:
                    selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : const Icon(
                      Icons.check,
                      size: 18,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.2
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textTertiary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
