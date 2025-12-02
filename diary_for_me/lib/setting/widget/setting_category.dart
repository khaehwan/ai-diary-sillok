import 'package:flutter/material.dart';

import '../../common/ui_kit.dart';

class SettingCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const SettingCategory({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ContainerButton(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      color: themePageColor,
      side: BorderSide(
          color: themeDeepColor,
          width: 1.0
      ),
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 12,),
          Text(
            title,
            style: TextStyle(
                fontSize: 20.0,
                color: textPrimary,
                fontWeight: FontWeight.w700
            ),
          ),
          Expanded(child: SizedBox()),
          Icon(Icons.keyboard_arrow_right, size: 28,)
        ],
      ),
    );
  }
}
