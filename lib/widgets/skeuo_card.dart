import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Raised Physical Card
/// Features top edge highlight bevel, layered ambient drop shadows, and rich organic styling.
class SkeuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isPressed;
  final Border? border;
  final double? width;
  final double? height;

  const SkeuoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 22,
    this.onTap,
    this.backgroundColor,
    this.isPressed = false,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isPressed ? SkeuoTheme.surfaceDark : (backgroundColor ?? SkeuoTheme.surface),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPressed
              ? [
                  SkeuoTheme.surfaceDark,
                  SkeuoTheme.surfacePressed,
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  backgroundColor ?? SkeuoTheme.surface,
                  (backgroundColor ?? SkeuoTheme.surface).withValues(alpha: 0.90),
                ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
        boxShadow: isPressed
            ? SkeuoTheme.pressedShadows()
            : [
                BoxShadow(
                  color: SkeuoTheme.darkShadow,
                  offset: const Offset(5, 7),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  offset: const Offset(-5, -5),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: SkeuoTheme.primaryGreen.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
