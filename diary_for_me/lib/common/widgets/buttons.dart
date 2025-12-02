import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';

class ContainerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final BorderSide? side;
  final EdgeInsets? margin;

  const ContainerButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.shadows,
    this.side,
    this.margin,
  });

  @override
  State<ContainerButton> createState() => _ContainerButtonState();
}

class _ContainerButtonState extends State<ContainerButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onPointerDown(PointerDownEvent details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onPointerUp(PointerUpEvent details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _onPointerCanceled(PointerCancelEvent details) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.94 : 1.0;
    final Color dimColor = _isPressed
        ? Color(0xFF111111).withAlpha(28)
        : Colors.transparent;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCanceled,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          padding: widget.padding ?? EdgeInsets.symmetric(),
          margin: widget.margin ?? EdgeInsets.symmetric(),
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: widget.color,
            shape: SmoothRectangleBorder(
              side: widget.side ?? BorderSide.none,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              smoothness: 0.6,
            ),
            shadows: widget.shadows,
          ),
          foregroundDecoration: ShapeDecoration(
            color: dimColor,
            shape: SmoothRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              smoothness: 0.6,
            ),
          ),
          alignment: Alignment.topLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

Widget bottomButton({required VoidCallback onTap, required Widget child}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: ContainerButton(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: child,
    ),
  );
}
