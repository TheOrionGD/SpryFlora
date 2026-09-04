import 'package:flutter/material.dart';

/// Renders the exact Corner Leaves from 258.jpg with optional corner flipping
class BotanicalCornerLeaves extends StatelessWidget {
  final double size;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  final double opacity;

  const BotanicalCornerLeaves({
    super.key,
    this.size = 140,
    this.isTopLeft = true,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget leafImage = Opacity(
      opacity: opacity,
      child: Image.asset(
        'assets/sprites/certificate_corner_leaves.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );

    if (isTopRight) {
      return Transform.scale(
        scaleX: -1,
        child: leafImage,
      );
    } else if (isBottomLeft) {
      return Transform.scale(
        scaleY: -1,
        child: leafImage,
      );
    } else if (isBottomRight) {
      return Transform.scale(
        scaleX: -1,
        scaleY: -1,
        child: leafImage,
      );
    }

    return leafImage;
  }
}

/// Full 4-corner botanical decorative frame using 258.jpg leaves
class BotanicalLeavesFrame extends StatelessWidget {
  final double leafSize;
  final double opacity;
  final Widget? child;

  const BotanicalLeavesFrame({
    super.key,
    this.leafSize = 130,
    this.opacity = 0.9,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-Left Corner Leaves
        Positioned(
          top: 0,
          left: 0,
          child: BotanicalCornerLeaves(
            size: leafSize,
            isTopLeft: true,
            opacity: opacity,
          ),
        ),

        // Top-Right Corner Leaves
        Positioned(
          top: 0,
          right: 0,
          child: BotanicalCornerLeaves(
            size: leafSize,
            isTopRight: true,
            opacity: opacity,
          ),
        ),

        // Bottom-Left Corner Leaves
        Positioned(
          bottom: 0,
          left: 0,
          child: BotanicalCornerLeaves(
            size: leafSize,
            isBottomLeft: true,
            opacity: opacity,
          ),
        ),

        // Bottom-Right Corner Leaves
        Positioned(
          bottom: 0,
          right: 0,
          child: BotanicalCornerLeaves(
            size: leafSize,
            isBottomRight: true,
            opacity: opacity,
          ),
        ),

        if (child != null) child!,
      ],
    );
  }
}
