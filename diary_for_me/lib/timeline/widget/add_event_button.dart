import 'package:flutter/material.dart';

import '../../common/ui_kit.dart';

class AddEventButton extends StatefulWidget {
  final VoidCallback onTap;
  const AddEventButton({super.key, required this.onTap});

  @override
  State<AddEventButton> createState() => _AddEventButtonState();
}

class _AddEventButtonState extends State<AddEventButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: ContainerButton(
          padding: EdgeInsets.symmetric(horizontal: 16),
          margin: EdgeInsets.only(bottom: 16),
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          height: 44,
          shadows: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 36,
              offset: Offset(0, 12),
            )
          ],
          onTap: widget.onTap,
          child: Center(
            child: Text('활동 추가 +',
              style: TextStyle(
                  color: textTertiary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
        ),
      ),
    );
  }
}
