import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Circular / Square Icon Push Button
class SkeuoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final bool isCircle;

  const SkeuoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 46,
    this.iconSize = 22,
    this.color,
    this.iconColor,
    this.isCircle = true,
  });

  @override
  State<SkeuoIconButton> createState() => _SkeuoIconButtonState();
}

class _SkeuoIconButtonState extends State<SkeuoIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(14),
          color: _isPressed ? SkeuoTheme.surfaceDark : (widget.color ?? SkeuoTheme.surface),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? [SkeuoTheme.surfaceDark, SkeuoTheme.surfacePressed]
                : [
                    Colors.white,
                    widget.color ?? SkeuoTheme.surface,
                    (widget.color ?? SkeuoTheme.surface).withValues(alpha: 0.9),
                  ],
            stops: _isPressed ? const [0.0, 1.0] : const [0.0, 0.45, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: _isPressed
              ? SkeuoTheme.pressedShadows()
              : [
                  BoxShadow(
                    color: SkeuoTheme.darkShadow,
                    offset: const Offset(3, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.iconColor ?? SkeuoTheme.textPrimary,
        ),
      ),
    );
  }
}
