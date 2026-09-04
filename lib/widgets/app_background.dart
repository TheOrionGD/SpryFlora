import 'package:flutter/material.dart';

/// Centralized SpryFlora App Background Wrapper.
/// Renders assets/sprites/image.png as the scenic background image for post-authentication screens.
class AppBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const AppBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Primary Post-Authentication Background Image (assets/sprites/image.png)
        Image.asset(
          'assets/sprites/image.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF81D4FA),
                  Color(0xFFA5D6A7),
                  Color(0xFF388E3C),
                ],
              ),
            ),
          ),
        ),

        // 2. Translucent soft overlay for UI contrast and readability
        if (overlayOpacity > 0)
          Container(
            color: Colors.black.withValues(alpha: overlayOpacity),
          ),

        // 3. Screen Body Content
        child,
      ],
    );
  }
}
