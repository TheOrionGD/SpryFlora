import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Tactile Push Button
/// Features a raised physical surface with bevel highlights, drop shadow,
/// and smooth interactive depression on press.
class SkeuoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isSecondary;
  final bool isLoading;

  const SkeuoButton({
    super.key,
    this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.color,
    this.textColor,
    this.height = 56,
    this.width,
    this.borderRadius = 18,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final Color contentColor = widget.textColor ??
        (widget.isSecondary ? SkeuoTheme.textPrimary : Colors.white);

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          0,
          _isPressed ? 2.5 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isSecondary
                ? (_isPressed
                    ? [SkeuoTheme.surfaceDark, SkeuoTheme.surfacePressed]
                    : [Colors.white, SkeuoTheme.surface, const Color(0xFFDFE7DE)])
                : (_isPressed
                    ? [SkeuoTheme.darkGreen, SkeuoTheme.primaryGreen]
                    : [
                        const Color(0xFF388E3C),
                        SkeuoTheme.primaryGreen,
                        SkeuoTheme.darkGreen,
                      ]),
            stops: _isPressed ? const [0.0, 1.0] : const [0.0, 0.45, 1.0],
          ),
          border: Border.all(
            color: widget.isSecondary
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF66BB6A).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B3820).withValues(alpha: 0.25),
                    offset: const Offset(1, 2),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.isSecondary
                        ? SkeuoTheme.darkShadow
                        : const Color(0xFF163E19).withValues(alpha: 0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                  ),
                )
              : widget.child ??
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: contentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.text != null)
                          Text(
                            widget.text!,
                            maxLines: 1,
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              shadows: widget.isSecondary
                                  ? null
                                  : [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
